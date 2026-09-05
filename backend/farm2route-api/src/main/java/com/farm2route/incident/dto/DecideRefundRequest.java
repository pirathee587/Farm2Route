package com.farm2route.incident.dto;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DecideRefundRequest {

    @NotNull(message = "Refund amount is required")
    private BigDecimal amount;

    private String decision;
}
