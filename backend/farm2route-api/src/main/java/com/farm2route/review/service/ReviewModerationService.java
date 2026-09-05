package com.farm2route.review.service;

import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.auth.entity.User;
import com.farm2route.auth.repository.UserRepository;
import com.farm2route.booking.entity.Booking;
import com.farm2route.common.event.ReviewModeratedEvent;
import com.farm2route.common.exception.ResourceNotFoundException;
import com.farm2route.driver.entity.DriverProfile;
import com.farm2route.farmer.entity.FarmerProfile;
import com.farm2route.review.dto.AdminReviewDto;
import com.farm2route.review.entity.Review;
import com.farm2route.review.repository.ReviewRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class ReviewModerationService {

    public static final String MODERATION_APPROVED = "APPROVED";
    public static final String MODERATION_PENDING  = "PENDING_REVIEW";
    public static final String MODERATION_HIDDEN   = "HIDDEN";

    private final ReviewRepository reviewRepository;
    private final UserRepository userRepository;
    private final ApplicationEventPublisher eventPublisher;

    @Transactional(readOnly = true)
    public Page<AdminReviewDto> getReportedReviews(Pageable pageable) {
        Page<Review> page = reviewRepository.findByModerationStatusOrderByCreatedAtDesc(MODERATION_PENDING, pageable);
        return page.map(this::mapToDto);
    }

    @Transactional
    public AdminReviewDto hide(UUID reviewId, UUID adminId, String reason) {
        Review review = reviewRepository.findById(reviewId)
                .orElseThrow(() -> new ResourceNotFoundException("Review not found with ID: " + reviewId));

        review.setModerationStatus(MODERATION_HIDDEN);
        setAdminRef(review, adminId);

        Review saved = reviewRepository.save(review);
        log.info("Moderated reviewId={} to HIDDEN by adminId={}, reason='{}'", reviewId, adminId, reason);

        publishModeratedEvent(saved, "HIDE", adminId, reason);
        return mapToDto(saved);
    }

    @Transactional
    public AdminReviewDto restore(UUID reviewId, UUID adminId) {
        Review review = reviewRepository.findById(reviewId)
                .orElseThrow(() -> new ResourceNotFoundException("Review not found with ID: " + reviewId));

        review.setModerationStatus(MODERATION_APPROVED);
        setAdminRef(review, adminId);

        Review saved = reviewRepository.save(review);
        log.info("Restored reviewId={} to APPROVED by adminId={}", reviewId, adminId);

        publishModeratedEvent(saved, "RESTORE", adminId, null);
        return mapToDto(saved);
    }

    @Transactional
    public AdminReviewDto escalate(UUID reviewId, UUID adminId, String reason) {
        Review review = reviewRepository.findById(reviewId)
                .orElseThrow(() -> new ResourceNotFoundException("Review not found with ID: " + reviewId));

        // Status remains PENDING_REVIEW per requirements
        setAdminRef(review, adminId);

        Review saved = reviewRepository.save(review);
        log.info("Escalated reviewId={} by adminId={}", reviewId, adminId);

        publishModeratedEvent(saved, "ESCALATE", adminId, reason);
        return mapToDto(saved);
    }

    private void setAdminRef(Review review, UUID adminId) {
        if (adminId != null) {
            userRepository.findById(adminId).ifPresent(review::setModeratedByAdmin);
        }
    }

    private void publishModeratedEvent(Review review, String action, UUID adminId, String reason) {
        UUID farmerUserId = review.getFarmer() != null && review.getFarmer().getUser() != null
                ? review.getFarmer().getUser().getId()
                : null;

        UUID agencyId = review.getAgency() != null ? review.getAgency().getId() : null;

        eventPublisher.publishEvent(ReviewModeratedEvent.builder()
                .reviewId(review.getId())
                .farmerUserId(farmerUserId)
                .agencyId(agencyId)
                .action(action)
                .adminId(adminId)
                .reason(reason)
                .build());
    }

    private AdminReviewDto mapToDto(Review entity) {
        Booking booking = entity.getBooking();
        FarmerProfile farmer = entity.getFarmer();
        AgencyProfile agency = entity.getAgency();
        DriverProfile driver = entity.getDriver();

        return AdminReviewDto.builder()
                .id(entity.getId())
                .bookingId(booking != null ? booking.getId() : null)
                .bookingNumber(booking != null ? booking.getBookingNumber() : null)
                .farmerId(farmer != null ? farmer.getId() : null)
                .farmerName(farmer != null && farmer.getUser() != null ? farmer.getFarmName() : null)
                .agencyId(agency != null ? agency.getId() : null)
                .agencyName(agency != null ? agency.getCompanyName() : null)
                .driverId(driver != null ? driver.getId() : null)
                .driverName(driver != null ? driver.getFullName() : null)
                .agencyRating(entity.getAgencyRating())
                .driverRating(entity.getDriverRating())
                .comment(entity.getComment())
                .agencyComment(entity.getAgencyComment())
                .driverComment(entity.getDriverComment())
                .agencyResponse(entity.getAgencyResponse())
                .agencyRespondedAt(entity.getAgencyRespondedAt())
                .moderationStatus(entity.getModerationStatus())
                .moderatedByAdminId(entity.getModeratedByAdmin() != null ? entity.getModeratedByAdmin().getId() : null)
                .createdAt(entity.getCreatedAt())
                .updatedAt(entity.getUpdatedAt())
                .build();
    }
}
