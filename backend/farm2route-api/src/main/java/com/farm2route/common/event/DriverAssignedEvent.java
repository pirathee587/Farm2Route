package com.farm2route.common.event;

import com.farm2route.config.RabbitMQConfig;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Getter
@NoArgsConstructor
public class DriverAssignedEvent extends DomainEvent {

    private UUID assignmentId;
    private UUID bookingId;
    private UUID driverId;
    private UUID vehicleId;

    @Builder
    public DriverAssignedEvent(UUID assignmentId, UUID bookingId, UUID driverId, UUID vehicleId) {
        super(RabbitMQConfig.RK_DRIVER_ASSIGNED);
        this.assignmentId = assignmentId;
        this.bookingId = bookingId;
        this.driverId = driverId;
        this.vehicleId = vehicleId;
    }
}
