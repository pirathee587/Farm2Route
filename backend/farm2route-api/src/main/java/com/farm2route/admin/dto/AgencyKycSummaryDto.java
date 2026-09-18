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
public class AgencyKycSummaryDto {
    private UUID id;
    private String companyName;
    private String contactEmail;
    private String contactPhone;
    private KycStatus kycStatus;
    private String kycRejectionReason;
    private Instant createdAt;
}
