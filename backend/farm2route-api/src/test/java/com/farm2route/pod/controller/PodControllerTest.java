package com.farm2route.pod.controller;

import com.farm2route.auth.entity.User;
import com.farm2route.auth.model.Role;
import com.farm2route.auth.model.UserStatus;
import com.farm2route.common.enums.PodConfirmationStatus;
import com.farm2route.common.filter.RequestCorrelationFilter;
import com.farm2route.pod.dto.ConfirmPodRequest;
import com.farm2route.pod.dto.PodDto;
import com.farm2route.pod.dto.SubmitPodRequest;
import com.farm2route.pod.service.PodService;
import com.farm2route.security.CustomUserPrincipal;
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
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(
        controllers = PodController.class,
        excludeFilters = @ComponentScan.Filter(
                type = FilterType.ASSIGNABLE_TYPE,
                classes = {JwtAuthenticationFilter.class, RequestCorrelationFilter.class}
        )
)
@AutoConfigureMockMvc(addFilters = false)
class PodControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private PodService podService;

    private UUID bookingId;
    private CustomUserPrincipal driverPrincipal;

    @BeforeEach
    void setUp() {
        bookingId = UUID.randomUUID();

        User driverUser = User.builder()
                .id(UUID.randomUUID())
                .email("driver@farm2route.lk")
                .phoneNumber("+94772222222")
                .role(Role.DRIVER)
                .status(UserStatus.ACTIVE)
                .build();

        driverPrincipal = new CustomUserPrincipal(driverUser);

        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(driverPrincipal, null, driverPrincipal.getAuthorities())
        );
    }

    @Test
    @DisplayName("POST /api/v1/bookings/{bookingId}/pod submits POD with multipart files")
    void testSubmitPod_Success() throws Exception {
        SubmitPodRequest submitReq = SubmitPodRequest.builder()
                .recipientName("Kamal Perera")
                .recipientPhone("+94770001111")
                .deliveryLatitude(BigDecimal.valueOf(6.9271))
                .deliveryLongitude(BigDecimal.valueOf(79.8612))
                .build();

        MockMultipartFile dataFile = new MockMultipartFile(
                "data", "", MediaType.APPLICATION_JSON_VALUE,
                objectMapper.writeValueAsBytes(submitReq)
        );
        MockMultipartFile signatureFile = new MockMultipartFile("signature", "sign.png", "image/png", "sig".getBytes());
        MockMultipartFile photoFile = new MockMultipartFile("photo", "photo.jpg", "image/jpeg", "photo".getBytes());

        PodDto responseDto = PodDto.builder()
                .id(UUID.randomUUID())
                .bookingId(bookingId)
                .recipientName("Kamal Perera")
                .farmerConfirmationStatus(PodConfirmationStatus.PENDING)
                .build();

        when(podService.submit(eq(bookingId), any(), any(), any(), any())).thenReturn(responseDto);

        mockMvc.perform(multipart("/api/v1/bookings/{bookingId}/pod", bookingId)
                        .file(dataFile)
                        .file(signatureFile)
                        .file(photoFile))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.recipientName").value("Kamal Perera"));
    }

    @Test
    @DisplayName("GET /api/v1/bookings/{bookingId}/pod returns POD record")
    void testGetPod_Success() throws Exception {
        PodDto responseDto = PodDto.builder()
                .id(UUID.randomUUID())
                .bookingId(bookingId)
                .farmerConfirmationStatus(PodConfirmationStatus.PENDING)
                .build();

        when(podService.getPodByBookingId(eq(bookingId), any(), any())).thenReturn(responseDto);

        mockMvc.perform(get("/api/v1/bookings/{bookingId}/pod", bookingId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.farmerConfirmationStatus").value("PENDING"));
    }

    @Test
    @DisplayName("POST /api/v1/bookings/{bookingId}/pod/confirm confirms POD record")
    void testConfirmPod_Success() throws Exception {
        ConfirmPodRequest request = ConfirmPodRequest.builder()
                .status(PodConfirmationStatus.CONFIRMED)
                .notes("Goods received intact")
                .build();

        PodDto responseDto = PodDto.builder()
                .id(UUID.randomUUID())
                .bookingId(bookingId)
                .farmerConfirmationStatus(PodConfirmationStatus.CONFIRMED)
                .build();

        when(podService.confirm(eq(bookingId), any(), any())).thenReturn(responseDto);

        mockMvc.perform(post("/api/v1/bookings/{bookingId}/pod/confirm", bookingId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.farmerConfirmationStatus").value("CONFIRMED"));
    }
}
