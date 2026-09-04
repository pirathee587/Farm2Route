package com.farm2route.common.event;

import com.farm2route.common.enums.IncidentStatus;
import com.farm2route.config.RabbitMQConfig;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.UUID;

/**
 * Fired when an incident status transitions (e.g. OPEN -> INVESTIGATING -> RESOLVED/REJECTED).
 * Consumers: notification.queue, audit.queue
 */
@Getter
@NoArgsConstructor
public class IncidentStatusChangedEvent extends DomainEvent {

    private UUID incidentId;
    private UUID bookingId;
    private UUID reporterUserId;
    private IncidentStatus oldStatus;
    private IncidentStatus newStatus;
    private UUID adminId;

    @Builder
    public IncidentStatusChangedEvent(UUID incidentId, UUID bookingId, UUID reporterUserId,
                                      IncidentStatus oldStatus, IncidentStatus newStatus, UUID adminId) {
        super(RabbitMQConfig.RK_INCIDENT_STATUS_CHANGED);
        this.incidentId = incidentId;
        this.bookingId = bookingId;
        this.reporterUserId = reporterUserId;
        this.oldStatus = oldStatus;
        this.newStatus = newStatus;
        this.adminId = adminId;
    }
}
