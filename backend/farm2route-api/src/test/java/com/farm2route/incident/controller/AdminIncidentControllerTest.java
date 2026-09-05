package com.farm2route.incident.controller;

import com.farm2route.auth.entity.User;
import com.farm2route.auth.model.Role;
import com.farm2route.auth.model.UserStatus;
import com.farm2route.common.enums.IncidentStatus;
import com.farm2route.common.enums.IncidentType;
import com.farm2route.common.filter.RequestCorrelationFilter;
import com.farm2route.incident.dto.AddInvestigationNoteRequest;
import com.farm2route.incident.dto.AdminIncidentDetailDto;
import com.farm2route.incident.dto.EscalateIncidentRequest;
import com.farm2route.incident.dto.ResolveIncidentRequest;
import com.farm2route.incident.service.AdminIncidentService;
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
import org.springframework.data.domain.PageImpl;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(
        controllers = AdminIncidentController.class,
        excludeFilters = @ComponentScan.Filter(
                type = FilterType.ASSIGNABLE_TYPE,
                classes = {JwtAuthenticationFilter.class, RequestCorrelationFilter.class}
        )
)
@AutoConfigureMockMvc(addFilters = false)
class AdminIncidentControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private AdminIncidentService adminIncidentService;

    private UUID incidentId;
    private CustomUserPrincipal adminPrincipal;

    @BeforeEach
    void setUp() {
        incidentId = UUID.randomUUID();

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
    @DisplayName("GET /api/v1/admin/incidents returns paged search results")
    void testSearchIncidents_Success() throws Exception {
        AdminIncidentDetailDto dto = AdminIncidentDetailDto.builder()
                .id(incidentId)
                .incidentType(IncidentType.CARGO_DAMAGE)
                .title("Damaged cargo")
                .status(IncidentStatus.OPEN)
                .build();

        when(adminIncidentService.search(any(), any(), any(), any(), any()))
                .thenReturn(new PageImpl<>(List.of(dto)));

        mockMvc.perform(get("/api/v1/admin/incidents"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.content[0].title").value("Damaged cargo"));
    }

    @Test
    @DisplayName("GET /api/v1/admin/incidents/{id} returns joined incident detail")
    void testGetIncidentDetail_Success() throws Exception {
        AdminIncidentDetailDto dto = AdminIncidentDetailDto.builder()
                .id(incidentId)
                .incidentType(IncidentType.DELAY)
                .title("Delay in delivery")
                .status(IncidentStatus.INVESTIGATING)
                .build();

        when(adminIncidentService.getDetail(eq(incidentId))).thenReturn(dto);

        mockMvc.perform(get("/api/v1/admin/incidents/{id}", incidentId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("INVESTIGATING"));
    }

    @Test
    @DisplayName("POST /api/v1/admin/incidents/{id}/notes adds investigation note")
    void testAddInvestigationNote_Success() throws Exception {
        AddInvestigationNoteRequest request = AddInvestigationNoteRequest.builder()
                .note("Contacted driver to obtain GPS log")
                .build();

        AdminIncidentDetailDto dto = AdminIncidentDetailDto.builder()
                .id(incidentId)
                .status(IncidentStatus.INVESTIGATING)
                .investigationNotes("Contacted driver to obtain GPS log")
                .build();

        when(adminIncidentService.addInvestigationNote(eq(incidentId), any(), any())).thenReturn(dto);

        mockMvc.perform(post("/api/v1/admin/incidents/{id}/notes", incidentId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("Investigation note added successfully"));
    }

    @Test
    @DisplayName("POST /api/v1/admin/incidents/{id}/resolve records resolution decision")
    void testResolveIncident_Success() throws Exception {
        ResolveIncidentRequest request = ResolveIncidentRequest.builder()
                .status(IncidentStatus.RESOLVED)
                .notes("Claim verified and approved")
                .refundAmount(BigDecimal.valueOf(5000.00))
                .build();

        AdminIncidentDetailDto dto = AdminIncidentDetailDto.builder()
                .id(incidentId)
                .status(IncidentStatus.RESOLVED)
                .resolutionOutcome("Claim verified and approved")
                .refundAmount(BigDecimal.valueOf(5000.00))
                .build();

        when(adminIncidentService.resolve(eq(incidentId), any(), any())).thenReturn(dto);

        mockMvc.perform(post("/api/v1/admin/incidents/{id}/resolve", incidentId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("RESOLVED"));
    }

    @Test
    @DisplayName("POST /api/v1/admin/incidents/{id}/escalate escalates incident")
    void testEscalateIncident_Success() throws Exception {
        EscalateIncidentRequest request = EscalateIncidentRequest.builder()
                .notes("Requires senior management review")
                .build();

        AdminIncidentDetailDto dto = AdminIncidentDetailDto.builder()
                .id(incidentId)
                .status(IncidentStatus.INVESTIGATING)
                .investigationNotes("ESCALATED: Requires senior management review")
                .build();

        when(adminIncidentService.escalate(eq(incidentId), any(), any())).thenReturn(dto);

        mockMvc.perform(post("/api/v1/admin/incidents/{id}/escalate", incidentId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("Incident escalated successfully"));
    }
}
