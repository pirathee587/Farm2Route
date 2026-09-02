package com.farm2route.admin.controller;

import com.farm2route.admin.dto.AdminStatsDto;
import com.farm2route.admin.dto.KycApprovalDto;
import com.farm2route.admin.service.AdminService;
import com.farm2route.common.response.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/admin")
@RequiredArgsConstructor
@Tag(name = "Admin Module", description = "Endpoints for platform administration, KYC verification, incident resolution, and moderation")
@SecurityRequirement(name = "BearerAuth")
@PreAuthorize("hasRole('ADMIN')")
public class AdminController {

    private final AdminService adminService;

    @GetMapping("/stats")
    @Operation(summary = "Get Dashboard Analytics", description = "Retrieves high-level platform metrics for admin dashboard")
    public ResponseEntity<ApiResponse<AdminStatsDto>> getStats(HttpServletRequest request) {
        AdminStatsDto stats = adminService.getDashboardStats();
        return ResponseEntity.ok(ApiResponse.ok(stats, "Admin metrics retrieved successfully", request.getRequestURI()));
    }

    @PostMapping("/kyc/agency")
    @Operation(summary = "Approve or Reject Agency KYC", description = "Updates KYC status for a registered logistics agency")
    public ResponseEntity<ApiResponse<Void>> reviewAgencyKyc(
            @Valid @RequestBody KycApprovalDto dto,
            HttpServletRequest request) {
        adminService.reviewAgencyKyc(dto);
        return ResponseEntity.ok(ApiResponse.ok(null, "Agency KYC reviewed successfully", request.getRequestURI()));
    }

    @PostMapping("/kyc/driver")
    @Operation(summary = "Approve or Reject Driver KYC", description = "Updates KYC status for a registered driver")
    public ResponseEntity<ApiResponse<Void>> reviewDriverKyc(
            @Valid @RequestBody KycApprovalDto dto,
            HttpServletRequest request) {
        adminService.reviewDriverKyc(dto);
        return ResponseEntity.ok(ApiResponse.ok(null, "Driver KYC reviewed successfully", request.getRequestURI()));
    }
}
