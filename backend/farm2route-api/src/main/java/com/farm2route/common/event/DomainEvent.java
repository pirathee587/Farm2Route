package com.farm2route.common.event;

import lombok.Getter;

import java.time.Instant;
import java.util.UUID;

/**
 * Abstract base for all Farm2Route domain events published to RabbitMQ.
 *
 * Design rules:
 *  - eventId:   UUID auto-generated at construction — used as the idempotency key by consumers.
 *  - eventType: String that matches the RabbitMQ routing key (e.g. "booking.created").
 *  - occurredAt: Instant of event creation — for auditing and ordering.
 *  - Payloads contain IDs and essential primitives ONLY — no nested entity graphs.
 *    Consumers re-fetch the full entity from the DB to avoid stale-data bugs.
 *
 * MVP Limitation: published via @TransactionalEventListener(AFTER_COMMIT).
 * If RabbitMQ is unavailable at publish time the event is permanently lost.
 * Future: replace with Transactional Outbox Pattern for guaranteed delivery.
 */
@Getter
public abstract class DomainEvent {

    private final UUID   eventId;
    private final Instant occurredAt;
    private final String  eventType;

    protected DomainEvent(String eventType) {
        this.eventId    = UUID.randomUUID();
        this.occurredAt = Instant.now();
        this.eventType  = eventType;
    }

    // No-arg constructor for Jackson deserialization
    protected DomainEvent() {
        this.eventId    = null;
        this.occurredAt = null;
        this.eventType  = null;
    }
}
