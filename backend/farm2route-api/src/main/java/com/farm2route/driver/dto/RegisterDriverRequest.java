package com.farm2route.driver.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RegisterDriverRequest {

    @NotBlank(message = "Full name is required")
    private String fullName;

    @Email(message = "Email must be a valid email address")
    private String email;

    @NotBlank(message = "Phone number is required")
    private String phoneNumber;

    private String password;

    @NotBlank(message = "Driving license number is required")
    private String drivingLicenseNumber;

    @NotNull(message = "License expiry date is required")
    private LocalDate licenseExpiryDate;

    @NotBlank(message = "NIC number is required")
    private String nicNumber;

    private String kycDocumentUrl;
}
