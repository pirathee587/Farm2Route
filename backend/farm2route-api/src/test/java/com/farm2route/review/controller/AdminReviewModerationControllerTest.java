package com.farm2route.review.controller;

import com.farm2route.auth.entity.User;
import com.farm2route.auth.model.Role;
import com.farm2route.auth.model.UserStatus;
import com.farm2route.common.filter.RequestCorrelationFilter;
import com.farm2route.review.dto.AdminReviewDto;
import com.farm2route.review.dto.ModerateReviewRequest;
import com.farm2route.review.service.ReviewModerationService;
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
        controllers = AdminReviewModerationController.class,
        excludeFilters = @ComponentScan.Filter(
                type = FilterType.ASSIGNABLE_TYPE,
                classes = {JwtAuthenticationFilter.class, RequestCorrelationFilter.class}
        )
)
@AutoConfigureMockMvc(addFilters = false)
class AdminReviewModerationControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private ReviewModerationService reviewModerationService;

    private UUID reviewId;
    private CustomUserPrincipal adminPrincipal;

    @BeforeEach
    void setUp() {
        reviewId = UUID.randomUUID();

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
    @DisplayName("GET /api/v1/admin/reviews/reported returns list of reported reviews")
    void testGetReportedReviews_Success() throws Exception {
        AdminReviewDto dto = AdminReviewDto.builder()
                .id(reviewId)
                .comment("Inappropriate comment")
                .moderationStatus("PENDING_REVIEW")
                .build();

        when(reviewModerationService.getReportedReviews(any()))
                .thenReturn(new PageImpl<>(List.of(dto)));

        mockMvc.perform(get("/api/v1/admin/reviews/reported"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.content[0].moderationStatus").value("PENDING_REVIEW"));
    }

    @Test
    @DisplayName("POST /api/v1/admin/reviews/{id}/hide hides review")
    void testHideReview_Success() throws Exception {
        ModerateReviewRequest request = ModerateReviewRequest.builder()
                .reason("Inappropriate language")
                .build();

        AdminReviewDto dto = AdminReviewDto.builder()
                .id(reviewId)
                .moderationStatus("HIDDEN")
                .build();

        when(reviewModerationService.hide(eq(reviewId), any(), any())).thenReturn(dto);

        mockMvc.perform(post("/api/v1/admin/reviews/{id}/hide", reviewId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.moderationStatus").value("HIDDEN"));
    }

    @Test
    @DisplayName("POST /api/v1/admin/reviews/{id}/restore restores review")
    void testRestoreReview_Success() throws Exception {
        AdminReviewDto dto = AdminReviewDto.builder()
                .id(reviewId)
                .moderationStatus("APPROVED")
                .build();

        when(reviewModerationService.restore(eq(reviewId), any())).thenReturn(dto);

        mockMvc.perform(post("/api/v1/admin/reviews/{id}/restore", reviewId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.moderationStatus").value("APPROVED"));
    }

    @Test
    @DisplayName("POST /api/v1/admin/reviews/{id}/escalate escalates review")
    void testEscalateReview_Success() throws Exception {
        ModerateReviewRequest request = ModerateReviewRequest.builder()
                .reason("Flagged for manual audit")
                .build();

        AdminReviewDto dto = AdminReviewDto.builder()
                .id(reviewId)
                .moderationStatus("PENDING_REVIEW")
                .build();

        when(reviewModerationService.escalate(eq(reviewId), any(), any())).thenReturn(dto);

        mockMvc.perform(post("/api/v1/admin/reviews/{id}/escalate", reviewId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.moderationStatus").value("PENDING_REVIEW"));
    }
}
