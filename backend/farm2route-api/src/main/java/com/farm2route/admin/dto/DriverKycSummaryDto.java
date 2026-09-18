package com.farm2route.admin.dto;

import com.farm2route.common.enums.KycStatus;
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
public class DriverKycSummaryDto {
    private UUID id;
    private String driverName;
    private String phone;
    private String licenseNumber;
    private UUID agencyId;
    private String agencyName;
    private KycStatus kycStatus;
    private Instant createdAt;
}
