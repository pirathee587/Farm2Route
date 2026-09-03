package com.farm2route.common.event;

import com.farm2route.config.RabbitMQConfig;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.UUID;

/**
 * Fired after a booking is successfully cancelled (AFTER_COMMIT).
 * Consumers: notification.queue (notify agency/driver), audit.queue
 */
@Getter
@NoArgsConstructor
public class BookingCancelledEvent extends DomainEvent {

    private UUID   bookingId;
    private String bookingNumber;
    private UUID   farmerId;
    private UUID   agencyId;
    private UUID   driverId;           // nullable — may not be assigned yet
    private String cancellationReason;

    @Builder
    public BookingCancelledEvent(UUID bookingId, String bookingNumber, UUID farmerId,
                                 UUID agencyId, UUID driverId, String cancellationReason) {
        super(RabbitMQConfig.RK_BOOKING_CANCELLED);
        this.bookingId          = bookingId;
        this.bookingNumber      = bookingNumber;
        this.farmerId           = farmerId;
        this.agencyId           = agencyId;
        this.driverId           = driverId;
        this.cancellationReason = cancellationReason;
    }
}
