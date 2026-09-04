package com.farm2route.farmer.review.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdateReviewRequest {

    @NotNull(message = "Agency rating is required")
    @Min(value = 1, message = "Agency rating must be between 1 and 5")
    @Max(value = 5, message = "Agency rating must be between 1 and 5")
    private Integer agencyRating;

    @Size(max = 1000, message = "Agency comment cannot exceed 1000 characters")
    private String agencyComment;

    @Min(value = 1, message = "Driver rating must be between 1 and 5")
    @Max(value = 5, message = "Driver rating must be between 1 and 5")
    private Integer driverRating;

    @Size(max = 1000, message = "Driver comment cannot exceed 1000 characters")
    private String driverComment;
}
