package com.farm2route.agency.dashboard.controller;

import com.farm2route.agency.dashboard.dto.AgencyDashboardResponse;
import com.farm2route.agency.dashboard.service.AgencyDashboardService;
import com.farm2route.common.response.ApiResponse;
import com.farm2route.security.UserPrincipal;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/agency/dashboard")
@RequiredArgsConstructor
@PreAuthorize("hasRole('AGENCY')")
@SecurityRequirement(name = "BearerAuth")
@Tag(name = "Agency Dashboard")
public class AgencyDashboardController {
    private final AgencyDashboardService agencyDashboardService;

    @GetMapping
    public ResponseEntity<ApiResponse<AgencyDashboardResponse>> getDashboard(
            @AuthenticationPrincipal UserPrincipal principal, HttpServletRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(agencyDashboardService.getDashboard(principal.getId()),
                "Agency dashboard retrieved successfully", request.getRequestURI()));
    }
}
