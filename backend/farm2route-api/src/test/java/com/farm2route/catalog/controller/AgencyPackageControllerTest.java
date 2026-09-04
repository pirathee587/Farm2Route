package com.farm2route.catalog.controller;

import com.farm2route.auth.entity.User;
import com.farm2route.auth.model.Role;
import com.farm2route.auth.model.UserStatus;
import com.farm2route.catalog.dto.CreatePackageRequest;
import com.farm2route.catalog.dto.PackageResponse;
import com.farm2route.catalog.dto.UpdatePackageRequest;
import com.farm2route.catalog.service.PackageService;
import com.farm2route.common.enums.PackageType;
import com.farm2route.common.filter.RequestCorrelationFilter;
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
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
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
        controllers = AgencyPackageController.class,
        excludeFilters = @ComponentScan.Filter(
                type = FilterType.ASSIGNABLE_TYPE,
                classes = {JwtAuthenticationFilter.class, RequestCorrelationFilter.class}
        )
)
@AutoConfigureMockMvc(addFilters = false)
class AgencyPackageControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private PackageService packageService;

    private UUID agencyUserId;
    private UUID packageId;
    private UserPrincipal agencyPrincipal;
    private PackageResponse packageResponse;

    @BeforeEach
    void setUp() {
        agencyUserId = UUID.randomUUID();
        packageId = UUID.randomUUID();

        User agencyUser = User.builder()
                .id(agencyUserId)
                .email("agency@farm2route.lk")
                .phoneNumber("+94771234567")
                .role(Role.AGENCY)
                .status(UserStatus.ACTIVE)
                .build();

        agencyPrincipal = new UserPrincipal(agencyUser);

        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(agencyPrincipal, null, agencyPrincipal.getAuthorities())
        );

        packageResponse = PackageResponse.builder()
                .id(packageId)
                .agencyId(UUID.randomUUID())
                .agencyName("Green Route Logistics")
                .title("Standard Vegetable Transport")
                .description("Daily vegetable route")
                .packageType(PackageType.WEIGHT_BASED)
                .basePrice(new BigDecimal("1500.00"))
                .pricePerKm(new BigDecimal("50.00"))
                .pricePerKg(new BigDecimal("10.00"))
                .maxWeightKg(new BigDecimal("1000.00"))
                .routeOrigin("Dambulla")
                .routeDestination("Colombo")
                .scheduleDays(List.of("MONDAY", "WEDNESDAY", "FRIDAY"))
                .isActive(true)
                .build();
    }

    @Test
    @DisplayName("POST /api/v1/agency/packages creates package and returns 201 Created")
    void testCreatePackage_Success() throws Exception {
        CreatePackageRequest request = CreatePackageRequest.builder()
                .title("Standard Vegetable Transport")
                .description("Daily vegetable route")
                .packageType(PackageType.WEIGHT_BASED)
                .basePrice(new BigDecimal("1500.00"))
                .pricePerKm(new BigDecimal("50.00"))
                .pricePerKg(new BigDecimal("10.00"))
                .maxWeightKg(new BigDecimal("1000.00"))
                .routeOrigin("Dambulla")
                .routeDestination("Colombo")
                .scheduleDays(List.of("MONDAY", "WEDNESDAY", "FRIDAY"))
                .build();

        when(packageService.createPackage(eq(agencyUserId), any(CreatePackageRequest.class)))
                .thenReturn(packageResponse);

        mockMvc.perform(post("/api/v1/agency/packages")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request))
                        .principal(new UsernamePasswordAuthenticationToken(agencyPrincipal, null, agencyPrincipal.getAuthorities())))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.id").value(packageId.toString()))
                .andExpect(jsonPath("$.data.title").value("Standard Vegetable Transport"));
    }

    @Test
    @DisplayName("GET /api/v1/agency/packages returns list of agency packages")
    void testGetAgencyPackages_Success() throws Exception {
        when(packageService.getAgencyPackages(agencyUserId)).thenReturn(List.of(packageResponse));

        mockMvc.perform(get("/api/v1/agency/packages")
                        .principal(new UsernamePasswordAuthenticationToken(agencyPrincipal, null, agencyPrincipal.getAuthorities())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].id").value(packageId.toString()));
    }

    @Test
    @DisplayName("GET /api/v1/agency/packages/{id} returns package details by ID")
    void testGetPackageById_Success() throws Exception {
        when(packageService.getAgencyPackageById(packageId, agencyUserId)).thenReturn(packageResponse);

        mockMvc.perform(get("/api/v1/agency/packages/" + packageId)
                        .principal(new UsernamePasswordAuthenticationToken(agencyPrincipal, null, agencyPrincipal.getAuthorities())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.id").value(packageId.toString()));
    }

    @Test
    @DisplayName("PUT /api/v1/agency/packages/{id} updates package details")
    void testUpdatePackage_Success() throws Exception {
        UpdatePackageRequest request = UpdatePackageRequest.builder()
                .title("Updated Express Transport")
                .basePrice(new BigDecimal("2000.00"))
                .build();

        when(packageService.updatePackage(eq(packageId), eq(agencyUserId), any(UpdatePackageRequest.class)))
                .thenReturn(packageResponse);

        mockMvc.perform(put("/api/v1/agency/packages/" + packageId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request))
                        .principal(new UsernamePasswordAuthenticationToken(agencyPrincipal, null, agencyPrincipal.getAuthorities())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.id").value(packageId.toString()));
    }

    @Test
    @DisplayName("DELETE /api/v1/agency/packages/{id} deletes package")
    void testDeletePackage_Success() throws Exception {
        doNothing().when(packageService).deletePackage(packageId, agencyUserId);

        mockMvc.perform(delete("/api/v1/agency/packages/" + packageId)
                        .principal(new UsernamePasswordAuthenticationToken(agencyPrincipal, null, agencyPrincipal.getAuthorities())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("Package deleted successfully"));
    }
}
