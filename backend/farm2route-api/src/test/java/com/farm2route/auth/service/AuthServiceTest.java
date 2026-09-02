package com.farm2route.auth.service;

import com.farm2route.auth.dto.AuthResponse;
import com.farm2route.auth.dto.LoginRequest;
import com.farm2route.auth.dto.RegisterRequest;
import com.farm2route.auth.entity.RefreshToken;
import com.farm2route.auth.entity.User;
import com.farm2route.auth.model.OtpPurpose;
import com.farm2route.auth.model.Role;
import com.farm2route.auth.model.UserStatus;
import com.farm2route.auth.repository.UserRepository;
import com.farm2route.common.exception.AccountLockedException;
import com.farm2route.common.exception.AuthenticationException;
import com.farm2route.common.exception.ConflictException;
import com.farm2route.security.JwtService;
import com.farm2route.security.TokenBlacklistService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordService passwordService;

    @Mock
    private JwtService jwtService;

    @Mock
    private RefreshTokenService refreshTokenService;

    @Mock
    private OtpService otpService;

    @Mock
    private TokenBlacklistService tokenBlacklistService;

    @Mock
    private LoginRateLimitService loginRateLimitService;

    @Mock
    private RegistrationRateLimitService registrationRateLimitService;

    @Mock
    private AuthenticationAuditService auditService;

    private AuthService authService;

    @BeforeEach
    void setUp() {
        authService = new AuthService(
                userRepository,
                passwordService,
                jwtService,
                refreshTokenService,
                otpService,
                tokenBlacklistService,
                loginRateLimitService,
                registrationRateLimitService,
                auditService
        );
        ReflectionTestUtils.setField(authService, "maxFailedLoginAttempts", 5);
        ReflectionTestUtils.setField(authService, "lockDurationMinutes", 15);
    }

    @Test
    @DisplayName("Should successfully register Farmer with BCrypt password and send OTP")
    void testRegisterFarmerSuccess() {
        RegisterRequest request = RegisterRequest.builder()
                .phoneNumber("+94771234567")
                .email("farmer@test.com")
                .password("StrongPassword123!")
                .role(Role.FARMER)
                .build();

        when(userRepository.existsByPhoneNumber(anyString())).thenReturn(false);
        when(userRepository.existsByEmail(anyString())).thenReturn(false);
        when(passwordService.hashPassword(anyString())).thenReturn("$2a$12$hashedpassword");
        when(userRepository.save(any(User.class))).thenAnswer(i -> {
            User u = i.getArgument(0);
            u.setId(UUID.randomUUID());
            return u;
        });

        AuthResponse response = authService.register(request, "127.0.0.1");

        assertTrue(response.isRequiresOtp());
        assertNotNull(response.getUser());
        assertEquals(Role.FARMER, response.getUser().getRole());
        assertEquals(UserStatus.PENDING_VERIFICATION, response.getUser().getStatus());

        verify(otpService).generateAndSendOtp(eq("+94771234567"), eq(OtpPurpose.REGISTRATION), any());
        verify(auditService).logUserRegistered(any(), eq("+94771234567"), eq("FARMER"), eq("127.0.0.1"));
    }

    @Test
    @DisplayName("Should reject public registration for ADMIN role")
    void testRegisterAdminRejected() {
        RegisterRequest request = RegisterRequest.builder()
                .phoneNumber("+94771234567")
                .password("StrongPassword123!")
                .role(Role.ADMIN)
                .build();

        assertThrows(ConflictException.class, () -> authService.register(request, "127.0.0.1"));
        verify(userRepository, never()).save(any());
    }

    @Test
    @DisplayName("Should reject registration with duplicate phone number")
    void testRegisterDuplicatePhone() {
        RegisterRequest request = RegisterRequest.builder()
                .phoneNumber("+94771234567")
                .password("StrongPassword123!")
                .role(Role.FARMER)
                .build();

        when(userRepository.existsByPhoneNumber("+94771234567")).thenReturn(true);

        assertThrows(ConflictException.class, () -> authService.register(request, "127.0.0.1"));
    }

    @Test
    @DisplayName("Should successfully login active user and issue tokens")
    void testLoginSuccess() {
        LoginRequest request = LoginRequest.builder()
                .phoneNumber("+94771234567")
                .password("StrongPassword123!")
                .build();

        User user = User.builder()
                .id(UUID.randomUUID())
                .phoneNumber("+94771234567")
                .passwordHash("$2a$12$hashedpassword")
                .role(Role.FARMER)
                .status(UserStatus.ACTIVE)
                .phoneVerified(true)
                .failedLoginCount(0)
                .build();

        when(userRepository.findByIdentifier("+94771234567")).thenReturn(Optional.of(user));
        when(passwordService.matches("StrongPassword123!", "$2a$12$hashedpassword")).thenReturn(true);
        when(jwtService.generateToken(any())).thenReturn("mock.jwt.token");
        when(jwtService.getAccessTokenExpirationMs()).thenReturn(900000L);
        when(refreshTokenService.createRefreshToken(any(), any(), any()))
                .thenReturn(new RefreshTokenService.CreatedToken(RefreshToken.builder().build(), "mock-refresh-token"));
        when(userRepository.save(any())).thenReturn(user);

        AuthResponse response = authService.login(request, "127.0.0.1", "Pixel 7");

        assertFalse(response.isRequiresOtp());
        assertEquals("mock.jwt.token", response.getAccessToken());
        assertEquals("mock-refresh-token", response.getRefreshToken());
        assertEquals(0, user.getFailedLoginCount());
        assertNotNull(user.getLastLoginAt());
        verify(auditService).logLoginSuccess(user.getId(), "FARMER", "127.0.0.1");
    }

    @Test
    @DisplayName("Should lock account after 5 consecutive failed login attempts")
    void testAccountLockoutAfterMaxFailedAttempts() {
        LoginRequest request = LoginRequest.builder()
                .phoneNumber("+94771234567")
                .password("WrongPassword")
                .build();

        User user = User.builder()
                .id(UUID.randomUUID())
                .phoneNumber("+94771234567")
                .passwordHash("$2a$12$hashedpassword")
                .role(Role.FARMER)
                .status(UserStatus.ACTIVE)
                .phoneVerified(true)
                .failedLoginCount(4) // 5th failure next
                .build();

        when(userRepository.findByIdentifier("+94771234567")).thenReturn(Optional.of(user));
        when(passwordService.matches("WrongPassword", "$2a$12$hashedpassword")).thenReturn(false);

        AccountLockedException ex = assertThrows(AccountLockedException.class,
                () -> authService.login(request, "127.0.0.1", "Pixel 7"));

        assertEquals(UserStatus.LOCKED, user.getStatus());
        assertEquals(5, user.getFailedLoginCount());
        assertNotNull(user.getLockedUntil());
        verify(auditService).logAccountLocked(eq(user.getId()), eq("+94771234567"), eq(15), eq("127.0.0.1"));
    }

    @Test
    @DisplayName("Should prevent login on currently locked account")
    void testLockedAccountCannotLogin() {
        LoginRequest request = LoginRequest.builder()
                .phoneNumber("+94771234567")
                .password("AnyPassword")
                .build();

        User user = User.builder()
                .id(UUID.randomUUID())
                .phoneNumber("+94771234567")
                .status(UserStatus.LOCKED)
                .lockedUntil(Instant.now().plusSeconds(600))
                .build();

        when(userRepository.findByIdentifier("+94771234567")).thenReturn(Optional.of(user));

        assertThrows(AccountLockedException.class, () -> authService.login(request, "127.0.0.1", "Pixel 7"));
    }
}
