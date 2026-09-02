package com.farm2route.smart.pricing;

import java.math.BigDecimal;

public interface PricingEngine {
    /**
     * Calculates transparent dynamic price estimation based on distance, cargo weight, refrigeration requirements, and peak demand.
     */
    PriceEstimate calculateEstimatedPrice(
            BigDecimal distanceKm,
            BigDecimal cargoWeightKg,
            boolean requiresRefrigeration,
            boolean isFragile,
            BigDecimal baseRatePerKm
    );

    record PriceEstimate(
            BigDecimal totalAmount,
            BigDecimal baseFare,
            BigDecimal distanceFare,
            BigDecimal weightSurcharge,
            BigDecimal specialHandlingFee,
            BigDecimal platformCommission
    ) {}
}
