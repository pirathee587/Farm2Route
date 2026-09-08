package com.farm2route.incident.dto;

import com.farm2route.common.enums.IncidentStatus;
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
public class ResolveIncidentRequest {

    @NotNull(message = "Status must be either RESOLVED or REJECTED")
    private IncidentStatus status;

    private String notes;

    private BigDecimal refundAmount;
}
