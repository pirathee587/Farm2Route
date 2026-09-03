package com.farm2route.farmer.review.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ReviewResponse {
    private UUID id;
    private UUID bookingId;
    private UUID farmerId;
    private UUID agencyId;
    private UUID driverId;
    private Integer agencyRating;
    private String agencyComment;
    private Integer driverRating;
    private String driverComment;
    private Instant createdAt;
    private Instant updatedAt;
}
