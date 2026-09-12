package com.farm2route.trip.service;

import com.farm2route.agency.repository.AgencyProfileRepository;
import com.farm2route.booking.entity.Booking;
import com.farm2route.booking.repository.BookingRepository;
import com.farm2route.common.enums.BookingStatus;
import com.farm2route.common.enums.DriverAvailability;
import com.farm2route.common.enums.KycStatus;
import com.farm2route.common.enums.TripStatus;
import com.farm2route.common.enums.VehicleStatus;
import com.farm2route.common.event.DriverAssignedEvent;
import com.farm2route.common.exception.BusinessRuleException;
import com.farm2route.common.exception.ForbiddenException;
import com.farm2route.common.exception.ResourceNotFoundException;
import com.farm2route.driver.entity.DriverProfile;
import com.farm2route.driver.repository.DriverProfileRepository;
import com.farm2route.smart.assignment.AssignmentEngine;
import com.farm2route.smart.assignment.DefaultAssignmentEngine;
import com.farm2route.trip.dto.AssignmentRecommendationResponse;
import com.farm2route.trip.dto.TripAssignmentRequest;
import com.farm2route.trip.dto.TripAssignmentResponse;
import com.farm2route.trip.entity.TripAssignment;
import com.farm2route.trip.repository.TripAssignmentRepository;
import com.farm2route.vehicle.entity.Vehicle;
import com.farm2route.vehicle.repository.VehicleRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Objects;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class TripAssignmentService {

    private static final List<String> ACTIVE_STATUSES = List.of(
            TripStatus.ASSIGNED.name(),
            TripStatus.STARTED.name(),
            TripStatus.AT_PICKUP.name(),
            TripStatus.LOADED.name(),
            TripStatus.IN_TRANSIT.name()
    );

    private final BookingRepository bookingRepository;
    private final AgencyProfileRepository agencyProfileRepository;
    private final DriverProfileRepository driverProfileRepository;
    private final VehicleRepository vehicleRepository;
    private final TripAssignmentRepository tripAssignmentRepository;
    private final DefaultAssignmentEngine assignmentEngine;
    private final ApplicationEventPublisher applicationEventPublisher;

    @Transactional(readOnly = true)
    public AssignmentRecommendationResponse recommendAssignment(UUID bookingId) {
        return recommendAssignment(null, bookingId);
    }

    @Transactional(readOnly = true)
    public AssignmentRecommendationResponse recommendAssignment(UUID agencyUserId, UUID bookingId) {
        Booking booking = findBooking(bookingId);
        validateAgencyAccess(agencyUserId, booking);
        AssignmentEngine.AssignmentResult result = assignmentEngine.matchAndAssign(
                bookingId, booking.getAgency().getId());

        if (result.vehicleId() == null || result.driverId() == null) {
            throw new BusinessRuleException(result.rationale());
        }

        DriverProfile driver = findDriver(result.driverId());
        Vehicle vehicle = findVehicle(result.vehicleId());
        return toRecommendation(bookingId, driver, vehicle, result);
    }

    @Transactional
    public TripAssignmentResponse assignTrip(UUID bookingId, UUID driverId, UUID vehicleId) {
        return assignTrip(null, bookingId, driverId, vehicleId);
    }

    @Transactional
    public TripAssignmentResponse assignTrip(UUID agencyUserId, UUID bookingId, UUID driverId, UUID vehicleId) {
        Booking booking = bookingRepository.findByIdForUpdate(bookingId)
                .orElseThrow(() -> new ResourceNotFoundException("Booking not found with id: " + bookingId));
        validateAgencyAccess(agencyUserId, booking);
        if (booking.getStatus() != BookingStatus.ACCEPTED) {
            throw new BusinessRuleException("Only ACCEPTED bookings can be assigned");
        }
        if (tripAssignmentRepository.findByBookingId(bookingId).isPresent()) {
            throw new BusinessRuleException("Booking already has a trip assignment");
        }

        DriverProfile driver = driverProfileRepository.findByIdForUpdate(driverId)
                .orElseThrow(() -> new ResourceNotFoundException("Driver not found with id: " + driverId));
        Vehicle vehicle = vehicleRepository.findByIdForUpdate(vehicleId)
                .orElseThrow(() -> new ResourceNotFoundException("Vehicle not found with id: " + vehicleId));
        validateOwnership(booking, driver, vehicle);
        validateDriver(driver);
        validateVehicle(vehicle, booking);

        if (tripAssignmentRepository.existsByDriverIdAndStatusIn(driverId, ACTIVE_STATUSES)) {
            throw new BusinessRuleException("Driver already has an active trip assignment");
        }
        if (tripAssignmentRepository.existsByVehicleIdAndStatusIn(vehicleId, ACTIVE_STATUSES)) {
            throw new BusinessRuleException("Vehicle already has an active trip assignment");
        }

        TripAssignment assignment = TripAssignment.builder()
                .booking(booking)
                .driver(driver)
                .vehicle(vehicle)
                .status(TripStatus.ASSIGNED)
                .build();
        assignment = tripAssignmentRepository.save(assignment);

        booking.setDriver(driver);
        booking.setStatus(BookingStatus.DRIVER_ASSIGNED);
        bookingRepository.save(booking);

        applicationEventPublisher.publishEvent(
                DriverAssignedEvent.builder()
                        .assignmentId(assignment.getId())
                        .bookingId(bookingId)
                        .driverId(driverId)
                        .vehicleId(vehicleId)
                        .build()
        );

        return toResponse(assignment);
    }

    private Booking findBooking(UUID bookingId) {
        return bookingRepository.findById(bookingId)
                .orElseThrow(() -> new ResourceNotFoundException("Booking not found with id: " + bookingId));
    }

    private DriverProfile findDriver(UUID driverId) {
        return driverProfileRepository.findById(driverId)
                .orElseThrow(() -> new ResourceNotFoundException("Driver not found with id: " + driverId));
    }

    private Vehicle findVehicle(UUID vehicleId) {
        return vehicleRepository.findById(vehicleId)
                .orElseThrow(() -> new ResourceNotFoundException("Vehicle not found with id: " + vehicleId));
    }

    private void validateOwnership(Booking booking, DriverProfile driver, Vehicle vehicle) {
        UUID agencyId = booking.getAgency().getId();
        if (driver.getAgency() == null || !Objects.equals(driver.getAgency().getId(), agencyId)) {
            throw new BusinessRuleException("Driver does not belong to the booking agency");
        }
        if (vehicle.getAgency() == null || !Objects.equals(vehicle.getAgency().getId(), agencyId)) {
            throw new BusinessRuleException("Vehicle does not belong to the booking agency");
        }
    }

    private void validateAgencyAccess(UUID agencyUserId, Booking booking) {
        if (agencyUserId == null) {
            return;
        }
        UUID bookingAgencyId = booking.getAgency().getId();
        UUID authenticatedAgencyId = agencyProfileRepository.findByUserId(agencyUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Agency profile not found for user: " + agencyUserId))
                .getId();
        if (!Objects.equals(authenticatedAgencyId, bookingAgencyId)) {
            throw new ForbiddenException("You are not authorized to assign this booking");
        }
    }

    private void validateDriver(DriverProfile driver) {
        if (driver.getKycStatus() != KycStatus.APPROVED) {
            throw new BusinessRuleException("Driver KYC is not approved");
        }
        if (driver.getAvailabilityStatus() != DriverAvailability.AVAILABLE) {
            throw new BusinessRuleException("Driver is not available for assignment");
        }
    }

    private void validateVehicle(Vehicle vehicle, Booking booking) {
        if (vehicle.getKycStatus() != KycStatus.APPROVED) {
            throw new BusinessRuleException("Vehicle KYC is not approved");
        }
        if (vehicle.getStatus() != VehicleStatus.AVAILABLE) {
            throw new BusinessRuleException("Vehicle is not available for assignment");
        }
        if (vehicle.getCapacity() == null || booking.getCargoWeightKg() == null
                || vehicle.getCapacity().compareTo(booking.getCargoWeightKg()) < 0) {
            throw new BusinessRuleException("Vehicle capacity is insufficient for the booking");
        }
        if (booking.getCargoVolumeCbm() != null && vehicle.getCargoVolumeCbm() != null
                && vehicle.getCargoVolumeCbm().compareTo(booking.getCargoVolumeCbm()) < 0) {
            throw new BusinessRuleException("Vehicle cargo volume is insufficient for the booking");
        }
        if (booking.isRequiresRefrigeration() && !vehicle.isRefrigerated()) {
            throw new BusinessRuleException("Booking requires a refrigerated vehicle");
        }
    }

    private AssignmentRecommendationResponse toRecommendation(
            UUID bookingId,
            DriverProfile driver,
            Vehicle vehicle,
            AssignmentEngine.AssignmentResult result) {
        return AssignmentRecommendationResponse.builder()
                .bookingId(bookingId)
                .recommendedDriverId(driver.getId())
                .recommendedDriverName(driver.getFullName())
                .recommendedDriverRating(driver.getRatingAverage())
                .recommendedDriverAvailability(driver.getAvailabilityStatus())
                .recommendedVehicleId(vehicle.getId())
                .recommendedVehicleRegistrationNumber(vehicle.getRegistrationNumber())
                .recommendedVehicleMakeAndModel(vehicle.getMakeAndModel())
                .recommendedVehicleCapacity(vehicle.getCapacity())
                .recommendedVehicleType(vehicle.getVehicleType())
                .matchScore(result.matchScore())
                .rationale(result.rationale())
                .build();
    }

    private TripAssignmentResponse toResponse(TripAssignment assignment) {
        return TripAssignmentResponse.builder()
                .assignmentId(assignment.getId())
                .bookingId(assignment.getBooking().getId())
                .driverId(assignment.getDriver().getId())
                .vehicleId(assignment.getVehicle().getId())
                .status(assignment.getStatus())
                .startedAt(assignment.getStartedAt())
                .completedAt(assignment.getCompletedAt())
                .createdAt(assignment.getCreatedAt())
                .updatedAt(assignment.getUpdatedAt())
                .build();
    }
}
