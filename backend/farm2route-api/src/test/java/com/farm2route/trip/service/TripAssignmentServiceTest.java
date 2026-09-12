package com.farm2route.trip.service;

import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.agency.repository.AgencyProfileRepository;
import com.farm2route.booking.entity.Booking;
import com.farm2route.booking.repository.BookingRepository;
import com.farm2route.common.enums.BookingStatus;
import com.farm2route.common.enums.DriverAvailability;
import com.farm2route.common.enums.KycStatus;
import com.farm2route.common.enums.TripStatus;
import com.farm2route.common.enums.VehicleStatus;
import com.farm2route.common.exception.BusinessRuleException;
import com.farm2route.common.exception.ResourceNotFoundException;
import com.farm2route.driver.entity.DriverProfile;
import com.farm2route.driver.repository.DriverProfileRepository;
import com.farm2route.smart.assignment.AssignmentEngine;
import com.farm2route.smart.assignment.DefaultAssignmentEngine;
import com.farm2route.trip.entity.TripAssignment;
import com.farm2route.trip.repository.TripAssignmentRepository;
import com.farm2route.vehicle.entity.Vehicle;
import com.farm2route.vehicle.repository.VehicleRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class TripAssignmentServiceTest {

    @Mock
    private BookingRepository bookingRepository;

    @Mock
    private AgencyProfileRepository agencyProfileRepository;

    @Mock
    private DriverProfileRepository driverProfileRepository;

    @Mock
    private VehicleRepository vehicleRepository;

    @Mock
    private TripAssignmentRepository tripAssignmentRepository;

    @Mock
    private DefaultAssignmentEngine assignmentEngine;

    @Mock
    private ApplicationEventPublisher applicationEventPublisher;

    @InjectMocks
    private TripAssignmentService tripAssignmentService;

    private UUID bookingId;
    private UUID agencyId;
    private UUID driverId;
    private UUID vehicleId;
    private Booking booking;
    private DriverProfile driver;
    private Vehicle vehicle;

    @BeforeEach
    void setUp() {
        bookingId = UUID.randomUUID();
        agencyId = UUID.randomUUID();
        driverId = UUID.randomUUID();
        vehicleId = UUID.randomUUID();

        AgencyProfile agency = AgencyProfile.builder().id(agencyId).build();
        driver = DriverProfile.builder()
                .id(driverId)
                .agency(agency)
                .fullName("Driver One")
                .kycStatus(KycStatus.APPROVED)
                .availabilityStatus(DriverAvailability.AVAILABLE)
                .build();
        vehicle = Vehicle.builder()
                .id(vehicleId)
                .agency(agency)
                .registrationNumber("TRK-001")
                .makeAndModel("Farm Truck")
                .capacity(new BigDecimal("1000"))
                .cargoVolumeCbm(new BigDecimal("10"))
                .status(VehicleStatus.AVAILABLE)
                .kycStatus(KycStatus.APPROVED)
                .build();
        booking = Booking.builder()
                .id(bookingId)
                .agency(agency)
                .status(BookingStatus.ACCEPTED)
                .cargoWeightKg(new BigDecimal("100"))
                .cargoVolumeCbm(new BigDecimal("1"))
                .requiresRefrigeration(false)
                .build();
    }

    @Test
    void recommendationSucceedsWithoutPersistingAssignment() {
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(booking));
        when(assignmentEngine.matchAndAssign(bookingId, agencyId))
                .thenReturn(new AssignmentEngine.AssignmentResult(vehicleId, driverId, 91.5, "best match"));
        when(driverProfileRepository.findById(driverId)).thenReturn(Optional.of(driver));
        when(vehicleRepository.findById(vehicleId)).thenReturn(Optional.of(vehicle));

        var result = tripAssignmentService.recommendAssignment(bookingId);

        assertThat(result.getRecommendedDriverId()).isEqualTo(driverId);
        assertThat(result.getRecommendedVehicleId()).isEqualTo(vehicleId);
        assertThat(result.getMatchScore()).isEqualTo(91.5);
        verifyNoInteractions(tripAssignmentRepository);
    }

    @Test
    void recommendationFailsWhenEngineHasNoCandidates() {
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(booking));
        when(assignmentEngine.matchAndAssign(bookingId, agencyId))
                .thenReturn(new AssignmentEngine.AssignmentResult(null, null, 0, "No matching candidates"));

        assertThatThrownBy(() -> tripAssignmentService.recommendAssignment(bookingId))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessage("No matching candidates");
        verifyNoInteractions(tripAssignmentRepository);
    }

    @Test
    void bookingNotFound() {
        when(bookingRepository.findByIdForUpdate(bookingId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> tripAssignmentService.assignTrip(bookingId, driverId, vehicleId))
                .isInstanceOf(ResourceNotFoundException.class);
        verifyNoInteractions(tripAssignmentRepository, driverProfileRepository, vehicleRepository);
    }

        @Test
        void unauthorizedAgencyCannotAssignBooking() {
        UUID otherAgencyUserId = UUID.randomUUID();
        when(bookingRepository.findByIdForUpdate(bookingId)).thenReturn(Optional.of(booking));
        when(agencyProfileRepository.findByUserId(otherAgencyUserId))
            .thenReturn(Optional.of(AgencyProfile.builder().id(UUID.randomUUID()).build()));

        assertThatThrownBy(() -> tripAssignmentService.assignTrip(otherAgencyUserId, bookingId, driverId, vehicleId))
            .isInstanceOf(com.farm2route.common.exception.ForbiddenException.class)
            .hasMessageContaining("not authorized");
        verifyNoInteractions(driverProfileRepository, vehicleRepository, tripAssignmentRepository);
        }

    @Test
    void driverNotFound() {
        when(bookingRepository.findByIdForUpdate(bookingId)).thenReturn(Optional.of(booking));
        when(driverProfileRepository.findByIdForUpdate(driverId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> tripAssignmentService.assignTrip(bookingId, driverId, vehicleId))
                .isInstanceOf(ResourceNotFoundException.class);
        verify(tripAssignmentRepository, never()).save(any());
    }

    @Test
    void vehicleNotFound() {
        when(bookingRepository.findByIdForUpdate(bookingId)).thenReturn(Optional.of(booking));
        when(driverProfileRepository.findByIdForUpdate(driverId)).thenReturn(Optional.of(driver));
        when(vehicleRepository.findByIdForUpdate(vehicleId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> tripAssignmentService.assignTrip(bookingId, driverId, vehicleId))
                .isInstanceOf(ResourceNotFoundException.class);
        verify(tripAssignmentRepository, never()).save(any());
    }

    @Test
    void driverAlreadyHasActiveAssignment() {
        givenAssignableResources();
        when(tripAssignmentRepository.findByBookingId(bookingId)).thenReturn(Optional.empty());
        when(tripAssignmentRepository.existsByDriverIdAndStatusIn(eq(driverId), any())).thenReturn(true);

        assertThatThrownBy(() -> tripAssignmentService.assignTrip(bookingId, driverId, vehicleId))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("Driver already");
        verify(tripAssignmentRepository, never()).save(any());
    }

    @Test
    void vehicleAlreadyHasActiveAssignment() {
        givenAssignableResources();
        when(tripAssignmentRepository.findByBookingId(bookingId)).thenReturn(Optional.empty());
        when(tripAssignmentRepository.existsByDriverIdAndStatusIn(eq(driverId), any())).thenReturn(false);
        when(tripAssignmentRepository.existsByVehicleIdAndStatusIn(eq(vehicleId), any())).thenReturn(true);

        assertThatThrownBy(() -> tripAssignmentService.assignTrip(bookingId, driverId, vehicleId))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("Vehicle already");
        verify(tripAssignmentRepository, never()).save(any());
    }

    @Test
    void successfulManualAssignmentUpdatesBookingAndPublishesEvent() {
        givenAssignableResources();
        when(tripAssignmentRepository.findByBookingId(bookingId)).thenReturn(Optional.empty());
        when(tripAssignmentRepository.existsByDriverIdAndStatusIn(eq(driverId), any())).thenReturn(false);
        when(tripAssignmentRepository.existsByVehicleIdAndStatusIn(eq(vehicleId), any())).thenReturn(false);
        when(tripAssignmentRepository.save(any(TripAssignment.class))).thenAnswer(invocation -> {
            TripAssignment assignment = invocation.getArgument(0);
            assignment.setId(UUID.randomUUID());
            return assignment;
        });
        when(bookingRepository.save(booking)).thenReturn(booking);

        var result = tripAssignmentService.assignTrip(bookingId, driverId, vehicleId);

        assertThat(result.getBookingId()).isEqualTo(bookingId);
        assertThat(result.getDriverId()).isEqualTo(driverId);
        assertThat(result.getVehicleId()).isEqualTo(vehicleId);
        assertThat(result.getStatus()).isEqualTo(TripStatus.ASSIGNED);
        assertThat(booking.getDriver()).isSameAs(driver);
        assertThat(booking.getStatus()).isEqualTo(BookingStatus.DRIVER_ASSIGNED);
        verify(tripAssignmentRepository).save(any(TripAssignment.class));
        verify(bookingRepository).save(booking);
        verify(applicationEventPublisher).publishEvent(any(com.farm2route.common.event.DriverAssignedEvent.class));
    }

    @Test
    void bookingCannotBeAssignedTwice() {
        when(bookingRepository.findByIdForUpdate(bookingId)).thenReturn(Optional.of(booking));
        when(tripAssignmentRepository.findByBookingId(bookingId)).thenReturn(Optional.of(new TripAssignment()));

        assertThatThrownBy(() -> tripAssignmentService.assignTrip(bookingId, driverId, vehicleId))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("already has a trip assignment");
        verify(tripAssignmentRepository, never()).save(any());
    }

    @Test
    void invalidDriverDoesNotCreatePartialAssignment() {
        givenAssignableResources();
        driver.setAvailabilityStatus(DriverAvailability.OFF_DUTY);
        when(tripAssignmentRepository.findByBookingId(bookingId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> tripAssignmentService.assignTrip(bookingId, driverId, vehicleId))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("Driver is not available");
        verify(tripAssignmentRepository, never()).save(any());
        verify(bookingRepository, never()).save(any());
        verifyNoInteractions(applicationEventPublisher);
    }

    @Test
    void onTripDriverCannotBeManuallyAssigned() {
        givenAssignableResources();
        driver.setAvailabilityStatus(DriverAvailability.ON_TRIP);
        when(tripAssignmentRepository.findByBookingId(bookingId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> tripAssignmentService.assignTrip(bookingId, driverId, vehicleId))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("Driver is not available");
    }

    @Test
    void pendingDriverKycCannotBeManuallyAssigned() {
        givenAssignableResources();
        driver.setKycStatus(KycStatus.PENDING);
        when(tripAssignmentRepository.findByBookingId(bookingId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> tripAssignmentService.assignTrip(bookingId, driverId, vehicleId))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("Driver KYC");
    }

    @Test
    void invalidVehicleDoesNotCreatePartialAssignment() {
        givenAssignableResources();
        vehicle.setStatus(VehicleStatus.UNDER_MAINTENANCE);
        when(tripAssignmentRepository.findByBookingId(bookingId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> tripAssignmentService.assignTrip(bookingId, driverId, vehicleId))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("Vehicle is not available");
        verify(tripAssignmentRepository, never()).save(any());
        verify(bookingRepository, never()).save(any());
        verifyNoInteractions(applicationEventPublisher);
    }

    @Test
    void inUseVehicleCannotBeManuallyAssigned() {
        givenAssignableResources();
        vehicle.setStatus(VehicleStatus.IN_USE);
        when(tripAssignmentRepository.findByBookingId(bookingId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> tripAssignmentService.assignTrip(bookingId, driverId, vehicleId))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("Vehicle is not available");
    }

    @Test
    void nonApprovedVehicleKycCannotBeManuallyAssigned() {
        givenAssignableResources();
        vehicle.setKycStatus(KycStatus.SUSPENDED);
        when(tripAssignmentRepository.findByBookingId(bookingId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> tripAssignmentService.assignTrip(bookingId, driverId, vehicleId))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("Vehicle KYC");
    }

    @Test
    void manualAssignmentUsesPessimisticLockLookupForAllOperationalRows() {
        givenAssignableResources();
        when(tripAssignmentRepository.findByBookingId(bookingId)).thenReturn(Optional.empty());
        when(tripAssignmentRepository.existsByDriverIdAndStatusIn(eq(driverId), any())).thenReturn(false);
        when(tripAssignmentRepository.existsByVehicleIdAndStatusIn(eq(vehicleId), any())).thenReturn(false);
        when(tripAssignmentRepository.save(any(TripAssignment.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(bookingRepository.save(booking)).thenReturn(booking);

        tripAssignmentService.assignTrip(bookingId, driverId, vehicleId);

        verify(bookingRepository).findByIdForUpdate(bookingId);
        verify(driverProfileRepository).findByIdForUpdate(driverId);
        verify(vehicleRepository).findByIdForUpdate(vehicleId);
    }

    private void givenAssignableResources() {
        when(bookingRepository.findByIdForUpdate(bookingId)).thenReturn(Optional.of(booking));
        when(driverProfileRepository.findByIdForUpdate(driverId)).thenReturn(Optional.of(driver));
        when(vehicleRepository.findByIdForUpdate(vehicleId)).thenReturn(Optional.of(vehicle));
    }
}
