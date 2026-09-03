package com.farm2route.transport.dto;

import com.farm2route.common.enums.VehicleType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PriceEstimationRequest {

    @NotBlank(message = "Pickup location is required")
    private String pickupLocation;

    @NotBlank(message = "Destination is required")
    private String destination;

    private BigDecimal pickupLatitude;
    private BigDecimal pickupLongitude;

    private BigDecimal deliveryLatitude;
    private BigDecimal deliveryLongitude;

    @NotNull(message = "Vehicle type is required for price estimation")
    private VehicleType vehicleType;

    @NotNull(message = "Required capacity is required")
    @Positive(message = "Required capacity must be greater than zero")
    private BigDecimal requiredCapacity;

    @Builder.Default
    private boolean requiresRefrigeration = false;

    @Builder.Default
    private boolean isFragile = false;
}
