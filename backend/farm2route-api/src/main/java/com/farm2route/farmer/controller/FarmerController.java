package com.farm2route.farmer.controller;

import com.farm2route.common.response.ApiResponse;
import com.farm2route.farmer.dto.FarmerProfileDto;
import com.farm2route.farmer.service.FarmerService;
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
@RequestMapping("/api/v1/farmer")
@RequiredArgsConstructor
@Tag(name = "Farmer Module", description = "Endpoints for farmer profiles, discovery, bookings, and operations")
@SecurityRequirement(name = "BearerAuth")
public class FarmerController {

    private final FarmerService farmerService;

    @GetMapping("/profile")
    @PreAuthorize("hasAnyRole('FARMER', 'ADMIN')")
    @Operation(summary = "Get Farmer Profile", description = "Retrieves profile information for the authenticated farmer")
    public ResponseEntity<ApiResponse<FarmerProfileDto>> getProfile(
            @AuthenticationPrincipal UserPrincipal principal,
            HttpServletRequest request) {
        FarmerProfileDto dto = farmerService.getProfileByUserId(principal.getId());
        return ResponseEntity.ok(ApiResponse.ok(dto, "Farmer profile retrieved successfully", request.getRequestURI()));
    }

    @PutMapping("/profile")
    @PreAuthorize("hasAnyRole('FARMER', 'ADMIN')")
    @Operation(summary = "Update Farmer Profile", description = "Updates or creates profile details for the authenticated farmer")
    public ResponseEntity<ApiResponse<FarmerProfileDto>> updateProfile(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody FarmerProfileDto dto,
            HttpServletRequest request) {
        FarmerProfileDto updated = farmerService.updateProfile(principal.getId(), dto);
        return ResponseEntity.ok(ApiResponse.ok(updated, "Farmer profile updated successfully", request.getRequestURI()));
    }
}
