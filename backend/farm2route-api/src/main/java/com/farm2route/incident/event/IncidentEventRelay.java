package com.farm2route.incident.event;

import com.farm2route.common.event.EventPublisher;
import com.farm2route.common.event.IncidentSubmittedEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * Relay between Spring's internal application event bus and RabbitMQ for Incident events.
 * Listens for IncidentSubmittedEvent AFTER_COMMIT and relays it to RabbitMQ.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class IncidentEventRelay {

    private final EventPublisher eventPublisher;

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onIncidentSubmitted(IncidentSubmittedEvent event) {
        log.info("[IncidentEventRelay] Relaying incident.submitted for incidentId={}", event.getIncidentId());
        eventPublisher.publish(event);
    }
}
