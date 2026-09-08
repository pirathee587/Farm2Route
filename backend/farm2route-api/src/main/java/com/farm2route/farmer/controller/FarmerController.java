package com.farm2route.farmer.controller;

import com.farm2route.common.response.ApiResponse;
import com.farm2route.farmer.dto.*;
import com.farm2route.farmer.service.FarmerService;
import com.farm2route.security.CustomUserPrincipal;
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

import java.util.UUID;

@RestController
@RequestMapping({"/api/v1/farmer", "/api/v1/farmers"})
@RequiredArgsConstructor
@Tag(name = "Farmer Module", description = "Endpoints for farmer signup, profiles, discovery, bookings, and operations")
@SecurityRequirement(name = "BearerAuth")
public class FarmerController {

    private final FarmerService farmerService;

    @PostMapping("/signup/request-otp")
    @Operation(summary = "Request Signup OTP", description = "Generates and sends a 6-digit OTP code to the farmer's mobile number", security = {})
    public ResponseEntity<ApiResponse<FarmerOtpResponse>> requestOtp(
            @Valid @RequestBody FarmerOtpRequest request,
            HttpServletRequest servletRequest) {
        FarmerOtpResponse response = farmerService.requestOtp(request);
        return ResponseEntity.ok(
                ApiResponse.ok(response, "OTP sent successfully", servletRequest.getRequestURI())
        );
    }

    @PostMapping("/signup/verify")
    @Operation(summary = "Verify OTP and Complete Farmer Signup", description = "Verifies the submitted OTP and registers a new farmer account, returning a JWT token for immediate login", security = {})
    public ResponseEntity<ApiResponse<FarmerResponse>> verifySignup(
            @Valid @RequestBody FarmerVerifyRequest request,
            HttpServletRequest servletRequest) {
        FarmerResponse response = farmerService.verifyAndSignup(request);
        return new ResponseEntity<>(
                ApiResponse.created(response, "Farmer registered successfully", servletRequest.getRequestURI()),
                HttpStatus.CREATED
        );
    }

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
        if (principal instanceof CustomUserPrincipal cup) {
            return cup.getId();
        } else if (principal instanceof UserPrincipal up) {
            return up.getId();
        }
        throw new com.farm2route.common.exception.UnauthorizedException("Unable to extract user ID from principal");
    }
}
