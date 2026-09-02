package com.farm2route.auth.service;

import com.farm2route.auth.dto.ForgotPasswordRequest;
import com.farm2route.auth.dto.ResetPasswordRequest;
import com.farm2route.auth.dto.VerifyPasswordResetOtpRequest;
import com.farm2route.auth.dto.VerifyPasswordResetOtpResponse;
import com.farm2route.auth.entity.User;
import com.farm2route.auth.model.OtpPurpose;
import com.farm2route.auth.model.UserStatus;
import com.farm2route.auth.repository.UserRepository;
import com.farm2route.common.exception.AuthenticationException;
import com.farm2route.common.exception.ResourceNotFoundException;
import com.farm2route.security.JwtService;
import com.farm2route.security.TokenBlacklistService;
import io.jsonwebtoken.Claims;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Date;
import java.util.Optional;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class PasswordResetService {

    private final UserRepository userRepository;
    private final OtpService otpService;
    private final JwtService jwtService;
    private final PasswordService passwordService;
    private final RefreshTokenService refreshTokenService;
    private final TokenBlacklistService tokenBlacklistService;
    private final PasswordResetRateLimitService rateLimitService;
    private final AuthenticationAuditService auditService;

    public static final String GENERIC_FORGOT_PASSWORD_RESPONSE =
            "If an account exists, a password reset code has been sent.";

    @Transactional
    public String forgotPassword(ForgotPasswordRequest request, String clientIp) {
        // Distributed rate limit check
        rateLimitService.checkAndIncrement(clientIp, request.getPhoneNumber());

        Optional<User> userOpt = userRepository.findByPhoneNumber(request.getPhoneNumber());

        if (userOpt.isPresent()) {
            User user = userOpt.get();
            otpService.generateAndSendOtp(user.getPhoneNumber(), OtpPurpose.PASSWORD_RESET, user.getId());
            auditService.logPasswordResetRequested(user.getPhoneNumber(), clientIp);
            auditService.logOtpRequested(user.getPhoneNumber(), OtpPurpose.PASSWORD_RESET.name(), clientIp);
        } else {
            // Anti-enumeration protection: do not reveal user absence
            log.debug("Password reset requested for unregistered phone: {}", request.getPhoneNumber());
        }

        return GENERIC_FORGOT_PASSWORD_RESPONSE;
    }

    @Transactional
    public VerifyPasswordResetOtpResponse verifyPasswordResetOtp(
            VerifyPasswordResetOtpRequest request, String clientIp) {
        // Timing-safe OTP verification
        otpService.verifyOtp(request.getPhoneNumber(), request.getOtp(), OtpPurpose.PASSWORD_RESET);

        User user = userRepository.findByPhoneNumber(request.getPhoneNumber())
                .orElseThrow(() -> new ResourceNotFoundException("User not found for phone: " + request.getPhoneNumber()));

        String resetToken = jwtService.generatePasswordResetToken(user);

        auditService.logPasswordResetOtpVerified(user.getId(), user.getPhoneNumber(), clientIp);

        return VerifyPasswordResetOtpResponse.builder()
                .resetToken(resetToken)
                .tokenType("Bearer")
                .expiresIn(600L) // 10 minutes
                .message("OTP verified successfully. You may now reset your password.")
                .build();
    }

    @Transactional
    public String resetPassword(ResetPasswordRequest request, String clientIp) {
        // Validate password reset token
        Claims claims = jwtService.validatePasswordResetToken(request.getResetToken());
        String userIdStr = claims.getSubject();
        String jti = claims.getId();
        Date expiration = claims.getExpiration();

        UUID userId = UUID.fromString(userIdStr);

        // Mark reset token as used (single-use replay protection)
        long remainingSeconds = expiration != null
                ? Math.max(60, (expiration.getTime() - System.currentTimeMillis()) / 1000)
                : 600;
        tokenBlacklistService.blacklistToken(jti, remainingSeconds);

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + userId));

        // Validate and hash new password using policy and BCrypt 12
        String newPasswordHash = passwordService.hashPassword(request.getNewPassword());

        user.setPasswordHash(newPasswordHash);
        user.setFailedLoginCount(0);
        user.setLockedUntil(null);
        if (user.getStatus() == UserStatus.LOCKED) {
            user.setStatus(UserStatus.ACTIVE);
        }
        userRepository.save(user);

        // Revoke ALL active refresh token sessions across all devices
        refreshTokenService.revokeAllUserTokens(user);

        auditService.logPasswordResetSuccess(user.getId(), clientIp);
        log.info("Password successfully reset for user {}", user.getId());

        return "Password has been reset successfully. Please login with your new password.";
    }
}
