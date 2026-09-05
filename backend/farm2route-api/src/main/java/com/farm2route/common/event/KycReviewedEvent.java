package com.farm2route.common.event;

import com.farm2route.common.enums.KycStatus;
import com.farm2route.config.RabbitMQConfig;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.UUID;

/**
 * Fired after an admin reviews (approves or rejects) a KYC submission for an agency, driver, or vehicle (AFTER_COMMIT).
 * Consumers: notification.queue, audit.queue
 */
@Getter
@NoArgsConstructor
public class KycReviewedEvent extends DomainEvent {

    private String entityType; // "AGENCY", "DRIVER", "VEHICLE"
    private UUID entityId;
    private UUID ownerUserId;
    private KycStatus status;
    private String rejectionReason;

    @Builder
    public KycReviewedEvent(String entityType, UUID entityId, UUID ownerUserId, KycStatus status, String rejectionReason) {
        super(RabbitMQConfig.RK_KYC_REVIEWED);
        this.entityType = entityType;
        this.entityId = entityId;
        this.ownerUserId = ownerUserId;
        this.status = status;
        this.rejectionReason = rejectionReason;
    }
}
