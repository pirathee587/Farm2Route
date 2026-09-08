package com.farm2route.common.event;

import com.farm2route.config.RabbitMQConfig;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.UUID;

/**
 * Fired when a vehicle arrives within the delivery geofence for the first time on a trip.
 * Consumers: notification.queue
 */
@Getter
@NoArgsConstructor
public class TripArrivedEvent extends DomainEvent {

    private UUID bookingId;
    private UUID farmerUserId;
    private UUID tripId;

    @Builder
    public TripArrivedEvent(UUID bookingId, UUID farmerUserId, UUID tripId) {
        super(RabbitMQConfig.RK_TRIP_ARRIVED);
        this.bookingId = bookingId;
        this.farmerUserId = farmerUserId;
        this.tripId = tripId;
    }
}
