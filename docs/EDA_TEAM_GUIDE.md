# Farm2Route — Event-Driven Architecture (EDA) Team Guide
### For Member 2 & Member 3

---

## 1. Executive Summary

We have migrated Farm2Route's architecture from synchronous method calls to an **asynchronous Event-Driven Architecture (EDA)** using **RabbitMQ**.

### Key Rules
1. **Zero Frontend Impact**: All REST controllers (`POST /api/v1/...`, `GET /api/v1/...`) keep their exact URLs, request bodies, and response shapes unchanged. Mobile/web clients continue talking to Spring Boot via HTTP REST.
2. **Core Writes Stay Synchronous**: The primary database insert/update remains in the main database transaction so the client receives IDs and status synchronously.
3. **Side Effects Become Asynchronous**: Notifications, audit logs, and cross-module handoffs are decoupled into domain events published to RabbitMQ.
4. **Publish ONLY After Commit**: Events are emitted via Spring's `@TransactionalEventListener(phase = AFTER_COMMIT)`. If a database transaction rolls back, no RabbitMQ message is ever sent.
5. **Idempotent Consumers**: Every consumer checks the `processed_events` table before processing to prevent duplicate operations in case of network redelivery.

---

## 2. RabbitMQ Architecture & Contracts

The authoritative contract is documented in [EVENTS.md](file:///c:/Users/Piratheepan/Desktop/Farm2Route/EVENTS.md) at the repository root.

### Exchanges & Queues

```
              ┌─────────────────────────────┐
              │  farm2route.events (Topic)  │
              └──────────────┬──────────────┘
                             │
            ┌────────────────┴────────────────┐
            │ routing keys                    │ routing key: #
            ▼                                 ▼
   ┌──────────────────┐              ┌──────────────────┐
   │notification.queue│              │   audit.queue    │
   └────────┬─────────┘              └────────┬─────────┘
            │                                 │
     (after 3 retries)                 (after 3 retries)
            │                                 │
            ▼                                 ▼
   ┌────────────────────────────────────────────────────┐
   │               farm2route.dlx (Direct)              │
   └────────┬─────────────────────────────────┬─────────┘
            ▼                                 ▼
┌──────────────────────┐          ┌──────────────────────┐
│notification.queue.dlq│          │   audit.queue.dlq    │
└──────────────────────┘          └──────────────────────┘
```

- **Exchange**: `farm2route.events` (Topic, Durable)
- **Dead Letter Exchange (DLX)**: `farm2route.dlx` (Direct)
- **Routing Key Convention**: `{module}.{action}` (e.g. `booking.created`, `pod.confirmed`, `incident.submitted`)
- **Retry Policy**: 3 attempts with exponential backoff (1s, 2s, 4s up to 10s), then automatically dead-lettered to `{queue}.dlq`.

---

## 3. Reference Implementation (Phase 3 Template)

The **Booking creation flow** has been fully migrated as the reference template. You should copy this pattern for your modules.

### Pattern Overview
```
BookingService (Service)
       │
       ▼ saves entity to PostgreSQL
1. bookingRepository.save(booking)
       │
       ▼ publishes Spring ApplicationEvent (in-memory)
2. applicationEventPublisher.publishEvent(BookingCreatedEvent)
       │
       ▼ DB Transaction COMMITS
BookingEventRelay (@TransactionalEventListener AFTER_COMMIT)
       │
       ▼ publishes to RabbitMQ via EventPublisher
3. eventPublisher.publish(event)
       │
       ▼ AMQP message routes to queues
BookingEventListener & AuditEventListener (@RabbitListener)
       │
       ▼ INSERT-first idempotency check
4. if (!idempotentHelper.tryMarkProcessed(event.getEventId())) return;
       │
       ▼ execute side effect asynchronously
5. log notification / write audit record
```

---

## 4. How Member 2 & Member 3 Should Implement Their Flows

### Member Responsibilities

| Member | Module / Domain | Events to Implement |
|---|---|---|
| **Member 1** | Booking, Incident, Review | `booking.created`, `booking.cancelled`, `incident.submitted`, `review.submitted` *(Completed)* |
| **Member 2** | Packages, Driver Assignment, Vehicle | `package.created`, `driver.assigned`, `vehicle.kyc_updated` |
| **Member 3** | POD (Proof of Delivery), Admin Moderation | `pod.confirmed` (triggers delivery notification + review eligibility) |

---

### Step-by-Step Recipe for Converting Any Service Flow

Follow these 4 simple steps to convert any flow in your module:

#### Step A: Create or Use the Event Class
Inherit from `com.farm2route.common.event.DomainEvent`. Keep payloads small (IDs and essential fields only):

```java
package com.farm2route.common.event;

import com.farm2route.config.RabbitMQConfig;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import java.util.UUID;

@Getter
@NoArgsConstructor
public class PodConfirmedEvent extends DomainEvent {
    private UUID podId;
    private UUID bookingId;
    private UUID farmerId;
    private UUID agencyId;
    private UUID driverId;

    @Builder
    public PodConfirmedEvent(UUID podId, UUID bookingId, UUID farmerId, UUID agencyId, UUID driverId) {
        super(RabbitMQConfig.RK_POD_CONFIRMED); // routing key constant
        this.podId = podId;
        this.bookingId = bookingId;
        this.farmerId = farmerId;
        this.agencyId = agencyId;
        this.driverId = driverId;
    }
}
```

#### Step B: Inject `ApplicationEventPublisher` into Your Service
In your core service, save the entity, then publish the event:

```java
@Service
@RequiredArgsConstructor
public class PodService {

    private final PodRepository podRepository;
    private final ApplicationEventPublisher applicationEventPublisher; // <-- Inject this

    @Transactional
    public PodResponse confirmDelivery(UUID podId) {
        PodRecord pod = podRepository.findById(podId).orElseThrow(...);
        pod.setStatus(PodStatus.CONFIRMED);
        pod = podRepository.save(pod);

        // Publish Spring in-memory event (guaranteed not sent if TX rolls back)
        applicationEventPublisher.publishEvent(
            PodConfirmedEvent.builder()
                .podId(pod.getId())
                .bookingId(pod.getBooking().getId())
                .farmerId(pod.getBooking().getFarmer().getId())
                .agencyId(pod.getBooking().getAgency().getId())
                .driverId(pod.getBooking().getDriver().getId())
                .build()
        );

        return mapToResponse(pod);
    }
}
```

#### Step C: Create an Event Relay Component
This relays the event to RabbitMQ **only after the database transaction commits**:

```java
package com.farm2route.tracking.event;

import com.farm2route.common.event.EventPublisher;
import com.farm2route.common.event.PodConfirmedEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

@Slf4j
@Component
@RequiredArgsConstructor
public class PodEventRelay {

    private final EventPublisher eventPublisher;

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onPodConfirmed(PodConfirmedEvent event) {
        log.info("[PodEventRelay] Relaying pod.confirmed to RabbitMQ: podId={}", event.getPodId());
        eventPublisher.publish(event);
    }
}
```

#### Step D: Create or Update Consumers with Idempotency
In the consumer, always check `idempotentHelper.tryMarkProcessed(event.getEventId())`:

```java
@Component
@RequiredArgsConstructor
public class ReviewEligibilityListener {

    private final IdempotentConsumerHelper idempotentHelper;

    @RabbitListener(queues = RabbitMQConfig.NOTIFICATION_QUEUE)
    public void handlePodConfirmed(@Payload PodConfirmedEvent event) {
        // Idempotency check: INSERT into processed_events. Skips if duplicate delivery.
        if (!idempotentHelper.tryMarkProcessed(event.getEventId())) {
            return;
        }

        // Side effect: Mark booking as eligible for farmer review
        log.info("Booking {} is now eligible for farmer review", event.getBookingId());
    }
}
```

---

## 5. Flyway Migrations Status

The migration version conflict has been resolved and verified against Supabase:
- `V17__seed_packages_and_indexes.sql` — Applied (Rank 17)
- `V18__enhance_incident_tables.sql` — Applied (Rank 18)
- `V19__enhance_review_tables.sql` — Applied (Rank 19)
- `V20__create_agency_earnings_and_withdrawal_requests.sql` — Applied (Rank 20)
- `V21__add_vehicle_kyc_columns.sql` — Applied (Rank 21)
- `V22__create_processed_events.sql` — Applied (Rank 22)

> **Important**: Any new database migration file added by Member 2 or Member 3 **must start at `V23__...`**.

---

## 6. How to Run Locally

### Pure REST / Database Development (No RabbitMQ needed)
```bash
cd backend/farm2route-api
mvn spring-boot:run
```
- `RABBITMQ_LISTENER_AUTO_STARTUP: false` is configured by default in `application-dev.yml`.
- No connection failure logs will spam your terminal.
- Publishing failures are handled gracefully without failing client requests.

### With RabbitMQ (Testing message flows)
1. Start RabbitMQ via Docker:
   ```bash
   docker run -d --name rabbitmq -p 5672:5672 -p 15672:15672 rabbitmq:3-management
   ```
2. Enable listeners:
   - PowerShell: `$env:RABBITMQ_LISTENER_AUTO_STARTUP="true"`
   - Bash: `export RABBITMQ_LISTENER_AUTO_STARTUP=true`
3. Run the API:
   ```bash
   mvn spring-boot:run
   ```
4. Access RabbitMQ UI: `http://localhost:15672` (User: `farm2route`, Password: `farm2route_dev`).

---

## 7. Unit Testing Requirements

When writing unit tests for your modified service:
- **Mock `ApplicationEventPublisher`**, NOT `RabbitTemplate`.
- Verify `publishEvent(...)` is called upon successful save.
- Verify `publishEvent(...)` is **NOT** called if repository save throws an exception.
- Write a separate unit test for your `*EventRelay` mocking `EventPublisher`.
