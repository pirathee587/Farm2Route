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
 *   if (repo.existsById(eventId)) return;  // SELECT
 *   process();
 *   repo.save(new ProcessedEvent(eventId)); // INSERT
 *
 * has a race window: two consumer threads can both read "not found"
 * simultaneously and both proceed to process the event.
 *
 * The correct pattern:
 *   try {
 *     repo.saveAndFlush(new ProcessedEvent(eventId));  // INSERT
 *     // ... won the race: proceed with business logic
 *   } catch (DataIntegrityViolationException) {
 *     // PRIMARY KEY violation: another thread already processed this event — skip
 *   }
 *
 * The PRIMARY KEY constraint on event_id is the idempotency guard.
 *
 * Transaction isolation:
 * REQUIRES_NEW ensures this INSERT commits independently of the caller's
 * transaction, so a rollback in the consumer does not undo the idempotency mark.
 * This is intentional: if the consumer fails after marking, the event goes to DLQ —
 * we never want to re-process an event that was already successfully handled.
 *
 * Usage in consumers:
 *   if (!idempotentHelper.tryMarkProcessed(event.getEventId())) return;
 *   // ... do the side effect here (audit, notification, etc.)
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class IdempotentConsumerHelper {

    private final ProcessedEventRepository processedEventRepository;

    /**
     * Attempts to mark the event as processed by inserting its eventId into processed_events.
     *
     * @param eventId the DomainEvent.eventId to mark
     * @return true  if the insert succeeded and the consumer should proceed
     *         false if the event was already processed (duplicate key) — consumer must skip
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public boolean tryMarkProcessed(UUID eventId) {
        try {
            processedEventRepository.saveAndFlush(
                    new ProcessedEvent(eventId, Instant.now())
            );
            log.debug("[IdempotentConsumer] Marked event {} as processed", eventId);
            return true;
        } catch (DataIntegrityViolationException ex) {
            log.warn("[IdempotentConsumer] Duplicate event {} — skipping (already processed)", eventId);
            return false;
        }
    }
}
