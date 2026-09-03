package com.farm2route.catalog.controller;

import com.farm2route.catalog.dto.PackageResponse;
import com.farm2route.catalog.dto.PackageSearchRequest;
import com.farm2route.catalog.service.PackageSearchService;
import com.farm2route.common.response.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping({"/api/v1/farmer/packages", "/api/farmer/packages"})
@RequiredArgsConstructor
@Tag(name = "Farmer Package Search", description = "Endpoints for farmers to discover, filter, and view transport service packages")
@SecurityRequirement(name = "BearerAuth")
public class FarmerPackageController {

    private final PackageSearchService packageSearchService;

    @GetMapping
    @PreAuthorize("hasAnyRole('FARMER', 'ADMIN')")
    @Operation(summary = "Search Transport Packages", description = "Search and filter agency transport packages by origin, destination, weight, price, and type")
    public ResponseEntity<ApiResponse<Page<PackageResponse>>> searchPackages(
            @ModelAttribute PackageSearchRequest request,
            HttpServletRequest servletRequest) {

        Page<PackageResponse> result = packageSearchService.searchPackages(request);
        return ResponseEntity.ok(ApiResponse.ok(result, "Transport packages retrieved successfully", servletRequest.getRequestURI()));
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('FARMER', 'ADMIN')")
    @Operation(summary = "Get Transport Package Details", description = "Retrieve full pricing, route, and schedule details for a transport package")
    public ResponseEntity<ApiResponse<PackageResponse>> getPackageById(
            @PathVariable UUID id,
            HttpServletRequest servletRequest) {

        PackageResponse result = packageSearchService.getPackageById(id);
        return ResponseEntity.ok(ApiResponse.ok(result, "Transport package retrieved successfully", servletRequest.getRequestURI()));
    }
}
