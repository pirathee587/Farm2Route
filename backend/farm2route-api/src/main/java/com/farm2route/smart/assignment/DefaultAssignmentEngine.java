package com.farm2route.smart.assignment;

import com.farm2route.agency.repository.AgencyProfileRepository;
import com.farm2route.booking.entity.Booking;
import com.farm2route.booking.repository.BookingRepository;
import com.farm2route.common.enums.BookingStatus;
import com.farm2route.common.enums.DriverAvailability;
import com.farm2route.common.enums.KycStatus;
import com.farm2route.common.enums.VehicleStatus;
import com.farm2route.common.exception.ResourceNotFoundException;
import com.farm2route.driver.entity.DriverProfile;
import com.farm2route.driver.repository.DriverProfileRepository;
import com.farm2route.vehicle.entity.Vehicle;
import com.farm2route.vehicle.repository.VehicleRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Smart assignment engine that matches accepted bookings with optimal agency vehicles and drivers.
 *
 * Scoring algorithm:
 * - Vehicle scoring (0-50 pts):
 *   1. KYC approval check (must be APPROVED)
 *   2. Maintenance exclusion (status must NOT be UNDER_MAINTENANCE or INACTIVE)
 *   3. Refrigeration requirement (if booking requires refrigeration, vehicle must be refrigerated)
 *   4. Capacity requirement (vehicle capacity >= cargoWeightKg and volume >= cargoVolumeCbm)
 *   5. Capacity utilization efficiency (closer to optimal payload ratio receives higher score)
 *
 * - Driver scoring (0-50 pts):
 *   1. KYC approval check (must be APPROVED)
 *   2. Availability check (status must NOT be OFF_DUTY or INACTIVE)
 *   3. Workload proxy scoring (fewer active ACCEPTED/DRIVER_ASSIGNED/IN_TRANSIT bookings = higher score)
 *   4. Driver rating score (higher ratingAverage = higher score)
 *
 * KNOWN LIMITATIONS & PLACEHOLDERS:
 * - Maintenance records: The vehicle_maintenance database table exists (V13), but no Java JPA
 *   maintenance entity/repository exists yet in com.farm2route.maintenance. VehicleStatus.UNDER_MAINTENANCE
 *   is used as the current filter.
 * - Workload proxy: TripAssignment entity does not exist yet. Current active booking count per driver
 *   is used as a temporary workload proxy and will be replaced once TripAssignment JPA entity is created.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class DefaultAssignmentEngine implements AssignmentEngine {

    private final BookingRepository bookingRepository;
    private final VehicleRepository vehicleRepository;
    private final DriverProfileRepository driverProfileRepository;
    private final AgencyProfileRepository agencyProfileRepository;

    @Override
    @Transactional(readOnly = true)
    public AssignmentResult matchAndAssign(UUID bookingId, UUID agencyId) {
        Booking booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new ResourceNotFoundException("Booking not found with id: " + bookingId));

        if (!agencyProfileRepository.existsById(agencyId)) {
            throw new ResourceNotFoundException("Agency not found with id: " + agencyId);
        }

        List<Vehicle> agencyVehicles = vehicleRepository.findByAgencyId(agencyId);
        List<DriverProfile> agencyDrivers = driverProfileRepository.findByAgencyId(agencyId);

        // Filter and score vehicles
        List<ScoredVehicle> candidateVehicles = new ArrayList<>();
        for (Vehicle vehicle : agencyVehicles) {
            if (isEligibleVehicle(vehicle, booking)) {
                double score = calculateVehicleScore(vehicle, booking);
                candidateVehicles.add(new ScoredVehicle(vehicle, score));
            }
        }

        // Filter and score drivers
        List<ScoredDriver> candidateDrivers = new ArrayList<>();
        for (DriverProfile driver : agencyDrivers) {
            if (isEligibleDriver(driver)) {
                double score = calculateDriverScore(driver);
                candidateDrivers.add(new ScoredDriver(driver, score));
            }
        }

        if (candidateVehicles.isEmpty() || candidateDrivers.isEmpty()) {
            String reason = String.format("No matching candidates available for agency %s: %d eligible vehicles, %d eligible drivers",
                    agencyId, candidateVehicles.size(), candidateDrivers.size());
            log.info("[AssignmentEngine] {}", reason);
            return new AssignmentResult(null, null, 0.0, reason);
        }

        // Find optimal (vehicle, driver) pair
        ScoredVehicle bestVehicle = null;
        ScoredDriver bestDriver = null;
        double bestCombinedScore = -1.0;

        for (ScoredVehicle sv : candidateVehicles) {
            for (ScoredDriver sd : candidateDrivers) {
                double combinedScore = sv.score + sd.score;
                if (combinedScore > bestCombinedScore) {
                    bestCombinedScore = combinedScore;
                    bestVehicle = sv;
                    bestDriver = sd;
                }
            }
        }

        if (bestVehicle == null || bestDriver == null) {
            return new AssignmentResult(null, null, 0.0, "Unable to compute optimal assignment pair");
        }

        String rationale = String.format("Selected vehicle %s (%s, capacity %.2fkg, score=%.1f) and driver %s (%s, score=%.1f). Combined score=%.1f/100",
                bestVehicle.vehicle.getId(), bestVehicle.vehicle.getRegistrationNumber(),
                bestVehicle.vehicle.getCapacity(), bestVehicle.score,
                bestDriver.driver.getId(), bestDriver.driver.getFullName(),
                bestDriver.score, bestCombinedScore);

        log.info("[AssignmentEngine] {}", rationale);

        return new AssignmentResult(
                bestVehicle.vehicle.getId(),
                bestDriver.driver.getId(),
                Math.round(bestCombinedScore * 10.0) / 10.0,
                rationale
        );
    }

    private boolean isEligibleVehicle(Vehicle vehicle, Booking booking) {
        // Must be KYC approved
        if (vehicle.getKycStatus() != KycStatus.APPROVED) {
            return false;
        }

        // Exclude maintenance and inactive vehicles
        if (vehicle.getStatus() == VehicleStatus.UNDER_MAINTENANCE || vehicle.getStatus() == VehicleStatus.INACTIVE) {
            return false;
        }

        // Check refrigeration requirement
        if (booking.isRequiresRefrigeration() && !vehicle.isRefrigerated()) {
            return false;
        }

        // Check weight capacity
        if (vehicle.getCapacity() == null || booking.getCargoWeightKg() == null) {
            return false;
        }
        if (vehicle.getCapacity().compareTo(booking.getCargoWeightKg()) < 0) {
            return false;
        }

        // Check volume capacity if specified
        if (booking.getCargoVolumeCbm() != null && vehicle.getCargoVolumeCbm() != null) {
            if (vehicle.getCargoVolumeCbm().compareTo(booking.getCargoVolumeCbm()) < 0) {
                return false;
            }
        }

        return true;
    }

    private double calculateVehicleScore(Vehicle vehicle, Booking booking) {
        double score = 20.0; // Base eligibility score

        // Availability bonus
        if (vehicle.getStatus() == VehicleStatus.AVAILABLE) {
            score += 10.0;
        }

        // Refrigeration exact match bonus
        if (booking.isRequiresRefrigeration() == vehicle.isRefrigerated()) {
            score += 10.0;
        }

        // Capacity utilization efficiency (0-10 pts): higher utilization without overflow is optimal
        if (vehicle.getCapacity() != null && booking.getCargoWeightKg() != null
                && vehicle.getCapacity().compareTo(BigDecimal.ZERO) > 0) {
            double ratio = booking.getCargoWeightKg().doubleValue() / vehicle.getCapacity().doubleValue();
            if (ratio >= 0.5 && ratio <= 0.95) {
                score += 10.0; // Optimal payload utilization
            } else if (ratio < 0.5) {
                score += 5.0;  // Oversized vehicle for cargo
            }
        }

        return score;
    }

    private boolean isEligibleDriver(DriverProfile driver) {
        // Must be KYC approved
        if (driver.getKycStatus() != KycStatus.APPROVED) {
            return false;
        }

        // Must be available or on trip (exclude off duty and inactive)
        if (driver.getAvailabilityStatus() == DriverAvailability.OFF_DUTY ||
                driver.getAvailabilityStatus() == DriverAvailability.INACTIVE) {
            return false;
        }

        return true;
    }

    private double calculateDriverScore(DriverProfile driver) {
        double score = 20.0; // Base eligibility score

        // Availability bonus
        if (driver.getAvailabilityStatus() == DriverAvailability.AVAILABLE) {
            score += 10.0;
        }

        // Workload proxy scoring using active booking count (0-15 pts)
        long activeBookings = countActiveBookingsForDriver(driver.getId());
        if (activeBookings == 0) {
            score += 15.0;
        } else if (activeBookings == 1) {
            score += 10.0;
        } else if (activeBookings == 2) {
            score += 5.0;
        }
        // 3+ active bookings receive 0 workload bonus

        // Rating average score (0-5 pts)
        if (driver.getRatingAverage() != null) {
            score += Math.min(5.0, driver.getRatingAverage().doubleValue());
        }

        return score;
    }

    private long countActiveBookingsForDriver(UUID driverId) {
        List<Booking> driverBookings = bookingRepository.findByDriverId(driverId);
        return driverBookings.stream()
                .filter(b -> b.getStatus() == BookingStatus.ACCEPTED
                        || b.getStatus() == BookingStatus.DRIVER_ASSIGNED
                        || b.getStatus() == BookingStatus.IN_TRANSIT)
                .count();
    }

    private record ScoredVehicle(Vehicle vehicle, double score) {}
    private record ScoredDriver(DriverProfile driver, double score) {}
}
