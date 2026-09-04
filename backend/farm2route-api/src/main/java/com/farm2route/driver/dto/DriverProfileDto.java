package com.farm2route.driver.dto;

import com.farm2route.common.enums.DriverAvailability;
import com.farm2route.common.enums.KycStatus;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DriverProfileDto {

    private UUID id;
    private UUID userId;
    private UUID agencyId;
    private String fullName;
    private String email;
    private String phoneNumber;

    @NotBlank(message = "Driving license number is required")
    private String drivingLicenseNumber;

    @NotNull(message = "License expiry date is required")
    private LocalDate licenseExpiryDate;

    @NotBlank(message = "NIC number is required")
    private String nicNumber;

    private KycStatus kycStatus;
    private String kycDocumentUrl;
    private String kycRejectionReason;
    private DriverAvailability availabilityStatus;
    private BigDecimal ratingAverage;
    private int totalRatingsCount;
    private Instant verifiedAt;
    private Instant createdAt;
    private Instant updatedAt;
}
