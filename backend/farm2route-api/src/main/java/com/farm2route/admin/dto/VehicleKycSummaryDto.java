package com.farm2route.admin.dto;

import com.farm2route.common.enums.KycStatus;
import com.farm2route.common.enums.VehicleType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VehicleKycSummaryDto {
    private UUID id;
    private String registrationNumber;
    private VehicleType vehicleType;
    private UUID agencyId;
    private String agencyName;
    private KycStatus kycStatus;
    private Instant createdAt;
}
