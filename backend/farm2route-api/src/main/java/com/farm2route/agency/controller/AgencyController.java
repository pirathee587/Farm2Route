package com.farm2route.agency.controller;

import com.farm2route.agency.dto.*;
import com.farm2route.agency.service.AgencyService;
import com.farm2route.common.response.ApiResponse;
import com.farm2route.security.UserPrincipal;
import io.swagger.v3.oas.annotations.Operation;
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
@RequestMapping({"/api/v1/agency", "/api/v1/agencies"})
@RequiredArgsConstructor
@Tag(name = "Agency Module", description = "Endpoints for logistics agencies, fleet management, and driver assignments")
public class AgencyController {

    private final AgencyService agencyService;

    @PostMapping("/signup")
    @Operation(summary = "Register Logistics Agency", description = "Registers a new logistics agency with account credentials and profile", security = {})
    public ResponseEntity<ApiResponse<AgencyResponse>> signup(
            @Valid @RequestBody AgencySignupRequest request,
            HttpServletRequest servletRequest) {
        AgencyResponse response = agencyService.signup(request);
        return new ResponseEntity<>(
                ApiResponse.created(response, "Agency registered successfully. Verification required.", servletRequest.getRequestURI()),
                HttpStatus.CREATED
        );
    }

    @PostMapping("/verify-email")
    @Operation(summary = "Verify Agency Email", description = "Verifies agency email address using link/token", security = {})
    public ResponseEntity<ApiResponse<AgencyStatusResponse>> verifyEmail(
            @Valid @RequestBody VerifyEmailRequest request,
            HttpServletRequest servletRequest) {
        AgencyStatusResponse statusResponse = agencyService.verifyEmail(request.getAgencyId(), request.getEmailToken());
        return ResponseEntity.ok(
                ApiResponse.ok(statusResponse, "Email verified successfully", servletRequest.getRequestURI())
        );
    }

    @PostMapping("/verify-phone")
    @Operation(summary = "Verify Agency Phone", description = "Verifies agency phone number using OTP code", security = {})
    public ResponseEntity<ApiResponse<AgencyStatusResponse>> verifyPhone(
            @Valid @RequestBody VerifyPhoneRequest request,
            HttpServletRequest servletRequest) {
        AgencyStatusResponse statusResponse = agencyService.verifyPhone(request.getAgencyId(), request.getOtp());
        return ResponseEntity.ok(
                ApiResponse.ok(statusResponse, "Phone verified successfully", servletRequest.getRequestURI())
        );
    }

    @PostMapping("/{id}/resend-email")
    @Operation(summary = "Resend Verification Email", description = "Resends email verification link to the agency", security = {})
    public ResponseEntity<ApiResponse<Void>> resendEmail(
            @PathVariable UUID id,
            HttpServletRequest servletRequest) {
        agencyService.resendEmail(id);
        return ResponseEntity.ok(
                ApiResponse.ok(null, "Verification email resent successfully", servletRequest.getRequestURI())
        );
    }

    @PostMapping("/{id}/resend-otp")
    @Operation(summary = "Resend Verification OTP", description = "Resends phone verification OTP SMS to the agency", security = {})
    public ResponseEntity<ApiResponse<Void>> resendPhoneOtp(
            @PathVariable UUID id,
            HttpServletRequest servletRequest) {
        agencyService.resendPhoneOtp(id);
        return ResponseEntity.ok(
                ApiResponse.ok(null, "Phone verification OTP resent successfully", servletRequest.getRequestURI())
        );
    }

    @GetMapping("/{id}/status")
    @Operation(summary = "Get Agency Verification Status", description = "Returns current email/phone verification status of an agency", security = {})
    public ResponseEntity<ApiResponse<AgencyStatusResponse>> getAgencyStatus(
            @PathVariable UUID id,
            HttpServletRequest servletRequest) {
        AgencyStatusResponse statusResponse = agencyService.getAgencyStatus(id);
        return ResponseEntity.ok(
                ApiResponse.ok(statusResponse, "Agency status retrieved", servletRequest.getRequestURI())
        );
    }

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
