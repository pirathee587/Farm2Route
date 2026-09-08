package com.farm2route.agency.review.dto;

import com.farm2route.review.entity.Review;
import lombok.Builder;
import lombok.Value;

import java.time.Instant;
import java.util.UUID;

@Value
@Builder
public class AgencyReviewResponse {
    UUID id;
    UUID bookingId;
    String bookingNumber;
    UUID farmerId;
    UUID driverId;
    String driverName;
    Integer agencyRating;
    String agencyComment;
    Integer driverRating;
    String driverComment;
    String agencyResponse;
    Instant agencyRespondedAt;
    String moderationStatus;
    Instant createdAt;
    Instant updatedAt;

    public static AgencyReviewResponse from(Review review) {
        return AgencyReviewResponse.builder()
                .id(review.getId())
                .bookingId(review.getBooking() == null ? null : review.getBooking().getId())
                .bookingNumber(review.getBooking() == null ? null : review.getBooking().getBookingNumber())
                .farmerId(review.getFarmer() == null ? null : review.getFarmer().getId())
                .driverId(review.getDriver() == null ? null : review.getDriver().getId())
                .driverName(review.getDriver() == null ? null : review.getDriver().getFullName())
                .agencyRating(review.getAgencyRating())
                .agencyComment(review.getAgencyComment() != null ? review.getAgencyComment() : review.getComment())
                .driverRating(review.getDriverRating())
                .driverComment(review.getDriverComment())
                .agencyResponse(review.getAgencyResponse())
                .agencyRespondedAt(review.getAgencyRespondedAt())
                .moderationStatus(review.getModerationStatus())
                .createdAt(review.getCreatedAt())
                .updatedAt(review.getUpdatedAt())
                .build();
    }
}
