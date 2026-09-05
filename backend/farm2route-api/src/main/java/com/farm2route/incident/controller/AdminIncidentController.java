package com.farm2route.incident.controller;

import com.farm2route.common.enums.IncidentStatus;
import com.farm2route.common.enums.IncidentType;
import com.farm2route.common.response.ApiResponse;
import com.farm2route.incident.dto.AddInvestigationNoteRequest;
import com.farm2route.incident.dto.AdminIncidentDetailDto;
import com.farm2route.incident.dto.EscalateIncidentRequest;
import com.farm2route.incident.dto.ResolveIncidentRequest;
import com.farm2route.incident.service.AdminIncidentService;
import com.farm2route.security.CustomUserPrincipal;
import com.farm2route.security.UserPrincipal;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
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

import com.farm2route.incident.dto.DecideRefundRequest;
import com.farm2route.incident.dto.OpenPodDisputeRequest;
import com.farm2route.incident.dto.RecordAgencyResponseRequest;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;

@Slf4j
@RestController
@RequestMapping("/api/v1/admin/incidents")
@PreAuthorize("hasRole('ADMIN')")
@RequiredArgsConstructor
@Tag(name = "Admin Incident Moderation", description = "Endpoints for administrator incident investigation, resolution, and escalation")
@SecurityRequirement(name = "BearerAuth")
public class AdminIncidentController {

    private final AdminIncidentService adminIncidentService;

    @GetMapping
    @Operation(summary = "Search Admin Incidents", description = "Retrieves paginated and filtered incident reports for admin investigation")
    public ResponseEntity<ApiResponse<Page<AdminIncidentDetailDto>>> searchIncidents(
            @RequestParam(required = false) IncidentStatus status,
            @RequestParam(required = false) IncidentType incidentType,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant fromDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant toDate,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {

        Page<AdminIncidentDetailDto> result = adminIncidentService.search(status, incidentType, fromDate, toDate, pageable);
        return ResponseEntity.ok(ApiResponse.success(result));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get Incident Detail", description = "Retrieves complete details of an incident report including party summaries and evidence")
    public ResponseEntity<ApiResponse<AdminIncidentDetailDto>> getIncidentDetail(@PathVariable UUID id) {
        AdminIncidentDetailDto detail = adminIncidentService.getDetail(id);
        return ResponseEntity.ok(ApiResponse.success(detail));
    }

    @PostMapping("/{id}/notes")
    @Operation(summary = "Add Investigation Note", description = "Appends an investigation note and transitions status to INVESTIGATING if OPEN")
    public ResponseEntity<ApiResponse<AdminIncidentDetailDto>> addInvestigationNote(
            @PathVariable UUID id,
            @Valid @RequestBody AddInvestigationNoteRequest request,
            @AuthenticationPrincipal Object principal) {

        UUID adminId = extractUserId(principal);
        AdminIncidentDetailDto result = adminIncidentService.addInvestigationNote(id, request.getNote(), adminId);
        return ResponseEntity.ok(ApiResponse.success("Investigation note added successfully", result));
    }

    @PostMapping("/{id}/agency-response")
    @Operation(summary = "Record Agency Response", description = "Appends official logistics agency response to incident investigation notes")
    public ResponseEntity<ApiResponse<AdminIncidentDetailDto>> recordAgencyResponse(
            @PathVariable UUID id,
            @Valid @RequestBody RecordAgencyResponseRequest request,
            @AuthenticationPrincipal Object principal) {

        UUID agencyUserId = extractUserId(principal);
        AdminIncidentDetailDto result = adminIncidentService.recordAgencyResponse(id, agencyUserId, request.getResponse());
        return ResponseEntity.ok(ApiResponse.success("Agency response recorded successfully", result));
    }

    @PostMapping("/{id}/refund")
    @Operation(summary = "Decide Dispute Refund", description = "Processes a dispute refund decision via FinanceService and resolves the incident")
    public ResponseEntity<ApiResponse<AdminIncidentDetailDto>> decideRefund(
            @PathVariable UUID id,
            @Valid @RequestBody DecideRefundRequest request,
            @AuthenticationPrincipal Object principal) {

        UUID adminId = extractUserId(principal);
        AdminIncidentDetailDto result = adminIncidentService.decideRefund(id, adminId, request.getAmount(), request.getDecision());
        return ResponseEntity.ok(ApiResponse.success("Dispute refund processed successfully", result));
    }

    @PostMapping("/from-pod-dispute")
    @Operation(summary = "Open Incident from POD Dispute", description = "Creates a new cargo damage incident triggered by a disputed Proof of Delivery")
    public ResponseEntity<ApiResponse<AdminIncidentDetailDto>> openFromPodDispute(
            @Valid @RequestBody OpenPodDisputeRequest request) {

        AdminIncidentDetailDto result = adminIncidentService.openFromPodDispute(request.getBookingId(), request.getFarmerId(), request.getReason());
        return ResponseEntity.ok(ApiResponse.success("POD dispute incident opened successfully", result));
    }

    @PostMapping("/{id}/resolve")
    @Operation(summary = "Resolve or Reject Incident", description = "Sets final resolution status (RESOLVED or REJECTED) and notes for an incident")
    public ResponseEntity<ApiResponse<AdminIncidentDetailDto>> resolveIncident(
            @PathVariable UUID id,
            @Valid @RequestBody ResolveIncidentRequest request,
            @AuthenticationPrincipal Object principal) {

        UUID adminId = extractUserId(principal);
        AdminIncidentDetailDto result = adminIncidentService.resolve(id, request, adminId);
        return ResponseEntity.ok(ApiResponse.success("Incident decision recorded successfully", result));
    }

    @PostMapping("/{id}/escalate")
    @Operation(summary = "Escalate Incident", description = "Escalates an incident report for priority admin review without altering status")
    public ResponseEntity<ApiResponse<AdminIncidentDetailDto>> escalateIncident(
            @PathVariable UUID id,
            @Valid @RequestBody EscalateIncidentRequest request,
            @AuthenticationPrincipal Object principal) {

        UUID adminId = extractUserId(principal);
        AdminIncidentDetailDto result = adminIncidentService.escalate(id, request.getNotes(), adminId);
        return ResponseEntity.ok(ApiResponse.success("Incident escalated successfully", result));
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
