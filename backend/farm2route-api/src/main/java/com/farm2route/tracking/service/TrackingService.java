package com.farm2route.tracking.service;

import com.farm2route.common.event.TripArrivedEvent;
import com.farm2route.common.exception.ForbiddenException;
import com.farm2route.common.exception.ResourceNotFoundException;
import com.farm2route.common.util.GeoUtils;
import com.farm2route.tracking.dto.GpsLocationDto;
import com.farm2route.tracking.dto.TripLocationResponse;
import com.farm2route.tracking.entity.GpsLocation;
import com.farm2route.tracking.entity.TripAssignment;
import com.farm2route.tracking.repository.GpsLocationRepository;
import com.farm2route.tracking.repository.TripAssignmentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class TrackingService {

    private final TripAssignmentRepository tripAssignmentRepository;
    private final GpsLocationRepository gpsLocationRepository;
    private final ApplicationEventPublisher eventPublisher;

    @Value("${app.tracking.geofence-radius-km:0.2}")
    private double geofenceRadiusKm;

    @Value("${app.tracking.avg-speed-kmh:40.0}")
    private double avgSpeedKmh;

    @Transactional
    public void saveGpsLocation(GpsLocationDto locationDto) {
        if (locationDto.getTripId() == null) {
            throw new IllegalArgumentException("Trip ID cannot be null");
        }

        TripAssignment assignment = tripAssignmentRepository.findById(locationDto.getTripId())
                .orElseThrow(() -> new ResourceNotFoundException("Trip assignment not found with ID: " + locationDto.getTripId()));

        UUID bookingId = assignment.getBooking().getId();
        UUID driverId = assignment.getDriver().getId();

        Instant timestamp = locationDto.getTimestamp() != null ? locationDto.getTimestamp() : Instant.now();
        locationDto.setTimestamp(timestamp);
        locationDto.setBookingId(bookingId);
        locationDto.setDriverId(driverId);

        GpsLocation location = GpsLocation.builder()
                .tripId(assignment.getId())
                .bookingId(bookingId)
                .driverId(driverId)
                .latitude(locationDto.getLatitude())
                .longitude(locationDto.getLongitude())
                .speedKmh(locationDto.getSpeedKmh())
                .headingDegrees(locationDto.getHeadingDegrees())
                .accuracyMeters(locationDto.getAccuracyMeters())
                .recordedAt(timestamp)
                .build();

        gpsLocationRepository.save(location);
        log.debug("Persisted GPS telemetry for trip: {}", assignment.getId());

        // Delivery Geofencing check
        BigDecimal delLat = assignment.getBooking().getDeliveryLatitude();
        BigDecimal delLng = assignment.getBooking().getDeliveryLongitude();

        if (delLat != null && delLng != null && locationDto.getLatitude() != null && locationDto.getLongitude() != null) {
            double currentDistanceKm = GeoUtils.calculateDistanceKm(
                    locationDto.getLatitude().doubleValue(),
                    locationDto.getLongitude().doubleValue(),
                    delLat.doubleValue(),
                    delLng.doubleValue()
            );

            if (currentDistanceKm <= geofenceRadiusKm) {
                boolean previouslyArrived = hasPriorGeofenceArrival(assignment.getId(), delLat, delLng, location.getId());
                if (!previouslyArrived) {
                    UUID farmerUserId = assignment.getBooking().getFarmer().getUser().getId();
                    log.info("[Geofence] Vehicle arrived at delivery for tripId={}, distance={}km", assignment.getId(), currentDistanceKm);

                    eventPublisher.publishEvent(TripArrivedEvent.builder()
                            .bookingId(bookingId)
                            .farmerUserId(farmerUserId)
                            .tripId(assignment.getId())
                            .build());
                }
            }
        }
    }

    @Transactional(readOnly = true)
    public TripLocationResponse getLatestLocation(UUID tripId, UUID requestingUserId, String requestingUserRole) {
        TripAssignment assignment = tripAssignmentRepository.findById(tripId)
                .orElseThrow(() -> new ResourceNotFoundException("Trip assignment not found with ID: " + tripId));

        validateOwnership(assignment, requestingUserId, requestingUserRole);

        GpsLocation latest = gpsLocationRepository.findTop1ByTripIdOrderByRecordedAtDesc(tripId)
                .orElseThrow(() -> new ResourceNotFoundException("No GPS telemetry recorded for trip: " + tripId));

        BigDecimal delLat = assignment.getBooking().getDeliveryLatitude();
        BigDecimal delLng = assignment.getBooking().getDeliveryLongitude();

        double remainingDistanceKm = 0.0;
        int estimatedMinutes = 0;
        boolean arrived = false;

        if (delLat != null && delLng != null && latest.getLatitude() != null && latest.getLongitude() != null) {
            remainingDistanceKm = GeoUtils.calculateDistanceKm(
                    latest.getLatitude().doubleValue(),
                    latest.getLongitude().doubleValue(),
                    delLat.doubleValue(),
                    delLng.doubleValue()
            );

            arrived = remainingDistanceKm <= geofenceRadiusKm;
            if (avgSpeedKmh > 0) {
                estimatedMinutes = (int) Math.round((remainingDistanceKm / avgSpeedKmh) * 60.0);
            }
        }

        return TripLocationResponse.builder()
                .latestLocation(mapToDto(latest))
                .remainingDistanceKm(BigDecimal.valueOf(remainingDistanceKm).setScale(2, RoundingMode.HALF_UP))
                .estimatedMinutesRemaining(estimatedMinutes)
                .arrivedAtDelivery(arrived)
                .build();
    }

    @Transactional(readOnly = true)
    public List<GpsLocationDto> getRouteHistory(UUID tripId, Instant from, Instant to, UUID requestingUserId, String requestingUserRole) {
        TripAssignment assignment = tripAssignmentRepository.findById(tripId)
                .orElseThrow(() -> new ResourceNotFoundException("Trip assignment not found with ID: " + tripId));

        validateOwnership(assignment, requestingUserId, requestingUserRole);

        List<GpsLocation> locations;
        if (from != null && to != null) {
            locations = gpsLocationRepository.findByTripIdAndRecordedAtBetweenOrderByRecordedAtAsc(tripId, from, to);
        } else {
            locations = gpsLocationRepository.findByTripIdOrderByRecordedAtAsc(tripId);
        }

        return locations.stream()
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    private boolean hasPriorGeofenceArrival(UUID tripId, BigDecimal delLat, BigDecimal delLng, UUID currentLocId) {
        List<GpsLocation> history = gpsLocationRepository.findByTripIdOrderByRecordedAtAsc(tripId);
        for (GpsLocation loc : history) {
            if (currentLocId != null && currentLocId.equals(loc.getId())) {
                continue;
            }
            if (loc.getLatitude() != null && loc.getLongitude() != null) {
                double dist = GeoUtils.calculateDistanceKm(
                        loc.getLatitude().doubleValue(),
                        loc.getLongitude().doubleValue(),
                        delLat.doubleValue(),
                        delLng.doubleValue()
                );
                if (dist <= geofenceRadiusKm) {
                    return true;
                }
            }
        }
        return false;
    }

    private void validateOwnership(TripAssignment assignment, UUID requestingUserId, String requestingUserRole) {
        if (requestingUserRole != null && requestingUserRole.toUpperCase().contains("ADMIN")) {
            return;
        }

        UUID farmerUserId = assignment.getBooking().getFarmer().getUser().getId();
        UUID driverUserId = assignment.getDriver().getUser().getId();

        if (requestingUserId != null && (requestingUserId.equals(farmerUserId) || requestingUserId.equals(driverUserId))) {
            return;
        }

        throw new ForbiddenException("You are not authorized to access telemetry for this trip");
    }

    private GpsLocationDto mapToDto(GpsLocation entity) {
        return GpsLocationDto.builder()
                .tripId(entity.getTripId())
                .bookingId(entity.getBookingId())
                .driverId(entity.getDriverId())
                .latitude(entity.getLatitude())
                .longitude(entity.getLongitude())
                .speedKmh(entity.getSpeedKmh())
                .headingDegrees(entity.getHeadingDegrees())
                .accuracyMeters(entity.getAccuracyMeters())
                .timestamp(entity.getRecordedAt())
                .build();
    }
}
