package com.farm2route.common.event;

import com.farm2route.config.RabbitMQConfig;
import com.farm2route.farmer.enums.CropType;
import com.farm2route.farmer.enums.PreferredLanguage;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.Set;
import java.util.UUID;

/**
 * Fired after a farmer is successfully registered and committed (AFTER_COMMIT).
 * Routing key: "farmer.registered"
 * Consumers: notification.queue, audit.queue
 */
@Getter
@NoArgsConstructor
public class FarmerRegisteredEvent extends DomainEvent {

    private UUID farmerId;
    private String fullName;
    private String phoneNumber;
    private String district;
    private PreferredLanguage preferredLanguage;
    private Set<CropType> primaryCrops;

    @Builder
    public FarmerRegisteredEvent(UUID farmerId, String fullName, String phoneNumber, String district, PreferredLanguage preferredLanguage, Set<CropType> primaryCrops) {
        super(RabbitMQConfig.RK_FARMER_REGISTERED);
        this.farmerId = farmerId;
        this.fullName = fullName;
        this.phoneNumber = phoneNumber;
        this.district = district;
        this.preferredLanguage = preferredLanguage;
        this.primaryCrops = primaryCrops;
    }
}
