package com.farm2route.agency.review.controller;

import com.farm2route.agency.review.dto.AgencyReviewResponse;
import com.farm2route.agency.review.dto.AgencyReviewResponseRequest;
import com.farm2route.agency.review.service.AgencyReviewService;
import com.farm2route.common.response.ApiResponse;
import com.farm2route.security.UserPrincipal;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/agency")
@RequiredArgsConstructor
@PreAuthorize("hasRole('AGENCY')")
@SecurityRequirement(name = "BearerAuth")
@Tag(name = "Agency Reviews")
public class AgencyReviewController {
    private final AgencyReviewService agencyReviewService;

    @GetMapping("/reviews")
    public ResponseEntity<ApiResponse<List<AgencyReviewResponse>>> list(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam(required = false) Integer rating,
            @RequestParam(required = false) UUID bookingId,
            @RequestParam(required = false) UUID driverId,
            @RequestParam(required = false) String moderationStatus,
            HttpServletRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(agencyReviewService.list(principal.getId(), rating, bookingId, driverId,
                        moderationStatus), "Agency reviews retrieved successfully", request.getRequestURI()));
    }

    @GetMapping("/drivers/{driverId}/reviews")
    public ResponseEntity<ApiResponse<List<AgencyReviewResponse>>> driverReviews(
            @AuthenticationPrincipal UserPrincipal principal, @PathVariable UUID driverId, HttpServletRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(agencyReviewService.listDriverReviews(principal.getId(), driverId),
                "Driver reviews retrieved successfully", request.getRequestURI()));
    }

    @PutMapping("/reviews/{reviewId}/response")
    public ResponseEntity<ApiResponse<AgencyReviewResponse>> respond(
            @AuthenticationPrincipal UserPrincipal principal, @PathVariable UUID reviewId,
            @Valid @RequestBody AgencyReviewResponseRequest body, HttpServletRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(agencyReviewService.respond(principal.getId(), reviewId, body),
                "Agency response saved successfully", request.getRequestURI()));
    }
}
