package com.farm2route.vehicle.dto;

import com.farm2route.common.enums.VehicleStatus;
import com.farm2route.common.enums.VehicleType;
import jakarta.validation.constraints.Positive;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdateVehicleRequest {

    private String registrationNumber;

    @Positive(message = "Capacity must be positive")
    private BigDecimal capacity;

    @Positive(message = "Cargo volume must be positive")
    private BigDecimal cargoVolumeCbm;

    private VehicleType vehicleType;
    private Boolean isRefrigerated;
    private String insurancePolicyNumber;
    private String makeAndModel;
    private LocalDate insuranceExpiryDate;
    private String revenueLicenseNumber;
    private LocalDate revenueLicenseExpiryDate;
    private VehicleStatus status;
}

