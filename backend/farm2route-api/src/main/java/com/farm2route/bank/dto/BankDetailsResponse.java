package com.farm2route.bank.dto;

import com.farm2route.bank.entity.BankAccountType;
import com.farm2route.bank.entity.BankDetails;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BankDetailsResponse {

    private UUID id;
    private String accountHolderName;
    private String bankName;
    private String branchName;
    private String maskedAccountNumber;
    private BankAccountType accountType;
    private String branchCode;
    private Instant createdAt;
    private Instant updatedAt;

    public static BankDetailsResponse fromEntity(BankDetails entity) {
        if (entity == null) {
            return null;
        }
        return BankDetailsResponse.builder()
                .id(entity.getId())
                .accountHolderName(entity.getAccountHolderName())
                .bankName(entity.getBankName())
                .branchName(entity.getBranchName())
                .maskedAccountNumber(maskAccountNumber(entity.getAccountNumber()))
                .accountType(entity.getAccountType())
                .branchCode(entity.getBranchCode())
                .createdAt(entity.getCreatedAt())
                .updatedAt(entity.getUpdatedAt())
                .build();
    }

    public static String maskAccountNumber(String rawNumber) {
        if (rawNumber == null || rawNumber.isBlank()) {
            return "******";
        }
        String clean = rawNumber.trim();
        if (clean.length() <= 4) {
            return "******" + clean;
        }
        return "******" + clean.substring(clean.length() - 4);
    }
}
