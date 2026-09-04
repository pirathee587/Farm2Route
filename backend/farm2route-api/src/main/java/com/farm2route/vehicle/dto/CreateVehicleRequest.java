package com.farm2route.vehicle.dto;

import com.farm2route.common.enums.VehicleType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
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
public class CreateVehicleRequest {

    @NotBlank(message = "Vehicle registration number is required")
    private String registrationNumber;

    @NotNull(message = "Capacity (max payload weight in kg) is required")
    @Positive(message = "Capacity must be positive")
    private BigDecimal capacity;

    @NotNull(message = "Cargo volume in CBM is required")
    @Positive(message = "Cargo volume must be positive")
    private BigDecimal cargoVolumeCbm;

    @NotNull(message = "Vehicle type is required")
    private VehicleType vehicleType;

    private boolean isRefrigerated;

    private String insurancePolicyNumber;
    private String makeAndModel;
    private LocalDate insuranceExpiryDate;
    private String revenueLicenseNumber;
    private LocalDate revenueLicenseExpiryDate;
}

