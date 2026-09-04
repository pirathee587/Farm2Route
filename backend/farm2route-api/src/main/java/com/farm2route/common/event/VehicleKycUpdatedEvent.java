package com.farm2route.common.event;

import com.farm2route.common.enums.KycStatus;
import com.farm2route.config.RabbitMQConfig;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.UUID;

/**
 * Fired after a vehicle's KYC status is updated (AFTER_COMMIT).
 * Consumers: notification.queue, audit.queue
 */
@Getter
@NoArgsConstructor
public class VehicleKycUpdatedEvent extends DomainEvent {

    private UUID vehicleId;
    private UUID agencyId;
    private KycStatus kycStatus;

    @Builder
    public VehicleKycUpdatedEvent(UUID vehicleId, UUID agencyId, KycStatus kycStatus) {
        super(RabbitMQConfig.RK_VEHICLE_KYC_UPDATED);
        this.vehicleId = vehicleId;
        this.agencyId = agencyId;
        this.kycStatus = kycStatus;
    }
}

