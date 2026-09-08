package com.farm2route.admin.controller;

import com.farm2route.admin.dto.AdminStatsDto;
import com.farm2route.admin.dto.KycApprovalDto;
import com.farm2route.admin.service.AdminService;
import com.farm2route.audit.dto.PagedAuditLogDto;
import com.farm2route.audit.service.AuditService;
import com.farm2route.auth.entity.User;
import com.farm2route.common.response.ApiResponse;
import com.farm2route.security.CustomUserPrincipal;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/admin")
@RequiredArgsConstructor
@Tag(name = "Admin Module", description = "Endpoints for platform administration, KYC verification, incident resolution, and moderation")
@SecurityRequirement(name = "BearerAuth")
@PreAuthorize("hasRole('ADMIN')")
public class AdminController {

    private final AdminService adminService;
    private final AuditService auditService;

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
            @AuthenticationPrincipal CustomUserPrincipal principal,
            HttpServletRequest request) {
        User actor = principal != null ? principal.getUser() : null;
        String ipAddress = extractIpAddress(request);
        String userAgent = request.getHeader("User-Agent");
        adminService.reviewAgencyKyc(dto, actor, ipAddress, userAgent);
        return ResponseEntity.ok(ApiResponse.ok(null, "Agency KYC reviewed successfully", request.getRequestURI()));
    }

    @PostMapping("/kyc/driver")
    @Operation(summary = "Approve or Reject Driver KYC", description = "Updates KYC status for a registered driver")
    public ResponseEntity<ApiResponse<Void>> reviewDriverKyc(
            @Valid @RequestBody KycApprovalDto dto,
            @AuthenticationPrincipal CustomUserPrincipal principal,
            HttpServletRequest request) {
        User actor = principal != null ? principal.getUser() : null;
        String ipAddress = extractIpAddress(request);
        String userAgent = request.getHeader("User-Agent");
        adminService.reviewDriverKyc(dto, actor, ipAddress, userAgent);
        return ResponseEntity.ok(ApiResponse.ok(null, "Driver KYC reviewed successfully", request.getRequestURI()));
    }

    @PostMapping("/kyc/vehicle")
    @Operation(summary = "Approve or Reject Vehicle KYC", description = "Updates KYC status for a registered vehicle")
    public ResponseEntity<ApiResponse<Void>> reviewVehicleKyc(
            @Valid @RequestBody KycApprovalDto dto,
            @AuthenticationPrincipal CustomUserPrincipal principal,
            HttpServletRequest request) {
        User actor = principal != null ? principal.getUser() : null;
        String ipAddress = extractIpAddress(request);
        String userAgent = request.getHeader("User-Agent");
        adminService.reviewVehicleKyc(dto, actor, ipAddress, userAgent);
        return ResponseEntity.ok(ApiResponse.ok(null, "Vehicle KYC reviewed successfully", request.getRequestURI()));
    }

    @GetMapping("/audit-logs")
    @Operation(summary = "Get Audit Logs", description = "Retrieves paginated and filtered platform audit logs")
    public ResponseEntity<ApiResponse<PagedAuditLogDto>> getAuditLogs(
            @RequestParam(required = false) String action,
            @RequestParam(required = false) String entityName,
            @RequestParam(required = false) UUID actorId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant fromDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant toDate,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable,
            HttpServletRequest request) {
        PagedAuditLogDto logs = auditService.getAuditLogs(action, entityName, actorId, fromDate, toDate, pageable);
        return ResponseEntity.ok(ApiResponse.ok(logs, "Audit logs retrieved successfully", request.getRequestURI()));
    }

    private String extractIpAddress(HttpServletRequest request) {
        String xForwardedFor = request.getHeader("X-Forwarded-For");
        if (xForwardedFor != null && !xForwardedFor.isBlank()) {
            return xForwardedFor.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}
