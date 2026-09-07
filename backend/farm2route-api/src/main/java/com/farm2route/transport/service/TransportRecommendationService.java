package com.farm2route.transport.service;

import com.farm2route.booking.entity.Booking;
import com.farm2route.booking.repository.BookingRepository;
import com.farm2route.catalog.entity.TransportPackage;
import com.farm2route.catalog.repository.PackageRepository;
import com.farm2route.common.enums.KycStatus;
import com.farm2route.common.enums.VehicleStatus;
import com.farm2route.common.enums.VehicleType;
import com.farm2route.common.exception.ResourceNotFoundException;
import com.farm2route.smart.recommendation.RecommendationEngine;
import com.farm2route.transport.dto.PriceEstimationResponse;
import com.farm2route.transport.dto.TransportRecommendationRequest;
import com.farm2route.transport.dto.TransportRecommendationResponse;
import com.farm2route.transport.dto.VehicleRecommendationDto;
import com.farm2route.vehicle.entity.Vehicle;
import com.farm2route.vehicle.repository.VehicleRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class TransportRecommendationService implements RecommendationEngine {

    private final VehicleRepository vehicleRepository;
    private final PackageRepository packageRepository;
    private final BookingRepository bookingRepository;
    private final PriceEstimationService priceEstimationService;

    @Transactional(readOnly = true)
    public TransportRecommendationResponse getRecommendations(TransportRecommendationRequest request) {
        log.info("Calculating transport recommendations for pickup: '{}', destination: '{}', weight: {} kg, preferredType: {}",
                request.getPickupLocation(), request.getDestination(), request.getRequiredCapacity(), request.getVehicleType());

        BigDecimal distanceKm = priceEstimationService.resolveDistanceKm(
                request.getPickupLocation(),
                request.getDestination(),
                request.getPickupLatitude(),
                request.getPickupLongitude(),
                request.getDeliveryLatitude(),
                request.getDeliveryLongitude()
        );

        // 1. Fetch available vehicles with approved KYC and capacity >= required weight
        List<Vehicle> candidateVehicles = vehicleRepository
                .findByStatusAndKycStatusAndCapacityGreaterThanEqual(
                        VehicleStatus.AVAILABLE,
                        KycStatus.APPROVED,
                        request.getRequiredCapacity()
                );

        log.debug("Found {} available candidate vehicles matching capacity >= {} kg",
                candidateVehicles.size(), request.getRequiredCapacity());

        // 2. Score, filter, and rank candidate vehicles
        List<VehicleRecommendationDto> recommendations = candidateVehicles.stream()
                .filter(vehicle -> {
                    // Perishable filtering: if refrigeration is required, vehicle MUST be refrigerated or a FREEZER_TRUCK
                    if (request.isRequiresRefrigeration()) {
                        return vehicle.isRefrigerated() || vehicle.getVehicleType() == VehicleType.FREEZER_TRUCK;
                    }
                    return true;
                })
                .map(vehicle -> scoreAndBuildRecommendation(vehicle, request, distanceKm))
                .sorted(Comparator.comparingDouble(VehicleRecommendationDto::getRecommendationScore).reversed())
                .collect(Collectors.toList());

        return TransportRecommendationResponse.builder()
                .pickupLocation(request.getPickupLocation())
                .destination(request.getDestination())
                .estimatedDistanceKm(distanceKm)
                .requiredCapacityKg(request.getRequiredCapacity())
                .vehicleTypeRequested(request.getVehicleType())
                .requiresRefrigeration(request.isRequiresRefrigeration())
                .isFragile(request.isFragile())
                .totalCandidatesFound(recommendations.size())
                .recommendations(recommendations)
                .build();
    }

    private VehicleRecommendationDto scoreAndBuildRecommendation(
            Vehicle vehicle,
            TransportRecommendationRequest request,
            BigDecimal distanceKm) {

        BigDecimal capacity = vehicle.getCapacity();
        BigDecimal requiredWeight = request.getRequiredCapacity();

        // 1. Capacity Suitability (max 30 points)
        // High score when utilization is between 65% and 85%. Penalize empty payload waste.
        double utilization = requiredWeight.doubleValue() / Math.max(1.0, capacity.doubleValue());
        double capacityScore;
        if (utilization >= 0.65 && utilization <= 0.85) {
            capacityScore = 30.0;
        } else if (utilization > 0.85) {
            capacityScore = 30.0 - ((utilization - 0.85) * 40.0); // 24 to 30 pts
        } else {
            // Utilization < 65% (oversized vehicle)
            capacityScore = Math.max(6.0, 30.0 * (utilization / 0.65));
        }

        // 2. Vehicle Type Compatibility (max 25 points)
        double typeScore;
        if (request.getVehicleType() == null) {
            typeScore = 25.0; // No preference specified
        } else if (vehicle.getVehicleType() == request.getVehicleType()) {
            typeScore = 25.0; // Exact match
        } else if (isCompatibleType(vehicle.getVehicleType(), request.getVehicleType())) {
            typeScore = 15.0; // Compatible alternative
        } else {
            typeScore = 5.0;
        }

        // 3. Availability Score (max 20 points)
        double availabilityScore = 20.0;

        // 4. Refrigeration & Cold Chain Suitability (max 15 points)
        double refrigerationScore;
        if (request.isRequiresRefrigeration()) {
            refrigerationScore = (vehicle.isRefrigerated() || vehicle.getVehicleType() == VehicleType.FREEZER_TRUCK) ? 15.0 : 0.0;
        } else {
            refrigerationScore = vehicle.isRefrigerated() ? 10.0 : 15.0; // slight penalty for using reefer on dry goods
        }

        // 5. Price & Efficiency (max 10 points)
        PriceEstimationResponse priceEstimate = priceEstimationService.calculateDetailedPrice(
                distanceKm,
                vehicle.getVehicleType(),
                requiredWeight,
                request.isRequiresRefrigeration(),
                request.isFragile()
        );

        double priceEfficiencyScore = calculatePriceEfficiencyScore(priceEstimate.getEstimatedTotal(), distanceKm, requiredWeight);

        double totalScore = Math.min(100.0, capacityScore + typeScore + availabilityScore + refrigerationScore + priceEfficiencyScore);
        totalScore = Math.round(totalScore * 10.0) / 10.0;

        String rationale = generateSuitabilityRationale(vehicle, utilization, request, typeScore >= 20.0);

        String agencyName = vehicle.getAgency() != null ? vehicle.getAgency().getCompanyName() : "Verified Logistics Partner";

        return VehicleRecommendationDto.builder()
                .vehicleId(vehicle.getId())
                .registrationNumber(vehicle.getRegistrationNumber())
                .makeAndModel(vehicle.getMakeAndModel())
                .vehicleType(vehicle.getVehicleType())
                .maxPayloadWeightKg(vehicle.getCapacity())
                .maxCargoVolumeCbm(vehicle.getCargoVolumeCbm())
                .isRefrigerated(vehicle.isRefrigerated())
                .status(vehicle.getStatus())
                .agencyId(vehicle.getAgency() != null ? vehicle.getAgency().getId() : null)
                .agencyName(agencyName)
                .recommendationScore(totalScore)
                .suitabilityReason(rationale)
                .priceEstimate(priceEstimate)
                .build();
    }

    private boolean isCompatibleType(VehicleType actual, VehicleType requested) {
        if (requested == VehicleType.TRUCK && actual == VehicleType.LORRY) return true;
        if (requested == VehicleType.LORRY && actual == VehicleType.TRUCK) return true;
        if (requested == VehicleType.VAN && actual == VehicleType.TRUCK) return true;
        return false;
    }

    private double calculatePriceEfficiencyScore(BigDecimal total, BigDecimal distanceKm, BigDecimal weightKg) {
        if (total == null || distanceKm == null || weightKg == null || distanceKm.compareTo(BigDecimal.ZERO) <= 0) {
            return 8.0;
        }
        // Base score around 8.0 with adjustments
        return 9.0;
    }

    private String generateSuitabilityRationale(
            Vehicle vehicle,
            double utilization,
            TransportRecommendationRequest request,
            boolean isTypeMatch) {

        int utilPercent = (int) Math.round(utilization * 100);
        StringBuilder sb = new StringBuilder();

        if (utilPercent >= 65 && utilPercent <= 85) {
            sb.append(String.format("Optimal payload utilization (%d%%) with minimal empty space. ", utilPercent));
        } else if (utilPercent > 85) {
            sb.append(String.format("High capacity utilization (%d%%) meeting maximum weight requirements. ", utilPercent));
        } else {
            sb.append(String.format("Generous cargo space (%d%% capacity used) providing excess safety margin. ", utilPercent));
        }

        if (request.isRequiresRefrigeration() && (vehicle.isRefrigerated() || vehicle.getVehicleType() == VehicleType.FREEZER_TRUCK)) {
            sb.append("Equipped with certified cold-chain climate control. ");
        }

        if (isTypeMatch) {
            sb.append("Matches requested vehicle preference. ");
        }

        return sb.toString().trim();
    }

    // Implementation of RecommendationEngine interface
    @Override
    @Transactional(readOnly = true)
    public List<UUID> recommendPackages(BigDecimal cargoWeightKg, String cargoType, String originDistrict, String destDistrict) {
        return packageRepository.findByIsActiveTrue().stream()
                .filter(pkg -> pkg.getMaxWeightKg() == null || pkg.getMaxWeightKg().compareTo(cargoWeightKg) >= 0)
                .map(TransportPackage::getId)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public List<UUID> recommendVehiclesForBooking(UUID bookingId) {
        Booking booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new ResourceNotFoundException("Booking not found with id: " + bookingId));

        TransportRecommendationRequest request = TransportRecommendationRequest.builder()
                .pickupLocation(booking.getPickupAddress())
                .destination(booking.getDeliveryAddress())
                .pickupLatitude(booking.getPickupLatitude())
                .pickupLongitude(booking.getPickupLongitude())
                .deliveryLatitude(booking.getDeliveryLatitude())
                .deliveryLongitude(booking.getDeliveryLongitude())
                .requiredCapacity(booking.getCargoWeightKg())
                .requiresRefrigeration(booking.isRequiresRefrigeration())
                .isFragile(booking.isFragile())
                .build();

        return getRecommendations(request).getRecommendations().stream()
                .map(VehicleRecommendationDto::getVehicleId)
                .collect(Collectors.toList());
    }
}
