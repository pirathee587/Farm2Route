package com.farm2route.common.util;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;

class GeoUtilsTest {

    @Test
    @DisplayName("Calculate distance between Kurunegala and Colombo is ~80-100 km")
    void testCalculateDistance_KurunegalaToColombo() {
        // Kurunegala: 7.4863, 80.3623
        // Colombo: 6.9271, 79.8612
        BigDecimal lat1 = new BigDecimal("7.4863");
        BigDecimal lon1 = new BigDecimal("80.3623");
        BigDecimal lat2 = new BigDecimal("6.9271");
        BigDecimal lon2 = new BigDecimal("79.8612");

        BigDecimal distance = GeoUtils.calculateDistanceKm(lat1, lon1, lat2, lon2);

        assertThat(distance).isNotNull();
        // Great-circle distance is approximately 83 km
        assertThat(distance.doubleValue()).isBetween(80.0, 90.0);
    }

    @Test
    @DisplayName("Estimate total transport cost with base, distance, and weight rates")
    void testEstimateTotalCost() {
        BigDecimal basePrice = new BigDecimal("5000.00");
        BigDecimal pricePerKm = new BigDecimal("100.00");
        BigDecimal pricePerKg = new BigDecimal("10.00");
        BigDecimal distanceKm = new BigDecimal("50.00");
        BigDecimal weightKg = new BigDecimal("200.00");

        // 5000 + (50 * 100 = 5000) + (200 * 10 = 2000) = 12000.00
        BigDecimal cost = GeoUtils.estimateTotalCost(basePrice, pricePerKm, pricePerKg, distanceKm, weightKg);

        assertThat(cost).isEqualByComparingTo(new BigDecimal("12000.00"));
    }
}
