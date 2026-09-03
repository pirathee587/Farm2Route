package com.farm2route.farmer.review.controller;

import com.farm2route.auth.entity.User;
import com.farm2route.auth.model.Role;
import com.farm2route.auth.model.UserStatus;
import com.farm2route.common.filter.RequestCorrelationFilter;
import com.farm2route.farmer.review.dto.ReviewResponse;
import com.farm2route.farmer.review.dto.SubmitReviewRequest;
import com.farm2route.farmer.review.dto.UpdateReviewRequest;
import com.farm2route.farmer.review.service.FarmerReviewService;
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

import java.time.Instant;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(
        controllers = FarmerReviewController.class,
        excludeFilters = @ComponentScan.Filter(
                type = FilterType.ASSIGNABLE_TYPE,
                classes = {JwtAuthenticationFilter.class, RequestCorrelationFilter.class}
        )
)
@AutoConfigureMockMvc(addFilters = false)
class FarmerReviewControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private FarmerReviewService farmerReviewService;

    private UUID farmerUserId;
    private UUID bookingId;
    private UUID reviewId;
    private UserPrincipal farmerPrincipal;
    private ReviewResponse reviewResponse;

    @BeforeEach
    void setUp() {
        farmerUserId = UUID.randomUUID();
        bookingId = UUID.randomUUID();
        reviewId = UUID.randomUUID();

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

        reviewResponse = ReviewResponse.builder()
                .id(reviewId)
                .bookingId(bookingId)
                .agencyRating(5)
                .agencyComment("Great service")
                .driverRating(4)
                .driverComment("On time")
                .createdAt(Instant.now())
                .updatedAt(Instant.now())
                .build();
    }

    @Test
    @DisplayName("POST /api/v1/farmer/bookings/{bookingId}/review with valid payload returns 201 Created")
    void submitReview_valid_returnsCreated() throws Exception {
        SubmitReviewRequest request = SubmitReviewRequest.builder()
                .agencyRating(5)
                .agencyComment("Great service")
                .driverRating(4)
                .driverComment("On time")
                .build();

        when(farmerReviewService.submitReview(eq(farmerUserId), eq(bookingId), any(SubmitReviewRequest.class)))
                .thenReturn(reviewResponse);

        mockMvc.perform(post("/api/v1/farmer/bookings/{bookingId}/review", bookingId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.id").value(reviewId.toString()))
                .andExpect(jsonPath("$.data.agencyRating").value(5))
                .andExpect(jsonPath("$.data.driverRating").value(4));
    }

    @Test
    @DisplayName("POST /api/v1/farmer/bookings/{bookingId}/review with agencyRating 0 returns 400 Bad Request")
    void submitReview_invalidAgencyRating_zero_returnsBadRequest() throws Exception {
        SubmitReviewRequest request = SubmitReviewRequest.builder()
                .agencyRating(0)
                .driverRating(4)
                .build();

        mockMvc.perform(post("/api/v1/farmer/bookings/{bookingId}/review", bookingId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("POST /api/v1/farmer/bookings/{bookingId}/review with agencyRating 6 returns 400 Bad Request")
    void submitReview_invalidAgencyRating_six_returnsBadRequest() throws Exception {
        SubmitReviewRequest request = SubmitReviewRequest.builder()
                .agencyRating(6)
                .driverRating(4)
                .build();

        mockMvc.perform(post("/api/v1/farmer/bookings/{bookingId}/review", bookingId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("POST /api/v1/farmer/bookings/{bookingId}/review with driverRating -1 returns 400 Bad Request")
    void submitReview_invalidDriverRating_negative_returnsBadRequest() throws Exception {
        SubmitReviewRequest request = SubmitReviewRequest.builder()
                .agencyRating(5)
                .driverRating(-1)
                .build();

        mockMvc.perform(post("/api/v1/farmer/bookings/{bookingId}/review", bookingId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("POST /api/v1/farmer/bookings/{bookingId}/review with comment exceeding 1000 characters returns 400 Bad Request")
    void submitReview_commentTooLong_returnsBadRequest() throws Exception {
        SubmitReviewRequest request = SubmitReviewRequest.builder()
                .agencyRating(5)
                .agencyComment("A".repeat(1001))
                .driverRating(4)
                .build();

        mockMvc.perform(post("/api/v1/farmer/bookings/{bookingId}/review", bookingId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("POST /api/v1/farmer/bookings/{bookingId}/review with optional null driverRating returns 201 Created")
    void submitReview_nullDriverRating_allowed() throws Exception {
        SubmitReviewRequest request = SubmitReviewRequest.builder()
                .agencyRating(5)
                .agencyComment("Great service")
                .driverRating(null)
                .driverComment(null)
                .build();

        reviewResponse.setDriverRating(null);
        reviewResponse.setDriverComment(null);

        when(farmerReviewService.submitReview(eq(farmerUserId), eq(bookingId), any(SubmitReviewRequest.class)))
                .thenReturn(reviewResponse);

        mockMvc.perform(post("/api/v1/farmer/bookings/{bookingId}/review", bookingId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.agencyRating").value(5));
    }

    @Test
    @DisplayName("PUT /api/v1/farmer/bookings/{bookingId}/review with valid payload returns 200 OK")
    void updateReview_valid_returnsOk() throws Exception {
        UpdateReviewRequest request = UpdateReviewRequest.builder()
                .agencyRating(4)
                .agencyComment("Updated feedback")
                .driverRating(5)
                .driverComment("Driver was great")
                .build();

        reviewResponse.setAgencyRating(4);
        reviewResponse.setAgencyComment("Updated feedback");

        when(farmerReviewService.updateReview(eq(farmerUserId), eq(bookingId), any(UpdateReviewRequest.class)))
                .thenReturn(reviewResponse);

        mockMvc.perform(put("/api/v1/farmer/bookings/{bookingId}/review", bookingId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.agencyRating").value(4));
    }

    @Test
    @DisplayName("GET /api/v1/farmer/bookings/{bookingId}/review returns 200 OK with review")
    void getReview_returnsOk() throws Exception {
        when(farmerReviewService.getReview(farmerUserId, bookingId)).thenReturn(reviewResponse);

        mockMvc.perform(get("/api/v1/farmer/bookings/{bookingId}/review", bookingId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.id").value(reviewId.toString()))
                .andExpect(jsonPath("$.data.agencyRating").value(5));
    }
}
