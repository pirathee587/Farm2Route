package com.farm2route.auth;

import com.farm2route.auth.dto.*;
import com.farm2route.auth.entity.RefreshToken;
import com.farm2route.auth.entity.User;
import com.farm2route.auth.repository.UserRepository;
import com.farm2route.auth.service.AuthService;
import com.farm2route.auth.service.OtpService;
import com.farm2route.auth.service.RefreshTokenService;
import com.farm2route.common.enums.Role;
import com.farm2route.common.enums.UserStatus;
import com.farm2route.common.exception.ConflictException;
import com.farm2route.common.exception.UnauthorizedException;
import com.farm2route.security.JwtService;
import com.farm2route.security.TokenBlacklistService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;

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
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtService jwtService;

    @Mock
    private RefreshTokenService refreshTokenService;

    @Mock
    private OtpService otpService;

    @Mock
    private TokenBlacklistService tokenBlacklistService;

    @Mock
    private AuthenticationManager authenticationManager;

    @InjectMocks
    private AuthService authService;

    private User sampleUser;
    private RegisterRequest registerRequest;

    @BeforeEach
    void setUp() {
        sampleUser = User.builder()
                .id(UUID.randomUUID())
                .phoneNumber("+94771234567")
                .email("farmer@farm2route.com")
                .fullName("Kamal Gunaratne")
                .passwordHash("$2a$12$hashedPassword")
                .role(Role.FARMER)
                .status(UserStatus.PENDING_VERIFICATION)
                .isPhoneVerified(false)
                .isEmailVerified(false)
                .build();

        registerRequest = RegisterRequest.builder()
                .fullName("Kamal Gunaratne")
                .phoneNumber("+94771234567")
                .email("farmer@farm2route.com")
                .password("StrongPass123!")
                .role(Role.FARMER)
                .build();
    }

    @Test
    @DisplayName("Should successfully register a new user and dispatch OTP")
    void register_Success() {
        when(userRepository.existsByPhoneNumber(anyString())).thenReturn(false);
        when(userRepository.existsByEmail(anyString())).thenReturn(false);
        when(passwordEncoder.encode(anyString())).thenReturn("$2a$12$hashedPassword");
        when(userRepository.save(any(User.class))).thenReturn(sampleUser);
        doNothing().when(otpService).generateAndSendOtp(anyString(), anyString());

        AuthResponse response = authService.register(registerRequest, "127.0.0.1");

        assertNotNull(response);
        assertTrue(response.isRequiresOtp());
        assertEquals("Kamal Gunaratne", response.getUser().getFullName());
        verify(userRepository, times(1)).save(any(User.class));
        verify(otpService, times(1)).generateAndSendOtp(eq("+94771234567"), eq("REGISTRATION"));
    }

    @Test
    @DisplayName("Should throw ConflictException when registering duplicate phone number")
    void register_DuplicatePhone_ThrowsConflict() {
        when(userRepository.existsByPhoneNumber("+94771234567")).thenReturn(true);

        assertThrows(ConflictException.class, () -> authService.register(registerRequest, "127.0.0.1"));
        verify(userRepository, never()).save(any(User.class));
    }

    @Test
    @DisplayName("Should verify OTP and activate user account")
    void verifyOtp_Success() {
        VerifyOtpRequest request = VerifyOtpRequest.builder()
                .phoneNumber("+94771234567")
                .otpCode("123456")
                .purpose("REGISTRATION")
                .build();

        when(otpService.verifyOtp("+94771234567", "123456", "REGISTRATION")).thenReturn(true);
        when(userRepository.findByPhoneNumber("+94771234567")).thenReturn(Optional.of(sampleUser));
        when(userRepository.save(any(User.class))).thenReturn(sampleUser);
        when(jwtService.generateToken(any(User.class))).thenReturn("mock-jwt-token");
        when(refreshTokenService.createRefreshToken(any(User.class), anyString())).thenReturn("mock-refresh-token");
        when(jwtService.getExpirationMs()).thenReturn(900000L);

        AuthResponse response = authService.verifyOtp(request, "127.0.0.1");

        assertNotNull(response);
        assertEquals("mock-jwt-token", response.getAccessToken());
        assertEquals("mock-refresh-token", response.getRefreshToken());
        assertFalse(response.isRequiresOtp());
        assertEquals(UserStatus.ACTIVE, sampleUser.getStatus());
        assertTrue(sampleUser.isPhoneVerified());
    }

    @Test
    @DisplayName("Should login active user and issue tokens")
    void login_Success() {
        sampleUser.setStatus(UserStatus.ACTIVE);
        sampleUser.setPhoneVerified(true);

        LoginRequest loginRequest = LoginRequest.builder()
                .identifier("+94771234567")
                .password("StrongPass123!")
                .build();

        when(userRepository.findByIdentifier("+94771234567")).thenReturn(Optional.of(sampleUser));
        when(passwordEncoder.matches("StrongPass123!", "$2a$12$hashedPassword")).thenReturn(true);
        when(jwtService.generateToken(any(User.class))).thenReturn("mock-jwt-token");
        when(refreshTokenService.createRefreshToken(any(User.class), anyString())).thenReturn("mock-refresh-token");
        when(jwtService.getExpirationMs()).thenReturn(900000L);

        AuthResponse response = authService.login(loginRequest, "127.0.0.1");

        assertNotNull(response);
        assertEquals("mock-jwt-token", response.getAccessToken());
        assertEquals("mock-refresh-token", response.getRefreshToken());
        assertFalse(response.isRequiresOtp());
    }

    @Test
    @DisplayName("Should throw BadCredentialsException when password does not match")
    void login_InvalidPassword_ThrowsBadCredentials() {
        LoginRequest loginRequest = LoginRequest.builder()
                .identifier("+94771234567")
                .password("WrongPassword!")
                .build();

        when(userRepository.findByIdentifier("+94771234567")).thenReturn(Optional.of(sampleUser));
        when(passwordEncoder.matches("WrongPassword!", "$2a$12$hashedPassword")).thenReturn(false);

        assertThrows(BadCredentialsException.class, () -> authService.login(loginRequest, "127.0.0.1"));
    }

    @Test
    @DisplayName("Should rotate refresh token and issue new token pair")
    void refreshToken_Success() {
        RefreshTokenRequest request = new RefreshTokenRequest("raw-refresh-token-123");
        RefreshToken tokenEntity = RefreshToken.builder()
                .user(sampleUser)
                .tokenHash("hash-123")
                .expiresAt(Instant.now().plusSeconds(3600))
                .build();

        when(refreshTokenService.verifyAndRotate("raw-refresh-token-123", "127.0.0.1")).thenReturn(tokenEntity);
        when(jwtService.generateToken(sampleUser)).thenReturn("new-jwt-token");
        when(refreshTokenService.createRefreshToken(sampleUser, "127.0.0.1")).thenReturn("new-raw-refresh-token");
        when(jwtService.getExpirationMs()).thenReturn(900000L);

        AuthResponse response = authService.refreshToken(request, "127.0.0.1");

        assertNotNull(response);
        assertEquals("new-jwt-token", response.getAccessToken());
        assertEquals("new-raw-refresh-token", response.getRefreshToken());
    }
}
