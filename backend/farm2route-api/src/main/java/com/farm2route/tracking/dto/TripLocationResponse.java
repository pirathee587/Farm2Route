package com.farm2route.tracking.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TripLocationResponse {
    private GpsLocationDto latestLocation;
    private BigDecimal remainingDistanceKm;
    private Integer estimatedMinutesRemaining;
    private boolean arrivedAtDelivery;
}
