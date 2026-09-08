package com.farm2route.farmer.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FarmerOtpRequest {

    @NotBlank(message = "Phone number is required")
    @Pattern(regexp = "^(?:\\+94|0)?7[0-9]{8}$", message = "Phone number must be a valid Sri Lankan mobile number (e.g., +94771234567 or 0771234567)")
    private String phoneNumber;
}
