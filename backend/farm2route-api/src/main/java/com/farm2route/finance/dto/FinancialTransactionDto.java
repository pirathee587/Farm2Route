package com.farm2route.finance.dto;

import com.farm2route.finance.entity.FinancialTransaction;
import lombok.Builder;
import lombok.Value;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Value
@Builder
public class FinancialTransactionDto {
    UUID id;
    String reference;
    UUID bookingId;
    BigDecimal amount;
    BigDecimal commission;
    BigDecimal netAmount;
    String type;
    String status;
    Instant createdAt;

    public static FinancialTransactionDto from(FinancialTransaction transaction) {
        return FinancialTransactionDto.builder()
                .id(transaction.getId())
                .reference(transaction.getTransactionReference())
                .bookingId(transaction.getBooking() == null ? null : transaction.getBooking().getId())
                .amount(transaction.getAmount())
                .commission(transaction.getCommissionDeducted())
                .netAmount(transaction.getNetAmount())
                .type(transaction.getTransactionType().name())
                .status(transaction.getStatus().name())
                .createdAt(transaction.getCreatedAt())
                .build();
    }
}
