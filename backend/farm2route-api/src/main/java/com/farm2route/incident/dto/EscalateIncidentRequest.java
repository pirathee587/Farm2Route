package com.farm2route.incident.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EscalateIncidentRequest {

    @NotBlank(message = "Escalation notes cannot be blank")
    private String notes;
}
