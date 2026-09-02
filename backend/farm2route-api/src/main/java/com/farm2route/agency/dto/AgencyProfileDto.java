package com.farm2route.agency.dto;

import com.farm2route.common.enums.KycStatus;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AgencyProfileDto {

    private UUID id;
    private UUID userId;

    @NotBlank(message = "Company name is required")
    private String companyName;

    @NotBlank(message = "Business registration number is required")
    private String businessRegistrationNumber;

    private String taxIdentificationNumber;

    @NotBlank(message = "Office address is required")
    private String officeAddress;

    @NotBlank(message = "District is required")
    private String district;

    @NotBlank(message = "Contact person name is required")
    private String contactPersonName;

    @NotBlank(message = "Contact person phone is required")
    private String contactPersonPhone;

    private KycStatus kycStatus;
    private String kycDocumentUrl;
    private BigDecimal commissionRatePercentage;
}
