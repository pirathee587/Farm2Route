package com.farm2route.review.dto;

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
public class AdminReviewDto {

    private UUID id;
    private UUID bookingId;
    private String bookingNumber;

    private UUID farmerId;
    private String farmerName;

    private UUID agencyId;
    private String agencyName;

    private UUID driverId;
    private String driverName;

    private Integer agencyRating;
    private Integer driverRating;
    private String comment;
    private String agencyComment;
    private String driverComment;

    private String agencyResponse;
    private Instant agencyRespondedAt;

    private String moderationStatus;
    private UUID moderatedByAdminId;

    private Instant createdAt;
    private Instant updatedAt;
}
