package com.farm2route.admin.controller;

import com.farm2route.admin.dto.AdminStatsDto;
import com.farm2route.admin.dto.KycApprovalDto;
import com.farm2route.admin.service.AdminService;
import com.farm2route.audit.service.AuditService;
import com.farm2route.auth.entity.User;
import com.farm2route.auth.model.Role;
import com.farm2route.auth.model.UserStatus;
import com.farm2route.common.enums.KycStatus;
import com.farm2route.security.CustomUserPrincipal;
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
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.web.servlet.MockMvc;

import com.farm2route.admin.dto.AgencyKycSummaryDto;
import com.farm2route.admin.dto.DriverKycSummaryDto;
import com.farm2route.admin.dto.VehicleKycSummaryDto;
import com.farm2route.common.enums.VehicleType;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(
        controllers = AdminController.class,
        excludeFilters = @ComponentScan.Filter(
                type = FilterType.ASSIGNABLE_TYPE,
                classes = {JwtAuthenticationFilter.class, RequestCorrelationFilter.class}
        )
)
@AutoConfigureMockMvc(addFilters = false)
class AdminControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private AdminService adminService;

    @MockBean
    private AuditService auditService;

    private CustomUserPrincipal adminPrincipal;
    private UUID vehicleId;

    @BeforeEach
    void setUp() {
        vehicleId = UUID.randomUUID();

        User adminUser = User.builder()
                .id(UUID.randomUUID())
                .email("admin@farm2route.lk")
                .phoneNumber("+94770000000")
                .role(Role.ADMIN)
                .status(UserStatus.ACTIVE)
                .build();

        adminPrincipal = new CustomUserPrincipal(adminUser);

        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(adminPrincipal, null, adminPrincipal.getAuthorities())
        );
    }

    @Test
    @DisplayName("GET /api/v1/admin/stats returns dashboard analytics")
    void testGetStats_Success() throws Exception {
        AdminStatsDto stats = AdminStatsDto.builder()
                .totalUsers(10)
                .totalFarmers(4)
                .totalAgencies(3)
                .totalDrivers(3)
                .pendingKycs(6)
                .activeBookings(5)
                .openIncidents(2)
                .build();

        when(adminService.getDashboardStats()).thenReturn(stats);

        mockMvc.perform(get("/api/v1/admin/stats"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.pendingKycs").value(6))
                .andExpect(jsonPath("$.data.activeBookings").value(5));
    }

    @Test
    @DisplayName("POST /api/v1/admin/kyc/vehicle approves vehicle KYC")
    void testReviewVehicleKyc_Success() throws Exception {
        KycApprovalDto dto = KycApprovalDto.builder()
                .entityId(vehicleId)
                .status(KycStatus.APPROVED)
                .build();

        doNothing().when(adminService).reviewVehicleKyc(any(), any(), any(), any());

        mockMvc.perform(post("/api/v1/admin/kyc/vehicle")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(dto)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("Vehicle KYC reviewed successfully"));
    }

    @Test
    @DisplayName("GET /api/v1/admin/kyc/agencies returns paged agency KYC queue")
    void testGetAgenciesKycQueue_Success() throws Exception {
        AgencyKycSummaryDto agency = AgencyKycSummaryDto.builder()
                .id(UUID.randomUUID())
                .companyName("Express Logistics")
                .contactEmail("contact@express.lk")
                .contactPhone("+94770001111")
                .kycStatus(KycStatus.PENDING)
                .build();

        when(adminService.getAgenciesKycQueue(any(), any()))
                .thenReturn(new PageImpl<>(List.of(agency), PageRequest.of(0, 20), 1));

        mockMvc.perform(get("/api/v1/admin/kyc/agencies"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.content[0].companyName").value("Express Logistics"))
                .andExpect(jsonPath("$.data.content[0].kycStatus").value("PENDING"));
    }

    @Test
    @DisplayName("GET /api/v1/admin/kyc/drivers returns paged driver KYC queue")
    void testGetDriversKycQueue_Success() throws Exception {
        DriverKycSummaryDto driver = DriverKycSummaryDto.builder()
                .id(UUID.randomUUID())
                .driverName("Sunil Perera")
                .phone("+94770002222")
                .licenseNumber("DL-12345")
                .agencyName("Express Logistics")
                .kycStatus(KycStatus.PENDING)
                .build();

        when(adminService.getDriversKycQueue(any(), any()))
                .thenReturn(new PageImpl<>(List.of(driver), PageRequest.of(0, 20), 1));

        mockMvc.perform(get("/api/v1/admin/kyc/drivers"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.content[0].driverName").value("Sunil Perera"))
                .andExpect(jsonPath("$.data.content[0].licenseNumber").value("DL-12345"));
    }

    @Test
    @DisplayName("GET /api/v1/admin/kyc/vehicles returns paged vehicle KYC queue")
    void testGetVehiclesKycQueue_Success() throws Exception {
        VehicleKycSummaryDto vehicle = VehicleKycSummaryDto.builder()
                .id(UUID.randomUUID())
                .registrationNumber("WP-CAB-1234")
                .vehicleType(VehicleType.TRUCK)
                .agencyName("Express Logistics")
                .kycStatus(KycStatus.PENDING_APPROVAL)
                .build();

        when(adminService.getVehiclesKycQueue(any(), any()))
                .thenReturn(new PageImpl<>(List.of(vehicle), PageRequest.of(0, 20), 1));

        mockMvc.perform(get("/api/v1/admin/kyc/vehicles"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.content[0].registrationNumber").value("WP-CAB-1234"))
                .andExpect(jsonPath("$.data.content[0].vehicleType").value("TRUCK"));
    }
}
