package com.farm2route.transport.service;

import com.farm2route.common.enums.VehicleType;
import com.farm2route.smart.pricing.PricingEngine;
import com.farm2route.transport.dto.PriceEstimationRequest;
import com.farm2route.transport.dto.PriceEstimationResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;

class PriceEstimationServiceTest {

    private PriceEstimationService priceEstimationService;

    @BeforeEach
    void setUp() {
        priceEstimationService = new PriceEstimationService();
    }

    @Test
    @DisplayName("Should calculate accurate price estimate for Truck with standard distance and load")
    void shouldEstimatePriceForTruck() {
        PriceEstimationRequest request = PriceEstimationRequest.builder()
                .pickupLocation("Kurunegala")
                .destination("Colombo")
                .vehicleType(VehicleType.TRUCK)
                .requiredCapacity(new BigDecimal("2000.00"))
                .requiresRefrigeration(false)
                .isFragile(false)
                .build();

        PriceEstimationResponse response = priceEstimationService.estimatePrice(request);

        assertThat(response).isNotNull();
        assertThat(response.getVehicleType()).isEqualTo(VehicleType.TRUCK);
        assertThat(response.getBaseFare()).isEqualByComparingTo("5000.00");
        assertThat(response.getRatePerKm()).isEqualByComparingTo("120.00");
        assertThat(response.getRatePerKg()).isEqualByComparingTo("5.00");
        assertThat(response.getEstimatedDistanceKm()).isGreaterThan(BigDecimal.ZERO);
        assertThat(response.getSpecialHandlingFee()).isEqualByComparingTo("0.00");
        assertThat(response.getPlatformCommission()).isGreaterThan(BigDecimal.ZERO);
        assertThat(response.getEstimatedTotal()).isGreaterThan(response.getBaseFare());
    }

    @Test
    @DisplayName("Should apply refrigeration and fragile surcharges when requested")
    void shouldApplyRefrigerationAndFragileSurcharges() {
        PriceEstimationRequest request = PriceEstimationRequest.builder()
                .pickupLocation("Dambulla")
                .destination("Colombo")
                .vehicleType(VehicleType.FREEZER_TRUCK)
                .requiredCapacity(new BigDecimal("1500.00"))
                .requiresRefrigeration(true)
                .isFragile(true)
                .build();

        PriceEstimationResponse response = priceEstimationService.estimatePrice(request);

        assertThat(response).isNotNull();
        // 2000 refrigeration + 1000 fragile = 3000
        assertThat(response.getSpecialHandlingFee()).isEqualByComparingTo("3000.00");
        assertThat(response.getBaseFare()).isEqualByComparingTo("8000.00");
    }

    @Test
    @DisplayName("Should calculate exact distance using provided GPS coordinates")
    void shouldCalculateDistanceUsingGpsCoordinates() {
        // Kurunegala (7.4863, 80.3623) to Colombo (6.9271, 79.8612)
        BigDecimal pickupLat = new BigDecimal("7.4863");
        BigDecimal pickupLon = new BigDecimal("80.3623");
        BigDecimal delLat = new BigDecimal("6.9271");
        BigDecimal delLon = new BigDecimal("79.8612");

        BigDecimal distance = priceEstimationService.resolveDistanceKm(
                "Somewhere", "Somewhere Else",
                pickupLat, pickupLon, delLat, delLon
        );

        // Great circle distance is approx 84 km
        assertThat(distance).isBetween(new BigDecimal("75.00"), new BigDecimal("95.00"));
    }

    @Test
    @DisplayName("Should resolve distance using built-in district coordinates dictionary")
    void shouldResolveDistanceUsingDistrictName() {
        BigDecimal distance = priceEstimationService.resolveDistanceKm(
                "Kurunegala Central Market",
                "Pettah Wholesale Market, Colombo",
                null, null, null, null
        );

        assertThat(distance).isBetween(new BigDecimal("75.00"), new BigDecimal("95.00"));
    }

    @Test
    @DisplayName("Should provide baseline fallback distance when locations cannot be resolved")
    void shouldProvideFallbackDistanceForUnknownLocations() {
        BigDecimal distance = priceEstimationService.resolveDistanceKm(
                "Unknown Town Alpha",
                "Unknown Town Beta",
                null, null, null, null
        );

        assertThat(distance).isEqualByComparingTo("35.00");
    }

    @Test
    @DisplayName("Should implement PricingEngine interface contract correctly")
    void shouldImplementPricingEngineContract() {
        PricingEngine.PriceEstimate estimate = priceEstimationService.calculateEstimatedPrice(
                new BigDecimal("50.00"),
                new BigDecimal("1000.00"),
                true,
                false,
                new BigDecimal("120.00")
        );

        assertThat(estimate).isNotNull();
        assertThat(estimate.baseFare()).isEqualByComparingTo("5000.00");
        assertThat(estimate.distanceFare()).isEqualByComparingTo("6000.00"); // 50 * 120
        assertThat(estimate.weightSurcharge()).isEqualByComparingTo("5000.00"); // 1000 * 5
        assertThat(estimate.specialHandlingFee()).isEqualByComparingTo("2000.00"); // refrigeration
        assertThat(estimate.platformCommission()).isEqualByComparingTo("1800.00"); // (5000+6000+5000+2000) * 10%
        assertThat(estimate.totalAmount()).isEqualByComparingTo("19800.00");
    }
}
