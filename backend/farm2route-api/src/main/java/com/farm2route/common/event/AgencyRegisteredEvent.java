package com.farm2route.common.event;

import com.farm2route.agency.enums.AgencyType;
import com.farm2route.config.RabbitMQConfig;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.UUID;

/**
 * Fired after an agency is successfully registered and committed (AFTER_COMMIT).
 * Routing key: "agency.registered"
 * Consumers: notification.queue, audit.queue
 */
@Getter
@NoArgsConstructor
public class AgencyRegisteredEvent extends DomainEvent {

    private UUID agencyId;
    private String agencyName;
    private String email;
    private String phoneNumber;
    private AgencyType agencyType;

    @Builder
    public AgencyRegisteredEvent(UUID agencyId, String agencyName, String email, String phoneNumber, AgencyType agencyType) {
        super(RabbitMQConfig.RK_AGENCY_REGISTERED);
        this.agencyId = agencyId;
        this.agencyName = agencyName;
        this.email = email;
        this.phoneNumber = phoneNumber;
        this.agencyType = agencyType;
    }
}
