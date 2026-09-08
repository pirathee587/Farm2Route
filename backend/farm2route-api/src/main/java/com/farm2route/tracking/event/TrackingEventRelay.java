package com.farm2route.tracking.event;

import com.farm2route.common.event.EventPublisher;
import com.farm2route.common.event.TripArrivedEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * Relay between Spring's internal application event bus and RabbitMQ for tracking events.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class TrackingEventRelay {

    private final EventPublisher eventPublisher;

    /**
     * Triggered AFTER the geofence arrival transaction commits.
     * Publishes TripArrivedEvent to RabbitMQ routing key "trip.arrived".
     */
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onTripArrived(TripArrivedEvent event) {
        log.info("[TrackingEventRelay] Relaying trip.arrived for tripId={}, bookingId={}",
                event.getTripId(), event.getBookingId());
        eventPublisher.publish(event);
    }
}
