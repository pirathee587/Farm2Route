package com.farm2route.booking.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
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
public class CreateBookingRequest {

    @NotNull(message = "Agency ID is required")
    private UUID agencyId;

    private UUID packageId;

    private String pickupContactName;
    private String pickupContactPhone;

    @NotBlank(message = "Pickup address is required")
    private String pickupAddress;

    @NotNull(message = "Pickup latitude is required")
    private BigDecimal pickupLatitude;

    @NotNull(message = "Pickup longitude is required")
    private BigDecimal pickupLongitude;

    @NotBlank(message = "Delivery address is required")
    private String deliveryAddress;

    @NotNull(message = "Delivery latitude is required")
    private BigDecimal deliveryLatitude;

    @NotNull(message = "Delivery longitude is required")
    private BigDecimal deliveryLongitude;

    @NotBlank(message = "Recipient name is required")
    private String recipientName;

    @NotBlank(message = "Recipient phone is required")
    private String recipientPhone;

    @NotBlank(message = "Cargo type is required")
    private String cargoType;

    @NotNull(message = "Cargo weight is required")
    @Positive(message = "Cargo weight must be positive")
    private BigDecimal cargoWeightKg;

    private BigDecimal cargoVolumeCbm;

    private boolean fragile;
    private boolean requiresRefrigeration;
    private String specialInstructions;

    @NotNull(message = "Scheduled pickup time is required")
    private Instant scheduledPickupAt;

    @NotNull(message = "Total estimated amount is required")
    @Positive(message = "Total amount must be positive")
    private BigDecimal totalAmount;
}
