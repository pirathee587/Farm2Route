package com.farm2route.maintenance.controller;

import com.farm2route.common.response.ApiResponse;
import com.farm2route.maintenance.dto.CreateMaintenanceRequest;
import com.farm2route.maintenance.dto.MaintenanceResponse;
import com.farm2route.maintenance.dto.UpdateMaintenanceRequest;
import com.farm2route.maintenance.service.MaintenanceService;
import com.farm2route.security.UserPrincipal;
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
@RequestMapping("/api/v1/agency")
@RequiredArgsConstructor
@Tag(name = "Vehicle Maintenance")
@SecurityRequirement(name = "BearerAuth")
public class MaintenanceController {
    private final MaintenanceService maintenanceService;

    @PostMapping("/vehicles/{vehicleId}/maintenance")
    @PreAuthorize("hasRole('AGENCY')")
    public ResponseEntity<ApiResponse<MaintenanceResponse>> create(
            @AuthenticationPrincipal UserPrincipal principal, @PathVariable UUID vehicleId,
            @Valid @RequestBody CreateMaintenanceRequest body, HttpServletRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.created(
                maintenanceService.create(principal.getId(), vehicleId, body),
                "Maintenance record created successfully", request.getRequestURI()));
    }

    @GetMapping("/vehicles/{vehicleId}/maintenance")
    @PreAuthorize("hasRole('AGENCY')")
    public ResponseEntity<ApiResponse<List<MaintenanceResponse>>> list(
            @AuthenticationPrincipal UserPrincipal principal, @PathVariable UUID vehicleId,
            HttpServletRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(maintenanceService.listForVehicle(principal.getId(), vehicleId),
                "Maintenance records retrieved successfully", request.getRequestURI()));
    }

    @GetMapping("/maintenance/in-progress")
    @PreAuthorize("hasRole('AGENCY')")
    public ResponseEntity<ApiResponse<List<MaintenanceResponse>>> active(
            @AuthenticationPrincipal UserPrincipal principal, HttpServletRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(maintenanceService.listActiveForAgency(principal.getId()),
                "Active maintenance records retrieved successfully", request.getRequestURI()));
    }

    @PutMapping("/maintenance/{maintenanceId}")
    @PreAuthorize("hasRole('AGENCY')")
    public ResponseEntity<ApiResponse<MaintenanceResponse>> update(
            @AuthenticationPrincipal UserPrincipal principal, @PathVariable UUID maintenanceId,
            @Valid @RequestBody UpdateMaintenanceRequest body, HttpServletRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(maintenanceService.update(principal.getId(), maintenanceId, body),
                "Maintenance record updated successfully", request.getRequestURI()));
    }
}
