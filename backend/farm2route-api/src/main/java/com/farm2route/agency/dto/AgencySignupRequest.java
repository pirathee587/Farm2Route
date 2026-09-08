package com.farm2route.agency.dto;

import com.farm2route.agency.enums.AgencyType;
import com.farm2route.agency.validation.PasswordMatch;
import com.farm2route.agency.validation.ValidBusinessRegNumber;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@PasswordMatch
@ValidBusinessRegNumber
public class AgencySignupRequest {

    @NotBlank(message = "Agency name is required")
    private String agencyName;

    @NotBlank(message = "Email is required")
    @Email(message = "Invalid email format")
    private String email;

    @NotBlank(message = "Phone number is required")
    private String phoneNumber;

    @NotBlank(message = "Password is required")
    @Size(min = 8, message = "Password must be at least 8 characters")
    private String password;

    @NotBlank(message = "Confirm password is required")
    private String confirmPassword;

    @NotNull(message = "Agency type is required")
    private AgencyType agencyType;

    private String businessRegNumber;

    @NotBlank(message = "District is required")
    private String district;

    @NotBlank(message = "Address is required")
    private String address;

    private String contactPersonName;
}
