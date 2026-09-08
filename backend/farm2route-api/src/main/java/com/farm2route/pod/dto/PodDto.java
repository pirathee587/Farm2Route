package com.farm2route.pod.dto;

import com.farm2route.common.enums.PodConfirmationStatus;
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
public class PodDto {

    private UUID id;
    private UUID bookingId;
    private String bookingNumber;
    private UUID driverId;
    private String driverName;

    private String recipientName;
    private String recipientPhone;
    private String recipientSignatureUrl;
    private String deliveryPhotoUrl;

    private BigDecimal deliveryLatitude;
    private BigDecimal deliveryLongitude;
    private Instant deliveryTimestamp;

    private PodConfirmationStatus farmerConfirmationStatus;
    private Instant farmerConfirmedAt;
    private String notes;
    private Instant createdAt;
}
