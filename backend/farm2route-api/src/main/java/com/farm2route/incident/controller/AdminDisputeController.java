package com.farm2route.incident.controller;

import com.farm2route.common.response.ApiResponse;
import com.farm2route.incident.dto.AdminIncidentDetailDto;
import com.farm2route.incident.dto.DecideRefundRequest;
import com.farm2route.incident.dto.OpenPodDisputeRequest;
import com.farm2route.incident.dto.RecordAgencyResponseRequest;
import com.farm2route.incident.service.AdminIncidentService;
import com.farm2route.security.CustomUserPrincipal;
import com.farm2route.security.UserPrincipal;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/api/v1/admin/disputes")
@PreAuthorize("hasRole('ADMIN')")
@RequiredArgsConstructor
public class AdminDisputeController {

    private final AdminIncidentService adminIncidentService;

    @PostMapping("/{id}/agency-response")
    public ResponseEntity<ApiResponse<AdminIncidentDetailDto>> recordAgencyResponse(
            @PathVariable UUID id,
            @Valid @RequestBody RecordAgencyResponseRequest request,
            @AuthenticationPrincipal Object principal) {

        UUID agencyUserId = extractUserId(principal);
        AdminIncidentDetailDto result = adminIncidentService.recordAgencyResponse(id, agencyUserId, request.getResponse());
        return ResponseEntity.ok(ApiResponse.success("Agency response recorded successfully", result));
    }

    @PostMapping("/{id}/refund")
    public ResponseEntity<ApiResponse<AdminIncidentDetailDto>> decideRefund(
            @PathVariable UUID id,
            @Valid @RequestBody DecideRefundRequest request,
            @AuthenticationPrincipal Object principal) {

        UUID adminId = extractUserId(principal);
        AdminIncidentDetailDto result = adminIncidentService.decideRefund(id, adminId, request.getAmount(), request.getDecision());
        return ResponseEntity.ok(ApiResponse.success("Dispute refund processed successfully", result));
    }

    @PostMapping("/from-pod")
    public ResponseEntity<ApiResponse<AdminIncidentDetailDto>> openFromPodDispute(
            @Valid @RequestBody OpenPodDisputeRequest request) {

        AdminIncidentDetailDto result = adminIncidentService.openFromPodDispute(request.getBookingId(), request.getFarmerId(), request.getReason());
        return ResponseEntity.ok(ApiResponse.success("Dispute incident opened successfully", result));
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
