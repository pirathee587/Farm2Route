package com.farm2route.vehicle.controller;

import com.farm2route.common.enums.KycStatus;
import com.farm2route.common.response.ApiResponse;
import com.farm2route.security.UserPrincipal;
import com.farm2route.vehicle.dto.CreateVehicleRequest;
import com.farm2route.vehicle.dto.UpdateVehicleKycRequest;
import com.farm2route.vehicle.dto.UpdateVehicleRequest;
import com.farm2route.vehicle.dto.VehicleDto;
import com.farm2route.vehicle.service.VehicleService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/agency/vehicles")
@RequiredArgsConstructor
@Tag(name = "Agency Vehicle Management", description = "Agency endpoints for managing fleet vehicles and KYC status")
@SecurityRequirement(name = "BearerAuth")
public class AgencyVehicleController {

    private final VehicleService vehicleService;

    @PostMapping
    @PreAuthorize("hasAnyRole('AGENCY', 'ADMIN')")
    @Operation(summary = "Create Vehicle", description = "Registers a new vehicle under the authenticated agency's fleet")
    public ResponseEntity<ApiResponse<VehicleDto>> createVehicle(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody CreateVehicleRequest requestBody,
            HttpServletRequest request) {
        VehicleDto dto = vehicleService.createVehicle(principal.getId(), requestBody);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(dto, "Vehicle registered successfully", request.getRequestURI()));
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('AGENCY', 'ADMIN')")
    @Operation(summary = "Get Agency Fleet Vehicles", description = "Retrieves all vehicles belonging to the authenticated agency")
    public ResponseEntity<ApiResponse<List<VehicleDto>>> getAgencyVehicles(
            @AuthenticationPrincipal UserPrincipal principal,
            HttpServletRequest request) {
        List<VehicleDto> vehicles = vehicleService.getAgencyVehicles(principal.getId());
        return ResponseEntity.ok(ApiResponse.ok(vehicles, "Agency vehicles retrieved successfully", request.getRequestURI()));
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('AGENCY', 'ADMIN')")
    @Operation(summary = "Get Vehicle by ID", description = "Retrieves details of a specific vehicle owned by the authenticated agency")
    public ResponseEntity<ApiResponse<VehicleDto>> getVehicleById(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID id,
            HttpServletRequest request) {
        VehicleDto dto = vehicleService.getVehicleById(id, principal.getId());
        return ResponseEntity.ok(ApiResponse.ok(dto, "Vehicle details retrieved successfully", request.getRequestURI()));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('AGENCY', 'ADMIN')")
    @Operation(summary = "Update Vehicle", description = "Updates details of an existing vehicle owned by the authenticated agency")
    public ResponseEntity<ApiResponse<VehicleDto>> updateVehicle(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID id,
            @Valid @RequestBody UpdateVehicleRequest requestBody,
            HttpServletRequest request) {
        VehicleDto dto = vehicleService.updateVehicle(id, principal.getId(), requestBody);
        return ResponseEntity.ok(ApiResponse.ok(dto, "Vehicle updated successfully", request.getRequestURI()));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('AGENCY', 'ADMIN')")
    @Operation(summary = "Delete Vehicle", description = "Removes a vehicle from the authenticated agency's fleet")
    public ResponseEntity<ApiResponse<Void>> deleteVehicle(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID id,
            HttpServletRequest request) {
        vehicleService.deleteVehicle(id, principal.getId());
        return ResponseEntity.ok(ApiResponse.ok(null, "Vehicle deleted successfully", request.getRequestURI()));
    }

    @PatchMapping("/{id}/kyc")
    @PreAuthorize("hasAnyRole('AGENCY', 'ADMIN')")
    @Operation(summary = "Update Vehicle KYC", description = "Submits or updates KYC review status for a vehicle")
    public ResponseEntity<ApiResponse<VehicleDto>> updateVehicleKyc(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID id,
            @Valid @RequestBody UpdateVehicleKycRequest requestBody,
            HttpServletRequest request) {
        VehicleDto dto = vehicleService.updateVehicleKyc(id, principal.getId(), requestBody);
        return ResponseEntity.ok(ApiResponse.ok(dto, "Vehicle KYC status updated successfully", request.getRequestURI()));
    }

    @GetMapping("/{id}/kyc")
    @PreAuthorize("hasAnyRole('AGENCY', 'ADMIN')")
    @Operation(summary = "Read Vehicle KYC Status", description = "Retrieves current KYC verification status for a vehicle")
    public ResponseEntity<ApiResponse<KycStatus>> getVehicleKycStatus(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID id,
            HttpServletRequest request) {
        VehicleDto dto = vehicleService.getVehicleById(id, principal.getId());
        return ResponseEntity.ok(ApiResponse.ok(dto.getKycStatus(), "Vehicle KYC status retrieved successfully", request.getRequestURI()));
    }
}

