package com.farm2route.review.controller;

import com.farm2route.common.response.ApiResponse;
import com.farm2route.review.dto.AdminReviewDto;
import com.farm2route.review.dto.ModerateReviewRequest;
import com.farm2route.review.service.ReviewModerationService;
import com.farm2route.security.CustomUserPrincipal;
import com.farm2route.security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;

@Slf4j
@RestController
@RequestMapping("/api/v1/admin/reviews")
@PreAuthorize("hasRole('ADMIN')")
@RequiredArgsConstructor
@Tag(name = "Admin Review Moderation", description = "Endpoints for administrator review inspection, hiding, restoring, and escalating")
@SecurityRequirement(name = "BearerAuth")
public class AdminReviewModerationController {

    private final ReviewModerationService reviewModerationService;

    @GetMapping("/reported")
    @Operation(summary = "Get Reported Reviews", description = "Retrieves paginated list of reviews requiring administrative moderation")
    public ResponseEntity<ApiResponse<Page<AdminReviewDto>>> getReportedReviews(
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {

        Page<AdminReviewDto> reported = reviewModerationService.getReportedReviews(pageable);
        return ResponseEntity.ok(ApiResponse.success(reported));
    }

    @PostMapping("/{id}/hide")
    @Operation(summary = "Hide Review", description = "Hides an inappropriate review from public display")
    public ResponseEntity<ApiResponse<AdminReviewDto>> hideReview(
            @PathVariable UUID id,
            @RequestBody(required = false) ModerateReviewRequest request,
            @AuthenticationPrincipal Object principal) {

        UUID adminId = extractUserId(principal);
        String reason = request != null ? request.getReason() : null;
        AdminReviewDto result = reviewModerationService.hide(id, adminId, reason);
        return ResponseEntity.ok(ApiResponse.success("Review hidden successfully", result));
    }

    @PostMapping("/{id}/restore")
    @Operation(summary = "Restore Review", description = "Restores a hidden review back to APPROVED status")
    public ResponseEntity<ApiResponse<AdminReviewDto>> restoreReview(
            @PathVariable UUID id,
            @AuthenticationPrincipal Object principal) {

        UUID adminId = extractUserId(principal);
        AdminReviewDto result = reviewModerationService.restore(id, adminId);
        return ResponseEntity.ok(ApiResponse.success("Review restored successfully", result));
    }

    @PostMapping("/{id}/escalate")
    @Operation(summary = "Escalate Review", description = "Escalates a review for senior moderation review")
    public ResponseEntity<ApiResponse<AdminReviewDto>> escalateReview(
            @PathVariable UUID id,
            @RequestBody(required = false) ModerateReviewRequest request,
            @AuthenticationPrincipal Object principal) {

        UUID adminId = extractUserId(principal);
        String reason = request != null ? request.getReason() : null;
        AdminReviewDto result = reviewModerationService.escalate(id, adminId, reason);
        return ResponseEntity.ok(ApiResponse.success("Review escalated successfully", result));
    }

    private UUID extractUserId(Object principal) {
        if (principal instanceof UserPrincipal up) {
            return up.getId();
        } else if (principal instanceof CustomUserPrincipal cup) {
            return cup.getId();
        }
        return null;
    }
}
