package com.farm2route.auth.controller;

import com.farm2route.auth.dto.AuthResponse;
import com.farm2route.auth.dto.LoginRequest;
import com.farm2route.auth.dto.RegisterRequest;
import com.farm2route.auth.dto.UserResponse;
import com.farm2route.auth.model.Role;
import com.farm2route.auth.model.UserStatus;
import com.farm2route.auth.service.AuthService;
import com.farm2route.common.filter.RequestCorrelationFilter;
import com.farm2route.security.CustomUserDetailsService;
import com.farm2route.security.JwtAuthenticationFilter;
import com.farm2route.security.JwtService;
import com.farm2route.security.SecurityExceptionHandler;
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

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(controllers = AuthController.class)
@AutoConfigureMockMvc(addFilters = false)
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
    private CustomUserDetailsService userDetailsService;

    @MockBean
    private SecurityExceptionHandler securityExceptionHandler;

    @MockBean
    private JwtAuthenticationFilter jwtAuthenticationFilter;

    @MockBean
    private RequestCorrelationFilter requestCorrelationFilter;

    @Test
    @DisplayName("POST /api/v1/auth/register should return 201 Created")
    void testRegisterEndpointSuccess() throws Exception {
        RegisterRequest request = RegisterRequest.builder()
                .phoneNumber("+94771234567")
                .email("test@farm2route.com")
                .password("StrongPassword123!")
                .role(Role.FARMER)
                .build();

        AuthResponse authResponse = AuthResponse.builder()
                .requiresOtp(true)
                .message("User registered successfully.")
                .user(UserResponse.builder()
                        .id(UUID.randomUUID())
                        .phoneNumber("+94771234567")
                        .role(Role.FARMER)
                        .status(UserStatus.PENDING_VERIFICATION)
                        .build())
                .build();

        when(authService.register(any(), any())).thenReturn(authResponse);

        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.requiresOtp").value(true));
    }

    @Test
    @DisplayName("POST /api/v1/auth/login should return 200 OK with tokens")
    void testLoginEndpointSuccess() throws Exception {
        LoginRequest request = LoginRequest.builder()
                .phoneNumber("+94771234567")
                .password("StrongPassword123!")
                .build();

        AuthResponse authResponse = AuthResponse.builder()
                .accessToken("mock.jwt.token")
                .refreshToken("mock.refresh.token")
                .tokenType("Bearer")
                .expiresIn(900L)
                .user(UserResponse.builder()
                        .id(UUID.randomUUID())
                        .phoneNumber("+94771234567")
                        .role(Role.FARMER)
                        .status(UserStatus.ACTIVE)
                        .build())
                .requiresOtp(false)
                .message("Login successful.")
                .build();

        when(authService.login(any(), any(), any())).thenReturn(authResponse);

        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.accessToken").value("mock.jwt.token"))
                .andExpect(jsonPath("$.data.refreshToken").value("mock.refresh.token"));
    }
}
