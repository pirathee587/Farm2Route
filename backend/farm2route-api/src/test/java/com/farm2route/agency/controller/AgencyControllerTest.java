package com.farm2route.agency.controller;

import com.farm2route.agency.dto.*;
import com.farm2route.agency.enums.AgencyStatus;
import com.farm2route.agency.enums.AgencyType;
import com.farm2route.agency.service.AgencyService;
import com.farm2route.common.exception.DuplicateResourceException;
import com.farm2route.common.filter.RequestCorrelationFilter;
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

import java.time.Instant;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(
        controllers = {AgencyController.class, AdminAgencyController.class},
        excludeFilters = @ComponentScan.Filter(
                type = FilterType.ASSIGNABLE_TYPE,
                classes = {JwtAuthenticationFilter.class, RequestCorrelationFilter.class}
        )
)
@AutoConfigureMockMvc(addFilters = false)
class AgencyControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private AgencyService agencyService;

    private AgencySignupRequest validRequest;
    private AgencyResponse mockResponse;
    private UUID agencyId;

    @BeforeEach
    void setUp() {
        agencyId = UUID.randomUUID();

        validRequest = AgencySignupRequest.builder()
                .agencyName("Lanka Agri Logistics")
                .email("contact@lankalogistics.lk")
                .phoneNumber("+94771234567")
                .password("Password123!")
                .confirmPassword("Password123!")
                .agencyType(AgencyType.COMPANY)
                .businessRegNumber("PV-123456")
                .district("Gampaha")
                .address("45 Kandy Road, Kelaniya")
                .contactPersonName("Kasun Silva")
                .build();

        mockResponse = AgencyResponse.builder()
                .id(agencyId)
                .agencyName("Lanka Agri Logistics")
                .email("contact@lankalogistics.lk")
                .phoneNumber("+94771234567")
                .agencyType(AgencyType.COMPANY)
                .businessRegNumber("PV-123456")
                .district("Gampaha")
                .address("45 Kandy Road, Kelaniya")
                .contactPersonName("Kasun Silva")
                .status(AgencyStatus.ACCOUNT_CREATED)
                .emailVerified(false)
                .phoneVerified(false)
                .createdAt(Instant.now())
                .updatedAt(Instant.now())
                .build();
    }

    @Test
    @DisplayName("POST /api/v1/agencies/signup returns 201 Created with AgencyResponse")
    void testSignup_Success() throws Exception {
        when(agencyService.signup(any(AgencySignupRequest.class))).thenReturn(mockResponse);

        mockMvc.perform(post("/api/v1/agencies/signup")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(validRequest)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.id").value(agencyId.toString()))
                .andExpect(jsonPath("$.data.agencyName").value("Lanka Agri Logistics"))
                .andExpect(jsonPath("$.data.email").value("contact@lankalogistics.lk"))
                .andExpect(jsonPath("$.data.phoneNumber").value("+94771234567"))
                .andExpect(jsonPath("$.data.agencyType").value("COMPANY"))
                .andExpect(jsonPath("$.data.status").value("ACCOUNT_CREATED"));
    }

    @Test
    @DisplayName("POST /api/v1/agency/signup alias path returns 201 Created")
    void testSignup_AliasPath_Success() throws Exception {
        when(agencyService.signup(any(AgencySignupRequest.class))).thenReturn(mockResponse);

        mockMvc.perform(post("/api/v1/agency/signup")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(validRequest)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.id").value(agencyId.toString()));
    }

    @Test
    @DisplayName("POST /api/v1/agencies/signup returns 400 Bad Request when businessRegNumber is missing for COMPANY")
    void testSignup_MissingBusinessRegNumber_ForCompany() throws Exception {
        validRequest.setBusinessRegNumber(null);

        mockMvc.perform(post("/api/v1/agencies/signup")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(validRequest)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error").value("ValidationError"));
    }

    @Test
    @DisplayName("POST /api/v1/agencies/signup returns 409 Conflict when duplicate resource exists")
    void testSignup_DuplicateResource_Returns409() throws Exception {
        when(agencyService.signup(any(AgencySignupRequest.class)))
                .thenThrow(new DuplicateResourceException("Agency with email contact@lankalogistics.lk already exists"));

        mockMvc.perform(post("/api/v1/agencies/signup")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(validRequest)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error").value("Conflict"))
                .andExpect(jsonPath("$.message").value("Agency with email contact@lankalogistics.lk already exists"));
    }

    @Test
    @DisplayName("POST /api/v1/agencies/signup returns 400 Bad Request when password and confirmPassword mismatch")
    void testSignup_PasswordMismatch_Returns400() throws Exception {
        validRequest.setConfirmPassword("MismatchPass456!");

        mockMvc.perform(post("/api/v1/agencies/signup")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(validRequest)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.error").value("ValidationError"));
    }

    @Test
    @DisplayName("POST /api/v1/agencies/verify-email returns 200 with AgencyStatusResponse")
    void testVerifyEmail_Success() throws Exception {
        VerifyEmailRequest request = VerifyEmailRequest.builder()
                .agencyId(agencyId)
                .emailToken("sample-token")
                .build();

        AgencyStatusResponse statusResponse = AgencyStatusResponse.builder()
                .agencyId(agencyId)
                .email("contact@lankalogistics.lk")
                .status(AgencyStatus.ACCOUNT_CREATED)
                .emailVerified(true)
                .phoneVerified(false)
                .build();

        when(agencyService.verifyEmail(eq(agencyId), eq("sample-token"))).thenReturn(statusResponse);

        mockMvc.perform(post("/api/v1/agencies/verify-email")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.emailVerified").value(true));
    }

    @Test
    @DisplayName("POST /api/v1/agencies/verify-phone returns 200 with AgencyStatusResponse")
    void testVerifyPhone_Success() throws Exception {
        VerifyPhoneRequest request = VerifyPhoneRequest.builder()
                .agencyId(agencyId)
                .otp("123456")
                .build();

        AgencyStatusResponse statusResponse = AgencyStatusResponse.builder()
                .agencyId(agencyId)
                .phoneNumber("+94771234567")
                .status(AgencyStatus.PENDING_VERIFICATION)
                .emailVerified(true)
                .phoneVerified(true)
                .build();

        when(agencyService.verifyPhone(eq(agencyId), eq("123456"))).thenReturn(statusResponse);

        mockMvc.perform(post("/api/v1/agencies/verify-phone")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.phoneVerified").value(true))
                .andExpect(jsonPath("$.data.status").value("PENDING_VERIFICATION"));
    }

    @Test
    @DisplayName("GET /api/v1/agencies/{id}/status returns 200 with current status")
    void testGetAgencyStatus_Success() throws Exception {
        AgencyStatusResponse statusResponse = AgencyStatusResponse.builder()
                .agencyId(agencyId)
                .status(AgencyStatus.ACCOUNT_CREATED)
                .emailVerified(false)
                .phoneVerified(false)
                .build();

        when(agencyService.getAgencyStatus(agencyId)).thenReturn(statusResponse);

        mockMvc.perform(get("/api/v1/agencies/" + agencyId + "/status"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("ACCOUNT_CREATED"));
    }

    @Test
    @DisplayName("POST /api/v1/admin/agencies/{id}/approve returns 200 with status APPROVED")
    void testApproveAgency_Success() throws Exception {
        AgencyResponse approvedResponse = AgencyResponse.builder()
                .id(agencyId)
                .status(AgencyStatus.APPROVED)
                .build();

        when(agencyService.approveAgency(eq(agencyId), any())).thenReturn(approvedResponse);

        mockMvc.perform(post("/api/v1/admin/agencies/" + agencyId + "/approve"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("APPROVED"));
    }

    @Test
    @DisplayName("POST /api/v1/admin/agencies/{id}/reject returns 200 with status REJECTED")
    void testRejectAgency_Success() throws Exception {
        AgencyRejectionRequest request = AgencyRejectionRequest.builder()
                .reason("Documents unreadable")
                .build();

        AgencyResponse rejectedResponse = AgencyResponse.builder()
                .id(agencyId)
                .status(AgencyStatus.REJECTED)
                .rejectionReason("Documents unreadable")
                .build();

        when(agencyService.rejectAgency(eq(agencyId), eq("Documents unreadable"), any())).thenReturn(rejectedResponse);

        mockMvc.perform(post("/api/v1/admin/agencies/" + agencyId + "/reject")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("REJECTED"))
                .andExpect(jsonPath("$.data.rejectionReason").value("Documents unreadable"));
    }
}
