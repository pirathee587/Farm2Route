package com.farm2route.farmer.dto;

import com.farm2route.farmer.enums.CropType;
import com.farm2route.farmer.enums.PreferredLanguage;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Positive;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FarmerVerifyRequest {

    @NotBlank(message = "Phone number is required")
    @Pattern(regexp = "^(?:\\+94|0)?7[0-9]{8}$", message = "Phone number must be a valid Sri Lankan mobile number (e.g., +94771234567 or 0771234567)")
    private String phoneNumber;

    @NotBlank(message = "OTP code is required")
    @Pattern(regexp = "^\\d{6}$", message = "OTP must be a 6-digit code")
    private String otp;

    @NotBlank(message = "Full name is required")
    private String fullName;

    @Email(message = "Invalid email format")
    private String email;

    @NotBlank(message = "District is required")
    private String district;

    private String gnDivision;

    private String address;

    private Double latitude;

    private Double longitude;

    @Positive(message = "Farm size in acres must be positive")
    private BigDecimal farmSizeAcres;

    private List<CropType> primaryCrops;

    @Builder.Default
    private PreferredLanguage preferredLanguage = PreferredLanguage.TA;

    private String bankAccountNumber;

    private String mobileWalletNumber;

    private String nicNumber;
}
