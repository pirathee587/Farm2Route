package com.farm2route.auth.controller;

import com.farm2route.auth.dto.*;
import com.farm2route.auth.service.AuthService;
import com.farm2route.common.response.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
@Tag(name = "Authentication & Authorization", description = "Endpoints for registration, login, OTP verification, token refresh, and logout")
public class AuthController {

    private final AuthService authService;

    @PostMapping("/register")
    @Operation(summary = "Register a new user", description = "Registers a new Farmer, Agency, Driver, or Admin and dispatches verification OTP")
    public ResponseEntity<ApiResponse<AuthResponse>> register(
            @Valid @RequestBody RegisterRequest request,
            HttpServletRequest servletRequest) {
        String clientIp = servletRequest.getRemoteAddr();
        AuthResponse response = authService.register(request, clientIp);
        return new ResponseEntity<>(
                ApiResponse.created(response, "User registered successfully. Verification OTP dispatched.", servletRequest.getRequestURI()),
                HttpStatus.CREATED
        );
    }

    @PostMapping("/verify-otp")
    @Operation(summary = "Verify OTP code", description = "Verifies 6-digit OTP, activates account on registration, and returns JWT tokens")
    public ResponseEntity<ApiResponse<AuthResponse>> verifyOtp(
            @Valid @RequestBody VerifyOtpRequest request,
            HttpServletRequest servletRequest) {
        String clientIp = servletRequest.getRemoteAddr();
        AuthResponse response = authService.verifyOtp(request, clientIp);
        return ResponseEntity.ok(
                ApiResponse.ok(response, "OTP verified successfully. Authentication complete.", servletRequest.getRequestURI())
        );
    }

    @PostMapping("/login")
    @Operation(summary = "User Login", description = "Authenticates using phone/email + password, returning JWT access token and refresh token")
    public ResponseEntity<ApiResponse<AuthResponse>> login(
            @Valid @RequestBody LoginRequest request,
            HttpServletRequest servletRequest) {
        String clientIp = servletRequest.getRemoteAddr();
        AuthResponse response = authService.login(request, clientIp);
        String message = response.isRequiresOtp()
                ? "Account verification required. OTP has been dispatched."
                : "Login successful";
        return ResponseEntity.ok(
                ApiResponse.ok(response, message, servletRequest.getRequestURI())
        );
    }

    @PostMapping("/refresh")
    @Operation(summary = "Refresh Access Token", description = "Rotates refresh token and issues a fresh short-lived JWT access token")
    public ResponseEntity<ApiResponse<AuthResponse>> refreshToken(
            @Valid @RequestBody RefreshTokenRequest request,
            HttpServletRequest servletRequest) {
        String clientIp = servletRequest.getRemoteAddr();
        AuthResponse response = authService.refreshToken(request, clientIp);
        return ResponseEntity.ok(
                ApiResponse.ok(response, "Access token refreshed successfully", servletRequest.getRequestURI())
        );
    }

    @PostMapping("/logout")
    @SecurityRequirement(name = "BearerAuth")
    @Operation(summary = "Logout User", description = "Blacklists JWT access token and revokes active server-side refresh token")
    public ResponseEntity<ApiResponse<Void>> logout(
            @RequestHeader(value = "Authorization", required = false) String authHeader,
            @RequestBody(required = false) RefreshTokenRequest request,
            HttpServletRequest servletRequest) {
        authService.logout(authHeader, request);
        return ResponseEntity.ok(
                ApiResponse.ok(null, "Logged out successfully. Tokens revoked.", servletRequest.getRequestURI())
        );
    }

    @GetMapping("/me")
    @SecurityRequirement(name = "BearerAuth")
    @Operation(summary = "Get Current Authenticated User", description = "Retrieves profile and role details of the current authenticated user")
    public ResponseEntity<ApiResponse<UserResponse>> getMe(
            @AuthenticationPrincipal UserDetails userDetails,
            HttpServletRequest servletRequest) {
        UserResponse response = authService.getMe(userDetails.getUsername());
        return ResponseEntity.ok(
                ApiResponse.ok(response, "Current user retrieved successfully", servletRequest.getRequestURI())
        );
    }
}
