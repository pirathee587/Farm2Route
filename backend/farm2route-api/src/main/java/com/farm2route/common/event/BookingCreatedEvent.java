package com.farm2route.common.event;

import com.farm2route.config.RabbitMQConfig;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Fired after a booking is successfully persisted (AFTER_COMMIT).
 * Consumers: notification.queue, audit.queue
 */
@Getter
@NoArgsConstructor
public class BookingCreatedEvent extends DomainEvent {

    private UUID       bookingId;
    private String     bookingNumber;
    private UUID       farmerId;
    private UUID       agencyId;
    private UUID       packageId;    // nullable
    private BigDecimal totalAmount;  // nullable

    @Builder
    public BookingCreatedEvent(UUID bookingId, String bookingNumber, UUID farmerId,
                               UUID agencyId, UUID packageId, BigDecimal totalAmount) {
        super(RabbitMQConfig.RK_BOOKING_CREATED);
        this.bookingId     = bookingId;
        this.bookingNumber = bookingNumber;
        this.farmerId      = farmerId;
        this.agencyId      = agencyId;
        this.packageId     = packageId;
        this.totalAmount   = totalAmount;
    }
}
