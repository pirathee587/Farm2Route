package com.farm2route.transport.service;

import com.farm2route.common.enums.VehicleType;
import com.farm2route.common.util.GeoUtils;
import com.farm2route.smart.pricing.PricingEngine;
import com.farm2route.transport.dto.PriceEstimationRequest;
import com.farm2route.transport.dto.PriceEstimationResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class PriceEstimationService implements PricingEngine {

    private static final BigDecimal DEFAULT_COMMISSION_RATE = new BigDecimal("0.10"); // 10%
    private static final BigDecimal REFRIGERATION_SURCHARGE = new BigDecimal("2000.00");
    private static final BigDecimal FRAGILE_SURCHARGE = new BigDecimal("1000.00");
    private static final String DEFAULT_CURRENCY = "LKR";

    // Standard Sri Lanka district coordinates for distance resolution
    private static final Map<String, double[]> DISTRICT_COORDINATES = Map.ofEntries(
            Map.entry("COLOMBO", new double[]{6.9271, 79.8612}),
            Map.entry("GAMPAHA", new double[]{7.0917, 79.9999}),
            Map.entry("KALUTARA", new double[]{6.5854, 79.9607}),
            Map.entry("KANDY", new double[]{7.2906, 80.6337}),
            Map.entry("MATALE", new double[]{7.4675, 80.6234}),
            Map.entry("NUWARA ELIYA", new double[]{6.9497, 80.7891}),
            Map.entry("GALLE", new double[]{6.0535, 80.2210}),
            Map.entry("MATARA", new double[]{5.9549, 80.5550}),
            Map.entry("HAMBANTOTA", new double[]{6.1429, 81.1212}),
            Map.entry("JAFFNA", new double[]{9.6615, 80.0255}),
            Map.entry("KURUNEGALA", new double[]{7.4863, 80.3623}),
            Map.entry("PUTTALAM", new double[]{8.0362, 79.8283}),
            Map.entry("ANURADHAPURA", new double[]{8.3114, 80.4037}),
            Map.entry("POLONNARUWA", new double[]{7.9403, 81.0188}),
            Map.entry("BADULLA", new double[]{6.9934, 81.0550}),
            Map.entry("MONARAGALA", new double[]{6.8728, 81.3507}),
            Map.entry("RATNAPURA", new double[]{6.6828, 80.4037}),
            Map.entry("KEGALLE", new double[]{7.2513, 80.3464}),
            Map.entry("DAMBULLA", new double[]{7.8600, 80.6517})
    );

    public PriceEstimationResponse estimatePrice(PriceEstimationRequest request) {
        BigDecimal distanceKm = resolveDistanceKm(
                request.getPickupLocation(),
                request.getDestination(),
                request.getPickupLatitude(),
                request.getPickupLongitude(),
                request.getDeliveryLatitude(),
                request.getDeliveryLongitude()
        );

        return calculateDetailedPrice(
                distanceKm,
                request.getVehicleType(),
                request.getRequiredCapacity(),
                request.isRequiresRefrigeration(),
                request.isFragile()
        );
    }

    public PriceEstimationResponse calculateDetailedPrice(
            BigDecimal distanceKm,
            VehicleType vehicleType,
            BigDecimal loadWeightKg,
            boolean requiresRefrigeration,
            boolean isFragile) {

        VehicleRateCard rateCard = getRateCard(vehicleType);

        BigDecimal baseFare = rateCard.baseFare();
        BigDecimal distanceCharge = rateCard.pricePerKm()
                .multiply(distanceKm != null ? distanceKm : BigDecimal.ZERO)
                .setScale(2, RoundingMode.HALF_UP);

        BigDecimal capacityCharge = rateCard.pricePerKg()
                .multiply(loadWeightKg != null ? loadWeightKg : BigDecimal.ZERO)
                .setScale(2, RoundingMode.HALF_UP);

        BigDecimal specialHandlingFee = BigDecimal.ZERO;
        if (requiresRefrigeration) {
            specialHandlingFee = specialHandlingFee.add(REFRIGERATION_SURCHARGE);
        }
        if (isFragile) {
            specialHandlingFee = specialHandlingFee.add(FRAGILE_SURCHARGE);
        }

        BigDecimal subtotal = baseFare
                .add(distanceCharge)
                .add(capacityCharge)
                .add(specialHandlingFee);

        BigDecimal platformCommission = subtotal
                .multiply(DEFAULT_COMMISSION_RATE)
                .setScale(2, RoundingMode.HALF_UP);

        BigDecimal estimatedTotal = subtotal
                .add(platformCommission)
                .setScale(2, RoundingMode.HALF_UP);

        return PriceEstimationResponse.builder()
                .estimatedDistanceKm(distanceKm != null ? distanceKm.setScale(2, RoundingMode.HALF_UP) : BigDecimal.ZERO)
                .vehicleType(vehicleType)
                .baseFare(baseFare)
                .ratePerKm(rateCard.pricePerKm())
                .distanceCharge(distanceCharge)
                .ratePerKg(rateCard.pricePerKg())
                .capacityCharge(capacityCharge)
                .specialHandlingFee(specialHandlingFee)
                .platformCommission(platformCommission)
                .estimatedTotal(estimatedTotal)
                .currency(DEFAULT_CURRENCY)
                .build();
    }

    @Override
    public PriceEstimate calculateEstimatedPrice(
            BigDecimal distanceKm,
            BigDecimal cargoWeightKg,
            boolean requiresRefrigeration,
            boolean isFragile,
            BigDecimal baseRatePerKm) {

        VehicleRateCard fallback = getRateCard(VehicleType.TRUCK);
        BigDecimal effectiveRatePerKm = baseRatePerKm != null ? baseRatePerKm : fallback.pricePerKm();

        BigDecimal baseFare = fallback.baseFare();
        BigDecimal distanceFare = effectiveRatePerKm
                .multiply(distanceKm != null ? distanceKm : BigDecimal.ZERO)
                .setScale(2, RoundingMode.HALF_UP);

        BigDecimal weightSurcharge = fallback.pricePerKg()
                .multiply(cargoWeightKg != null ? cargoWeightKg : BigDecimal.ZERO)
                .setScale(2, RoundingMode.HALF_UP);

        BigDecimal specialHandlingFee = BigDecimal.ZERO;
        if (requiresRefrigeration) specialHandlingFee = specialHandlingFee.add(REFRIGERATION_SURCHARGE);
        if (isFragile) specialHandlingFee = specialHandlingFee.add(FRAGILE_SURCHARGE);

        BigDecimal subtotal = baseFare.add(distanceFare).add(weightSurcharge).add(specialHandlingFee);
        BigDecimal platformCommission = subtotal.multiply(DEFAULT_COMMISSION_RATE).setScale(2, RoundingMode.HALF_UP);
        BigDecimal total = subtotal.add(platformCommission).setScale(2, RoundingMode.HALF_UP);

        return new PriceEstimate(
                total,
                baseFare,
                distanceFare,
                weightSurcharge,
                specialHandlingFee,
                platformCommission
        );
    }

    public BigDecimal resolveDistanceKm(
            String pickupLocation,
            String destination,
            BigDecimal pickupLat,
            BigDecimal pickupLon,
            BigDecimal deliveryLat,
            BigDecimal deliveryLon) {

        // 1. If exact coordinates are provided, use Haversine formula
        if (pickupLat != null && pickupLon != null && deliveryLat != null && deliveryLon != null) {
            BigDecimal dist = GeoUtils.calculateDistanceKm(pickupLat, pickupLon, deliveryLat, deliveryLon);
            if (dist.compareTo(BigDecimal.ZERO) > 0) {
                return dist;
            }
        }

        // 2. Resolve via district center coordinates
        double[] pickupCoords = lookupDistrictCoordinates(pickupLocation);
        double[] destCoords = lookupDistrictCoordinates(destination);

        if (pickupCoords != null && destCoords != null) {
            double distance = GeoUtils.calculateDistanceKm(
                    pickupCoords[0], pickupCoords[1],
                    destCoords[0], destCoords[1]
            );
            return BigDecimal.valueOf(distance).setScale(2, RoundingMode.HALF_UP);
        }

        // 3. Fallback heuristic: inter-district transit baseline
        log.warn("Coordinates unavailable for locations: '{}' -> '{}'. Using default distance heuristic.", pickupLocation, destination);
        return new BigDecimal("35.00");
    }

    private double[] lookupDistrictCoordinates(String locationName) {
        if (locationName == null || locationName.isBlank()) {
            return null;
        }
        String normalized = locationName.trim().toUpperCase();
        for (Map.Entry<String, double[]> entry : DISTRICT_COORDINATES.entrySet()) {
            if (normalized.contains(entry.getKey())) {
                return entry.getValue();
            }
        }
        return null;
    }

    private VehicleRateCard getRateCard(VehicleType vehicleType) {
        if (vehicleType == null) {
            return new VehicleRateCard(new BigDecimal("5000.00"), new BigDecimal("120.00"), new BigDecimal("5.00"));
        }
        return switch (vehicleType) {
            case VAN -> new VehicleRateCard(new BigDecimal("3500.00"), new BigDecimal("90.00"), new BigDecimal("4.00"));
            case TRUCK -> new VehicleRateCard(new BigDecimal("5000.00"), new BigDecimal("120.00"), new BigDecimal("5.00"));
            case LORRY -> new VehicleRateCard(new BigDecimal("7500.00"), new BigDecimal("140.00"), new BigDecimal("6.00"));
            case TRACTOR -> new VehicleRateCard(new BigDecimal("2500.00"), new BigDecimal("75.00"), new BigDecimal("3.00"));
            case FREEZER_TRUCK -> new VehicleRateCard(new BigDecimal("8000.00"), new BigDecimal("160.00"), new BigDecimal("8.00"));
        };
    }

    private record VehicleRateCard(BigDecimal baseFare, BigDecimal pricePerKm, BigDecimal pricePerKg) {}
}
