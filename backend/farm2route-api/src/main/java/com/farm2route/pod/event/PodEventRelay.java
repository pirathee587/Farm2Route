package com.farm2route.pod.event;

import com.farm2route.common.event.EventPublisher;
import com.farm2route.common.event.PodConfirmedEvent;
import com.farm2route.common.event.PodSubmittedEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * Relay between Spring's internal application event bus and RabbitMQ for Proof of Delivery (POD) events.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class PodEventRelay {

    private final EventPublisher eventPublisher;

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onPodSubmitted(PodSubmittedEvent event) {
        log.info("[PodEventRelay] Relaying pod.submitted for podId={}, bookingId={}", event.getPodId(), event.getBookingId());
        eventPublisher.publish(event);
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onPodConfirmed(PodConfirmedEvent event) {
        log.info("[PodEventRelay] Relaying pod.confirmed for podId={}, bookingId={}", event.getPodId(), event.getBookingId());
        eventPublisher.publish(event);
    }
}
