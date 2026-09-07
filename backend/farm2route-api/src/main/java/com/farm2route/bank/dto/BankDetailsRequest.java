package com.farm2route.bank.dto;

import com.farm2route.bank.entity.BankAccountType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BankDetailsRequest {

    @NotBlank(message = "Account holder name is required")
    @Size(min = 2, max = 150, message = "Account holder name must be between 2 and 150 characters")
    private String accountHolderName;

    @NotBlank(message = "Bank name is required")
    @Size(min = 2, max = 150, message = "Bank name must be between 2 and 150 characters")
    private String bankName;

    @Size(max = 150, message = "Branch name cannot exceed 150 characters")
    private String branchName;

    @NotBlank(message = "Account number is required")
    @Pattern(regexp = "^[0-9A-Za-z]{6,34}$", message = "Account number must be between 6 and 34 alphanumeric characters without spaces")
    private String accountNumber;

    @NotNull(message = "Account type is required")
    private BankAccountType accountType;

    @Size(max = 30, message = "Branch code cannot exceed 30 characters")
    private String branchCode;
}
