package com.farm2route.tracking.controller;

import com.farm2route.common.filter.RequestCorrelationFilter;
import com.farm2route.security.CustomUserPrincipal;
import com.farm2route.security.JwtAuthenticationFilter;

import com.farm2route.auth.entity.User;
import com.farm2route.auth.model.Role;
import com.farm2route.auth.model.UserStatus;
import com.farm2route.tracking.dto.GpsLocationDto;
import com.farm2route.tracking.dto.TripLocationResponse;
import com.farm2route.tracking.service.TrackingService;
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
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(
        controllers = TrackingController.class,
        excludeFilters = @ComponentScan.Filter(
                type = FilterType.ASSIGNABLE_TYPE,
                classes = {JwtAuthenticationFilter.class, RequestCorrelationFilter.class}
        )
)
@AutoConfigureMockMvc(addFilters = false)
class TrackingControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private TrackingService trackingService;

    private UUID tripId;
    private UUID farmerUserId;
    private CustomUserPrincipal farmerPrincipal;

    @BeforeEach
    void setUp() {
        tripId = UUID.randomUUID();
        farmerUserId = UUID.randomUUID();

        User farmerUser = User.builder()
                .id(farmerUserId)
                .email("farmer@farm2route.lk")
                .phoneNumber("+94771111111")
                .role(Role.FARMER)
                .status(UserStatus.ACTIVE)
                .build();

        farmerPrincipal = new CustomUserPrincipal(farmerUser);

        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(farmerPrincipal, null, farmerPrincipal.getAuthorities())
        );
    }

    @Test
    @DisplayName("GET /api/v1/tracking/{tripId}/latest returns latest GPS location and ETA")
    void testGetLatestLocation_Success() throws Exception {
        GpsLocationDto locationDto = GpsLocationDto.builder()
                .tripId(tripId)
                .latitude(BigDecimal.valueOf(6.9271))
                .longitude(BigDecimal.valueOf(79.8612))
                .speedKmh(BigDecimal.valueOf(45.0))
                .timestamp(Instant.now())
                .build();

        TripLocationResponse response = TripLocationResponse.builder()
                .latestLocation(locationDto)
                .remainingDistanceKm(BigDecimal.valueOf(5.20))
                .estimatedMinutesRemaining(8)
                .arrivedAtDelivery(false)
                .build();

        when(trackingService.getLatestLocation(eq(tripId), any(), any())).thenReturn(response);

        mockMvc.perform(get("/api/v1/tracking/{tripId}/latest", tripId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.remainingDistanceKm").value(5.20))
                .andExpect(jsonPath("$.data.estimatedMinutesRemaining").value(8))
                .andExpect(jsonPath("$.data.arrivedAtDelivery").value(false));
    }

    @Test
    @DisplayName("GET /api/v1/tracking/{tripId}/history returns list of GPS telemetry points")
    void testGetRouteHistory_Success() throws Exception {
        GpsLocationDto p1 = GpsLocationDto.builder()
                .tripId(tripId)
                .latitude(BigDecimal.valueOf(6.9000))
                .longitude(BigDecimal.valueOf(79.8500))
                .timestamp(Instant.now().minusSeconds(120))
                .build();

        GpsLocationDto p2 = GpsLocationDto.builder()
                .tripId(tripId)
                .latitude(BigDecimal.valueOf(6.9100))
                .longitude(BigDecimal.valueOf(79.8550))
                .timestamp(Instant.now().minusSeconds(60))
                .build();

        when(trackingService.getRouteHistory(eq(tripId), any(), any(), any(), any()))
                .thenReturn(List.of(p1, p2));

        mockMvc.perform(get("/api/v1/tracking/{tripId}/history", tripId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.length()").value(2))
                .andExpect(jsonPath("$.data[0].latitude").value(6.9000))
                .andExpect(jsonPath("$.data[1].latitude").value(6.9100));
    }
}
