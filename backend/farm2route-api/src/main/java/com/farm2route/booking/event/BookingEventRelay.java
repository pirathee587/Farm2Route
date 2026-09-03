package com.farm2route.booking.event;

import com.farm2route.common.event.BookingCancelledEvent;
import com.farm2route.common.event.BookingCreatedEvent;
import com.farm2route.common.event.EventPublisher;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * Relay between Spring's internal application event bus and RabbitMQ.
 *
 * BookingService publishes a Spring ApplicationEvent (in-JVM, no broker involved).
 * This relay receives it via @TransactionalEventListener(phase = AFTER_COMMIT),
 * which guarantees the event fires ONLY if the originating DB transaction committed.
 *
 * If the DB transaction rolls back for any reason, this method is never called —
 * so we never publish a RabbitMQ message about a booking that doesn't exist in the DB.
 *
 * MVP Limitation: if RabbitMQ is unavailable at the moment this runs (AFTER_COMMIT),
 * EventPublisher logs the error and the event is permanently lost.
 * Future fix: Transactional Outbox Pattern (see EVENTS.md).
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class BookingEventRelay {

    private final EventPublisher eventPublisher;

    /**
     * Triggered AFTER the booking creation transaction commits.
     * Publishes BookingCreatedEvent to RabbitMQ routing key "booking.created".
     */
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onBookingCreated(BookingCreatedEvent event) {
        log.info("[BookingEventRelay] Relaying booking.created for bookingId={}", event.getBookingId());
        eventPublisher.publish(event);
    }

    /**
     * Triggered AFTER the booking cancellation transaction commits.
     * Publishes BookingCancelledEvent to RabbitMQ routing key "booking.cancelled".
     */
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onBookingCancelled(BookingCancelledEvent event) {
        log.info("[BookingEventRelay] Relaying booking.cancelled for bookingId={}", event.getBookingId());
        eventPublisher.publish(event);
    }
}
