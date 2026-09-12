package com.farm2route.trip.dto;

import com.farm2route.common.enums.DriverAvailability;
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
public class AssignmentRecommendationResponse {

    private UUID bookingId;
    private UUID recommendedDriverId;
    private String recommendedDriverName;
    private BigDecimal recommendedDriverRating;
    private DriverAvailability recommendedDriverAvailability;
    private UUID recommendedVehicleId;
    private String recommendedVehicleRegistrationNumber;
    private String recommendedVehicleMakeAndModel;
    private BigDecimal recommendedVehicleCapacity;
    private VehicleType recommendedVehicleType;
    private double matchScore;
    private String rationale;
}
