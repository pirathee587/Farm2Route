package com.farm2route.smart.assignment;

import com.farm2route.agency.entity.AgencyProfile;
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
import com.farm2route.smart.assignment.AssignmentEngine.AssignmentResult;
import com.farm2route.vehicle.entity.Vehicle;
import com.farm2route.vehicle.repository.VehicleRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class DefaultAssignmentEngineTest {

    @Mock
    private BookingRepository bookingRepository;

    @Mock
    private VehicleRepository vehicleRepository;

    @Mock
    private DriverProfileRepository driverProfileRepository;

    @Mock
    private AgencyProfileRepository agencyProfileRepository;

    @InjectMocks
    private DefaultAssignmentEngine assignmentEngine;

    private UUID bookingId;
    private UUID agencyId;
    private UUID vehicleId1;
    private UUID vehicleId2;
    private UUID driverId1;
    private UUID driverId2;

    private Booking booking;
    private Vehicle vehicle1;
    private Vehicle vehicle2;
    private DriverProfile driver1;
    private DriverProfile driver2;

    @BeforeEach
    void setUp() {
        bookingId = UUID.randomUUID();
        agencyId = UUID.randomUUID();
        vehicleId1 = UUID.randomUUID();
        vehicleId2 = UUID.randomUUID();
        driverId1 = UUID.randomUUID();
        driverId2 = UUID.randomUUID();

        AgencyProfile agency = AgencyProfile.builder().id(agencyId).companyName("Green Logistics").build();

        booking = Booking.builder()
                .id(bookingId)
                .bookingNumber("F2R-1001")
                .agency(agency)
                .cargoWeightKg(new BigDecimal("1000.00"))
                .cargoVolumeCbm(new BigDecimal("5.00"))
                .requiresRefrigeration(false)
                .status(BookingStatus.ACCEPTED)
                .build();

        vehicle1 = Vehicle.builder()
                .id(vehicleId1)
                .agency(agency)
                .registrationNumber("WP-CAB-1001")
                .capacity(new BigDecimal("2000.00"))
                .cargoVolumeCbm(new BigDecimal("10.00"))
                .isRefrigerated(false)
                .status(VehicleStatus.AVAILABLE)
                .kycStatus(KycStatus.APPROVED)
                .build();

        vehicle2 = Vehicle.builder()
                .id(vehicleId2)
                .agency(agency)
                .registrationNumber("WP-CAB-1002")
                .capacity(new BigDecimal("5000.00"))
                .cargoVolumeCbm(new BigDecimal("25.00"))
                .isRefrigerated(true)
                .status(VehicleStatus.AVAILABLE)
                .kycStatus(KycStatus.APPROVED)
                .build();

        driver1 = DriverProfile.builder()
                .id(driverId1)
                .agency(agency)
                .fullName("Kamal Perera")
                .kycStatus(KycStatus.APPROVED)
                .availabilityStatus(DriverAvailability.AVAILABLE)
                .ratingAverage(new BigDecimal("4.80"))
                .build();

        driver2 = DriverProfile.builder()
                .id(driverId2)
                .agency(agency)
                .fullName("Nimal Fernando")
                .kycStatus(KycStatus.APPROVED)
                .availabilityStatus(DriverAvailability.AVAILABLE)
                .ratingAverage(new BigDecimal("4.20"))
                .build();
    }

    @Test
    @DisplayName("matchAndAssign selects optimal vehicle and driver pair successfully")
    void testMatchAndAssign_Success() {
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(booking));
        when(agencyProfileRepository.existsById(agencyId)).thenReturn(true);
        when(vehicleRepository.findByAgencyId(agencyId)).thenReturn(List.of(vehicle1, vehicle2));
        when(driverProfileRepository.findByAgencyId(agencyId)).thenReturn(List.of(driver1, driver2));

        AssignmentResult result = assignmentEngine.matchAndAssign(bookingId, agencyId);

        assertThat(result).isNotNull();
        assertThat(result.vehicleId()).isNotNull();
        assertThat(result.driverId()).isNotNull();
        assertThat(result.matchScore()).isGreaterThan(0.0);
        assertThat(result.rationale()).contains("Selected vehicle");
    }

    @Test
    @DisplayName("matchAndAssign excludes non-refrigerated vehicles when refrigeration is required")
    void testMatchAndAssign_RefrigerationRequired_ExcludesNonRefrigerated() {
        booking.setRequiresRefrigeration(true);

        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(booking));
        when(agencyProfileRepository.existsById(agencyId)).thenReturn(true);
        when(vehicleRepository.findByAgencyId(agencyId)).thenReturn(List.of(vehicle1, vehicle2));
        when(driverProfileRepository.findByAgencyId(agencyId)).thenReturn(List.of(driver1));

        AssignmentResult result = assignmentEngine.matchAndAssign(bookingId, agencyId);

        // vehicle1 is not refrigerated, so vehicle2 (refrigerated) must be selected
        assertThat(result.vehicleId()).isEqualTo(vehicleId2);
        assertThat(result.driverId()).isEqualTo(driverId1);
    }

    @Test
    @DisplayName("matchAndAssign excludes vehicles with insufficient capacity")
    void testMatchAndAssign_InsufficientCapacity_ExcludesSmallVehicle() {
        booking.setCargoWeightKg(new BigDecimal("3000.00")); // exceeds vehicle1 capacity (2000kg)

        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(booking));
        when(agencyProfileRepository.existsById(agencyId)).thenReturn(true);
        when(vehicleRepository.findByAgencyId(agencyId)).thenReturn(List.of(vehicle1, vehicle2));
        when(driverProfileRepository.findByAgencyId(agencyId)).thenReturn(List.of(driver1));

        AssignmentResult result = assignmentEngine.matchAndAssign(bookingId, agencyId);

        // vehicle1 capacity is 2000kg < 3000kg, so vehicle2 must be selected
        assertThat(result.vehicleId()).isEqualTo(vehicleId2);
    }

    @Test
    @DisplayName("matchAndAssign excludes unapproved KYC vehicles and drivers")
    void testMatchAndAssign_UnapprovedKyc_Excluded() {
        vehicle1.setKycStatus(KycStatus.PENDING_APPROVAL);
        driver1.setKycStatus(KycStatus.PENDING);

        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(booking));
        when(agencyProfileRepository.existsById(agencyId)).thenReturn(true);
        when(vehicleRepository.findByAgencyId(agencyId)).thenReturn(List.of(vehicle1, vehicle2));
        when(driverProfileRepository.findByAgencyId(agencyId)).thenReturn(List.of(driver1, driver2));

        AssignmentResult result = assignmentEngine.matchAndAssign(bookingId, agencyId);

        assertThat(result.vehicleId()).isEqualTo(vehicleId2);
        assertThat(result.driverId()).isEqualTo(driverId2);
    }

    @Test
    @DisplayName("matchAndAssign excludes vehicles under maintenance")
    void testMatchAndAssign_UnderMaintenance_Excluded() {
        vehicle1.setStatus(VehicleStatus.UNDER_MAINTENANCE);

        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(booking));
        when(agencyProfileRepository.existsById(agencyId)).thenReturn(true);
        when(vehicleRepository.findByAgencyId(agencyId)).thenReturn(List.of(vehicle1, vehicle2));
        when(driverProfileRepository.findByAgencyId(agencyId)).thenReturn(List.of(driver1));

        AssignmentResult result = assignmentEngine.matchAndAssign(bookingId, agencyId);

        assertThat(result.vehicleId()).isEqualTo(vehicleId2);
    }

    @Test
    @DisplayName("matchAndAssign scores driver with lower workload higher than overloaded driver")
    void testMatchAndAssign_OverloadedDriver_LowerScore() {
        Booking activeBooking1 = Booking.builder().id(UUID.randomUUID()).driver(driver1).status(BookingStatus.ACCEPTED).build();
        Booking activeBooking2 = Booking.builder().id(UUID.randomUUID()).driver(driver1).status(BookingStatus.IN_TRANSIT).build();
        Booking activeBooking3 = Booking.builder().id(UUID.randomUUID()).driver(driver1).status(BookingStatus.DRIVER_ASSIGNED).build();

        // driver1 has 3 active bookings, driver2 has 0 active bookings
        when(bookingRepository.findByDriverId(driverId1)).thenReturn(List.of(activeBooking1, activeBooking2, activeBooking3));
        when(bookingRepository.findByDriverId(driverId2)).thenReturn(List.of());

        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(booking));
        when(agencyProfileRepository.existsById(agencyId)).thenReturn(true);
        when(vehicleRepository.findByAgencyId(agencyId)).thenReturn(List.of(vehicle1));
        when(driverProfileRepository.findByAgencyId(agencyId)).thenReturn(List.of(driver1, driver2));

        AssignmentResult result = assignmentEngine.matchAndAssign(bookingId, agencyId);

        // driver2 should be preferred because driver1 is overloaded with 3 active bookings
        assertThat(result.driverId()).isEqualTo(driverId2);
    }

    @Test
    @DisplayName("matchAndAssign throws ResourceNotFoundException when booking or agency not found")
    void testMatchAndAssign_NotFound_ThrowsException() {
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> assignmentEngine.matchAndAssign(bookingId, agencyId))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Booking not found");
    }
}
