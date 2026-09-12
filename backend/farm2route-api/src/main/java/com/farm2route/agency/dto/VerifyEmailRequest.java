package com.farm2route.agency.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VerifyEmailRequest {

    @NotNull(message = "Agency ID is required")
    private UUID agencyId;

    @NotBlank(message = "Email token is required")
    private String emailToken;
}
