package com.farm2route.common.util;

import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * Geographic calculation utilities using Haversine formula for spherical coordinates.
 */
public final class GeoUtils {

    private static final double EARTH_RADIUS_KM = 6371.0;

    private GeoUtils() {
        // Utility class
    }

    /**
     * Calculates great-circle distance between two points in kilometers.
     */
    public static double calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);

        double a = Math.sin(dLat / 2.0) * Math.sin(dLat / 2.0)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLon / 2.0) * Math.sin(dLon / 2.0);

        double c = 2.0 * Math.atan2(Math.sqrt(a), Math.sqrt(1.0 - a));
        return EARTH_RADIUS_KM * c;
    }

    /**
     * Calculates distance between coordinates represented as BigDecimal, rounded to 2 decimal places.
     */
    public static BigDecimal calculateDistanceKm(BigDecimal lat1, BigDecimal lon1, BigDecimal lat2, BigDecimal lon2) {
        if (lat1 == null || lon1 == null || lat2 == null || lon2 == null) {
            return BigDecimal.ZERO;
        }
        double dist = calculateDistanceKm(
                lat1.doubleValue(),
                lon1.doubleValue(),
                lat2.doubleValue(),
                lon2.doubleValue()
        );
        return BigDecimal.valueOf(dist).setScale(2, RoundingMode.HALF_UP);
    }

    /**
     * Estimates total cost for a package transport given distance and weight.
     * Formula: BasePrice + (DistanceKm * PricePerKm) + (WeightKg * PricePerKg)
     */
    public static BigDecimal estimateTotalCost(
            BigDecimal basePrice,
            BigDecimal pricePerKm,
            BigDecimal pricePerKg,
            BigDecimal distanceKm,
            BigDecimal weightKg) {

        BigDecimal total = basePrice != null ? basePrice : BigDecimal.ZERO;

        if (pricePerKm != null && distanceKm != null && distanceKm.compareTo(BigDecimal.ZERO) > 0) {
            total = total.add(pricePerKm.multiply(distanceKm));
        }

        if (pricePerKg != null && weightKg != null && weightKg.compareTo(BigDecimal.ZERO) > 0) {
            total = total.add(pricePerKg.multiply(weightKg));
        }

        return total.setScale(2, RoundingMode.HALF_UP);
    }
}
