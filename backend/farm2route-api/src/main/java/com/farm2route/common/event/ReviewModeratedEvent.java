package com.farm2route.common.event;

import com.farm2route.config.RabbitMQConfig;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.UUID;

/**
 * Fired when an admin moderates a review (HIDE, RESTORE, or ESCALATE).
 * Consumers: notification.queue, audit.queue
 */
@Getter
@NoArgsConstructor
public class ReviewModeratedEvent extends DomainEvent {

    private UUID reviewId;
    private UUID farmerUserId;
    private UUID agencyId;
    private String action;
    private UUID adminId;
    private String reason;

    @Builder
    public ReviewModeratedEvent(UUID reviewId, UUID farmerUserId, UUID agencyId, String action, UUID adminId, String reason) {
        super(RabbitMQConfig.RK_REVIEW_MODERATED);
        this.reviewId = reviewId;
        this.farmerUserId = farmerUserId;
        this.agencyId = agencyId;
        this.action = action;
        this.adminId = adminId;
        this.reason = reason;
    }
}
