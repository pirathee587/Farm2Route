package com.farm2route.booking.controller;

import com.farm2route.auth.entity.User;
import com.farm2route.auth.model.Role;
import com.farm2route.auth.model.UserStatus;
import com.farm2route.booking.dto.BookingDto;
import com.farm2route.booking.dto.CancelBookingRequest;
import com.farm2route.booking.dto.CreateBookingRequest;
import com.farm2route.booking.service.BookingService;
import com.farm2route.common.enums.BookingStatus;
import com.farm2route.common.exception.UnauthorizedException;
import com.farm2route.common.response.ApiResponse;
import com.farm2route.security.UserPrincipal;
import jakarta.servlet.http.HttpServletRequest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.mock.web.MockHttpServletRequest;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class FarmerBookingControllerTest {

    @Mock
    private BookingService bookingService;

    @InjectMocks
    private FarmerBookingController controller;

    private UUID userId;
    private UUID bookingId;
    private UserPrincipal userPrincipal;
    private BookingDto sampleDto;
    private HttpServletRequest servletRequest;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        bookingId = UUID.randomUUID();

        User user = User.builder()
                .id(userId)
                .email("farmer@farm2route.lk")
                .phoneNumber("+94771234567")
                .role(Role.FARMER)
                .status(UserStatus.ACTIVE)
                .build();

        userPrincipal = new UserPrincipal(user);
        servletRequest = new MockHttpServletRequest("POST", "/api/v1/farmer/bookings");

        sampleDto = BookingDto.builder()
                .id(bookingId)
                .bookingNumber("F2R-12345")
                .status(BookingStatus.PENDING)
                .totalAmount(new BigDecimal("15000.00"))
                .build();
    }

    @Test
    @DisplayName("Extract farmer ID correctly retrieves user UUID from UserPrincipal")
    void testExtractFarmerId_Success() {
        UUID extracted = controller.extractFarmerId(userPrincipal);
        assertThat(extracted).isEqualTo(userId);
    }

    @Test
    @DisplayName("Extract farmer ID throws UnauthorizedException for invalid principal type")
    void testExtractFarmerId_InvalidPrincipal_ThrowsUnauthorizedException() {
        assertThatThrownBy(() -> controller.extractFarmerId("invalid-string-principal"))
                .isInstanceOf(UnauthorizedException.class)
                .hasMessageContaining("Unable to extract farmer ID");
    }

    @Test
    @DisplayName("Create booking controller endpoint returns 201 CREATED")
    void testCreateBooking_ReturnsCreated() {
        CreateBookingRequest request = CreateBookingRequest.builder()
                .agencyId(UUID.randomUUID())
                .pickupAddress("Kurunegala")
                .pickupLatitude(BigDecimal.TEN)
                .pickupLongitude(BigDecimal.TEN)
                .deliveryAddress("Colombo")
                .deliveryLatitude(BigDecimal.ONE)
                .deliveryLongitude(BigDecimal.ONE)
                .recipientName("Trader")
                .recipientPhone("+94771111111")
                .cargoType("Vegetables")
                .cargoWeightKg(BigDecimal.valueOf(100))
                .totalAmount(BigDecimal.valueOf(5000))
                .scheduledPickupAt(Instant.now())
                .build();

        when(bookingService.createBooking(eq(userId), any(CreateBookingRequest.class))).thenReturn(sampleDto);

        ResponseEntity<ApiResponse<BookingDto>> response = controller.createBooking(userPrincipal, request, servletRequest);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().getData().getId()).isEqualTo(bookingId);
        assertThat(response.getBody().isSuccess()).isTrue();
    }

    @Test
    @DisplayName("Get farmer bookings returns list with 200 OK")
    void testGetFarmerBookings_ReturnsOk() {
        when(bookingService.getFarmerBookings(userId)).thenReturn(List.of(sampleDto));

        ResponseEntity<ApiResponse<List<BookingDto>>> response = controller.getFarmerBookings(userPrincipal, servletRequest);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().getData()).hasSize(1);
    }

    @Test
    @DisplayName("Cancel booking returns 200 OK with cancelled booking")
    void testCancelBooking_ReturnsOk() {
        BookingDto cancelledDto = BookingDto.builder()
                .id(bookingId)
                .status(BookingStatus.CANCELLED)
                .cancellationReason("Postponed")
                .build();

        when(bookingService.cancelBooking(eq(bookingId), eq(userId), eq("Postponed"))).thenReturn(cancelledDto);

        CancelBookingRequest cancelReq = new CancelBookingRequest("Postponed");
        ResponseEntity<ApiResponse<BookingDto>> response = controller.cancelBookingPost(userPrincipal, bookingId, cancelReq, servletRequest);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().getData().getStatus()).isEqualTo(BookingStatus.CANCELLED);
    }
}
