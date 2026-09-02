package com.farm2route.admin.dto;

import com.farm2route.common.enums.KycStatus;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class KycApprovalDto {

    @NotNull(message = "Entity ID is required")
    private UUID entityId;

    @NotNull(message = "KYC status is required (APPROVED, REJECTED)")
    private KycStatus status;

    private String rejectionReason;
}
