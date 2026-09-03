package com.farm2route.catalog.dto;

import com.farm2route.common.enums.PackageType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PackageResponse {

    private UUID id;
    private UUID agencyId;
    private String agencyName;
    private String agencyPhone;
    private String title;
    private String description;
    private PackageType packageType;
    private BigDecimal basePrice;
    private BigDecimal pricePerKm;
    private BigDecimal pricePerKg;
    private BigDecimal maxWeightKg;
    private String routeOrigin;
    private String routeDestination;
    private List<String> scheduleDays;
    private boolean isActive;
    private BigDecimal estimatedCost;
    private Instant createdAt;
}
