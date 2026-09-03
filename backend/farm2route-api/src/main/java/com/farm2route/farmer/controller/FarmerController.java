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

import java.util.UUID;

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
            @AuthenticationPrincipal Object principal,
            HttpServletRequest request) {
        UUID userId = extractUserId(principal);
        FarmerProfileDto dto = farmerService.getProfileByUserId(userId);
        return ResponseEntity.ok(ApiResponse.ok(dto, "Farmer profile retrieved successfully", request.getRequestURI()));
    }

    @PutMapping("/profile")
    @PreAuthorize("hasAnyRole('FARMER', 'ADMIN')")
    @Operation(summary = "Update Farmer Profile", description = "Updates or creates profile details for the authenticated farmer")
    public ResponseEntity<ApiResponse<FarmerProfileDto>> updateProfile(
            @AuthenticationPrincipal Object principal,
            @Valid @RequestBody FarmerProfileDto dto,
            HttpServletRequest request) {
        UUID userId = extractUserId(principal);
        FarmerProfileDto updated = farmerService.updateProfile(userId, dto);
        return ResponseEntity.ok(ApiResponse.ok(updated, "Farmer profile updated successfully", request.getRequestURI()));
    }

    private UUID extractUserId(Object principal) {
        if (principal instanceof com.farm2route.security.CustomUserPrincipal cup) {
            return cup.getId();
        } else if (principal instanceof com.farm2route.security.UserPrincipal up) {
            return up.getId();
        }
        throw new com.farm2route.common.exception.UnauthorizedException("Unable to extract user ID from principal");
    }
}
