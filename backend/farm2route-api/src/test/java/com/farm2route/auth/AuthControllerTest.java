package com.farm2route.auth;

import com.farm2route.auth.controller.AuthController;
import com.farm2route.auth.dto.*;
import com.farm2route.auth.service.AuthService;
import com.farm2route.common.enums.Role;
import com.farm2route.common.enums.UserStatus;
import com.farm2route.security.CustomUserDetailsService;
import com.farm2route.security.JwtService;
import com.farm2route.security.SecurityExceptionHandler;
import com.farm2route.security.TokenBlacklistService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(AuthController.class)
@AutoConfigureMockMvc(addFilters = false) // focus on MVC layer & DTO validation
class AuthControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private AuthService authService;

    @MockBean
    private JwtService jwtService;

    @MockBean
    private CustomUserDetailsService customUserDetailsService;

    @MockBean
    private TokenBlacklistService tokenBlacklistService;

    @MockBean
    private SecurityExceptionHandler securityExceptionHandler;

    @Test
    @DisplayName("POST /api/v1/auth/register - Valid payload returns 201 CREATED")
    void register_ValidPayload_Returns201() throws Exception {
        RegisterRequest request = RegisterRequest.builder()
                .fullName("John Doe")
                .phoneNumber("+94771234567")
                .email("john@example.com")
                .password("Password123!")
                .role(Role.FARMER)
                .build();

        UserResponse userResponse = UserResponse.builder()
                .id(UUID.randomUUID())
                .fullName("John Doe")
                .phoneNumber("+94771234567")
                .role(Role.FARMER)
                .status(UserStatus.PENDING_VERIFICATION)
                .build();

        AuthResponse authResponse = AuthResponse.builder()
                .user(userResponse)
                .requiresOtp(true)
                .build();

        when(authService.register(any(RegisterRequest.class), anyString())).thenReturn(authResponse);

        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.requiresOtp").value(true))
                .andExpect(jsonPath("$.data.user.phoneNumber").value("+94771234567"));
    }

    @Test
    @DisplayName("POST /api/v1/auth/register - Invalid password format returns 400 BAD REQUEST")
    void register_InvalidPassword_Returns400() throws Exception {
        RegisterRequest invalidRequest = RegisterRequest.builder()
                .fullName("John Doe")
                .phoneNumber("+94771234567")
                .email("john@example.com")
                .password("weak") // Does not meet password policy
                .role(Role.FARMER)
                .build();

        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(invalidRequest)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error").value("ValidationError"));
    }

    @Test
    @DisplayName("POST /api/v1/auth/login - Valid credentials return 200 OK with tokens")
    void login_ValidCredentials_Returns200() throws Exception {
        LoginRequest request = LoginRequest.builder()
                .identifier("+94771234567")
                .password("Password123!")
                .build();

        AuthResponse authResponse = AuthResponse.builder()
                .accessToken("mock-access-token")
                .refreshToken("mock-refresh-token")
                .tokenType("Bearer")
                .expiresInMs(900000)
                .requiresOtp(false)
                .build();

        when(authService.login(any(LoginRequest.class), anyString())).thenReturn(authResponse);

        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.accessToken").value("mock-access-token"))
                .andExpect(jsonPath("$.data.refreshToken").value("mock-refresh-token"));
    }

    @Test
    @DisplayName("POST /api/v1/auth/verify-otp - Valid OTP returns 200 OK with session tokens")
    void verifyOtp_ValidOtp_Returns200() throws Exception {
        VerifyOtpRequest request = VerifyOtpRequest.builder()
                .phoneNumber("+94771234567")
                .otpCode("654321")
                .purpose("REGISTRATION")
                .build();

        AuthResponse authResponse = AuthResponse.builder()
                .accessToken("mock-access-token")
                .refreshToken("mock-refresh-token")
                .requiresOtp(false)
                .build();

        when(authService.verifyOtp(any(VerifyOtpRequest.class), anyString())).thenReturn(authResponse);

        mockMvc.perform(post("/api/v1/auth/verify-otp")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.accessToken").value("mock-access-token"));
    }
}
