package com.farm2route.booking.dto;

import com.farm2route.common.enums.BookingStatus;
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
public class BookingDto {
    private UUID id;
    private String bookingNumber;
    private UUID farmerId;
    private UUID agencyId;
    private UUID driverId;
    private String pickupAddress;
    private BigDecimal pickupLatitude;
    private BigDecimal pickupLongitude;
    private String deliveryAddress;
    private BigDecimal deliveryLatitude;
    private BigDecimal deliveryLongitude;
    private String recipientName;
    private String recipientPhone;
    private String cargoType;
    private BigDecimal cargoWeightKg;
    private boolean isFragile;
    private boolean requiresRefrigeration;
    private BigDecimal totalAmount;
    private BookingStatus status;
    private Instant scheduledPickupAt;
    private Instant createdAt;
}
