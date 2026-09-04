package com.farm2route.common.event;

import com.farm2route.config.RabbitMQConfig;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.UUID;

/**
 * Fired after Proof-of-Delivery is confirmed (DELIVERED transition, AFTER_COMMIT).
 * Consumers:
 *   - notification.queue: notify farmer + agency
 *   - audit.queue: audit trail
 *   - Future: review-eligibility listener (Review module listens for this instead of
 *     Booking module needing a direct dependency on Review — the EDA decoupling benefit)
 */
@Getter
@NoArgsConstructor
public class PodConfirmedEvent extends DomainEvent {

    private UUID    podId;
    private UUID    bookingId;
    private UUID    farmerId;
    private UUID    agencyId;
    private UUID    driverId;
    private Instant confirmedAt;

    @Builder
    public PodConfirmedEvent(UUID podId, UUID bookingId, UUID farmerId,
                             UUID agencyId, UUID driverId, Instant confirmedAt) {
        super(RabbitMQConfig.RK_POD_CONFIRMED);
        this.podId       = podId;
        this.bookingId   = bookingId;
        this.farmerId    = farmerId;
        this.agencyId    = agencyId;
        this.driverId    = driverId;
        this.confirmedAt = confirmedAt;
    }
}
