package com.farm2route.farmer.review.service;

import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.audit.service.AuditService;
import com.farm2route.auth.entity.User;
import com.farm2route.auth.repository.UserRepository;
import com.farm2route.booking.entity.Booking;
import com.farm2route.booking.repository.BookingRepository;
import com.farm2route.common.enums.BookingStatus;
import com.farm2route.common.exception.ConflictException;
import com.farm2route.common.exception.ForbiddenException;
import com.farm2route.common.exception.ResourceNotFoundException;
import com.farm2route.driver.entity.DriverProfile;
import com.farm2route.farmer.entity.FarmerProfile;
import com.farm2route.farmer.repository.FarmerProfileRepository;
import com.farm2route.farmer.review.dto.ReviewResponse;
import com.farm2route.farmer.review.dto.SubmitReviewRequest;
import com.farm2route.farmer.review.dto.UpdateReviewRequest;
import com.farm2route.review.entity.Review;
import com.farm2route.review.repository.ReviewRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class FarmerReviewService {

    private final ReviewRepository reviewRepository;
    private final BookingRepository bookingRepository;
    private final FarmerProfileRepository farmerProfileRepository;
    private final UserRepository userRepository;
    private final AuditService auditService;

    /**
     * Submits a new review for a completed (DELIVERED) booking.
     * Enforces farmer ownership, DELIVERED status, duplicate prevention, and derives targets from booking.
     */
    @Transactional
    public ReviewResponse submitReview(UUID farmerUserId, UUID bookingId, SubmitReviewRequest request) {
        Booking booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new ResourceNotFoundException("Booking not found with id: " + bookingId));

        validateBookingOwnership(booking, farmerUserId);

        if (booking.getStatus() != BookingStatus.DELIVERED) {
            log.warn("Farmer {} attempted to review booking {} with non-delivered status {}",
                    farmerUserId, bookingId, booking.getStatus());
            throw new ConflictException("Reviews can only be submitted for bookings with DELIVERED status. Current status: " + booking.getStatus());
        }

        if (reviewRepository.existsByBookingId(bookingId)) {
            log.warn("Farmer {} attempted duplicate review submission for booking {}", farmerUserId, bookingId);
            throw new ConflictException("A review has already been submitted for this booking.");
        }

        AgencyProfile agency = booking.getAgency();
        DriverProfile driver = booking.getDriver();

        String trimmedAgencyComment = request.getAgencyComment() != null ? request.getAgencyComment().trim() : null;
        String trimmedDriverComment = request.getDriverComment() != null ? request.getDriverComment().trim() : null;

        Review review = Review.builder()
                .booking(booking)
                .farmer(booking.getFarmer())
                .agency(agency)
                .driver(driver)
                .agencyRating(request.getAgencyRating())
                .agencyComment(trimmedAgencyComment)
                .comment(trimmedAgencyComment)
                .driverRating(request.getDriverRating())
                .driverComment(trimmedDriverComment)
                .moderationStatus("APPROVED")
                .build();

        Review savedReview;
        try {
            savedReview = reviewRepository.saveAndFlush(review);
        } catch (DataIntegrityViolationException ex) {
            log.warn("Concurrent duplicate review detected for booking {}: {}", bookingId, ex.getMessage());
            throw new ConflictException("A review has already been submitted for this booking.");
        }

        try {
            User actor = userRepository.findById(farmerUserId).orElse(null);
            auditService.logAction(
                    actor,
                    "REVIEW_SUBMITTED",
                    "REVIEW",
                    savedReview.getId().toString(),
                    null,
                    "bookingId=" + bookingId + ",agencyRating=" + savedReview.getAgencyRating(),
                    null,
                    null
            );
        } catch (Exception ex) {
            log.warn("Failed to record audit log for review submission {}: {}", savedReview.getId(), ex.getMessage());
        }

        log.info("Review {} submitted successfully by farmer {} for booking {}", savedReview.getId(), farmerUserId, bookingId);
        return mapToResponse(savedReview);
    }

    /**
     * Updates an existing review submitted by the authenticated farmer.
     * Updates only farmer-owned fields and leaves moderation state intact.
     */
    @Transactional
    public ReviewResponse updateReview(UUID farmerUserId, UUID bookingId, UpdateReviewRequest request) {
        Booking booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new ResourceNotFoundException("Booking not found with id: " + bookingId));

        validateBookingOwnership(booking, farmerUserId);

        Review review = reviewRepository.findByBookingId(bookingId)
                .orElseThrow(() -> new ResourceNotFoundException("No review found for booking " + bookingId));

        if (review.getFarmer() == null || review.getFarmer().getUser() == null ||
                !review.getFarmer().getUser().getId().equals(farmerUserId)) {
            log.warn("Farmer {} attempted to edit review {} owned by another farmer", farmerUserId, review.getId());
            throw new ForbiddenException("You are not authorized to edit this review");
        }

        String oldValue = "agencyRating=" + review.getAgencyRating() + ",driverRating=" + review.getDriverRating();

        String trimmedAgencyComment = request.getAgencyComment() != null ? request.getAgencyComment().trim() : null;
        String trimmedDriverComment = request.getDriverComment() != null ? request.getDriverComment().trim() : null;

        review.setAgencyRating(request.getAgencyRating());
        review.setAgencyComment(trimmedAgencyComment);
        review.setComment(trimmedAgencyComment);
        review.setDriverRating(request.getDriverRating());
        review.setDriverComment(trimmedDriverComment);

        Review updatedReview = reviewRepository.save(review);

        try {
            User actor = userRepository.findById(farmerUserId).orElse(null);
            auditService.logAction(
                    actor,
                    "REVIEW_UPDATED",
                    "REVIEW",
                    updatedReview.getId().toString(),
                    oldValue,
                    "agencyRating=" + updatedReview.getAgencyRating() + ",driverRating=" + updatedReview.getDriverRating(),
                    null,
                    null
            );
        } catch (Exception ex) {
            log.warn("Failed to record audit log for review update {}: {}", updatedReview.getId(), ex.getMessage());
        }

        log.info("Review {} updated successfully by farmer {} for booking {}", updatedReview.getId(), farmerUserId, bookingId);
        return mapToResponse(updatedReview);
    }

    /**
     * Retrieves the review for a specific booking owned by the authenticated farmer.
     */
    @Transactional(readOnly = true)
    public ReviewResponse getReview(UUID farmerUserId, UUID bookingId) {
        Booking booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new ResourceNotFoundException("Booking not found with id: " + bookingId));

        validateBookingOwnership(booking, farmerUserId);

        Review review = reviewRepository.findByBookingId(bookingId)
                .orElseThrow(() -> new ResourceNotFoundException("No review found for booking " + bookingId));

        return mapToResponse(review);
    }

    private void validateBookingOwnership(Booking booking, UUID farmerUserId) {
        FarmerProfile farmerProfile = booking.getFarmer();
        if (farmerProfile == null || farmerProfile.getUser() == null ||
                !farmerProfile.getUser().getId().equals(farmerUserId)) {
            log.warn("Farmer {} attempted unauthorized access to booking {}", farmerUserId, booking.getId());
            throw new ForbiddenException("You are not authorized to access this booking");
        }
    }

    private ReviewResponse mapToResponse(Review review) {
        return ReviewResponse.builder()
                .id(review.getId())
                .bookingId(review.getBooking() != null ? review.getBooking().getId() : null)
                .farmerId(review.getFarmer() != null ? review.getFarmer().getId() : null)
                .agencyId(review.getAgency() != null ? review.getAgency().getId() : null)
                .driverId(review.getDriver() != null ? review.getDriver().getId() : null)
                .agencyRating(review.getAgencyRating())
                .agencyComment(review.getAgencyComment() != null ? review.getAgencyComment() : review.getComment())
                .driverRating(review.getDriverRating())
                .driverComment(review.getDriverComment())
                .createdAt(review.getCreatedAt())
                .updatedAt(review.getUpdatedAt())
                .build();
    }
}
