package com.farm2route.farmer.dto;

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
public class FarmerProfileDto {

    private UUID id;
    private UUID userId;
    private String farmName;

    @NotBlank(message = "Farm address is required")
    private String address;

    @NotBlank(message = "District is required")
    private String district;

    @NotBlank(message = "Province is required")
    private String province;

    private BigDecimal latitude;
    private BigDecimal longitude;
    private BigDecimal farmSizeHectares;
}
