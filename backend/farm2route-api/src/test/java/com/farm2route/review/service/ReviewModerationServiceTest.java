package com.farm2route.review.service;

import com.farm2route.auth.entity.User;
import com.farm2route.auth.repository.UserRepository;
import com.farm2route.common.event.ReviewModeratedEvent;
import com.farm2route.common.exception.ResourceNotFoundException;
import com.farm2route.review.dto.AdminReviewDto;
import com.farm2route.review.entity.Review;
import com.farm2route.review.repository.ReviewRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;

import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ReviewModerationServiceTest {

    @Mock
    private ReviewRepository reviewRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private ApplicationEventPublisher eventPublisher;

    @InjectMocks
    private ReviewModerationService reviewModerationService;

    private UUID reviewId;
    private UUID adminId;
    private Review review;
    private User adminUser;

    @BeforeEach
    void setUp() {
        reviewId = UUID.randomUUID();
        adminId = UUID.randomUUID();

        review = Review.builder()
                .id(reviewId)
                .agencyRating(4)
                .comment("Great service")
                .moderationStatus("APPROVED")
                .build();

        adminUser = User.builder().id(adminId).build();
    }

    @Test
    @DisplayName("hide transitions moderationStatus to HIDDEN and publishes ReviewModeratedEvent")
    void testHide_SetsHiddenStatusAndPublishesEvent() {
        when(reviewRepository.findById(reviewId)).thenReturn(Optional.of(review));
        when(userRepository.findById(adminId)).thenReturn(Optional.of(adminUser));
        when(reviewRepository.save(any(Review.class))).thenAnswer(inv -> inv.getArgument(0));

        AdminReviewDto result = reviewModerationService.hide(reviewId, adminId, "Inappropriate language");

        assertNotNull(result);
        assertEquals("HIDDEN", result.getModerationStatus());
        assertEquals(adminId, result.getModeratedByAdminId());

        ArgumentCaptor<ReviewModeratedEvent> eventCaptor = ArgumentCaptor.forClass(ReviewModeratedEvent.class);
        verify(eventPublisher).publishEvent(eventCaptor.capture());

        ReviewModeratedEvent event = eventCaptor.getValue();
        assertEquals(reviewId, event.getReviewId());
        assertEquals("HIDE", event.getAction());
        assertEquals("Inappropriate language", event.getReason());
        assertEquals(adminId, event.getAdminId());
    }

    @Test
    @DisplayName("restore transitions moderationStatus to APPROVED and publishes ReviewModeratedEvent")
    void testRestore_SetsApprovedStatusAndPublishesEvent() {
        review.setModerationStatus("HIDDEN");
        when(reviewRepository.findById(reviewId)).thenReturn(Optional.of(review));
        when(userRepository.findById(adminId)).thenReturn(Optional.of(adminUser));
        when(reviewRepository.save(any(Review.class))).thenAnswer(inv -> inv.getArgument(0));

        AdminReviewDto result = reviewModerationService.restore(reviewId, adminId);

        assertNotNull(result);
        assertEquals("APPROVED", result.getModerationStatus());

        ArgumentCaptor<ReviewModeratedEvent> eventCaptor = ArgumentCaptor.forClass(ReviewModeratedEvent.class);
        verify(eventPublisher).publishEvent(eventCaptor.capture());

        ReviewModeratedEvent event = eventCaptor.getValue();
        assertEquals("RESTORE", event.getAction());
        assertEquals(adminId, event.getAdminId());
    }

    @Test
    @DisplayName("escalate retains PENDING_REVIEW moderationStatus and publishes ReviewModeratedEvent")
    void testEscalate_RetainsPendingReviewStatusAndPublishesEvent() {
        review.setModerationStatus("PENDING_REVIEW");
        when(reviewRepository.findById(reviewId)).thenReturn(Optional.of(review));
        when(userRepository.findById(adminId)).thenReturn(Optional.of(adminUser));
        when(reviewRepository.save(any(Review.class))).thenAnswer(inv -> inv.getArgument(0));

        AdminReviewDto result = reviewModerationService.escalate(reviewId, adminId, "Requires senior moderator review");

        assertNotNull(result);
        assertEquals("PENDING_REVIEW", result.getModerationStatus()); // Status unchanged!

        ArgumentCaptor<ReviewModeratedEvent> eventCaptor = ArgumentCaptor.forClass(ReviewModeratedEvent.class);
        verify(eventPublisher).publishEvent(eventCaptor.capture());

        ReviewModeratedEvent event = eventCaptor.getValue();
        assertEquals("ESCALATE", event.getAction());
        assertEquals("Requires senior moderator review", event.getReason());
    }

    @Test
    @DisplayName("hide throws ResourceNotFoundException for unknown review ID")
    void testHide_NotFoundThrowsException() {
        UUID unknownId = UUID.randomUUID();
        when(reviewRepository.findById(unknownId)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> reviewModerationService.hide(unknownId, adminId, "reason"));
    }
}
