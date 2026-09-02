package com.farm2route.auth.controller;

import com.farm2route.auth.dto.*;
import com.farm2route.auth.service.AuthService;
import com.farm2route.auth.service.PasswordResetService;
import com.farm2route.common.response.ApiResponse;
import com.farm2route.security.CustomUserPrincipal;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
@Tag(name = "Authentication", description = "Endpoints for registration, login, OTP verification, password reset, and token rotation")
public class AuthController {

    private final AuthService authService;
    private final PasswordResetService passwordResetService;

    @PostMapping("/register")
    @Operation(summary = "Register new user account", description = "Creates a new farmer, agency, or driver user and dispatches an OTP")
    public ResponseEntity<ApiResponse<AuthResponse>> register(
            @Valid @RequestBody RegisterRequest request,
            HttpServletRequest httpRequest) {
        String clientIp = extractClientIp(httpRequest);
        AuthResponse response = authService.register(request, clientIp);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(response.getMessage(), response));
    }

    @PostMapping("/verify-otp")
    @Operation(summary = "Verify OTP code", description = "Verifies 6-digit OTP, activates user account and issues JWT + Refresh tokens")
    public ResponseEntity<ApiResponse<AuthResponse>> verifyOtp(
            @Valid @RequestBody VerifyOtpRequest request,
            HttpServletRequest httpRequest) {
        String clientIp = extractClientIp(httpRequest);
        String userAgent = httpRequest.getHeader("User-Agent");
        AuthResponse response = authService.verifyOtp(request, clientIp, userAgent);
        return ResponseEntity.ok(ApiResponse.success(response.getMessage(), response));
    }

    @PostMapping("/login")
    @Operation(summary = "Authenticate user with password", description = "Authenticates user and returns JWT + Refresh tokens")
    public ResponseEntity<ApiResponse<AuthResponse>> login(
            @Valid @RequestBody LoginRequest request,
            HttpServletRequest httpRequest) {
        String clientIp = extractClientIp(httpRequest);
        String userAgent = httpRequest.getHeader("User-Agent");
        AuthResponse response = authService.login(request, clientIp, userAgent);
        return ResponseEntity.ok(ApiResponse.success(response.getMessage(), response));
    }

    @PostMapping("/refresh")
    @Operation(summary = "Rotate refresh token", description = "Exchanges a valid refresh token for a newly rotated refresh token and short-lived access JWT")
    public ResponseEntity<ApiResponse<AuthResponse>> refresh(
            @Valid @RequestBody RefreshTokenRequest request,
            HttpServletRequest httpRequest) {
        String clientIp = extractClientIp(httpRequest);
        String userAgent = httpRequest.getHeader("User-Agent");
        AuthResponse response = authService.refresh(request, clientIp, userAgent);
        return ResponseEntity.ok(ApiResponse.success(response.getMessage(), response));
    }

    @PostMapping("/logout")
    @Operation(summary = "Logout user", description = "Revokes refresh token and blacklists current access JWT in Redis", security = @SecurityRequirement(name = "BearerAuth"))
    public ResponseEntity<ApiResponse<Void>> logout(
            @RequestHeader(value = "Authorization", required = false) String authHeader,
            @RequestBody(required = false) LogoutRequest request,
            HttpServletRequest httpRequest) {
        String clientIp = extractClientIp(httpRequest);
        authService.logout(authHeader, request, clientIp);
        return ResponseEntity.ok(ApiResponse.success("Logged out successfully.", null));
    }

    @GetMapping("/me")
    @Operation(summary = "Get current authenticated user profile", description = "Returns details of the currently authenticated user identity", security = @SecurityRequirement(name = "BearerAuth"))
    public ResponseEntity<ApiResponse<UserResponse>> getCurrentUser(
            @AuthenticationPrincipal CustomUserPrincipal principal) {
        UserResponse response = authService.getCurrentUser(principal.getId());
        return ResponseEntity.ok(ApiResponse.success("Current user profile retrieved.", response));
    }

    @PostMapping("/forgot-password")
    @Operation(summary = "Request password reset OTP", description = "Generates and dispatches a password reset OTP. Protects against account enumeration with generic response.")
    public ResponseEntity<ApiResponse<String>> forgotPassword(
            @Valid @RequestBody ForgotPasswordRequest request,
            HttpServletRequest httpRequest) {
        String clientIp = extractClientIp(httpRequest);
        String message = passwordResetService.forgotPassword(request, clientIp);
        return ResponseEntity.ok(ApiResponse.success(message, null));
    }

    @PostMapping("/verify-password-reset-otp")
    @Operation(summary = "Verify password reset OTP", description = "Verifies password reset OTP and issues a dedicated short-lived password reset token.")
    public ResponseEntity<ApiResponse<VerifyPasswordResetOtpResponse>> verifyPasswordResetOtp(
            @Valid @RequestBody VerifyPasswordResetOtpRequest request,
            HttpServletRequest httpRequest) {
        String clientIp = extractClientIp(httpRequest);
        VerifyPasswordResetOtpResponse response = passwordResetService.verifyPasswordResetOtp(request, clientIp);
        return ResponseEntity.ok(ApiResponse.success(response.getMessage(), response));
    }

    @PostMapping("/reset-password")
    @Operation(summary = "Reset password", description = "Resets user password using single-use reset token and revokes all active user sessions across all devices.")
    public ResponseEntity<ApiResponse<String>> resetPassword(
            @Valid @RequestBody ResetPasswordRequest request,
            HttpServletRequest httpRequest) {
        String clientIp = extractClientIp(httpRequest);
        String message = passwordResetService.resetPassword(request, clientIp);
        return ResponseEntity.ok(ApiResponse.success(message, null));
    }

    private String extractClientIp(HttpServletRequest request) {
        String xf = request.getHeader("X-Forwarded-For");
        if (xf != null && !xf.isBlank()) {
            return xf.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}
