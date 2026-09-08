package com.farm2route.auth.dto;

import com.fasterxml.jackson.annotation.JsonAlias;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LoginRequest {

    @NotBlank(message = "Phone number or email is required")
    @JsonAlias({"identifier", "email", "username"})
    private String phoneNumber;

    @NotBlank(message = "Password is required")
    private String password;
}
