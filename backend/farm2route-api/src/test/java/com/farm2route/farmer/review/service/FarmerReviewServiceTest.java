package com.farm2route.farmer.review.service;

import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.audit.service.AuditService;
import com.farm2route.auth.entity.User;
import com.farm2route.auth.model.Role;
import com.farm2route.auth.model.UserStatus;
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
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.EnumSource;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DataIntegrityViolationException;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class FarmerReviewServiceTest {

    @Mock
    private ReviewRepository reviewRepository;

    @Mock
    private BookingRepository bookingRepository;

    @Mock
    private FarmerProfileRepository farmerProfileRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private AuditService auditService;

    @Mock
    private org.springframework.context.ApplicationEventPublisher applicationEventPublisher;

    @InjectMocks
    private FarmerReviewService farmerReviewService;

    private UUID farmerUserId;
    private UUID otherFarmerUserId;
    private UUID bookingId;
    private UUID reviewId;
    private User farmerUser;
    private User otherUser;
    private FarmerProfile farmerProfile;
    private AgencyProfile agencyProfile;
    private DriverProfile driverProfile;
    private Booking deliveredBooking;
    private SubmitReviewRequest submitRequest;

    @BeforeEach
    void setUp() {
        farmerUserId = UUID.randomUUID();
        otherFarmerUserId = UUID.randomUUID();
        bookingId = UUID.randomUUID();
        reviewId = UUID.randomUUID();

        farmerUser = User.builder()
                .id(farmerUserId)
                .email("farmer@farm2route.lk")
                .phoneNumber("+94771234567")
                .role(Role.FARMER)
                .status(UserStatus.ACTIVE)
                .build();

        otherUser = User.builder()
                .id(otherFarmerUserId)
                .email("other@farm2route.lk")
                .phoneNumber("+94777654321")
                .role(Role.FARMER)
                .status(UserStatus.ACTIVE)
                .build();

        farmerProfile = FarmerProfile.builder()
                .id(UUID.randomUUID())
                .user(farmerUser)
                .farmName("Green Acres")
                .address("123 Farm Road")
                .district("Kandy")
                .province("Central")
                .build();

        agencyProfile = AgencyProfile.builder()
                .id(UUID.randomUUID())
                .companyName("Fast Freight Ltd")
                .businessRegistrationNumber("BR-12345")
                .officeAddress("45 Harbor St, Colombo")
                .district("Colombo")
                .contactPersonName("Jane Agency")
                .contactPersonPhone("+94112345678")
                .build();

        driverProfile = DriverProfile.builder()
                .id(UUID.randomUUID())
                .agency(agencyProfile)
                .drivingLicenseNumber("B1234567")
                .nicNumber("199012345678")
                .build();

        deliveredBooking = Booking.builder()
                .id(bookingId)
                .bookingNumber("F2R-TEST-1001")
                .farmer(farmerProfile)
                .agency(agencyProfile)
                .driver(driverProfile)
                .status(BookingStatus.DELIVERED)
                .pickupAddress("Kandy")
                .deliveryAddress("Colombo")
                .recipientName("Recipient")
                .recipientPhone("+94771112233")
                .cargoType("VEGETABLES")
                .build();

        submitRequest = SubmitReviewRequest.builder()
                .agencyRating(5)
                .agencyComment("Outstanding logistics support")
                .driverRating(4)
                .driverComment("Polite and timely delivery")
                .build();
    }

    @Test
    @DisplayName("Should successfully submit review with assigned driver and record audit")
    void submitReview_success_withDriver() {
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(deliveredBooking));
        when(reviewRepository.existsByBookingId(bookingId)).thenReturn(false);
        when(reviewRepository.saveAndFlush(any(Review.class))).thenAnswer(invocation -> {
            Review review = invocation.getArgument(0);
            review.setId(reviewId);
            review.setCreatedAt(Instant.now());
            review.setUpdatedAt(Instant.now());
            return review;
        });
        ReviewResponse response = farmerReviewService.submitReview(farmerUserId, bookingId, submitRequest);

        assertThat(response).isNotNull();
        assertThat(response.getId()).isEqualTo(reviewId);
        assertThat(response.getBookingId()).isEqualTo(bookingId);
        assertThat(response.getAgencyRating()).isEqualTo(5);
        assertThat(response.getAgencyComment()).isEqualTo("Outstanding logistics support");
        assertThat(response.getDriverRating()).isEqualTo(4);
        assertThat(response.getDriverComment()).isEqualTo("Polite and timely delivery");

        verify(reviewRepository).saveAndFlush(any(Review.class));
        verify(applicationEventPublisher).publishEvent(any(com.farm2route.common.event.ReviewSubmittedEvent.class));
    }

    @Test
    @DisplayName("Should successfully submit review when booking driver is null (Member 2 assignment pending)")
    void submitReview_success_withoutDriver() {
        deliveredBooking.setDriver(null);
        submitRequest.setDriverRating(null);
        submitRequest.setDriverComment(null);

        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(deliveredBooking));
        when(reviewRepository.existsByBookingId(bookingId)).thenReturn(false);
        when(reviewRepository.saveAndFlush(any(Review.class))).thenAnswer(invocation -> {
            Review review = invocation.getArgument(0);
            review.setId(reviewId);
            review.setCreatedAt(Instant.now());
            review.setUpdatedAt(Instant.now());
            return review;
        });

        ReviewResponse response = farmerReviewService.submitReview(farmerUserId, bookingId, submitRequest);

        assertThat(response).isNotNull();
        assertThat(response.getDriverId()).isNull();
        assertThat(response.getDriverRating()).isNull();
        assertThat(response.getAgencyRating()).isEqualTo(5);
        verify(reviewRepository).saveAndFlush(any(Review.class));
        verify(applicationEventPublisher).publishEvent(any(com.farm2route.common.event.ReviewSubmittedEvent.class));
    }

    @Test
    @DisplayName("Should throw ForbiddenException when farmer does not own the booking")
    void submitReview_forbidden_differentFarmer() {
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(deliveredBooking));

        assertThatThrownBy(() -> farmerReviewService.submitReview(otherFarmerUserId, bookingId, submitRequest))
                .isInstanceOf(ForbiddenException.class)
                .hasMessageContaining("not authorized to access this booking");

        verify(reviewRepository, never()).saveAndFlush(any());
    }

    @ParameterizedTest
    @EnumSource(value = BookingStatus.class, names = {"PENDING", "ACCEPTED", "REJECTED", "DRIVER_ASSIGNED", "IN_TRANSIT", "CANCELLED"})
    @DisplayName("Should reject review submission with 409 Conflict if booking is not DELIVERED")
    void submitReview_conflict_notDelivered(BookingStatus status) {
        deliveredBooking.setStatus(status);
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(deliveredBooking));

        assertThatThrownBy(() -> farmerReviewService.submitReview(farmerUserId, bookingId, submitRequest))
                .isInstanceOf(ConflictException.class)
                .hasMessageContaining("DELIVERED status");

        verify(reviewRepository, never()).saveAndFlush(any());
    }

    @Test
    @DisplayName("Should throw ConflictException when duplicate review is detected at application check")
    void submitReview_conflict_duplicate() {
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(deliveredBooking));
        when(reviewRepository.existsByBookingId(bookingId)).thenReturn(true);

        assertThatThrownBy(() -> farmerReviewService.submitReview(farmerUserId, bookingId, submitRequest))
                .isInstanceOf(ConflictException.class)
                .hasMessageContaining("already been submitted");

        verify(reviewRepository, never()).saveAndFlush(any());
    }

    @Test
    @DisplayName("Should convert DataIntegrityViolationException to ConflictException on concurrent duplicate insert")
    void submitReview_conflict_concurrentDuplicate() {
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(deliveredBooking));
        when(reviewRepository.existsByBookingId(bookingId)).thenReturn(false);
        when(reviewRepository.saveAndFlush(any(Review.class)))
                .thenThrow(new DataIntegrityViolationException("duplicate key value violates unique constraint"));

        assertThatThrownBy(() -> farmerReviewService.submitReview(farmerUserId, bookingId, submitRequest))
                .isInstanceOf(ConflictException.class)
                .hasMessageContaining("already been submitted");
    }

    @Test
    @DisplayName("Should throw ResourceNotFoundException when booking does not exist")
    void submitReview_notFound_booking() {
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> farmerReviewService.submitReview(farmerUserId, bookingId, submitRequest))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Booking not found");
    }

    @Test
    @DisplayName("Should successfully update own review without altering moderation fields")
    void updateReview_success() {
        Review existingReview = Review.builder()
                .id(reviewId)
                .booking(deliveredBooking)
                .farmer(farmerProfile)
                .agency(agencyProfile)
                .driver(driverProfile)
                .agencyRating(5)
                .agencyComment("Old agency comment")
                .driverRating(4)
                .driverComment("Old driver comment")
                .moderationStatus("APPROVED")
                .moderatedByAdmin(null)
                .build();

        UpdateReviewRequest updateRequest = UpdateReviewRequest.builder()
                .agencyRating(4)
                .agencyComment("Updated agency feedback")
                .driverRating(5)
                .driverComment("Driver was exceptional on second thought")
                .build();

        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(deliveredBooking));
        when(reviewRepository.findByBookingId(bookingId)).thenReturn(Optional.of(existingReview));
        when(reviewRepository.save(any(Review.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(userRepository.findById(farmerUserId)).thenReturn(Optional.of(farmerUser));

        ReviewResponse response = farmerReviewService.updateReview(farmerUserId, bookingId, updateRequest);

        assertThat(response).isNotNull();
        assertThat(response.getAgencyRating()).isEqualTo(4);
        assertThat(response.getAgencyComment()).isEqualTo("Updated agency feedback");
        assertThat(response.getDriverRating()).isEqualTo(5);
        assertThat(response.getDriverComment()).isEqualTo("Driver was exceptional on second thought");

        // Ensure moderation fields are preserved
        assertThat(existingReview.getModerationStatus()).isEqualTo("APPROVED");
        assertThat(existingReview.getModeratedByAdmin()).isNull();

        verify(auditService).logAction(
                eq(farmerUser),
                eq("REVIEW_UPDATED"),
                eq("REVIEW"),
                eq(reviewId.toString()),
                any(),
                any(),
                isNull(),
                isNull()
        );
    }

    @Test
    @DisplayName("Should throw ForbiddenException when updating review belonging to another farmer")
    void updateReview_forbidden_differentFarmer() {
        FarmerProfile otherFarmerProfile = FarmerProfile.builder()
                .id(UUID.randomUUID())
                .user(otherUser)
                .build();

        Review otherReview = Review.builder()
                .id(reviewId)
                .booking(deliveredBooking)
                .farmer(otherFarmerProfile)
                .agency(agencyProfile)
                .build();

        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(deliveredBooking));
        when(reviewRepository.findByBookingId(bookingId)).thenReturn(Optional.of(otherReview));

        UpdateReviewRequest updateRequest = UpdateReviewRequest.builder()
                .agencyRating(4)
                .build();

        assertThatThrownBy(() -> farmerReviewService.updateReview(farmerUserId, bookingId, updateRequest))
                .isInstanceOf(ForbiddenException.class)
                .hasMessageContaining("not authorized to edit this review");

        verify(reviewRepository, never()).save(any());
    }

    @Test
    @DisplayName("Should throw ResourceNotFoundException when updating non-existent review")
    void updateReview_notFound() {
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(deliveredBooking));
        when(reviewRepository.findByBookingId(bookingId)).thenReturn(Optional.empty());

        UpdateReviewRequest updateRequest = UpdateReviewRequest.builder()
                .agencyRating(4)
                .build();

        assertThatThrownBy(() -> farmerReviewService.updateReview(farmerUserId, bookingId, updateRequest))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("No review found for booking");
    }

    @Test
    @DisplayName("Should successfully retrieve review for owned booking")
    void getReview_success() {
        Review review = Review.builder()
                .id(reviewId)
                .booking(deliveredBooking)
                .farmer(farmerProfile)
                .agency(agencyProfile)
                .driver(driverProfile)
                .agencyRating(5)
                .agencyComment("Great service")
                .driverRating(5)
                .driverComment("Great driver")
                .build();

        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(deliveredBooking));
        when(reviewRepository.findByBookingId(bookingId)).thenReturn(Optional.of(review));

        ReviewResponse response = farmerReviewService.getReview(farmerUserId, bookingId);

        assertThat(response).isNotNull();
        assertThat(response.getId()).isEqualTo(reviewId);
        assertThat(response.getAgencyRating()).isEqualTo(5);
    }

    @Test
    @DisplayName("Should throw ForbiddenException when viewing review on non-owned booking")
    void getReview_forbidden_notOwner() {
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(deliveredBooking));

        assertThatThrownBy(() -> farmerReviewService.getReview(otherFarmerUserId, bookingId))
                .isInstanceOf(ForbiddenException.class)
                .hasMessageContaining("not authorized to access this booking");
    }

    @Test
    @DisplayName("Should throw ResourceNotFoundException when review does not exist for booking")
    void getReview_notFound() {
        when(bookingRepository.findById(bookingId)).thenReturn(Optional.of(deliveredBooking));
        when(reviewRepository.findByBookingId(bookingId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> farmerReviewService.getReview(farmerUserId, bookingId))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("No review found for booking");
    }
}
