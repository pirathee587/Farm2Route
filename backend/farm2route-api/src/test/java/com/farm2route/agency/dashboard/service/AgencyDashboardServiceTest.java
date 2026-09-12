package com.farm2route.agency.dashboard.service;

import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.agency.repository.AgencyProfileRepository;
import com.farm2route.booking.repository.BookingRepository;
import com.farm2route.common.enums.BookingStatus;
import com.farm2route.common.enums.DriverAvailability;
import com.farm2route.common.enums.KycStatus;
import com.farm2route.common.enums.MaintenanceStatus;
import com.farm2route.common.enums.TripStatus;
import com.farm2route.common.enums.VehicleStatus;
import com.farm2route.driver.repository.DriverProfileRepository;
import com.farm2route.finance.AgencyFinanceService;
import com.farm2route.finance.dto.AgencyEarningsSummaryDto;
import com.farm2route.maintenance.repository.VehicleMaintenanceRepository;
import com.farm2route.trip.repository.TripAssignmentRepository;
import com.farm2route.vehicle.repository.VehicleRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AgencyDashboardServiceTest {
    @Mock AgencyProfileRepository agencyRepository;
    @Mock BookingRepository bookingRepository;
    @Mock DriverProfileRepository driverRepository;
    @Mock VehicleRepository vehicleRepository;
    @Mock TripAssignmentRepository tripRepository;
    @Mock VehicleMaintenanceRepository maintenanceRepository;
    @Mock AgencyFinanceService financeService;
    private AgencyDashboardService service;
    private final UUID userId = UUID.randomUUID();
    private final UUID agencyId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        service = new AgencyDashboardService(agencyRepository, bookingRepository, driverRepository, vehicleRepository,
                tripRepository, maintenanceRepository, financeService);
        when(agencyRepository.findByUserId(userId)).thenReturn(Optional.of(AgencyProfile.builder().id(agencyId).build()));
        when(financeService.getSummary(userId)).thenReturn(AgencyEarningsSummaryDto.builder()
                .grossEarnings(new BigDecimal("100.00")).commission(new BigDecimal("10.00"))
                .netEarnings(new BigDecimal("90.00")).withdrawn(BigDecimal.ZERO)
                .availableBalance(new BigDecimal("90.00")).build());
        lenient().when(bookingRepository.countByAgencyIdAndStatus(eq(agencyId), any(BookingStatus.class))).thenReturn(0L);
        lenient().when(tripRepository.countByBookingAgencyIdAndStatus(eq(agencyId), any(TripStatus.class))).thenReturn(0L);
    }

    @Test
    void aggregatesAgencyScopedMetricsAndReusesFinanceService() {
        when(bookingRepository.countByAgencyId(agencyId)).thenReturn(4L);
        when(bookingRepository.countByAgencyIdAndStatus(agencyId, BookingStatus.PENDING)).thenReturn(2L);
        when(bookingRepository.countByAgencyIdAndStatus(agencyId, BookingStatus.DELIVERED)).thenReturn(1L);
        when(driverRepository.countByAgencyId(agencyId)).thenReturn(3L);
        when(driverRepository.countByAgencyIdAndKycStatus(agencyId, KycStatus.APPROVED)).thenReturn(2L);
        when(driverRepository.countByAgencyIdAndAvailabilityStatus(agencyId, DriverAvailability.AVAILABLE)).thenReturn(1L);
        when(vehicleRepository.countByAgencyId(agencyId)).thenReturn(2L);
        when(vehicleRepository.countByAgencyIdAndKycStatus(agencyId, KycStatus.APPROVED)).thenReturn(2L);
        when(vehicleRepository.countByAgencyIdAndStatus(agencyId, VehicleStatus.AVAILABLE)).thenReturn(1L);
        when(tripRepository.countByBookingAgencyId(agencyId)).thenReturn(2L);
        when(tripRepository.countByBookingAgencyIdAndStatus(agencyId, TripStatus.COMPLETED)).thenReturn(1L);

        var result = service.getDashboard(userId);

        assertThat(result.getBookingSummary().getTotal()).isEqualTo(4);
        assertThat(result.getDriverSummary().getApproved()).isEqualTo(2);
        assertThat(result.getVehicleSummary().getAvailable()).isEqualTo(1);
        assertThat(result.getAssignmentSummary().getUnassignedBookings()).isEqualTo(2);
        assertThat(result.getFinanceSummary().getAvailableBalance()).isEqualByComparingTo("90.00");
        verify(financeService).getSummary(userId);
    }

    @Test
    void emptyAgencyReturnsZeroMetrics() {
        var result = service.getDashboard(userId);
        assertThat(result.getBookingSummary().getTotal()).isZero();
        assertThat(result.getAssignmentSummary().getUnassignedBookings()).isZero();
        assertThat(result.getMaintenanceSummary().getOverdue()).isZero();
    }
}
