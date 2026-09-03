package com.farm2route.incident.controller;

import com.farm2route.auth.entity.User;
import com.farm2route.common.enums.IncidentStatus;
import com.farm2route.common.enums.IncidentType;
import com.farm2route.common.exception.UnauthorizedException;
import com.farm2route.common.response.ApiResponse;
import com.farm2route.incident.dto.IncidentResponse;
import com.farm2route.incident.dto.SubmitIncidentRequest;
import com.farm2route.incident.service.IncidentService;
import com.farm2route.security.CustomUserPrincipal;
import com.farm2route.security.UserPrincipal;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.UUID;

@Slf4j
@RestController
@RequestMapping({"/api/v1/farmer/incidents", "/api/farmer/incidents"})
@RequiredArgsConstructor
@Tag(name = "Farmer Incident Reporting", description = "Endpoints for farmers to report incidents on bookings and monitor resolution status")
@SecurityRequirement(name = "BearerAuth")
public class FarmerIncidentController {

    private final IncidentService incidentService;

    @PostMapping(consumes = {MediaType.MULTIPART_FORM_DATA_VALUE, MediaType.APPLICATION_JSON_VALUE})
    @PreAuthorize("hasRole('FARMER')")
    @Operation(summary = "Submit an Incident Report", description = "File a new cargo damage, delay, or route incident for an active booking with optional evidence photos")
    public ResponseEntity<ApiResponse<IncidentResponse>> submitIncident(
            @AuthenticationPrincipal Object principal,
            @RequestPart(value = "request", required = false) @Valid SubmitIncidentRequest request,
            @RequestParam(value = "bookingId", required = false) UUID paramBookingId,
            @RequestParam(value = "incidentType", required = false) IncidentType paramIncidentType,
            @RequestParam(value = "title", required = false) String paramTitle,
            @RequestParam(value = "description", required = false) String paramDescription,
            @RequestPart(value = "evidencePhotos", required = false) MultipartFile[] evidencePhotos,
            HttpServletRequest servletRequest) {

        UUID farmerUserId = extractFarmerId(principal);

        SubmitIncidentRequest effectiveRequest = request;
        if (effectiveRequest == null) {
            effectiveRequest = SubmitIncidentRequest.builder()
                    .bookingId(paramBookingId)
                    .incidentType(paramIncidentType)
                    .title(paramTitle)
                    .description(paramDescription)
                    .build();
        }

        if (effectiveRequest.getBookingId() == null) {
            throw new com.farm2route.common.exception.BadRequestException("Booking ID is required");
        }
        if (effectiveRequest.getIncidentType() == null) {
            throw new com.farm2route.common.exception.BadRequestException("Incident type is required");
        }
        if (effectiveRequest.getDescription() == null || effectiveRequest.getDescription().trim().length() < 10) {
            throw new com.farm2route.common.exception.BadRequestException("Description must be at least 10 characters long");
        }

        IncidentResponse response = incidentService.submitIncident(farmerUserId, effectiveRequest, evidencePhotos);

        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.created(response, "Incident report submitted successfully", servletRequest.getRequestURI()));
    }

    @GetMapping
    @PreAuthorize("hasRole('FARMER')")
    @Operation(summary = "List Farmer Incidents", description = "Retrieve a paginated list of all incidents reported by the authenticated farmer, with optional status filter")
    public ResponseEntity<ApiResponse<Page<IncidentResponse>>> getFarmerIncidents(
            @AuthenticationPrincipal Object principal,
            @RequestParam(value = "status", required = false) IncidentStatus status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            HttpServletRequest servletRequest) {

        UUID farmerUserId = extractFarmerId(principal);
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));

        Page<IncidentResponse> results = incidentService.getFarmerIncidents(farmerUserId, status, pageable);

        return ResponseEntity.ok(ApiResponse.ok(results, "Farmer incident reports retrieved successfully", servletRequest.getRequestURI()));
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasRole('FARMER')")
    @Operation(summary = "Get Incident Details", description = "Retrieve full incident report details, evidence photo URLs, and current resolution status")
    public ResponseEntity<ApiResponse<IncidentResponse>> getIncidentById(
            @AuthenticationPrincipal Object principal,
            @PathVariable UUID id,
            HttpServletRequest servletRequest) {

        UUID farmerUserId = extractFarmerId(principal);
        IncidentResponse response = incidentService.getIncidentById(farmerUserId, id);

        return ResponseEntity.ok(ApiResponse.ok(response, "Incident report retrieved successfully", servletRequest.getRequestURI()));
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
