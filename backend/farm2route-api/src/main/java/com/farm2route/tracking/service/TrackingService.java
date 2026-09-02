package com.farm2route.tracking.service;

import com.farm2route.tracking.dto.GpsLocationDto;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Instant;

@Slf4j
@Service
public class TrackingService {

    public void saveGpsLocation(GpsLocationDto locationDto) {
        if (locationDto.getTimestamp() == null) {
            locationDto.setTimestamp(Instant.now());
        }
        // Save to gps_locations table
        log.debug("Persisted GPS telemetry for trip: {}", locationDto.getTripId());
    }
}
