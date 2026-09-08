package com.farm2route.common.event;

import com.farm2route.config.RabbitMQConfig;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.UUID;

/**
 * Fired when a driver submits a Proof-of-Delivery (POD) record.
 * Consumers: notification.queue, audit.queue
 */
@Getter
@NoArgsConstructor
public class PodSubmittedEvent extends DomainEvent {

    private UUID podId;
    private UUID bookingId;
    private UUID farmerUserId;
    private UUID agencyId;
    private UUID driverId;

    @Builder
    public PodSubmittedEvent(UUID podId, UUID bookingId, UUID farmerUserId, UUID agencyId, UUID driverId) {
        super(RabbitMQConfig.RK_POD_SUBMITTED);
        this.podId = podId;
        this.bookingId = bookingId;
        this.farmerUserId = farmerUserId;
        this.agencyId = agencyId;
        this.driverId = driverId;
    }
}
