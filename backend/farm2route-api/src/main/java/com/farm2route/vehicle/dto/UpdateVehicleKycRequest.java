package com.farm2route.vehicle.dto;

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
public class UpdateVehicleKycRequest {

    @NotNull(message = "KYC status is required")
    private KycStatus kycStatus;

    private String rejectionReason;
}

