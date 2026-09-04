package com.farm2route.driver.controller;

import com.farm2route.auth.entity.User;
import com.farm2route.auth.model.Role;
import com.farm2route.auth.model.UserStatus;
import com.farm2route.common.enums.DriverAvailability;
import com.farm2route.common.enums.KycStatus;
import com.farm2route.common.filter.RequestCorrelationFilter;
import com.farm2route.driver.dto.DriverProfileDto;
import com.farm2route.driver.dto.RegisterDriverRequest;
import com.farm2route.driver.dto.UpdateDriverKycRequest;
import com.farm2route.driver.dto.UpdateDriverRequest;
import com.farm2route.driver.service.DriverService;
import com.farm2route.security.JwtAuthenticationFilter;
import com.farm2route.security.UserPrincipal;
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
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(
        controllers = DriverController.class,
        excludeFilters = @ComponentScan.Filter(
                type = FilterType.ASSIGNABLE_TYPE,
                classes = {JwtAuthenticationFilter.class, RequestCorrelationFilter.class}
        )
)
@AutoConfigureMockMvc(addFilters = false)
class DriverControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private DriverService driverService;

    private UUID agencyUserId;
    private UUID driverUserId;
    private UUID driverId;
    private UserPrincipal agencyPrincipal;
    private UserPrincipal driverPrincipal;
    private DriverProfileDto driverProfileDto;

    @BeforeEach
    void setUp() {
        agencyUserId = UUID.randomUUID();
        driverUserId = UUID.randomUUID();
        driverId = UUID.randomUUID();

        User agencyUser = User.builder()
                .id(agencyUserId)
                .email("agency@farm2route.lk")
                .phoneNumber("+94771234567")
                .role(Role.AGENCY)
                .status(UserStatus.ACTIVE)
                .build();

        agencyPrincipal = new UserPrincipal(agencyUser);

        User driverUser = User.builder()
                .id(driverUserId)
                .email("driver@farm2route.lk")
                .phoneNumber("+94777654321")
                .role(Role.DRIVER)
                .status(UserStatus.ACTIVE)
                .build();

        driverPrincipal = new UserPrincipal(driverUser);

        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(agencyPrincipal, null, agencyPrincipal.getAuthorities())
        );

        driverProfileDto = DriverProfileDto.builder()
                .id(driverId)
                .userId(driverUserId)
                .agencyId(UUID.randomUUID())
                .fullName("John Driver")
                .email("driver@farm2route.lk")
                .phoneNumber("+94777654321")
                .drivingLicenseNumber("B1234567")
                .licenseExpiryDate(LocalDate.of(2028, 12, 31))
                .nicNumber("199012345678")
                .kycStatus(KycStatus.APPROVED)
                .availabilityStatus(DriverAvailability.AVAILABLE)
                .build();
    }

    @Test
    @DisplayName("GET /api/v1/driver/profile returns authenticated driver profile")
    void testGetProfile_Success() throws Exception {
        when(driverService.getProfileByUserId(driverUserId)).thenReturn(driverProfileDto);

        mockMvc.perform(get("/api/v1/driver/profile")
                        .principal(new UsernamePasswordAuthenticationToken(driverPrincipal, null, driverPrincipal.getAuthorities())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.id").value(driverId.toString()))
                .andExpect(jsonPath("$.data.fullName").value("John Driver"));
    }

    @Test
    @DisplayName("PATCH /api/v1/driver/availability updates driver availability")
    void testUpdateAvailability_Success() throws Exception {
        when(driverService.updateAvailability(driverUserId, DriverAvailability.AVAILABLE)).thenReturn(driverProfileDto);

        mockMvc.perform(patch("/api/v1/driver/availability")
                        .param("status", "AVAILABLE")
                        .principal(new UsernamePasswordAuthenticationToken(driverPrincipal, null, driverPrincipal.getAuthorities())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.availabilityStatus").value("AVAILABLE"));
    }

    @Test
    @DisplayName("POST /api/v1/agency/drivers registers a new driver and returns 201 Created")
    void testRegisterDriver_Success() throws Exception {
        RegisterDriverRequest request = RegisterDriverRequest.builder()
                .fullName("John Driver")
                .email("driver@farm2route.lk")
                .phoneNumber("+94777654321")
                .drivingLicenseNumber("B1234567")
                .licenseExpiryDate(LocalDate.of(2028, 12, 31))
                .nicNumber("199012345678")
                .build();

        when(driverService.registerDriver(eq(agencyUserId), any(RegisterDriverRequest.class)))
                .thenReturn(driverProfileDto);

        mockMvc.perform(post("/api/v1/agency/drivers")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request))
                        .principal(new UsernamePasswordAuthenticationToken(agencyPrincipal, null, agencyPrincipal.getAuthorities())))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.id").value(driverId.toString()))
                .andExpect(jsonPath("$.data.drivingLicenseNumber").value("B1234567"));
    }

    @Test
    @DisplayName("GET /api/v1/agency/drivers returns list of agency drivers")
    void testGetAgencyDrivers_Success() throws Exception {
        when(driverService.getAgencyDrivers(agencyUserId)).thenReturn(List.of(driverProfileDto));

        mockMvc.perform(get("/api/v1/agency/drivers")
                        .principal(new UsernamePasswordAuthenticationToken(agencyPrincipal, null, agencyPrincipal.getAuthorities())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].id").value(driverId.toString()));
    }

    @Test
    @DisplayName("GET /api/v1/agency/drivers/available returns list of available agency drivers")
    void testGetAvailableAgencyDrivers_Success() throws Exception {
        when(driverService.getAvailableAgencyDrivers(agencyUserId)).thenReturn(List.of(driverProfileDto));

        mockMvc.perform(get("/api/v1/agency/drivers/available")
                        .principal(new UsernamePasswordAuthenticationToken(agencyPrincipal, null, agencyPrincipal.getAuthorities())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].availabilityStatus").value("AVAILABLE"));
    }

    @Test
    @DisplayName("GET /api/v1/agency/drivers/{id} returns driver details by ID")
    void testGetDriverById_Success() throws Exception {
        when(driverService.getDriverById(driverId, agencyUserId)).thenReturn(driverProfileDto);

        mockMvc.perform(get("/api/v1/agency/drivers/" + driverId)
                        .principal(new UsernamePasswordAuthenticationToken(agencyPrincipal, null, agencyPrincipal.getAuthorities())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.id").value(driverId.toString()));
    }

    @Test
    @DisplayName("PUT /api/v1/agency/drivers/{id} updates driver details")
    void testUpdateDriver_Success() throws Exception {
        UpdateDriverRequest request = UpdateDriverRequest.builder()
                .fullName("John Driver Updated")
                .drivingLicenseNumber("B1234567")
                .availabilityStatus(DriverAvailability.AVAILABLE)
                .build();

        when(driverService.updateDriver(eq(driverId), eq(agencyUserId), any(UpdateDriverRequest.class)))
                .thenReturn(driverProfileDto);

        mockMvc.perform(put("/api/v1/agency/drivers/" + driverId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request))
                        .principal(new UsernamePasswordAuthenticationToken(agencyPrincipal, null, agencyPrincipal.getAuthorities())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.id").value(driverId.toString()));
    }

    @Test
    @DisplayName("DELETE /api/v1/agency/drivers/{id} deletes driver")
    void testDeleteDriver_Success() throws Exception {
        doNothing().when(driverService).deleteDriver(driverId, agencyUserId);

        mockMvc.perform(delete("/api/v1/agency/drivers/" + driverId)
                        .principal(new UsernamePasswordAuthenticationToken(agencyPrincipal, null, agencyPrincipal.getAuthorities())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("Driver deleted successfully"));
    }

    @Test
    @DisplayName("PATCH /api/v1/agency/drivers/{id}/kyc updates driver KYC status")
    void testUpdateDriverKyc_Success() throws Exception {
        UpdateDriverKycRequest request = UpdateDriverKycRequest.builder()
                .kycStatus(KycStatus.APPROVED)
                .build();

        when(driverService.updateDriverKyc(eq(driverId), eq(agencyUserId), any(UpdateDriverKycRequest.class)))
                .thenReturn(driverProfileDto);

        mockMvc.perform(patch("/api/v1/agency/drivers/" + driverId + "/kyc")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request))
                        .principal(new UsernamePasswordAuthenticationToken(agencyPrincipal, null, agencyPrincipal.getAuthorities())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.kycStatus").value("APPROVED"));
    }

    @Test
    @DisplayName("POST /api/v1/agency/drivers/{id}/kyc/document uploads driver KYC document")
    void testUploadDriverKycDocument_Success() throws Exception {
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "kyc.pdf",
                MediaType.APPLICATION_PDF_VALUE,
                "dummy pdf content".getBytes()
        );

        when(driverService.uploadDriverKycDocument(eq(driverId), eq(agencyUserId), any()))
                .thenReturn(driverProfileDto);

        mockMvc.perform(multipart("/api/v1/agency/drivers/" + driverId + "/kyc/document")
                        .file(file)
                        .principal(new UsernamePasswordAuthenticationToken(agencyPrincipal, null, agencyPrincipal.getAuthorities())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.id").value(driverId.toString()));
    }
}
