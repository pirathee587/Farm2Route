package com.farm2route.agency.controller;

import com.farm2route.agency.dto.AgencyProfileDto;
import com.farm2route.agency.service.AgencyService;
import com.farm2route.common.response.ApiResponse;
import com.farm2route.security.UserPrincipal;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.http.MediaType;

@RestController
@RequestMapping("/api/v1/agency")
@RequiredArgsConstructor
@Tag(name = "Agency Module", description = "Endpoints for logistics agencies, fleet management, and driver assignments")
@SecurityRequirement(name = "BearerAuth")
public class AgencyController {

    private final AgencyService agencyService;

    @GetMapping("/profile")
    @PreAuthorize("hasRole('AGENCY')")
    @Operation(summary = "Get Agency Profile", description = "Retrieves company profile details for the authenticated agency")
    public ResponseEntity<ApiResponse<AgencyProfileDto>> getProfile(
            @AuthenticationPrincipal UserPrincipal principal,
            HttpServletRequest request) {
        AgencyProfileDto dto = agencyService.getProfileByUserId(principal.getId());
        return ResponseEntity.ok(ApiResponse.ok(dto, "Agency profile retrieved successfully", request.getRequestURI()));
    }

    @PutMapping("/profile")
    @PreAuthorize("hasRole('AGENCY')")
    @Operation(summary = "Update Agency Profile", description = "Updates business registration, KYC docs, and profile details")
    public ResponseEntity<ApiResponse<AgencyProfileDto>> updateProfile(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody AgencyProfileDto dto,
            HttpServletRequest request) {
        AgencyProfileDto updated = agencyService.updateProfile(principal.getId(), dto);
        return ResponseEntity.ok(ApiResponse.ok(updated, "Agency profile updated successfully", request.getRequestURI()));
    }

    @PostMapping(value = "/kyc/document", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasRole('AGENCY')")
    public ResponseEntity<ApiResponse<AgencyProfileDto>> uploadKycDocument(
            @AuthenticationPrincipal UserPrincipal principal, @RequestParam("file") MultipartFile file,
            HttpServletRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(agencyService.uploadKycDocument(principal.getId(), file),
                "Agency KYC document uploaded successfully", request.getRequestURI()));
    }

    @GetMapping("/kyc/document")
    @PreAuthorize("hasRole('AGENCY')")
    public ResponseEntity<ApiResponse<String>> getKycDocument(
            @AuthenticationPrincipal UserPrincipal principal, HttpServletRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(agencyService.getKycDocumentUrl(principal.getId()),
                "Secure agency KYC document URL created", request.getRequestURI()));
    }
}
