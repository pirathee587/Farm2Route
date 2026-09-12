package com.farm2route.agency.review.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class AgencyReviewResponseRequest {
    @NotBlank(message = "Agency response cannot be blank")
    @Size(max = 1000, message = "Agency response cannot exceed 1000 characters")
    private String response;
}
