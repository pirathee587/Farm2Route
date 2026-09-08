package com.farm2route.pod.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SubmitPodRequest {

    @NotBlank(message = "Recipient name cannot be blank")
    private String recipientName;

    @NotBlank(message = "Recipient phone cannot be blank")
    private String recipientPhone;

    @NotNull(message = "Delivery latitude is required")
    private BigDecimal deliveryLatitude;

    @NotNull(message = "Delivery longitude is required")
    private BigDecimal deliveryLongitude;

    private String notes;
}
