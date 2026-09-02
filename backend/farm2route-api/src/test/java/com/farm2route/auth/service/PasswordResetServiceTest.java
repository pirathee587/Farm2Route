package com.farm2route.auth.service;

import com.farm2route.auth.dto.ForgotPasswordRequest;
import com.farm2route.auth.dto.ResetPasswordRequest;
import com.farm2route.auth.dto.VerifyPasswordResetOtpRequest;
import com.farm2route.auth.dto.VerifyPasswordResetOtpResponse;
import com.farm2route.auth.entity.User;
import com.farm2route.auth.model.OtpPurpose;
import com.farm2route.auth.model.Role;
import com.farm2route.auth.model.UserStatus;
import com.farm2route.auth.repository.UserRepository;
import com.farm2route.common.exception.AuthenticationException;
import com.farm2route.common.exception.InvalidOtpException;
import com.farm2route.common.validation.PasswordPolicyValidator;
import com.farm2route.security.JwtService;
import com.farm2route.security.TokenBlacklistService;
import io.jsonwebtoken.Claims;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Date;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class PasswordResetServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private OtpService otpService;

    @Mock
    private JwtService jwtService;

    @Mock
    private RefreshTokenService refreshTokenService;

    @Mock
    private TokenBlacklistService tokenBlacklistService;

    @Mock
    private PasswordResetRateLimitService rateLimitService;

    @Mock
    private AuthenticationAuditService auditService;

    private PasswordService passwordService;
    private PasswordResetService passwordResetService;

    private User sampleUser;

    @BeforeEach
    void setUp() {
        PasswordPolicyValidator policyValidator = new PasswordPolicyValidator(8, 128, List.of("password", "password123", "12345678"));
        passwordService = new PasswordService(12, policyValidator);

        passwordResetService = new PasswordResetService(
                userRepository,
                otpService,
                jwtService,
                passwordService,
                refreshTokenService,
                tokenBlacklistService,
                rateLimitService,
                auditService
        );

        sampleUser = User.builder()
                .id(UUID.randomUUID())
                .phoneNumber("+94771234567")
                .email("farmer@test.com")
                .passwordHash("$2a$12$oldhashedpassword")
                .role(Role.FARMER)
                .status(UserStatus.ACTIVE)
                .phoneVerified(true)
                .failedLoginCount(2)
                .build();
    }

    @Test
    @DisplayName("Forgot Password: Existing user receives OTP and gets generic response")
    void testForgotPasswordExistingUser() {
        ForgotPasswordRequest request = ForgotPasswordRequest.builder()
                .phoneNumber("+94771234567")
                .build();

        when(userRepository.findByPhoneNumber("+94771234567")).thenReturn(Optional.of(sampleUser));

        String message = passwordResetService.forgotPassword(request, "127.0.0.1");

        assertEquals(PasswordResetService.GENERIC_FORGOT_PASSWORD_RESPONSE, message);
        verify(rateLimitService).checkAndIncrement("127.0.0.1", "+94771234567");
        verify(otpService).generateAndSendOtp(eq("+94771234567"), eq(OtpPurpose.PASSWORD_RESET), eq(sampleUser.getId()));
        verify(auditService).logPasswordResetRequested(eq("+94771234567"), eq("127.0.0.1"));
    }

    @Test
    @DisplayName("Forgot Password ANTI-ENUMERATION: Non-existing user returns identical generic response without error")
    void testForgotPasswordNonExistingUserAntiEnumeration() {
        ForgotPasswordRequest request = ForgotPasswordRequest.builder()
                .phoneNumber("+94779999999")
                .build();

        when(userRepository.findByPhoneNumber("+94779999999")).thenReturn(Optional.empty());

        String message = passwordResetService.forgotPassword(request, "127.0.0.1");

        assertEquals(PasswordResetService.GENERIC_FORGOT_PASSWORD_RESPONSE, message);
        verify(rateLimitService).checkAndIncrement("127.0.0.1", "+94779999999");
        verify(otpService, never()).generateAndSendOtp(anyString(), any(), any());
    }

    @Test
    @DisplayName("Verify Password Reset OTP: Valid OTP issues dedicated reset token")
    void testVerifyPasswordResetOtpSuccess() {
        VerifyPasswordResetOtpRequest request = VerifyPasswordResetOtpRequest.builder()
                .phoneNumber("+94771234567")
                .otp("123456")
                .build();

        when(otpService.verifyOtp("+94771234567", "123456", OtpPurpose.PASSWORD_RESET)).thenReturn(true);
        when(userRepository.findByPhoneNumber("+94771234567")).thenReturn(Optional.of(sampleUser));
        when(jwtService.generatePasswordResetToken(sampleUser)).thenReturn("mock.password.reset.token");

        VerifyPasswordResetOtpResponse response = passwordResetService.verifyPasswordResetOtp(request, "127.0.0.1");

        assertNotNull(response.getResetToken());
        assertEquals("mock.password.reset.token", response.getResetToken());
        assertEquals(600L, response.getExpiresIn());
        verify(auditService).logPasswordResetOtpVerified(sampleUser.getId(), "+94771234567", "127.0.0.1");
    }

    @Test
    @DisplayName("Verify Password Reset OTP: Invalid OTP throws exception")
    void testVerifyPasswordResetOtpInvalid() {
        VerifyPasswordResetOtpRequest request = VerifyPasswordResetOtpRequest.builder()
                .phoneNumber("+94771234567")
                .otp("000000")
                .build();

        when(otpService.verifyOtp("+94771234567", "000000", OtpPurpose.PASSWORD_RESET))
                .thenThrow(new InvalidOtpException("Invalid OTP code."));

        assertThrows(InvalidOtpException.class,
                () -> passwordResetService.verifyPasswordResetOtp(request, "127.0.0.1"));
    }

    @Test
    @DisplayName("Reset Password: Valid reset token and strong password updates user, revokes all sessions, and blacklists token")
    void testResetPasswordSuccess() {
        ResetPasswordRequest request = ResetPasswordRequest.builder()
                .resetToken("valid.reset.token")
                .newPassword("BrandNewSecurePass123!")
                .build();

        Claims mockClaims = mock(Claims.class);
        when(mockClaims.getSubject()).thenReturn(sampleUser.getId().toString());
        when(mockClaims.getId()).thenReturn("reset-jti-999");
        when(mockClaims.getExpiration()).thenReturn(new Date(System.currentTimeMillis() + 600000));

        when(jwtService.validatePasswordResetToken("valid.reset.token")).thenReturn(mockClaims);
        when(userRepository.findById(sampleUser.getId())).thenReturn(Optional.of(sampleUser));
        when(userRepository.save(any(User.class))).thenAnswer(i -> i.getArgument(0));

        String message = passwordResetService.resetPassword(request, "127.0.0.1");

        assertTrue(message.contains("successfully"));
        assertTrue(passwordService.matches("BrandNewSecurePass123!", sampleUser.getPasswordHash()));
        assertEquals(0, sampleUser.getFailedLoginCount());

        // Verify all refresh sessions are revoked globally
        verify(refreshTokenService).revokeAllUserTokens(sampleUser);
        // Verify reset token JTI is blacklisted against reuse
        verify(tokenBlacklistService).blacklistToken(eq("reset-jti-999"), anyLong());
        verify(auditService).logPasswordResetSuccess(sampleUser.getId(), "127.0.0.1");
    }

    @Test
    @DisplayName("Reset Password REPLAY PROTECTION: Reused reset token is rejected")
    void testResetPasswordTokenReplayRejected() {
        ResetPasswordRequest request = ResetPasswordRequest.builder()
                .resetToken("replayed.reset.token")
                .newPassword("BrandNewSecurePass123!")
                .build();

        when(jwtService.validatePasswordResetToken("replayed.reset.token"))
                .thenThrow(new AuthenticationException("Password reset token has already been used or is invalid."));

        assertThrows(AuthenticationException.class,
                () -> passwordResetService.resetPassword(request, "127.0.0.1"));

        verify(userRepository, never()).save(any());
        verify(refreshTokenService, never()).revokeAllUserTokens(any());
    }

    @Test
    @DisplayName("Reset Password: Weak password rejected by policy validator")
    void testResetPasswordWeakPasswordRejected() {
        ResetPasswordRequest request = ResetPasswordRequest.builder()
                .resetToken("valid.reset.token")
                .newPassword("password123") // in weak list
                .build();

        Claims mockClaims = mock(Claims.class);
        when(mockClaims.getSubject()).thenReturn(sampleUser.getId().toString());
        when(jwtService.validatePasswordResetToken("valid.reset.token")).thenReturn(mockClaims);
        when(userRepository.findById(sampleUser.getId())).thenReturn(Optional.of(sampleUser));

        assertThrows(IllegalArgumentException.class,
                () -> passwordResetService.resetPassword(request, "127.0.0.1"));
    }
}
