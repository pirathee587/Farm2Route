package com.farm2route.farmer.event;

import com.farm2route.common.event.EventPublisher;
import com.farm2route.common.event.FarmerRegisteredEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * Relay between Spring's internal application event bus and RabbitMQ for the Farmer module.
 *
 * FarmerService publishes a Spring ApplicationEvent.
 * This relay receives it via @TransactionalEventListener(phase = AFTER_COMMIT),
 * ensuring the RabbitMQ message is dispatched only after the DB transaction commits successfully.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class FarmerEventRelay {

    private final EventPublisher eventPublisher;

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onFarmerRegistered(FarmerRegisteredEvent event) {
        log.info("[FarmerEventRelay] Relaying farmer.registered for farmerId={}", event.getFarmerId());
        eventPublisher.publish(event);
    }
}
