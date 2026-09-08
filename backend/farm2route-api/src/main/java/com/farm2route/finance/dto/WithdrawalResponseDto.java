package com.farm2route.finance.dto;

import com.farm2route.finance.entity.WithdrawalRequest;
import lombok.Builder;
import lombok.Value;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Value
@Builder
public class WithdrawalResponseDto {
    UUID id;
    BigDecimal amount;
    String status;
    Instant createdAt;
    Instant updatedAt;

    public static WithdrawalResponseDto from(WithdrawalRequest request) {
        return WithdrawalResponseDto.builder()
                .id(request.getId())
                .amount(request.getAmount())
                .status(request.getStatus().name())
                .createdAt(request.getCreatedAt())
                .updatedAt(request.getUpdatedAt())
                .build();
    }
}
