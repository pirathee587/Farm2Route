package com.farm2route.vehicle.dto;

import com.farm2route.common.enums.KycStatus;
import com.farm2route.common.enums.VehicleStatus;
import com.farm2route.common.enums.VehicleType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VehicleDto {
    private UUID id;
    private UUID agencyId;
    private String registrationNumber;
    private BigDecimal capacity;
    private BigDecimal cargoVolumeCbm;
    private VehicleType vehicleType;
    private boolean isRefrigerated;
    private String insurancePolicyNumber;
    private String makeAndModel;
    private LocalDate insuranceExpiryDate;
    private String revenueLicenseNumber;
    private LocalDate revenueLicenseExpiryDate;
    private VehicleStatus status;
    private KycStatus kycStatus;
    private String rejectionReason;
    private Instant verifiedAt;
    private Instant createdAt;
    private Instant updatedAt;
}

