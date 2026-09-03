package com.farm2route.farmer.review.controller;

import com.farm2route.auth.entity.User;
import com.farm2route.common.exception.UnauthorizedException;
import com.farm2route.common.response.ApiResponse;
import com.farm2route.farmer.review.dto.ReviewResponse;
import com.farm2route.farmer.review.dto.SubmitReviewRequest;
import com.farm2route.farmer.review.dto.UpdateReviewRequest;
import com.farm2route.farmer.review.service.FarmerReviewService;
import com.farm2route.security.CustomUserPrincipal;
import com.farm2route.security.UserPrincipal;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@Slf4j
@RestController
@RequestMapping({"/api/v1/farmer/bookings/{bookingId}/review", "/api/farmer/bookings/{bookingId}/review"})
@RequiredArgsConstructor
@Tag(name = "Farmer Review Operations", description = "Endpoints for farmers to submit, edit, and retrieve reviews for completed transport bookings")
@SecurityRequirement(name = "BearerAuth")
public class FarmerReviewController {

    private final FarmerReviewService farmerReviewService;

    @PostMapping
    @PreAuthorize("hasRole('FARMER')")
    @Operation(summary = "Submit Booking Review", description = "Submits a review with ratings and comments for the agency and optional driver on a delivered booking")
    public ResponseEntity<ApiResponse<ReviewResponse>> submitReview(
            @AuthenticationPrincipal Object principal,
            @PathVariable UUID bookingId,
            @Valid @RequestBody SubmitReviewRequest request,
            HttpServletRequest servletRequest) {

        UUID farmerUserId = extractFarmerId(principal);
        ReviewResponse response = farmerReviewService.submitReview(farmerUserId, bookingId, request);

        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.created(response, "Review submitted successfully", servletRequest.getRequestURI()));
    }

    @PutMapping
    @PreAuthorize("hasRole('FARMER')")
    @Operation(summary = "Edit Booking Review", description = "Updates an existing review previously submitted by the authenticated farmer")
    public ResponseEntity<ApiResponse<ReviewResponse>> updateReview(
            @AuthenticationPrincipal Object principal,
            @PathVariable UUID bookingId,
            @Valid @RequestBody UpdateReviewRequest request,
            HttpServletRequest servletRequest) {

        UUID farmerUserId = extractFarmerId(principal);
        ReviewResponse response = farmerReviewService.updateReview(farmerUserId, bookingId, request);

        return ResponseEntity.ok(ApiResponse.ok(response, "Review updated successfully", servletRequest.getRequestURI()));
    }

    @GetMapping
    @PreAuthorize("hasRole('FARMER')")
    @Operation(summary = "Get Booking Review", description = "Retrieves the review submitted for the specified booking if owned by the authenticated farmer")
    public ResponseEntity<ApiResponse<ReviewResponse>> getReview(
            @AuthenticationPrincipal Object principal,
            @PathVariable UUID bookingId,
            HttpServletRequest servletRequest) {

        UUID farmerUserId = extractFarmerId(principal);
        ReviewResponse response = farmerReviewService.getReview(farmerUserId, bookingId);

        return ResponseEntity.ok(ApiResponse.ok(response, "Review retrieved successfully", servletRequest.getRequestURI()));
    }

    private UUID extractFarmerId(Object principal) {
        if (principal instanceof UserPrincipal userPrincipal) {
            return userPrincipal.getId();
        } else if (principal instanceof CustomUserPrincipal customUserPrincipal) {
            return customUserPrincipal.getId();
        } else if (principal instanceof User user) {
            return user.getId();
        }
        throw new UnauthorizedException("Unable to extract farmer ID from principal");
    }
}
