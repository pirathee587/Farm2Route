package com.farm2route.incident.controller;

import com.farm2route.auth.entity.User;
import com.farm2route.auth.model.Role;
import com.farm2route.auth.model.UserStatus;
import com.farm2route.common.enums.IncidentStatus;
import com.farm2route.common.enums.IncidentType;
import com.farm2route.common.filter.RequestCorrelationFilter;
import com.farm2route.incident.dto.IncidentResponse;
import com.farm2route.incident.dto.SubmitIncidentRequest;
import com.farm2route.incident.service.IncidentService;
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
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(
        controllers = FarmerIncidentController.class,
        excludeFilters = @ComponentScan.Filter(
                type = FilterType.ASSIGNABLE_TYPE,
                classes = {JwtAuthenticationFilter.class, RequestCorrelationFilter.class}
        )
)
@AutoConfigureMockMvc(addFilters = false)
class FarmerIncidentControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private IncidentService incidentService;

    private UUID farmerUserId;
    private UUID incidentId;
    private UUID bookingId;
    private UserPrincipal farmerPrincipal;
    private IncidentResponse incidentResponse;

    @BeforeEach
    void setUp() {
        farmerUserId = UUID.randomUUID();
        incidentId = UUID.randomUUID();
        bookingId = UUID.randomUUID();

        User user = User.builder()
                .id(farmerUserId)
                .email("farmer@farm2route.lk")
                .phoneNumber("+94771234567")
                .role(Role.FARMER)
                .status(UserStatus.ACTIVE)
                .build();

        farmerPrincipal = new UserPrincipal(user);

        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(farmerPrincipal, null, farmerPrincipal.getAuthorities())
        );

        incidentResponse = IncidentResponse.builder()
                .id(incidentId)
                .bookingId(bookingId)
                .bookingNumber("F2R-1001-2026")
                .route("Kurunegala -> Colombo")
                .cargoType("Tomatoes")
                .incidentType(IncidentType.CROP_DAMAGE)
                .title("Damaged cargo")
                .description("Produce damaged due to rough driving")
                .status(IncidentStatus.OPEN)
                .evidencePhotoUrls(List.of("https://storage.supabase.co/damage.jpg"))
                .createdAt(Instant.now())
                .build();
    }

    @Test
    @DisplayName("POST /api/v1/farmer/incidents submits an incident and returns 201 Created")
    void testSubmitIncident_Success() throws Exception {
        SubmitIncidentRequest request = SubmitIncidentRequest.builder()
                .bookingId(bookingId)
                .incidentType(IncidentType.CROP_DAMAGE)
                .title("Damaged cargo")
                .description("Produce damaged due to rough driving")
                .build();

        MockMultipartFile requestPart = new MockMultipartFile(
                "request",
                "",
                MediaType.APPLICATION_JSON_VALUE,
                objectMapper.writeValueAsBytes(request)
        );

        MockMultipartFile filePart = new MockMultipartFile(
                "evidencePhotos",
                "evidence.jpg",
                MediaType.IMAGE_JPEG_VALUE,
                new byte[]{1, 2, 3}
        );

        when(incidentService.submitIncident(eq(farmerUserId), any(SubmitIncidentRequest.class), any()))
                .thenReturn(incidentResponse);

        mockMvc.perform(multipart("/api/v1/farmer/incidents")
                        .file(requestPart)
                        .file(filePart)
                        .principal(new UsernamePasswordAuthenticationToken(farmerPrincipal, null, farmerPrincipal.getAuthorities())))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.id").value(incidentId.toString()))
                .andExpect(jsonPath("$.data.status").value("OPEN"))
                .andExpect(jsonPath("$.data.bookingNumber").value("F2R-1001-2026"));
    }

    @Test
    @DisplayName("GET /api/v1/farmer/incidents returns paginated list of farmer incidents")
    void testGetFarmerIncidents_Success() throws Exception {
        when(incidentService.getFarmerIncidents(eq(farmerUserId), any(), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of(incidentResponse)));

        mockMvc.perform(get("/api/v1/farmer/incidents")
                        .principal(new UsernamePasswordAuthenticationToken(farmerPrincipal, null, farmerPrincipal.getAuthorities())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.content[0].id").value(incidentId.toString()))
                .andExpect(jsonPath("$.data.content[0].incidentType").value("CROP_DAMAGE"));
    }

    @Test
    @DisplayName("GET /api/v1/farmer/incidents/{id} returns single incident response")
    void testGetIncidentById_Success() throws Exception {
        when(incidentService.getIncidentById(farmerUserId, incidentId))
                .thenReturn(incidentResponse);

        mockMvc.perform(get("/api/v1/farmer/incidents/" + incidentId)
                        .principal(new UsernamePasswordAuthenticationToken(farmerPrincipal, null, farmerPrincipal.getAuthorities())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.id").value(incidentId.toString()))
                .andExpect(jsonPath("$.data.route").value("Kurunegala -> Colombo"));
    }
}
