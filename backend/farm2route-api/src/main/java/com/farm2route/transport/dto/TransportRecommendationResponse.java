package com.farm2route.transport.dto;

import com.farm2route.common.enums.VehicleType;
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
public class TransportRecommendationResponse {

    private String pickupLocation;
    private String destination;
    private BigDecimal estimatedDistanceKm;
    private BigDecimal requiredCapacityKg;
    private VehicleType vehicleTypeRequested;
    private boolean requiresRefrigeration;
    private boolean isFragile;
    private int totalCandidatesFound;
    private List<VehicleRecommendationDto> recommendations;
}
