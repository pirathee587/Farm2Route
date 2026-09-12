package com.farm2route.farmer.controller;

import com.farm2route.common.exception.DuplicatePhoneException;
import com.farm2route.common.exception.OtpExpiredException;
import com.farm2route.common.exception.OtpMismatchException;
import com.farm2route.common.filter.RequestCorrelationFilter;
import com.farm2route.farmer.dto.*;
import com.farm2route.farmer.enums.CropType;
import com.farm2route.farmer.enums.FarmerStatus;
import com.farm2route.farmer.enums.PreferredLanguage;
import com.farm2route.farmer.service.FarmerService;
import com.farm2route.security.JwtAuthenticationFilter;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.FilterType;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Set;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(
        controllers = FarmerController.class,
        excludeFilters = @ComponentScan.Filter(
                type = FilterType.ASSIGNABLE_TYPE,
                classes = {JwtAuthenticationFilter.class, RequestCorrelationFilter.class}
        )
)
@AutoConfigureMockMvc(addFilters = false)
class FarmerControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private FarmerService farmerService;

    private FarmerOtpRequest validOtpRequest;
    private FarmerVerifyRequest validVerifyRequest;
    private FarmerResponse mockFarmerResponse;
    private FarmerOtpResponse mockOtpResponse;
    private UUID farmerId;

    @BeforeEach
    void setUp() {
        farmerId = UUID.randomUUID();

        validOtpRequest = FarmerOtpRequest.builder()
                .phoneNumber("+94771234567")
                .build();

        mockOtpResponse = FarmerOtpResponse.builder()
                .phoneNumber("+94771234567")
                .message("OTP sent successfully to +94771234567")
                .build();

        validVerifyRequest = FarmerVerifyRequest.builder()
                .phoneNumber("+94771234567")
                .otp("123456")
                .fullName("Kamal Perera")
                .district("Anuradhapura")
                .gnDivision("Medawachchiya-North")
                .address("45 Field Track, Medawachchiya")
                .email("kamal.perera@example.lk")
                .latitude(8.5342)
                .longitude(80.4958)
                .farmSizeAcres(BigDecimal.valueOf(3.5))
                .primaryCrops(List.of(CropType.GRAINS, CropType.VEGETABLES))
                .preferredLanguage(PreferredLanguage.SI)
                .build();

        mockFarmerResponse = FarmerResponse.builder()
                .id(farmerId)
                .fullName("Kamal Perera")
                .phoneNumber("+94771234567")
                .email("kamal.perera@example.lk")
                .district("Anuradhapura")
                .gnDivision("Medawachchiya-North")
                .address("45 Field Track, Medawachchiya")
                .latitude(8.5342)
                .longitude(80.4958)
                .farmSizeAcres(BigDecimal.valueOf(3.5))
                .primaryCrops(Set.of(CropType.GRAINS, CropType.VEGETABLES))
                .preferredLanguage(PreferredLanguage.SI)
                .phoneVerified(true)
                .status(FarmerStatus.ACTIVE)
                .token("mocked.jwt.token")
                .tokenType("Bearer")
                .createdAt(Instant.now())
                .updatedAt(Instant.now())
                .build();
    }

    @Test
    @DisplayName("POST /api/v1/farmers/signup/request-otp returns 200 OK with success message")
    void testRequestOtp_Success() throws Exception {
        when(farmerService.requestOtp(any(FarmerOtpRequest.class))).thenReturn(mockOtpResponse);

        mockMvc.perform(post("/api/v1/farmers/signup/request-otp")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(validOtpRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.phoneNumber").value("+94771234567"))
                .andExpect(jsonPath("$.data.message").value("OTP sent successfully to +94771234567"));
    }

    @Test
    @DisplayName("POST /api/v1/farmer/signup/request-otp alias path returns 200 OK")
    void testRequestOtp_AliasPath_Success() throws Exception {
        when(farmerService.requestOtp(any(FarmerOtpRequest.class))).thenReturn(mockOtpResponse);

        mockMvc.perform(post("/api/v1/farmer/signup/request-otp")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(validOtpRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.phoneNumber").value("+94771234567"));
    }

    @Test
    @DisplayName("POST /api/v1/farmers/signup/request-otp returns 409 Conflict when phone number already exists")
    void testRequestOtp_DuplicatePhone_Returns409() throws Exception {
        when(farmerService.requestOtp(any(FarmerOtpRequest.class)))
                .thenThrow(new DuplicatePhoneException("Farmer with phone number +94771234567 already exists"));

        mockMvc.perform(post("/api/v1/farmers/signup/request-otp")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(validOtpRequest)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error").value("Conflict"))
                .andExpect(jsonPath("$.message").value("Farmer with phone number +94771234567 already exists"));
    }

    @Test
    @DisplayName("POST /api/v1/farmers/signup/request-otp returns 400 Bad Request when phone number format is invalid")
    void testRequestOtp_InvalidPhone_Returns400() throws Exception {
        FarmerOtpRequest invalidRequest = FarmerOtpRequest.builder()
                .phoneNumber("invalid-phone")
                .build();

        mockMvc.perform(post("/api/v1/farmers/signup/request-otp")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(invalidRequest)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error").value("ValidationError"));
    }

    @Test
    @DisplayName("POST /api/v1/farmers/signup/verify returns 201 Created with FarmerResponse and JWT token")
    void testVerifySignup_Success() throws Exception {
        when(farmerService.verifyAndSignup(any(FarmerVerifyRequest.class))).thenReturn(mockFarmerResponse);

        mockMvc.perform(post("/api/v1/farmers/signup/verify")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(validVerifyRequest)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.id").value(farmerId.toString()))
                .andExpect(jsonPath("$.data.fullName").value("Kamal Perera"))
                .andExpect(jsonPath("$.data.phoneNumber").value("+94771234567"))
                .andExpect(jsonPath("$.data.district").value("Anuradhapura"))
                .andExpect(jsonPath("$.data.phoneVerified").value(true))
                .andExpect(jsonPath("$.data.status").value("ACTIVE"))
                .andExpect(jsonPath("$.data.token").value("mocked.jwt.token"))
                .andExpect(jsonPath("$.data.tokenType").value("Bearer"));
    }

    @Test
    @DisplayName("POST /api/v1/farmer/signup/verify alias path returns 201 Created")
    void testVerifySignup_AliasPath_Success() throws Exception {
        when(farmerService.verifyAndSignup(any(FarmerVerifyRequest.class))).thenReturn(mockFarmerResponse);

        mockMvc.perform(post("/api/v1/farmer/signup/verify")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(validVerifyRequest)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.id").value(farmerId.toString()));
    }

    @Test
    @DisplayName("POST /api/v1/farmers/signup/verify returns 400 Bad Request when OTP is expired")
    void testVerifySignup_ExpiredOtp_Returns400() throws Exception {
        when(farmerService.verifyAndSignup(any(FarmerVerifyRequest.class)))
                .thenThrow(new OtpExpiredException("OTP has expired. Please request a new verification code."));

        mockMvc.perform(post("/api/v1/farmers/signup/verify")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(validVerifyRequest)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error").value("BadRequest"))
                .andExpect(jsonPath("$.message").value("OTP has expired. Please request a new verification code."));
    }

    @Test
    @DisplayName("POST /api/v1/farmers/signup/verify returns 400 Bad Request when OTP code is wrong")
    void testVerifySignup_WrongOtp_Returns400() throws Exception {
        when(farmerService.verifyAndSignup(any(FarmerVerifyRequest.class)))
                .thenThrow(new OtpMismatchException("Invalid OTP code. 4 attempts remaining."));

        mockMvc.perform(post("/api/v1/farmers/signup/verify")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(validVerifyRequest)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error").value("BadRequest"))
                .andExpect(jsonPath("$.message").value("Invalid OTP code. 4 attempts remaining."));
    }

    @Test
    @DisplayName("POST /api/v1/farmers/signup/verify returns 409 Conflict when phone number is already registered")
    void testVerifySignup_DuplicatePhone_Returns409() throws Exception {
        when(farmerService.verifyAndSignup(any(FarmerVerifyRequest.class)))
                .thenThrow(new DuplicatePhoneException("Farmer with phone number +94771234567 already exists"));

        mockMvc.perform(post("/api/v1/farmers/signup/verify")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(validVerifyRequest)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error").value("Conflict"))
                .andExpect(jsonPath("$.message").value("Farmer with phone number +94771234567 already exists"));
    }

    @Test
    @DisplayName("POST /api/v1/farmers/signup/verify returns 400 Bad Request when required fields are missing")
    void testVerifySignup_MissingFields_Returns400() throws Exception {
        FarmerVerifyRequest invalidRequest = FarmerVerifyRequest.builder()
                .phoneNumber("+94771234567")
                .otp("123456")
                .fullName("") // Blank fullName
                .district("") // Blank district
                .build();

        mockMvc.perform(post("/api/v1/farmers/signup/verify")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(invalidRequest)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error").value("ValidationError"));
    }
}
