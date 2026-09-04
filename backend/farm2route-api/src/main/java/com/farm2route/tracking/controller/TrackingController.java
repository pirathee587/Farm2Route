package com.farm2route.tracking.controller;

import com.farm2route.common.response.ApiResponse;
import com.farm2route.security.CustomUserPrincipal;
import com.farm2route.security.UserPrincipal;
import com.farm2route.tracking.dto.GpsLocationDto;
import com.farm2route.tracking.dto.TripLocationResponse;
import com.farm2route.tracking.service.TrackingService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/api/v1/tracking")
@RequiredArgsConstructor
public class TrackingController {

    private final TrackingService trackingService;

    @GetMapping("/{tripId}/latest")
    public ResponseEntity<ApiResponse<TripLocationResponse>> getLatestLocation(
            @PathVariable UUID tripId,
            @AuthenticationPrincipal Object principal) {

        UUID userId = extractUserId(principal);
        String role = extractRole(principal);

        TripLocationResponse response = trackingService.getLatestLocation(tripId, userId, role);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @GetMapping("/{tripId}/history")
    public ResponseEntity<ApiResponse<List<GpsLocationDto>>> getRouteHistory(
            @PathVariable UUID tripId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant to,
            @AuthenticationPrincipal Object principal) {

        UUID userId = extractUserId(principal);
        String role = extractRole(principal);

        List<GpsLocationDto> history = trackingService.getRouteHistory(tripId, from, to, userId, role);
        return ResponseEntity.ok(ApiResponse.success(history));
    }

    private UUID extractUserId(Object principal) {
        if (principal instanceof UserPrincipal up) {
            return up.getId();
        } else if (principal instanceof CustomUserPrincipal cup) {
            return cup.getId();
        }
        return null;
    }

    private String extractRole(Object principal) {
        if (principal instanceof UserPrincipal up) {
            return up.getRole() != null ? up.getRole().name() : null;
        } else if (principal instanceof CustomUserPrincipal cup) {
            return cup.getAuthorities().stream()
                    .findFirst()
                    .map(a -> a.getAuthority())
                    .orElse(null);
        }
        return null;
    }
}
