package com.farm2route.catalog.dto;

import com.farm2route.common.enums.PackageType;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreatePackageRequest {

    @NotBlank(message = "Title is required")
    private String title;

    private String description;

    @NotNull(message = "Package type is required")
    private PackageType packageType;

    @NotNull(message = "Base price is required")
    @DecimalMin(value = "0.00", inclusive = true, message = "Base price must be non-negative")
    private BigDecimal basePrice;

    @NotNull(message = "Price per km is required")
    @DecimalMin(value = "0.00", inclusive = true, message = "Price per km must be non-negative")
    private BigDecimal pricePerKm;

    @DecimalMin(value = "0.00", inclusive = true, message = "Price per kg must be non-negative")
    private BigDecimal pricePerKg;

    @NotNull(message = "Max weight is required")
    @DecimalMin(value = "0.01", message = "Max weight must be positive")
    private BigDecimal maxWeightKg;

    private String routeOrigin;
    private String routeDestination;

    /** Recurring schedule days, e.g. ["MONDAY","WEDNESDAY","FRIDAY"] */
    private List<String> scheduleDays;
}
