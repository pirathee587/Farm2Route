package com.farm2route.transport.dto;

import com.farm2route.common.enums.VehicleStatus;
import com.farm2route.common.enums.VehicleType;
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
public class VehicleRecommendationDto {

    private UUID vehicleId;
    private String registrationNumber;
    private String makeAndModel;
    private VehicleType vehicleType;
    private BigDecimal maxPayloadWeightKg;
    private BigDecimal maxCargoVolumeCbm;
    private boolean isRefrigerated;
    private VehicleStatus status;
    private UUID agencyId;
    private String agencyName;
    private double recommendationScore;
    private String suitabilityReason;
    private PriceEstimationResponse priceEstimate;
}
