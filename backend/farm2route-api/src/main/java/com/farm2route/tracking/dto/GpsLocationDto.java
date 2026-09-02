package com.farm2route.tracking.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GpsLocationDto {
    private UUID tripId;
    private UUID bookingId;
    private UUID driverId;
    private BigDecimal latitude;
    private BigDecimal longitude;
    private BigDecimal speedKmh;
    private BigDecimal headingDegrees;
    private BigDecimal accuracyMeters;
    private Instant timestamp;
}
