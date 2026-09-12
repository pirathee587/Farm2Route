package com.farm2route.agency.review.service;

import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.agency.repository.AgencyProfileRepository;
import com.farm2route.agency.review.dto.AgencyReviewResponseRequest;
import com.farm2route.booking.entity.Booking;
import com.farm2route.driver.repository.DriverProfileRepository;
import com.farm2route.review.entity.Review;
import com.farm2route.review.repository.ReviewRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AgencyReviewServiceTest {
    @Mock AgencyProfileRepository agencyRepository;
    @Mock ReviewRepository reviewRepository;
    @Mock DriverProfileRepository driverRepository;
    private AgencyReviewService service;
    private final UUID userId = UUID.randomUUID();
    private final UUID agencyId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        service = new AgencyReviewService(agencyRepository, reviewRepository, driverRepository);
        when(agencyRepository.findByUserId(userId)).thenReturn(Optional.of(AgencyProfile.builder().id(agencyId).build()));
    }

    @Test
    void listsOwnVisibleReviewsAndExcludesHiddenReviews() {
        Review visible = Review.builder().id(UUID.randomUUID()).agencyRating(5).moderationStatus("APPROVED").build();
        Review hidden = Review.builder().id(UUID.randomUUID()).agencyRating(1).moderationStatus("HIDDEN").build();
        when(reviewRepository.findByAgencyId(agencyId)).thenReturn(List.of(visible, hidden));

        assertThat(service.list(userId, null, null, null, null)).extracting("id").containsExactly(visible.getId());
        verify(reviewRepository).findByAgencyId(agencyId);
    }

    @Test
    void respondsOnlyToOwnReview() {
        UUID reviewId = UUID.randomUUID();
        Review review = Review.builder().id(reviewId).agencyResponse("old").build();
        when(reviewRepository.findByIdAndAgencyId(reviewId, agencyId)).thenReturn(Optional.of(review));
        when(reviewRepository.save(review)).thenReturn(review);
        AgencyReviewResponseRequest request = new AgencyReviewResponseRequest();
        request.setResponse("  Thank you for your feedback.  ");

        assertThat(service.respond(userId, reviewId, request).getAgencyResponse())
                .isEqualTo("Thank you for your feedback.");
        verify(reviewRepository).save(review);
    }

    @Test
    void rejectsBlankResponse() {
        when(reviewRepository.findByIdAndAgencyId(any(), eq(agencyId)))
                .thenReturn(Optional.of(Review.builder().build()));
        AgencyReviewResponseRequest request = new AgencyReviewResponseRequest();
        request.setResponse("   ");
        assertThatThrownBy(() -> service.respond(userId, UUID.randomUUID(), request))
                .isInstanceOf(IllegalArgumentException.class);
        verify(reviewRepository, never()).save(any());
    }

    @Test
    void rejectsDriverOwnedByAnotherAgency() {
        UUID driverId = UUID.randomUUID();
        when(driverRepository.findByIdAndAgencyId(driverId, agencyId)).thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.listDriverReviews(userId, driverId))
                .isInstanceOf(com.farm2route.common.exception.ForbiddenException.class);
        verify(reviewRepository, never()).findByDriverId(any());
    }
}
