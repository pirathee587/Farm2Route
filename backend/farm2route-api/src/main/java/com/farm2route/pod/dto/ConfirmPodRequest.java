package com.farm2route.pod.dto;

import com.farm2route.common.enums.PodConfirmationStatus;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ConfirmPodRequest {

    @NotNull(message = "Status must be CONFIRMED or DISPUTED")
    private PodConfirmationStatus status;

    private String notes;
}
