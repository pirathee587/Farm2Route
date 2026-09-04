package com.farm2route.common.event;

import com.farm2route.common.enums.PackageType;
import com.farm2route.config.RabbitMQConfig;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Fired after a new transport package is created by an agency (AFTER_COMMIT).
 * Consumers: notification.queue, audit.queue
 */
@Getter
@NoArgsConstructor
public class PackageCreatedEvent extends DomainEvent {

    private UUID packageId;
    private UUID agencyId;
    private String title;
    private PackageType packageType;
    private BigDecimal basePrice;

    @Builder
    public PackageCreatedEvent(UUID packageId, UUID agencyId, String title,
                               PackageType packageType, BigDecimal basePrice) {
        super(RabbitMQConfig.RK_PACKAGE_CREATED);
        this.packageId   = packageId;
        this.agencyId    = agencyId;
        this.title       = title;
        this.packageType = packageType;
        this.basePrice   = basePrice;
    }
}
