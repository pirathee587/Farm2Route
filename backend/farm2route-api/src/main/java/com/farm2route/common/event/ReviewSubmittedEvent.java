package com.farm2route.common.event;

import com.farm2route.config.RabbitMQConfig;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.UUID;

/**
 * Fired after a farmer review is successfully persisted (AFTER_COMMIT).
 * Consumers: notification.queue (notify agency), audit.queue
 */
@Getter
@NoArgsConstructor
public class ReviewSubmittedEvent extends DomainEvent {

    private UUID    reviewId;
    private UUID    bookingId;
    private UUID    farmerId;
    private UUID    agencyId;
    private UUID    driverId;      // nullable — driver may not have been assigned
    private Integer agencyRating;

    @Builder
    public ReviewSubmittedEvent(UUID reviewId, UUID bookingId, UUID farmerId,
                                UUID agencyId, UUID driverId, Integer agencyRating) {
        super(RabbitMQConfig.RK_REVIEW_SUBMITTED);
        this.reviewId     = reviewId;
        this.bookingId    = bookingId;
        this.farmerId     = farmerId;
        this.agencyId     = agencyId;
        this.driverId     = driverId;
        this.agencyRating = agencyRating;
    }
}
