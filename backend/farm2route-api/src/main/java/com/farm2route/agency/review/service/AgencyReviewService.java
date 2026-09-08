package com.farm2route.agency.review.service;

import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.agency.repository.AgencyProfileRepository;
import com.farm2route.agency.review.dto.AgencyReviewResponse;
import com.farm2route.agency.review.dto.AgencyReviewResponseRequest;
import com.farm2route.common.exception.ForbiddenException;
import com.farm2route.common.exception.ResourceNotFoundException;
import com.farm2route.driver.entity.DriverProfile;
import com.farm2route.driver.repository.DriverProfileRepository;
import com.farm2route.review.entity.Review;
import com.farm2route.review.repository.ReviewRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AgencyReviewService {
    private final AgencyProfileRepository agencyProfileRepository;
    private final ReviewRepository reviewRepository;
    private final DriverProfileRepository driverProfileRepository;

    @Transactional(readOnly = true)
    public List<AgencyReviewResponse> list(UUID agencyUserId, Integer rating, UUID bookingId, UUID driverId,
                                           String moderationStatus) {
        UUID agencyId = resolveAgency(agencyUserId).getId();
        if (driverId != null) {
            requireDriverBelongsToAgency(driverId, agencyId);
        }
        return reviewRepository.findByAgencyId(agencyId).stream()
                .filter(review -> !"HIDDEN".equalsIgnoreCase(review.getModerationStatus()))
                .filter(review -> rating == null || rating.equals(review.getAgencyRating()))
                .filter(review -> bookingId == null || (review.getBooking() != null && bookingId.equals(review.getBooking().getId())))
                .filter(review -> driverId == null || (review.getDriver() != null && driverId.equals(review.getDriver().getId())))
                .filter(review -> moderationStatus == null || moderationStatus.equalsIgnoreCase(review.getModerationStatus()))
                .map(AgencyReviewResponse::from)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<AgencyReviewResponse> listDriverReviews(UUID agencyUserId, UUID driverId) {
        UUID agencyId = resolveAgency(agencyUserId).getId();
        requireDriverBelongsToAgency(driverId, agencyId);
        return reviewRepository.findByDriverId(driverId).stream()
                .filter(review -> agencyId.equals(review.getAgency() == null ? null : review.getAgency().getId()))
                .filter(review -> !"HIDDEN".equalsIgnoreCase(review.getModerationStatus()))
                .map(AgencyReviewResponse::from)
                .collect(Collectors.toList());
    }

    @Transactional
    public AgencyReviewResponse respond(UUID agencyUserId, UUID reviewId, AgencyReviewResponseRequest request) {
        UUID agencyId = resolveAgency(agencyUserId).getId();
        Review review = reviewRepository.findByIdAndAgencyId(reviewId, agencyId)
                .orElseThrow(() -> new ResourceNotFoundException("Review not found"));
        String response = request.getResponse() == null ? null : request.getResponse().trim();
        if (response == null || response.isBlank()) {
            throw new IllegalArgumentException("Agency response cannot be blank");
        }
        review.setAgencyResponse(response);
        review.setAgencyRespondedAt(java.time.Instant.now());
        return AgencyReviewResponse.from(reviewRepository.save(review));
    }

    private AgencyProfile resolveAgency(UUID userId) {
        return agencyProfileRepository.findByUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Agency profile not found"));
    }

    private void requireDriverBelongsToAgency(UUID driverId, UUID agencyId) {
        DriverProfile driver = driverProfileRepository.findByIdAndAgencyId(driverId, agencyId)
                .orElseThrow(() -> new ForbiddenException("Driver does not belong to this agency"));
    }
}
