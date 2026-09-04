package com.farm2route.driver.controller;

import com.farm2route.common.enums.DriverAvailability;
import com.farm2route.common.response.ApiResponse;
import com.farm2route.driver.dto.DriverProfileDto;
import com.farm2route.driver.dto.RegisterDriverRequest;
import com.farm2route.driver.dto.UpdateDriverKycRequest;
import com.farm2route.driver.dto.UpdateDriverRequest;
import com.farm2route.driver.service.DriverService;
import com.farm2route.security.UserPrincipal;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping
@RequiredArgsConstructor
@Tag(name = "Driver Module", description = "Endpoints for drivers, agency driver management, trip execution, POD submissions, and live telemetry")
@SecurityRequirement(name = "BearerAuth")
public class DriverController {

    private final DriverService driverService;

    // ─────────────────────────────────────────────────────────────────────────
    // Driver Self Endpoints
    // ─────────────────────────────────────────────────────────────────────────

    @GetMapping("/api/v1/driver/profile")
    @PreAuthorize("hasAnyRole('DRIVER', 'ADMIN')")
    @Operation(summary = "Get Driver Profile", description = "Retrieves profile and driving license details for the authenticated driver")
    public ResponseEntity<ApiResponse<DriverProfileDto>> getProfile(
            @AuthenticationPrincipal UserPrincipal principal,
            HttpServletRequest request) {
        DriverProfileDto dto = driverService.getProfileByUserId(principal.getId());
        return ResponseEntity.ok(ApiResponse.ok(dto, "Driver profile retrieved successfully", request.getRequestURI()));
    }

    @PatchMapping("/api/v1/driver/availability")
    @PreAuthorize("hasAnyRole('DRIVER', 'ADMIN')")
    @Operation(summary = "Update Driver Availability", description = "Toggles driver availability status (AVAILABLE, ON_TRIP, OFF_DUTY)")
    public ResponseEntity<ApiResponse<DriverProfileDto>> updateAvailability(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam DriverAvailability status,
            HttpServletRequest request) {
        DriverProfileDto updated = driverService.updateAvailability(principal.getId(), status);
        return ResponseEntity.ok(ApiResponse.ok(updated, "Driver availability updated to " + status, request.getRequestURI()));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Agency Driver Management Endpoints
    // ─────────────────────────────────────────────────────────────────────────

    @PostMapping({"/api/v1/agency/drivers", "/api/v1/driver/agency"})
    @PreAuthorize("hasAnyRole('AGENCY', 'ADMIN')")
    @Operation(summary = "Register Driver", description = "Registers a new driver under the authenticated agency")
    public ResponseEntity<ApiResponse<DriverProfileDto>> registerDriver(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody RegisterDriverRequest requestBody,
            HttpServletRequest request) {
        DriverProfileDto dto = driverService.registerDriver(principal.getId(), requestBody);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.created(dto, "Driver registered successfully", request.getRequestURI()));
    }

    @GetMapping({"/api/v1/agency/drivers", "/api/v1/driver/agency"})
    @PreAuthorize("hasAnyRole('AGENCY', 'ADMIN')")
    @Operation(summary = "Get Agency Drivers", description = "Retrieves all drivers belonging to the authenticated agency")
    public ResponseEntity<ApiResponse<List<DriverProfileDto>>> getAgencyDrivers(
            @AuthenticationPrincipal UserPrincipal principal,
            HttpServletRequest request) {
        List<DriverProfileDto> drivers = driverService.getAgencyDrivers(principal.getId());
        return ResponseEntity.ok(ApiResponse.ok(drivers, "Agency drivers retrieved successfully", request.getRequestURI()));
    }

    @GetMapping({"/api/v1/agency/drivers/available", "/api/v1/driver/agency/available"})
    @PreAuthorize("hasAnyRole('AGENCY', 'ADMIN')")
    @Operation(summary = "Get Available Agency Drivers", description = "Retrieves available drivers belonging to the authenticated agency")
    public ResponseEntity<ApiResponse<List<DriverProfileDto>>> getAvailableAgencyDrivers(
            @AuthenticationPrincipal UserPrincipal principal,
            HttpServletRequest request) {
        List<DriverProfileDto> drivers = driverService.getAvailableAgencyDrivers(principal.getId());
        return ResponseEntity.ok(ApiResponse.ok(drivers, "Available agency drivers retrieved successfully", request.getRequestURI()));
    }

    @GetMapping({"/api/v1/agency/drivers/{id}", "/api/v1/driver/agency/{id}"})
    @PreAuthorize("hasAnyRole('AGENCY', 'ADMIN')")
    @Operation(summary = "Get Driver by ID", description = "Retrieves details of a specific driver owned by the authenticated agency")
    public ResponseEntity<ApiResponse<DriverProfileDto>> getDriverById(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID id,
            HttpServletRequest request) {
        DriverProfileDto dto = driverService.getDriverById(id, principal.getId());
        return ResponseEntity.ok(ApiResponse.ok(dto, "Driver details retrieved successfully", request.getRequestURI()));
    }

    @PutMapping({"/api/v1/agency/drivers/{id}", "/api/v1/driver/agency/{id}"})
    @PreAuthorize("hasAnyRole('AGENCY', 'ADMIN')")
    @Operation(summary = "Update Driver", description = "Updates details of an existing driver owned by the authenticated agency")
    public ResponseEntity<ApiResponse<DriverProfileDto>> updateDriver(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID id,
            @Valid @RequestBody UpdateDriverRequest requestBody,
            HttpServletRequest request) {
        DriverProfileDto dto = driverService.updateDriver(id, principal.getId(), requestBody);
        return ResponseEntity.ok(ApiResponse.ok(dto, "Driver updated successfully", request.getRequestURI()));
    }

    @DeleteMapping({"/api/v1/agency/drivers/{id}", "/api/v1/driver/agency/{id}"})
    @PreAuthorize("hasAnyRole('AGENCY', 'ADMIN')")
    @Operation(summary = "Delete Driver", description = "Removes a driver from the authenticated agency")
    public ResponseEntity<ApiResponse<Void>> deleteDriver(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID id,
            HttpServletRequest request) {
        driverService.deleteDriver(id, principal.getId());
        return ResponseEntity.ok(ApiResponse.ok(null, "Driver deleted successfully", request.getRequestURI()));
    }

    @PatchMapping({"/api/v1/agency/drivers/{id}/kyc", "/api/v1/driver/agency/{id}/kyc"})
    @PreAuthorize("hasAnyRole('AGENCY', 'ADMIN')")
    @Operation(summary = "Update Driver KYC", description = "Submits or updates KYC review status for a driver")
    public ResponseEntity<ApiResponse<DriverProfileDto>> updateDriverKyc(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID id,
            @Valid @RequestBody UpdateDriverKycRequest requestBody,
            HttpServletRequest request) {
        DriverProfileDto dto = driverService.updateDriverKyc(id, principal.getId(), requestBody);
        return ResponseEntity.ok(ApiResponse.ok(dto, "Driver KYC status updated successfully", request.getRequestURI()));
    }

    @PostMapping(value = {"/api/v1/agency/drivers/{id}/kyc/document", "/api/v1/driver/agency/{id}/kyc/document"}, consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasAnyRole('AGENCY', 'ADMIN')")
    @Operation(summary = "Upload Driver KYC Document", description = "Uploads a KYC document for a driver")
    public ResponseEntity<ApiResponse<DriverProfileDto>> uploadDriverKycDocument(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID id,
            @RequestParam("file") MultipartFile file,
            HttpServletRequest request) throws IOException {
        DriverProfileDto dto = driverService.uploadDriverKycDocument(id, principal.getId(), file);
        return ResponseEntity.ok(ApiResponse.ok(dto, "Driver KYC document uploaded successfully", request.getRequestURI()));
    }
}
