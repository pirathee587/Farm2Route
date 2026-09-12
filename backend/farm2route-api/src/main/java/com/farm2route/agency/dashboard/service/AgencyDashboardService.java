package com.farm2route.agency.dashboard.service;

import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.agency.repository.AgencyProfileRepository;
import com.farm2route.agency.dashboard.dto.AgencyDashboardResponse;
import com.farm2route.booking.repository.BookingRepository;
import com.farm2route.common.enums.BookingStatus;
import com.farm2route.common.enums.DriverAvailability;
import com.farm2route.common.enums.KycStatus;
import com.farm2route.common.enums.MaintenanceStatus;
import com.farm2route.common.enums.TripStatus;
import com.farm2route.common.enums.VehicleStatus;
import com.farm2route.driver.repository.DriverProfileRepository;
import com.farm2route.finance.AgencyFinanceService;
import com.farm2route.maintenance.repository.VehicleMaintenanceRepository;
import com.farm2route.trip.repository.TripAssignmentRepository;
import com.farm2route.vehicle.repository.VehicleRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.UUID;
import java.util.List;

@Service
@RequiredArgsConstructor
public class AgencyDashboardService {
    private final AgencyProfileRepository agencyProfileRepository;
    private final BookingRepository bookingRepository;
    private final DriverProfileRepository driverProfileRepository;
    private final VehicleRepository vehicleRepository;
    private final TripAssignmentRepository tripAssignmentRepository;
    private final VehicleMaintenanceRepository maintenanceRepository;
    private final AgencyFinanceService agencyFinanceService;

    @Transactional(readOnly = true)
    public AgencyDashboardResponse getDashboard(UUID agencyUserId) {
        AgencyProfile agency = agencyProfileRepository.findByUserId(agencyUserId)
                .orElseThrow(() -> new com.farm2route.common.exception.ResourceNotFoundException("Agency profile not found"));
        UUID agencyId = agency.getId();

        long totalBookings = bookingRepository.countByAgencyId(agencyId);
        long assignedBookings = bookingRepository.countByAgencyIdAndStatus(agencyId, BookingStatus.DRIVER_ASSIGNED);
        long activeAssignments = sumTrips(agencyId, TripStatus.ASSIGNED, TripStatus.STARTED, TripStatus.AT_PICKUP,
                TripStatus.LOADED, TripStatus.IN_TRANSIT);
        long totalTrips = tripAssignmentRepository.countByBookingAgencyId(agencyId);

        return AgencyDashboardResponse.builder()
                .bookingSummary(AgencyDashboardResponse.BookingSummary.builder()
                        .total(totalBookings)
                        .pending(countBooking(agencyId, BookingStatus.PENDING))
                        .accepted(countBooking(agencyId, BookingStatus.ACCEPTED))
                        .rejected(countBooking(agencyId, BookingStatus.REJECTED))
                        .assigned(assignedBookings)
                        .delivered(countBooking(agencyId, BookingStatus.DELIVERED))
                        .cancelled(countBooking(agencyId, BookingStatus.CANCELLED)).build())
                .driverSummary(AgencyDashboardResponse.DriverSummary.builder()
                        .total(driverProfileRepository.countByAgencyId(agencyId))
                        .approved(driverProfileRepository.countByAgencyIdAndKycStatus(agencyId, KycStatus.APPROVED))
                        .pending(countDriversPending(agencyId))
                        .available(driverProfileRepository.countByAgencyIdAndAvailabilityStatus(agencyId, DriverAvailability.AVAILABLE))
                        .unavailable(driverProfileRepository.countByAgencyIdAndAvailabilityStatus(agencyId, DriverAvailability.OFF_DUTY)
                                + driverProfileRepository.countByAgencyIdAndAvailabilityStatus(agencyId, DriverAvailability.INACTIVE)).build())
                .vehicleSummary(AgencyDashboardResponse.VehicleSummary.builder()
                        .total(vehicleRepository.countByAgencyId(agencyId))
                        .approved(vehicleRepository.countByAgencyIdAndKycStatus(agencyId, KycStatus.APPROVED))
                        .pending(vehicleRepository.countByAgencyIdAndKycStatus(agencyId, KycStatus.PENDING_APPROVAL)
                                + vehicleRepository.countByAgencyIdAndKycStatus(agencyId, KycStatus.PENDING))
                        .available(vehicleRepository.countByAgencyIdAndStatus(agencyId, VehicleStatus.AVAILABLE))
                        .underMaintenance(vehicleRepository.countByAgencyIdAndStatus(agencyId, VehicleStatus.UNDER_MAINTENANCE)).build())
                .assignmentSummary(AgencyDashboardResponse.AssignmentSummary.builder()
                        .assigned(totalTrips)
                        .active(activeAssignments)
                        .completed(tripAssignmentRepository.countByBookingAgencyIdAndStatus(agencyId, TripStatus.COMPLETED))
                        .unassignedBookings(Math.max(0, totalBookings - totalTrips)).build())
                .maintenanceSummary(AgencyDashboardResponse.MaintenanceSummary.builder()
                        .inProgress(maintenanceRepository.countByVehicleAgencyIdAndStatus(agencyId, MaintenanceStatus.IN_PROGRESS))
                        .scheduled(maintenanceRepository.countByVehicleAgencyIdAndStatus(agencyId, MaintenanceStatus.SCHEDULED))
                        .overdue(maintenanceRepository.countOverdueForAgency(agencyId, LocalDate.now(),
                                List.of(MaintenanceStatus.SCHEDULED, MaintenanceStatus.IN_PROGRESS))).build())
                .financeSummary(agencyFinanceService.getSummary(agencyUserId))
                .build();
    }

    private long countBooking(UUID agencyId, BookingStatus status) {
        return bookingRepository.countByAgencyIdAndStatus(agencyId, status);
    }

    private long countDriversPending(UUID agencyId) {
        return driverProfileRepository.countByAgencyIdAndKycStatus(agencyId, KycStatus.PENDING)
                + driverProfileRepository.countByAgencyIdAndKycStatus(agencyId, KycStatus.PENDING_APPROVAL);
    }

    private long sumTrips(UUID agencyId, TripStatus... statuses) {
        long total = 0;
        for (TripStatus status : statuses) {
            total += tripAssignmentRepository.countByBookingAgencyIdAndStatus(agencyId, status);
        }
        return total;
    }
}
