package com.farm2route.driver.dto;

import com.farm2route.common.enums.KycStatus;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdateDriverKycRequest {

    @NotNull(message = "KYC status is required")
    private KycStatus kycStatus;

    private String kycDocumentUrl;
    private String rejectionReason;
}
