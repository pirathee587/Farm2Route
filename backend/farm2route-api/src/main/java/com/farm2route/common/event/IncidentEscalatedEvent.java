package com.farm2route.common.event;

import com.farm2route.config.RabbitMQConfig;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.UUID;

/**
 * Fired when an admin escalates an incident report.
 * Consumers: notification.queue, audit.queue
 */
@Getter
@NoArgsConstructor
public class IncidentEscalatedEvent extends DomainEvent {

    private UUID incidentId;
    private UUID bookingId;
    private UUID reporterUserId;
    private UUID adminId;
    private String notes;

    @Builder
    public IncidentEscalatedEvent(UUID incidentId, UUID bookingId, UUID reporterUserId, UUID adminId, String notes) {
        super(RabbitMQConfig.RK_INCIDENT_ESCALATED);
        this.incidentId = incidentId;
        this.bookingId = bookingId;
        this.reporterUserId = reporterUserId;
        this.adminId = adminId;
        this.notes = notes;
    }
}
