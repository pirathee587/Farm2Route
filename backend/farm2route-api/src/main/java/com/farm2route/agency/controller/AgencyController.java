package com.farm2route.agency.controller;

import com.farm2route.agency.dto.AgencyProfileDto;
import com.farm2route.agency.service.AgencyService;
import com.farm2route.common.response.ApiResponse;
import com.farm2route.security.UserPrincipal;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/agency")
@RequiredArgsConstructor
@Tag(name = "Agency Module", description = "Endpoints for logistics agencies, fleet management, and driver assignments")
@SecurityRequirement(name = "BearerAuth")
public class AgencyController {

    private final AgencyService agencyService;

    @GetMapping("/profile")
    @PreAuthorize("hasAnyRole('AGENCY', 'ADMIN')")
    @Operation(summary = "Get Agency Profile", description = "Retrieves company profile details for the authenticated agency")
    public ResponseEntity<ApiResponse<AgencyProfileDto>> getProfile(
            @AuthenticationPrincipal UserPrincipal principal,
            HttpServletRequest request) {
        AgencyProfileDto dto = agencyService.getProfileByUserId(principal.getId());
        return ResponseEntity.ok(ApiResponse.ok(dto, "Agency profile retrieved successfully", request.getRequestURI()));
    }

    @PutMapping("/profile")
    @PreAuthorize("hasAnyRole('AGENCY', 'ADMIN')")
    @Operation(summary = "Update Agency Profile", description = "Updates business registration, KYC docs, and profile details")
    public ResponseEntity<ApiResponse<AgencyProfileDto>> updateProfile(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody AgencyProfileDto dto,
            HttpServletRequest request) {
        AgencyProfileDto updated = agencyService.updateProfile(principal.getId(), dto);
        return ResponseEntity.ok(ApiResponse.ok(updated, "Agency profile updated successfully", request.getRequestURI()));
    }
}
