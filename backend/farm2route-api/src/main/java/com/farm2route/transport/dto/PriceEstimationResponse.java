package com.farm2route.transport.dto;

import com.farm2route.common.enums.VehicleType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PriceEstimationResponse {

    private BigDecimal estimatedDistanceKm;
    private VehicleType vehicleType;
    private BigDecimal baseFare;
    private BigDecimal ratePerKm;
    private BigDecimal distanceCharge;
    private BigDecimal ratePerKg;
    private BigDecimal capacityCharge;
    private BigDecimal specialHandlingFee;
    private BigDecimal platformCommission;
    private BigDecimal estimatedTotal;
    private String currency;
}
