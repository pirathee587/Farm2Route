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

@Slf4j
@RestController
@RequestMapping("/api/v1/admin/incidents")
@PreAuthorize("hasRole('ADMIN')")
@RequiredArgsConstructor
public class AdminIncidentController {

    private final AdminIncidentService adminIncidentService;

    @GetMapping
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
    public ResponseEntity<ApiResponse<AdminIncidentDetailDto>> getIncidentDetail(@PathVariable UUID id) {
        AdminIncidentDetailDto detail = adminIncidentService.getDetail(id);
        return ResponseEntity.ok(ApiResponse.success(detail));
    }

    @PostMapping("/{id}/notes")
    public ResponseEntity<ApiResponse<AdminIncidentDetailDto>> addInvestigationNote(
            @PathVariable UUID id,
            @Valid @RequestBody AddInvestigationNoteRequest request,
            @AuthenticationPrincipal Object principal) {

        UUID adminId = extractUserId(principal);
        AdminIncidentDetailDto result = adminIncidentService.addInvestigationNote(id, request.getNote(), adminId);
        return ResponseEntity.ok(ApiResponse.success("Investigation note added successfully", result));
    }

    @PostMapping("/{id}/resolve")
    public ResponseEntity<ApiResponse<AdminIncidentDetailDto>> resolveIncident(
            @PathVariable UUID id,
            @Valid @RequestBody ResolveIncidentRequest request,
            @AuthenticationPrincipal Object principal) {

        UUID adminId = extractUserId(principal);
        AdminIncidentDetailDto result = adminIncidentService.resolve(id, request, adminId);
        return ResponseEntity.ok(ApiResponse.success("Incident decision recorded successfully", result));
    }

    @PostMapping("/{id}/escalate")
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
