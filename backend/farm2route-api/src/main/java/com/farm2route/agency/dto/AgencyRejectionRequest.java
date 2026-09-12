package com.farm2route.agency.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AgencyRejectionRequest {

    @NotBlank(message = "Rejection reason is required")
    private String reason;
}
