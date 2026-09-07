package com.farm2route.bank.controller;

import com.farm2route.bank.dto.BankDetailsRequest;
import com.farm2route.bank.dto.BankDetailsResponse;
import com.farm2route.bank.service.BankDetailsService;
import com.farm2route.common.exception.UnauthorizedException;
import com.farm2route.common.response.ApiResponse;
import com.farm2route.security.CustomUserPrincipal;
import com.farm2route.security.UserPrincipal;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@Slf4j
@RestController
@RequestMapping({"/api/v1/farmers/me/bank-details", "/api/v1/farmer/me/bank-details"})
@RequiredArgsConstructor
@Tag(name = "Farmer Bank Details", description = "Endpoints for farmers to manage their settlement bank accounts")
@SecurityRequirement(name = "BearerAuth")
public class BankDetailsController {

    private final BankDetailsService bankDetailsService;

    @GetMapping
    @PreAuthorize("hasRole('FARMER')")
    @Operation(summary = "Get Farmer Bank Details", description = "Retrieves the authenticated farmer's masked bank account details")
    public ResponseEntity<ApiResponse<BankDetailsResponse>> getBankDetails(
            @AuthenticationPrincipal Object principal,
            HttpServletRequest request) {

        UUID farmerUserId = extractUserId(principal);
        BankDetailsResponse response = bankDetailsService.getFarmerBankDetails(farmerUserId);
        return ResponseEntity.ok(ApiResponse.ok(response, "Bank details retrieved successfully", request.getRequestURI()));
    }

    @PostMapping
    @PreAuthorize("hasRole('FARMER')")
    @Operation(summary = "Register Bank Details", description = "Registers a new settlement bank account for the authenticated farmer")
    public ResponseEntity<ApiResponse<BankDetailsResponse>> createBankDetails(
            @AuthenticationPrincipal Object principal,
            @Valid @RequestBody BankDetailsRequest bankDetailsRequest,
            HttpServletRequest request) {

        UUID farmerUserId = extractUserId(principal);
        BankDetailsResponse response = bankDetailsService.createBankDetails(farmerUserId, bankDetailsRequest);
        return new ResponseEntity<>(
                ApiResponse.created(response, "Bank details registered successfully", request.getRequestURI()),
                HttpStatus.CREATED
        );
    }

    @PutMapping
    @PreAuthorize("hasRole('FARMER')")
    @Operation(summary = "Update Bank Details", description = "Updates the authenticated farmer's existing bank account details")
    public ResponseEntity<ApiResponse<BankDetailsResponse>> updateBankDetails(
            @AuthenticationPrincipal Object principal,
            @Valid @RequestBody BankDetailsRequest bankDetailsRequest,
            HttpServletRequest request) {

        UUID farmerUserId = extractUserId(principal);
        BankDetailsResponse response = bankDetailsService.updateBankDetails(farmerUserId, bankDetailsRequest);
        return ResponseEntity.ok(ApiResponse.ok(response, "Bank details updated successfully", request.getRequestURI()));
    }

    @DeleteMapping
    @PreAuthorize("hasRole('FARMER')")
    @Operation(summary = "Delete Bank Details", description = "Deletes the authenticated farmer's bank account details")
    public ResponseEntity<ApiResponse<Void>> deleteBankDetails(
            @AuthenticationPrincipal Object principal,
            HttpServletRequest request) {

        UUID farmerUserId = extractUserId(principal);
        bankDetailsService.deleteBankDetails(farmerUserId);
        return ResponseEntity.ok(ApiResponse.ok(null, "Bank details deleted successfully", request.getRequestURI()));
    }

    private UUID extractUserId(Object principal) {
        if (principal instanceof CustomUserPrincipal cup) {
            return cup.getId();
        } else if (principal instanceof UserPrincipal up) {
            return up.getId();
        }
        throw new UnauthorizedException("Unable to extract user ID from authenticated principal");
    }
}
