package com.farm2route.finance.controller;

import com.farm2route.common.response.ApiResponse;
import com.farm2route.finance.AgencyFinanceService;
import com.farm2route.finance.dto.AgencyEarningsSummaryDto;
import com.farm2route.finance.dto.FinancialTransactionDto;
import com.farm2route.finance.dto.WithdrawalRequestDto;
import com.farm2route.finance.dto.WithdrawalResponseDto;
import com.farm2route.security.UserPrincipal;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/agency/finance")
@RequiredArgsConstructor
@PreAuthorize("hasRole('AGENCY')")
@Tag(name = "Agency Finance")
@SecurityRequirement(name = "BearerAuth")
public class AgencyFinanceController {
    private final AgencyFinanceService financeService;

    @GetMapping("/summary")
    public ResponseEntity<ApiResponse<AgencyEarningsSummaryDto>> summary(
            @AuthenticationPrincipal UserPrincipal principal, HttpServletRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(financeService.getSummary(principal.getId()),
                "Agency earnings retrieved successfully", request.getRequestURI()));
    }

    @GetMapping("/transactions")
    public ResponseEntity<ApiResponse<List<FinancialTransactionDto>>> transactions(
            @AuthenticationPrincipal UserPrincipal principal, HttpServletRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(financeService.getTransactions(principal.getId()),
                "Agency transactions retrieved successfully", request.getRequestURI()));
    }

    @PostMapping("/withdrawals")
    public ResponseEntity<ApiResponse<WithdrawalResponseDto>> requestWithdrawal(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody WithdrawalRequestDto withdrawal,
            HttpServletRequest request) {
        WithdrawalResponseDto created = financeService.requestWithdrawal(principal.getId(), withdrawal);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.created(created,
                "Withdrawal request created successfully", request.getRequestURI()));
    }

    @GetMapping("/withdrawals")
    public ResponseEntity<ApiResponse<List<WithdrawalResponseDto>>> withdrawals(
            @AuthenticationPrincipal UserPrincipal principal, HttpServletRequest request) {
        return ResponseEntity.ok(ApiResponse.ok(financeService.getWithdrawals(principal.getId()),
                "Withdrawal requests retrieved successfully", request.getRequestURI()));
    }
}
