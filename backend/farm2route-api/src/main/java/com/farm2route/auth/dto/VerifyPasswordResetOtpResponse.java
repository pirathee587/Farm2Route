package com.farm2route.auth.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class VerifyPasswordResetOtpResponse {

    private String resetToken;

    @Builder.Default
    private String tokenType = "Bearer";

    private Long expiresIn;
    private String message;
}
