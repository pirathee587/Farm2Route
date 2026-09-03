package com.farm2route.bank.controller;

import com.farm2route.bank.dto.BankDetailsRequest;
import com.farm2route.bank.dto.BankDetailsResponse;
import com.farm2route.bank.entity.BankAccountType;
import com.farm2route.bank.service.BankDetailsService;
import com.farm2route.common.response.ApiResponse;
import com.farm2route.security.UserPrincipal;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import jakarta.validation.ValidatorFactory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.mock.web.MockHttpServletRequest;

import java.time.Instant;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class BankDetailsControllerTest {

    @Mock
    private BankDetailsService bankDetailsService;

    @InjectMocks
    private BankDetailsController controller;

    private UUID userId;
    private UserPrincipal userPrincipal;
    private HttpServletRequest servletRequest;
    private Validator validator;
    private BankDetailsResponse sampleResponse;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        com.farm2route.auth.entity.User user = com.farm2route.auth.entity.User.builder()
                .id(userId)
                .email("farmer@farm2route.lk")
                .role(com.farm2route.auth.model.Role.FARMER)
                .build();
        userPrincipal = new UserPrincipal(user);
        servletRequest = new MockHttpServletRequest("GET", "/api/v1/farmers/me/bank-details");

        ValidatorFactory factory = Validation.buildDefaultValidatorFactory();
        validator = factory.getValidator();

        sampleResponse = BankDetailsResponse.builder()
                .id(UUID.randomUUID())
                .accountHolderName("Nimal Bandara")
                .bankName("Bank of Ceylon")
                .branchName("Kurunegala")
                .maskedAccountNumber("******8475")
                .accountType(BankAccountType.SAVINGS)
                .branchCode("BOC014")
                .createdAt(Instant.now())
                .updatedAt(Instant.now())
                .build();
    }

    @Test
    @DisplayName("GET /api/v1/farmers/me/bank-details should return 200 OK with masked bank details")
    void shouldReturnBankDetailsSuccessfully() {
        when(bankDetailsService.getFarmerBankDetails(userId)).thenReturn(sampleResponse);

        ResponseEntity<ApiResponse<BankDetailsResponse>> entity = controller.getBankDetails(userPrincipal, servletRequest);

        assertThat(entity.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(entity.getBody()).isNotNull();
        assertThat(entity.getBody().isSuccess()).isTrue();
        assertThat(entity.getBody().getData().getMaskedAccountNumber()).isEqualTo("******8475");
        // Verify full account number is not present
        assertThat(entity.getBody().getData().getMaskedAccountNumber()).doesNotContain("810293");
    }

    @Test
    @DisplayName("POST /api/v1/farmers/me/bank-details should return 201 Created on valid request")
    void shouldCreateBankDetailsSuccessfully() {
        BankDetailsRequest request = BankDetailsRequest.builder()
                .accountHolderName("Nimal Bandara")
                .bankName("Bank of Ceylon")
                .branchName("Kurunegala")
                .accountNumber("8102938475")
                .accountType(BankAccountType.SAVINGS)
                .branchCode("BOC014")
                .build();

        when(bankDetailsService.createBankDetails(eq(userId), any(BankDetailsRequest.class)))
                .thenReturn(sampleResponse);

        ResponseEntity<ApiResponse<BankDetailsResponse>> entity = controller.createBankDetails(userPrincipal, request, servletRequest);

        assertThat(entity.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(entity.getBody()).isNotNull();
        assertThat(entity.getBody().getData().getMaskedAccountNumber()).isEqualTo("******8475");
    }

    @Test
    @DisplayName("PUT /api/v1/farmers/me/bank-details should return 200 OK on valid update")
    void shouldUpdateBankDetailsSuccessfully() {
        BankDetailsRequest request = BankDetailsRequest.builder()
                .accountHolderName("Nimal Bandara")
                .bankName("Commercial Bank")
                .accountNumber("8102938475")
                .accountType(BankAccountType.CURRENT)
                .build();

        when(bankDetailsService.updateBankDetails(eq(userId), any(BankDetailsRequest.class)))
                .thenReturn(sampleResponse);

        ResponseEntity<ApiResponse<BankDetailsResponse>> entity = controller.updateBankDetails(userPrincipal, request, servletRequest);

        assertThat(entity.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(entity.getBody()).isNotNull();
    }

    @Test
    @DisplayName("DELETE /api/v1/farmers/me/bank-details should return 200 OK")
    void shouldDeleteBankDetailsSuccessfully() {
        ResponseEntity<ApiResponse<Void>> entity = controller.deleteBankDetails(userPrincipal, servletRequest);

        assertThat(entity.getStatusCode()).isEqualTo(HttpStatus.OK);
        verify(bankDetailsService).deleteBankDetails(userId);
    }

    @Test
    @DisplayName("Validation should fail on blank account number, blank bank name, or missing accountType")
    void shouldFailValidationOnMissingRequiredFields() {
        BankDetailsRequest invalidRequest = BankDetailsRequest.builder()
                .accountHolderName("") // blank
                .bankName("") // blank
                .accountNumber("") // blank
                .accountType(null) // null
                .build();

        var violations = validator.validate(invalidRequest);
        assertThat(violations.size()).isGreaterThanOrEqualTo(4);
    }

    @Test
    @DisplayName("Validation should fail on invalid account number format")
    void shouldFailValidationOnInvalidAccountNumber() {
        BankDetailsRequest invalidRequest = BankDetailsRequest.builder()
                .accountHolderName("John Doe")
                .bankName("Bank of Ceylon")
                .accountNumber("123-456-789") // invalid dashes
                .accountType(BankAccountType.SAVINGS)
                .build();

        var violations = validator.validate(invalidRequest);
        assertThat(violations).anyMatch(v -> v.getPropertyPath().toString().equals("accountNumber"));
    }
}
