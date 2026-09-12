package com.farm2route.agency.event;

import com.farm2route.common.event.AgencyRegisteredEvent;
import com.farm2route.common.event.EventPublisher;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * Relay between Spring's internal application event bus and RabbitMQ for the Agency module.
 *
 * AgencyService publishes a Spring ApplicationEvent.
 * This relay receives it via @TransactionalEventListener(phase = AFTER_COMMIT),
 * ensuring the RabbitMQ message is dispatched only after the DB transaction commits successfully.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class AgencyEventRelay {

    private final EventPublisher eventPublisher;

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onAgencyRegistered(AgencyRegisteredEvent event) {
        log.info("[AgencyEventRelay] Relaying agency.registered for agencyId={}", event.getAgencyId());
        eventPublisher.publish(event);
    }
}
