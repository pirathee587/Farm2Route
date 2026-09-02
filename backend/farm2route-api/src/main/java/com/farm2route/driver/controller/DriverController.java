package com.farm2route.driver.controller;

import com.farm2route.common.enums.DriverAvailability;
import com.farm2route.common.response.ApiResponse;
import com.farm2route.driver.dto.DriverProfileDto;
import com.farm2route.driver.service.DriverService;
import com.farm2route.security.UserPrincipal;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/driver")
@RequiredArgsConstructor
@Tag(name = "Driver Module", description = "Endpoints for drivers, trip execution, POD submissions, and live telemetry")
@SecurityRequirement(name = "BearerAuth")
public class DriverController {

    private final DriverService driverService;

    @GetMapping("/profile")
    @PreAuthorize("hasAnyRole('DRIVER', 'ADMIN')")
    @Operation(summary = "Get Driver Profile", description = "Retrieves profile and driving license details for the authenticated driver")
    public ResponseEntity<ApiResponse<DriverProfileDto>> getProfile(
            @AuthenticationPrincipal UserPrincipal principal,
            HttpServletRequest request) {
        DriverProfileDto dto = driverService.getProfileByUserId(principal.getId());
        return ResponseEntity.ok(ApiResponse.ok(dto, "Driver profile retrieved successfully", request.getRequestURI()));
    }

    @PatchMapping("/availability")
    @PreAuthorize("hasAnyRole('DRIVER', 'ADMIN')")
    @Operation(summary = "Update Driver Availability", description = "Toggles driver availability status (AVAILABLE, ON_TRIP, OFF_DUTY)")
    public ResponseEntity<ApiResponse<DriverProfileDto>> updateAvailability(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam DriverAvailability status,
            HttpServletRequest request) {
        DriverProfileDto updated = driverService.updateAvailability(principal.getId(), status);
        return ResponseEntity.ok(ApiResponse.ok(updated, "Driver availability updated to " + status, request.getRequestURI()));
    }
}
