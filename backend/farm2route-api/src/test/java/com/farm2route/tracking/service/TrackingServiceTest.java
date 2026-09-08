package com.farm2route.tracking.service;

import com.farm2route.auth.entity.User;
import com.farm2route.auth.model.Role;

import com.farm2route.booking.entity.Booking;
import com.farm2route.common.enums.TripStatus;
import com.farm2route.common.event.TripArrivedEvent;
import com.farm2route.common.exception.ForbiddenException;
import com.farm2route.common.exception.ResourceNotFoundException;
import com.farm2route.driver.entity.DriverProfile;
import com.farm2route.farmer.entity.FarmerProfile;
import com.farm2route.tracking.dto.GpsLocationDto;
import com.farm2route.tracking.dto.TripLocationResponse;
import com.farm2route.tracking.entity.GpsLocation;
import com.farm2route.tracking.entity.TripAssignment;
import com.farm2route.tracking.repository.GpsLocationRepository;
import com.farm2route.tracking.repository.TripAssignmentRepository;
import com.farm2route.vehicle.entity.Vehicle;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.test.util.ReflectionTestUtils;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class TrackingServiceTest {

    @Mock
    private TripAssignmentRepository tripAssignmentRepository;

    @Mock
    private GpsLocationRepository gpsLocationRepository;

    @Mock
    private ApplicationEventPublisher eventPublisher;

    @InjectMocks
    private TrackingService trackingService;

    private UUID tripId;
    private UUID bookingId;
    private UUID farmerUserId;
    private UUID driverUserId;
    private UUID driverProfileId;
    private TripAssignment assignment;

    @BeforeEach
    void setUp() {
        ReflectionTestUtils.setField(trackingService, "geofenceRadiusKm", 0.2);
        ReflectionTestUtils.setField(trackingService, "avgSpeedKmh", 40.0);

        tripId = UUID.randomUUID();
        bookingId = UUID.randomUUID();
        farmerUserId = UUID.randomUUID();
        driverUserId = UUID.randomUUID();
        driverProfileId = UUID.randomUUID();

        User farmerUser = User.builder().id(farmerUserId).role(Role.FARMER).build();
        FarmerProfile farmerProfile = FarmerProfile.builder().id(UUID.randomUUID()).user(farmerUser).build();

        User driverUser = User.builder().id(driverUserId).role(Role.DRIVER).build();
        DriverProfile driverProfile = DriverProfile.builder().id(driverProfileId).user(driverUser).build();

        Booking booking = Booking.builder()
                .id(bookingId)
                .farmer(farmerProfile)
                .deliveryLatitude(BigDecimal.valueOf(6.9271))
                .deliveryLongitude(BigDecimal.valueOf(79.8612))
                .build();

        Vehicle vehicle = Vehicle.builder().id(UUID.randomUUID()).build();

        assignment = TripAssignment.builder()
                .id(tripId)
                .booking(booking)
                .driver(driverProfile)
                .vehicle(vehicle)
                .status(TripStatus.IN_TRANSIT)
                .build();
    }

    @Test
    @DisplayName("saveGpsLocation persists GpsLocation entity with correct trip, booking, and driver references")
    void testSaveGpsLocation_PersistsRow() {
        when(tripAssignmentRepository.findById(tripId)).thenReturn(Optional.of(assignment));
        when(gpsLocationRepository.save(any(GpsLocation.class))).thenAnswer(inv -> inv.getArgument(0));

        GpsLocationDto dto = GpsLocationDto.builder()
                .tripId(tripId)
                .latitude(BigDecimal.valueOf(6.9000))
                .longitude(BigDecimal.valueOf(79.8500))
                .speedKmh(BigDecimal.valueOf(45.5))
                .headingDegrees(BigDecimal.valueOf(180.0))
                .accuracyMeters(BigDecimal.valueOf(5.0))
                .build();

        trackingService.saveGpsLocation(dto);

        ArgumentCaptor<GpsLocation> captor = ArgumentCaptor.forClass(GpsLocation.class);
        verify(gpsLocationRepository).save(captor.capture());

        GpsLocation saved = captor.getValue();
        assertEquals(tripId, saved.getTripId());
        assertEquals(bookingId, saved.getBookingId());
        assertEquals(driverProfileId, saved.getDriverId());
        assertEquals(BigDecimal.valueOf(6.9000), saved.getLatitude());
        assertEquals(BigDecimal.valueOf(79.8500), saved.getLongitude());
        assertNotNull(saved.getRecordedAt());
    }

    @Test
    @DisplayName("saveGpsLocation triggers TripArrivedEvent when entering geofence for the first time")
    void testGeofenceTrigger_FiresEventOnFirstEntry() {
        when(tripAssignmentRepository.findById(tripId)).thenReturn(Optional.of(assignment));
        when(gpsLocationRepository.save(any(GpsLocation.class))).thenAnswer(inv -> {
            GpsLocation loc = inv.getArgument(0);
            loc.setId(UUID.randomUUID());
            return loc;
        });
        when(gpsLocationRepository.findByTripIdOrderByRecordedAtAsc(tripId)).thenReturn(Collections.emptyList());

        // Delivery is (6.9271, 79.8612). Point at (6.9272, 79.8613) is ~15 meters away (< 0.2km)
        GpsLocationDto dto = GpsLocationDto.builder()
                .tripId(tripId)
                .latitude(BigDecimal.valueOf(6.9272))
                .longitude(BigDecimal.valueOf(79.8613))
                .build();

        trackingService.saveGpsLocation(dto);

        ArgumentCaptor<TripArrivedEvent> eventCaptor = ArgumentCaptor.forClass(TripArrivedEvent.class);
        verify(eventPublisher).publishEvent(eventCaptor.capture());

        TripArrivedEvent event = eventCaptor.getValue();
        assertEquals(bookingId, event.getBookingId());
        assertEquals(farmerUserId, event.getFarmerUserId());
        assertEquals(tripId, event.getTripId());
    }

    @Test
    @DisplayName("saveGpsLocation does NOT re-trigger TripArrivedEvent if prior location was already in geofence")
    void testGeofenceTrigger_DoesNotReFireIfAlreadyArrived() {
        when(tripAssignmentRepository.findById(tripId)).thenReturn(Optional.of(assignment));
        when(gpsLocationRepository.save(any(GpsLocation.class))).thenAnswer(inv -> {
            GpsLocation loc = inv.getArgument(0);
            loc.setId(UUID.randomUUID());
            return loc;
        });

        GpsLocation priorLoc = GpsLocation.builder()
                .id(UUID.randomUUID())
                .tripId(tripId)
                .latitude(BigDecimal.valueOf(6.92715))
                .longitude(BigDecimal.valueOf(79.86125))
                .recordedAt(Instant.now().minusSeconds(60))
                .build();

        when(gpsLocationRepository.findByTripIdOrderByRecordedAtAsc(tripId)).thenReturn(List.of(priorLoc));

        GpsLocationDto dto = GpsLocationDto.builder()
                .tripId(tripId)
                .latitude(BigDecimal.valueOf(6.9272))
                .longitude(BigDecimal.valueOf(79.8613))
                .build();

        trackingService.saveGpsLocation(dto);

        verify(eventPublisher, never()).publishEvent(any(TripArrivedEvent.class));
    }

    @Test
    @DisplayName("getLatestLocation calculates distance and ETA accurately for known coordinates")
    void testEtaCalculation_FixedCoordinates() {
        when(tripAssignmentRepository.findById(tripId)).thenReturn(Optional.of(assignment));

        // Delivery: Colombo Fort (6.9271, 79.8612). Current: Mount Lavinia (6.8301, 79.8658) ~ 10.8 km
        GpsLocation latest = GpsLocation.builder()
                .tripId(tripId)
                .bookingId(bookingId)
                .driverId(driverProfileId)
                .latitude(BigDecimal.valueOf(6.8301))
                .longitude(BigDecimal.valueOf(79.8658))
                .speedKmh(BigDecimal.valueOf(40.0))
                .recordedAt(Instant.now())
                .build();

        when(gpsLocationRepository.findTop1ByTripIdOrderByRecordedAtDesc(tripId)).thenReturn(Optional.of(latest));

        TripLocationResponse response = trackingService.getLatestLocation(tripId, farmerUserId, "FARMER");

        assertNotNull(response);
        assertNotNull(response.getLatestLocation());
        assertTrue(response.getRemainingDistanceKm().doubleValue() > 10.0 && response.getRemainingDistanceKm().doubleValue() < 12.0);
        // 10.8km at 40km/h => ~16 minutes
        assertTrue(response.getEstimatedMinutesRemaining() >= 15 && response.getEstimatedMinutesRemaining() <= 18);
        assertFalse(response.isArrivedAtDelivery());
    }

    @Test
    @DisplayName("validateOwnership allows Farmer, Driver, and Admin but denies third-party users")
    void testValidateOwnership_Permissions() {
        when(tripAssignmentRepository.findById(tripId)).thenReturn(Optional.of(assignment));
        GpsLocation latest = GpsLocation.builder()
                .tripId(tripId)
                .bookingId(bookingId)
                .driverId(driverProfileId)
                .latitude(BigDecimal.valueOf(6.9000))
                .longitude(BigDecimal.valueOf(79.8500))
                .recordedAt(Instant.now())
                .build();
        when(gpsLocationRepository.findTop1ByTripIdOrderByRecordedAtDesc(tripId)).thenReturn(Optional.of(latest));

        // Farmer authorized
        assertDoesNotThrow(() -> trackingService.getLatestLocation(tripId, farmerUserId, "FARMER"));

        // Driver authorized
        assertDoesNotThrow(() -> trackingService.getLatestLocation(tripId, driverUserId, "DRIVER"));

        // Admin authorized
        assertDoesNotThrow(() -> trackingService.getLatestLocation(tripId, UUID.randomUUID(), "ADMIN"));

        // Third-party unauthorized
        UUID strangerId = UUID.randomUUID();
        assertThrows(ForbiddenException.class, () -> trackingService.getLatestLocation(tripId, strangerId, "FARMER"));
    }

    @Test
    @DisplayName("getLatestLocation throws ResourceNotFoundException if trip or telemetry missing")
    void testGetLatestLocation_NotFound() {
        UUID unknownTripId = UUID.randomUUID();
        when(tripAssignmentRepository.findById(unknownTripId)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () ->
                trackingService.getLatestLocation(unknownTripId, farmerUserId, "FARMER"));
    }
}
