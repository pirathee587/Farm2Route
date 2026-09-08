package com.farm2route.incident.event;

import com.farm2route.common.event.EventPublisher;
import com.farm2route.common.event.IncidentEscalatedEvent;
import com.farm2route.common.event.IncidentStatusChangedEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * Relay between Spring's internal application event bus and RabbitMQ for Admin Incident moderation events.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class AdminIncidentEventRelay {

    private final EventPublisher eventPublisher;

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onIncidentStatusChanged(IncidentStatusChangedEvent event) {
        log.info("[AdminIncidentEventRelay] Relaying incident.status_changed for incidentId={}, oldStatus={}, newStatus={}",
                event.getIncidentId(), event.getOldStatus(), event.getNewStatus());
        eventPublisher.publish(event);
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onIncidentEscalated(IncidentEscalatedEvent event) {
        log.info("[AdminIncidentEventRelay] Relaying incident.escalated for incidentId={}, adminId={}",
                event.getIncidentId(), event.getAdminId());
        eventPublisher.publish(event);
    }
}
