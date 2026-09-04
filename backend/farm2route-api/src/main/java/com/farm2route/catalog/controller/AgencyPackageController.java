package com.farm2route.catalog.controller;

import com.farm2route.catalog.dto.CreatePackageRequest;
import com.farm2route.catalog.dto.PackageResponse;
import com.farm2route.catalog.dto.UpdatePackageRequest;
import com.farm2route.catalog.service.PackageService;
import com.farm2route.common.response.ApiResponse;
import com.farm2route.security.UserPrincipal;
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
@RequestMapping("/api/v1/agency/packages")
@RequiredArgsConstructor
@Tag(name = "Agency Package Management", description = "Agency endpoints for managing transport service packages and pricing")
@SecurityRequirement(name = "BearerAuth")
public class AgencyPackageController {

    private final PackageService packageService;

    @PostMapping
    @PreAuthorize("hasAnyRole('AGENCY', 'ADMIN')")
    @Operation(summary = "Create Package", description = "Creates a new transport service package under the authenticated agency")
    public ResponseEntity<ApiResponse<PackageResponse>> createPackage(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody CreatePackageRequest requestBody,
            HttpServletRequest request) {
        PackageResponse dto = packageService.createPackage(principal.getId(), requestBody);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.created(dto, "Package created successfully", request.getRequestURI()));
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('AGENCY', 'ADMIN')")
    @Operation(summary = "Get Agency Packages", description = "Retrieves all transport packages belonging to the authenticated agency")
    public ResponseEntity<ApiResponse<List<PackageResponse>>> getAgencyPackages(
            @AuthenticationPrincipal UserPrincipal principal,
            HttpServletRequest request) {
        List<PackageResponse> packages = packageService.getAgencyPackages(principal.getId());
        return ResponseEntity.ok(ApiResponse.ok(packages, "Agency packages retrieved successfully", request.getRequestURI()));
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('AGENCY', 'ADMIN')")
    @Operation(summary = "Get Package by ID", description = "Retrieves details of a specific package owned by the authenticated agency")
    public ResponseEntity<ApiResponse<PackageResponse>> getPackageById(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID id,
            HttpServletRequest request) {
        PackageResponse dto = packageService.getAgencyPackageById(id, principal.getId());
        return ResponseEntity.ok(ApiResponse.ok(dto, "Package details retrieved successfully", request.getRequestURI()));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('AGENCY', 'ADMIN')")
    @Operation(summary = "Update Package", description = "Updates details of an existing transport package owned by the authenticated agency")
    public ResponseEntity<ApiResponse<PackageResponse>> updatePackage(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID id,
            @Valid @RequestBody UpdatePackageRequest requestBody,
            HttpServletRequest request) {
        PackageResponse dto = packageService.updatePackage(id, principal.getId(), requestBody);
        return ResponseEntity.ok(ApiResponse.ok(dto, "Package updated successfully", request.getRequestURI()));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('AGENCY', 'ADMIN')")
    @Operation(summary = "Delete Package", description = "Removes a transport package from the authenticated agency")
    public ResponseEntity<ApiResponse<Void>> deletePackage(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID id,
            HttpServletRequest request) {
        packageService.deletePackage(id, principal.getId());
        return ResponseEntity.ok(ApiResponse.ok(null, "Package deleted successfully", request.getRequestURI()));
    }
}
