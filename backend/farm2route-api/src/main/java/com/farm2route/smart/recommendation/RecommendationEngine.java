package com.farm2route.smart.recommendation;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

public interface RecommendationEngine {
    /**
     * Recommends optimal transport packages for a farmer based on cargo weight, type, origin, and destination.
     */
    List<UUID> recommendPackages(BigDecimal cargoWeightKg, String cargoType, String originDistrict, String destDistrict);

    /**
     * Recommends optimal vehicles for an agency booking based on capacity, refrigeration, and distance.
     */
    List<UUID> recommendVehiclesForBooking(UUID bookingId);
}
