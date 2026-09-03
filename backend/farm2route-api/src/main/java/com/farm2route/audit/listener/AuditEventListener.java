package com.farm2route.audit.listener;

import com.farm2route.audit.service.AuditService;
import com.farm2route.common.event.*;
import com.farm2route.config.RabbitMQConfig;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Component;

/**
 * RabbitMQ consumer for the audit.queue.
 *
 * Bound to routing key "#" — receives ALL domain events regardless of type.
 * Each event type maps to an audit log entry via AuditService.logAction().
 *
 * Idempotency: INSERT-first pattern via IdempotentConsumerHelper ensures
 * each event is audited exactly once even if RabbitMQ redelivers the message.
 *
 * AuditService.logAction() is already @Async — within this consumer that
 * annotation has no effect (we're already on a listener thread), but it doesn't
 * cause harm. The call completes synchronously within the consumer.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class AuditEventListener {

    private final AuditService            auditService;
    private final IdempotentConsumerHelper idempotentHelper;

    @RabbitListener(queues = RabbitMQConfig.AUDIT_QUEUE)
    public void handleEvent(@Payload DomainEvent event) {
        if (!idempotentHelper.tryMarkProcessed(event.getEventId())) return;

        try {
            String details = buildAuditDetails(event);
            auditService.logAction(
                    null,                        // actor: null — event is system-generated post-commit
                    event.getEventType().toUpperCase().replace(".", "_"),
                    resolveEntityName(event),
                    resolveEntityId(event),
                    null,
                    details,
                    null,
                    null
            );
            log.debug("[AuditEventListener] Audit entry written for eventType={} eventId={}",
                    event.getEventType(), event.getEventId());
        } catch (Exception ex) {
            // AuditService already swallows exceptions, but guard here too so DLQ only
            // receives genuine deserialization/infrastructure failures.
            log.error("[AuditEventListener] Failed to write audit log for eventType={} eventId={}: {}",
                    event.getEventType(), event.getEventId(), ex.getMessage(), ex);
            throw ex; // rethrow so retry/DLQ mechanism can handle it
        }
    }

    private String buildAuditDetails(DomainEvent event) {
        if (event instanceof BookingCreatedEvent e) {
            return "bookingNumber=" + e.getBookingNumber()
                    + ",farmerId=" + e.getFarmerId()
                    + ",agencyId=" + e.getAgencyId()
                    + ",totalAmount=" + e.getTotalAmount();
        }
        if (event instanceof BookingCancelledEvent e) {
            return "bookingNumber=" + e.getBookingNumber()
                    + ",reason=" + e.getCancellationReason();
        }
        if (event instanceof IncidentSubmittedEvent e) {
            return "bookingId=" + e.getBookingId()
                    + ",incidentType=" + e.getIncidentType()
                    + ",status=OPEN";
        }
        if (event instanceof PodConfirmedEvent e) {
            return "bookingId=" + e.getBookingId()
                    + ",confirmedAt=" + e.getConfirmedAt();
        }
        if (event instanceof ReviewSubmittedEvent e) {
            return "bookingId=" + e.getBookingId()
                    + ",agencyRating=" + e.getAgencyRating();
        }
        return "eventType=" + event.getEventType();
    }

    private String resolveEntityName(DomainEvent event) {
        if (event instanceof BookingCreatedEvent || event instanceof BookingCancelledEvent) return "BOOKING";
        if (event instanceof IncidentSubmittedEvent) return "INCIDENT_REPORT";
        if (event instanceof PodConfirmedEvent)      return "POD_RECORD";
        if (event instanceof ReviewSubmittedEvent)   return "REVIEW";
        return "UNKNOWN";
    }

    private String resolveEntityId(DomainEvent event) {
        if (event instanceof BookingCreatedEvent e)   return e.getBookingId().toString();
        if (event instanceof BookingCancelledEvent e) return e.getBookingId().toString();
        if (event instanceof IncidentSubmittedEvent e) return e.getIncidentId().toString();
        if (event instanceof PodConfirmedEvent e)     return e.getPodId().toString();
        if (event instanceof ReviewSubmittedEvent e)  return e.getReviewId().toString();
        return "unknown";
    }
}
