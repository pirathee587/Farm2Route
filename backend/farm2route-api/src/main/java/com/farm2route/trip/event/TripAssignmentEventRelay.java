package com.farm2route.trip.event;

import com.farm2route.common.event.DriverAssignedEvent;
import com.farm2route.common.event.EventPublisher;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

@Slf4j
@Component
@RequiredArgsConstructor
public class TripAssignmentEventRelay {

    private final EventPublisher eventPublisher;

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onDriverAssigned(DriverAssignedEvent event) {
        log.info("[TripAssignmentEventRelay] Relaying driver.assigned for assignmentId={}, bookingId={}",
                event.getAssignmentId(), event.getBookingId());
        eventPublisher.publish(event);
    }
}
