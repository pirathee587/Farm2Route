package com.farm2route.catalog.dto;

import com.farm2route.common.enums.PackageType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PackageSearchRequest {

    private String routeOrigin;
    private String routeDestination;
    private PackageType packageType;
    private BigDecimal maxWeight;
    private BigDecimal maxPrice;
    private UUID agencyId;

    // Optional parameters for estimated cost calculation
    private BigDecimal distanceKm;
    private BigDecimal weightKg;

    @Builder.Default
    private int page = 0;

    @Builder.Default
    private int size = 20;

    @Builder.Default
    private String sortBy = "basePrice";

    @Builder.Default
    private String sortDirection = "ASC";
}
