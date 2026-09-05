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
public class RecordAgencyResponseRequest {

    @NotBlank(message = "Response text cannot be blank")
    private String response;
}
