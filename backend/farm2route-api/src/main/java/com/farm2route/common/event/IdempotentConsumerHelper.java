package com.farm2route.common.event;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.UUID;

/**
 * INSERT-first idempotency guard for RabbitMQ consumers.
 *
 * Why INSERT-first instead of check-then-insert?
 * -------------------------------------------------
 * A naive pattern:
 *   if (repo.existsById(new ProcessedEventId(eventId, consumerName))) return;  // SELECT
 *   process();
 *   repo.save(new ProcessedEvent(eventId, consumerName, Instant.now())); // INSERT
 *
 * has a race window: two consumer threads can both read "not found"
 * simultaneously and both proceed to process the event.
 *
 * The correct pattern:
 *   try {
 *     repo.saveAndFlush(new ProcessedEvent(eventId, consumerName, Instant.now()));  // INSERT
 *     // ... won the race: proceed with business logic
 *   } catch (DataIntegrityViolationException) {
 *     // Composite PRIMARY KEY violation: this consumer already processed this event — skip
 *   }
 *
 * The composite PRIMARY KEY constraint on (event_id, consumer_name) is the per-consumer idempotency guard.
 *
 * Transaction isolation:
 * REQUIRES_NEW ensures this INSERT commits independently of the caller's
 * transaction, so a rollback in the consumer does not undo the idempotency mark.
 * This is intentional: if the consumer fails after marking, the event goes to DLQ —
 * we never want to re-process an event that was already successfully handled.
 *
 * Usage in consumers:
 *   if (!idempotentHelper.tryMarkProcessed(event.getEventId(), CONSUMER_NAME)) return;
 *   // ... do the side effect here (audit, notification, etc.)
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class IdempotentConsumerHelper {

    private final ProcessedEventRepository processedEventRepository;

    /**
     * Attempts to mark the event as processed by inserting (eventId, consumerName) into processed_events.
     *
     * @param eventId      the DomainEvent.eventId to mark
     * @param consumerName the identifier of the consumer (e.g. "notification-service", "audit-service")
     * @return true  if the insert succeeded and the consumer should proceed
     *         false if the event was already processed by this consumer (duplicate composite key) — consumer must skip
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public boolean tryMarkProcessed(UUID eventId, String consumerName) {
        try {
            processedEventRepository.saveAndFlush(
                    new ProcessedEvent(eventId, consumerName, Instant.now())
            );
            log.debug("[IdempotentConsumer] Marked event {} for consumer '{}' as processed", eventId, consumerName);
            return true;
        } catch (DataIntegrityViolationException ex) {
            log.warn("[IdempotentConsumer] Duplicate event {} for consumer '{}' — skipping (already processed)", eventId, consumerName);
            return false;
        }
    }
}
