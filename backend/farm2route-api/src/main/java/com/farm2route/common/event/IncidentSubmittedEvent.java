package com.farm2route.common.event;

import com.farm2route.common.enums.IncidentType;
import com.farm2route.config.RabbitMQConfig;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.UUID;

/**
 * Fired after an incident report is successfully saved (AFTER_COMMIT).
 * Consumers: notification.queue (notify admin), audit.queue
 */
@Getter
@NoArgsConstructor
public class IncidentSubmittedEvent extends DomainEvent {

    private UUID         incidentId;
    private UUID         bookingId;
    private UUID         farmerId;
    private IncidentType incidentType;
    private String       title;

    @Builder
    public IncidentSubmittedEvent(UUID incidentId, UUID bookingId, UUID farmerId,
                                  IncidentType incidentType, String title) {
        super(RabbitMQConfig.RK_INCIDENT_SUBMITTED);
        this.incidentId   = incidentId;
        this.bookingId    = bookingId;
        this.farmerId     = farmerId;
        this.incidentType = incidentType;
        this.title        = title;
    }
}
