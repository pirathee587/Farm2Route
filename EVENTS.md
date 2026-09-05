# Farm2Route — Domain Event Contract (EVENTS.md)

> **This document is the authoritative contract for all RabbitMQ events in the Farm2Route system.**
> Every team member must code against these definitions. Do not invent routing keys or payload fields outside this document.
> Update this document and get it reviewed before adding a new event.

---

## Exchange

| Name | Type | Durable |
|---|---|---|
| `farm2route.events` | Topic | Yes |

One shared exchange for all modules. Routing keys determine which consumers receive which messages.

---

## Dead Letter Exchange (DLX)

| Name | Type | Purpose |
|---|---|---|
| `farm2route.dlx` | Direct | Receives messages that exhaust all retries |

Each queue routes failed messages here via `x-dead-letter-exchange` queue argument.

---

## Queues & Bindings

| Queue | Exchange | Routing Key(s) | DLQ |
|---|---|---|---|
| `notification.queue` | `farm2route.events` | `booking.created`, `booking.cancelled`, `incident.submitted`, `pod.submitted`, `pod.confirmed`, `review.submitted`, `vehicle.kyc_updated`, `package.created`, `kyc.reviewed`, `trip.arrived`, `incident.status_changed`, `incident.escalated`, `review.moderated` | `notification.queue.dlq` |
| `audit.queue` | `farm2route.events` | `#` (wildcard — all events) | `audit.queue.dlq` |
| `notification.queue.dlq` | `farm2route.dlx` | `notification.queue.dlq` | — |
| `audit.queue.dlq` | `farm2route.dlx` | `audit.queue.dlq` | — |

---

## Routing Key Convention

```
{module}.{action}
```

Examples: `booking.created`, `booking.cancelled`, `incident.submitted`, `pod.submitted`, `pod.confirmed`, `review.submitted`, `kyc.reviewed`, `trip.arrived`, `incident.status_changed`, `incident.escalated`, `review.moderated`

---

## Retry & DLQ Policy

| Setting | Value |
|---|---|
| Max retry attempts | 3 |
| Initial retry interval | 1000 ms |
| Backoff multiplier | 2.0x |
| Max retry interval | 10000 ms |
| `default-requeue-rejected` | `false` — **critical**: without this, failed messages requeue forever and never reach DLQ |
| After exhausting retries | Message routed to `{queue}.dlq` via `farm2route.dlx` |

---

## Idempotency (INSERT-first Pattern)

All consumers use `tryMarkProcessed(UUID eventId)` via `IdempotentConsumerHelper`.

**Why INSERT-first?** A pre-check `SELECT` followed by `INSERT` has a race condition when two consumer threads process the same event concurrently. The `event_id UUID PRIMARY KEY` constraint is the idempotency guard:
1. `saveAndFlush()` inserts `event_id`
2. If duplicate, `DataIntegrityViolationException` is caught and helper returns `false`
3. Consumer skips processing immediately

---

## ⚠️ Architectural Limitation — MVP vs Production

> **Event Loss Risk (MVP)**
>
> The current implementation uses `@TransactionalEventListener(phase = AFTER_COMMIT)`:
> ```
> DB commit ✅  →  RabbitMQ publish ❌ (if broker down / network failure)
>                        ↓
>              event PERMANENTLY LOST
> ```
> This is an accepted trade-off for the MVP deadline.
>
> **Future Production Enhancement — Transactional Outbox Pattern**:
> ```
> BookingService — ONE DB TRANSACTION
>  ┌──────────────────────────┐
>  │  INSERT booking          │
>  │  INSERT outbox_events    │  ← stored atomically in PostgreSQL
>  └──────────────────────────┘
>           ↓
>  OutboxPublisher (@Scheduled / Debezium CDC)
>           ↓
>       RabbitMQ
> ```

---

## Event Payload Schemas

Payloads contain IDs and essential fields only — no nested entity objects. Consumers re-fetch what they need.

### `booking.created` → BookingCreatedEvent
```json
{
  "eventId":       "uuid",
  "eventType":     "booking.created",
  "occurredAt":    "2026-09-03T14:00:00Z",
  "bookingId":     "uuid",
  "bookingNumber": "F2R-xxx",
  "farmerId":      "uuid",
  "agencyId":      "uuid",
  "packageId":     "uuid | null",
  "totalAmount":   "125.50"
}
```

### `booking.cancelled` → BookingCancelledEvent
```json
{
  "eventId":            "uuid",
  "eventType":          "booking.cancelled",
  "occurredAt":         "2026-09-03T14:00:00Z",
  "bookingId":          "uuid",
  "bookingNumber":      "F2R-xxx",
  "farmerId":           "uuid",
  "agencyId":           "uuid",
  "driverId":           "uuid | null",
  "cancellationReason": "Cancelled by farmer"
}
```

### `incident.submitted` → IncidentSubmittedEvent
```json
{
  "eventId":      "uuid",
  "eventType":    "incident.submitted",
  "occurredAt":   "2026-09-03T14:00:00Z",
  "incidentId":   "uuid",
  "bookingId":    "uuid",
  "farmerId":     "uuid",
  "incidentType": "CARGO_DAMAGE",
  "title":        "Cargo Damage - F2R-xxx"
}
```

### `pod.submitted` → PodSubmittedEvent
```json
{
  "eventId":      "uuid",
  "eventType":    "pod.submitted",
  "occurredAt":   "2026-09-03T14:00:00Z",
  "podId":        "uuid",
  "bookingId":    "uuid",
  "farmerUserId": "uuid",
  "agencyId":     "uuid",
  "driverId":     "uuid"
}
```

### `pod.confirmed` → PodConfirmedEvent
```json
{
  "eventId":     "uuid",
  "eventType":   "pod.confirmed",
  "occurredAt":  "2026-09-03T14:00:00Z",
  "podId":       "uuid",
  "bookingId":   "uuid",
  "farmerId":    "uuid",
  "agencyId":    "uuid",
  "driverId":    "uuid",
  "confirmedAt": "2026-09-03T13:55:00Z"
}
```

### `review.submitted` → ReviewSubmittedEvent
```json
{
  "eventId":      "uuid",
  "eventType":    "review.submitted",
  "occurredAt":   "2026-09-03T14:00:00Z",
  "reviewId":     "uuid",
  "bookingId":    "uuid",
  "farmerId":     "uuid",
  "agencyId":     "uuid",
  "driverId":     "uuid | null",
  "agencyRating": 5
}
```

### `vehicle.kyc_updated` → VehicleKycUpdatedEvent
```json
{
  "eventId":   "uuid",
  "eventType": "vehicle.kyc_updated",
  "occurredAt": "2026-09-03T14:00:00Z",
  "vehicleId": "uuid",
  "agencyId":  "uuid",
  "kycStatus": "APPROVED"
}
```

### `kyc.reviewed` → KycReviewedEvent
```json
{
  "eventId":         "uuid",
  "eventType":       "kyc.reviewed",
  "occurredAt":      "2026-09-03T14:00:00Z",
  "entityType":      "AGENCY | DRIVER | VEHICLE",
  "entityId":        "uuid",
  "ownerUserId":     "uuid",
  "status":          "APPROVED | REJECTED",
  "rejectionReason": "string | null"
}
```

### `trip.arrived` → TripArrivedEvent
```json
{
  "eventId":      "uuid",
  "eventType":    "trip.arrived",
  "occurredAt":   "2026-09-03T14:00:00Z",
  "tripId":       "uuid",
  "bookingId":    "uuid",
  "farmerUserId": "uuid",
  "agencyUserId": "uuid"
}
```

### `incident.status_changed` → IncidentStatusChangedEvent
```json
{
  "eventId":        "uuid",
  "eventType":      "incident.status_changed",
  "occurredAt":     "2026-09-03T14:00:00Z",
  "incidentId":     "uuid",
  "bookingId":      "uuid",
  "reporterUserId": "uuid",
  "oldStatus":      "OPEN",
  "newStatus":      "INVESTIGATING | RESOLVED | REJECTED",
  "adminId":        "uuid"
}
```

### `incident.escalated` → IncidentEscalatedEvent
```json
{
  "eventId":        "uuid",
  "eventType":      "incident.escalated",
  "occurredAt":     "2026-09-03T14:00:00Z",
  "incidentId":     "uuid",
  "bookingId":      "uuid",
  "reporterUserId": "uuid",
  "adminId":        "uuid",
  "notes":          "Priority review required"
}
```

### `review.moderated` → ReviewModeratedEvent
```json
{
  "eventId":      "uuid",
  "eventType":    "review.moderated",
  "occurredAt":   "2026-09-03T14:00:00Z",
  "reviewId":     "uuid",
  "adminId":      "uuid",
  "action":       "HIDE | RESTORE | ESCALATE",
  "reason":       "Inappropriate content",
  "farmerUserId": "uuid"
}
```

---

## Team Module Ownership (Phase 4 Rollout)

| Flow | Event | Module Owner | Status |
|---|---|---|---|
| Booking creation | `booking.created` | Member 1 | Reference complete |
| Booking cancellation | `booking.cancelled` | Member 1 | Complete |
| Incident submission | `incident.submitted` | Member 1 | Complete |
| POD submission | `pod.submitted` | Member 3 | Complete |
| POD confirmation | `pod.confirmed` | Member 3 | Complete |
| Review submission | `review.submitted` | Member 1 | Complete |
| Vehicle KYC update | `vehicle.kyc_updated` | Member 2 | Complete |
| Admin KYC review | `kyc.reviewed` | Member 3 | Complete |
| Geofence trip arrival | `trip.arrived` | Member 3 | Complete |
| Incident status change | `incident.status_changed` | Member 3 | Complete |
| Incident escalation | `incident.escalated` | Member 3 | Complete |
| Review moderation | `review.moderated` | Member 3 | Complete |
