package com.farm2route.agency.controller;

import com.farm2route.agency.dto.AgencyRejectionRequest;
import com.farm2route.agency.dto.AgencyResponse;
import com.farm2route.agency.service.AgencyService;
import com.farm2route.common.response.ApiResponse;
import com.farm2route.security.UserPrincipal;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/admin/agencies")
@RequiredArgsConstructor
@Tag(name = "Admin Agency Module", description = "Admin endpoints for approving and rejecting agency registrations")
// TODO: Secure with @PreAuthorize("hasRole('ADMIN')") once admin authentication is fully configured in all environments
public class AdminAgencyController {

    private final AgencyService agencyService;

    @PostMapping("/{id}/approve")
    @Operation(summary = "Approve Agency Registration", description = "Approves a pending agency registration and transitions status to APPROVED")
    public ResponseEntity<ApiResponse<AgencyResponse>> approveAgency(
            @PathVariable UUID id,
            @AuthenticationPrincipal UserPrincipal principal,
            HttpServletRequest servletRequest) {
        UUID adminId = principal != null ? principal.getId() : null;
        AgencyResponse response = agencyService.approveAgency(id, adminId);
        return ResponseEntity.ok(
                ApiResponse.ok(response, "Agency approved successfully", servletRequest.getRequestURI())
        );
    }

    @PostMapping("/{id}/reject")
    @Operation(summary = "Reject Agency Registration", description = "Rejects a pending agency registration with a mandatory reason")
    public ResponseEntity<ApiResponse<AgencyResponse>> rejectAgency(
            @PathVariable UUID id,
            @Valid @RequestBody AgencyRejectionRequest request,
            @AuthenticationPrincipal UserPrincipal principal,
            HttpServletRequest servletRequest) {
        UUID adminId = principal != null ? principal.getId() : null;
        AgencyResponse response = agencyService.rejectAgency(id, request.getReason(), adminId);
        return ResponseEntity.ok(
                ApiResponse.ok(response, "Agency registration rejected", servletRequest.getRequestURI())
        );
    }
}
