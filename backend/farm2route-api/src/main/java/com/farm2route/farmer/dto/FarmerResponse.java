package com.farm2route.farmer.dto;

import com.farm2route.farmer.enums.CropType;
import com.farm2route.farmer.enums.FarmerStatus;
import com.farm2route.farmer.enums.PreferredLanguage;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Set;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FarmerResponse {

    private UUID id;
    private String fullName;
    private String phoneNumber;
    private String email;
    private String district;
    private String gnDivision;
    private String address;
    private Double latitude;
    private Double longitude;
    private BigDecimal farmSizeAcres;
    private Set<CropType> primaryCrops;
    private PreferredLanguage preferredLanguage;
    private boolean phoneVerified;
    private FarmerStatus status;
    private String token;
    @Builder.Default
    private String tokenType = "Bearer";
    private Instant createdAt;
    private Instant updatedAt;
}
