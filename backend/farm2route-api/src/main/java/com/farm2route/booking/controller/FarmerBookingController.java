package com.farm2route.booking.controller;

import com.farm2route.auth.entity.User;
import com.farm2route.booking.dto.BookingDto;
import com.farm2route.booking.dto.CancelBookingRequest;
import com.farm2route.booking.dto.CreateBookingRequest;
import com.farm2route.booking.service.BookingService;
import com.farm2route.common.exception.UnauthorizedException;
import com.farm2route.common.response.ApiResponse;
import com.farm2route.security.CustomUserPrincipal;
import com.farm2route.security.UserPrincipal;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping({"/api/v1/farmer/bookings", "/api/farmer/bookings"})
@RequiredArgsConstructor
@Tag(name = "Farmer Booking Operations", description = "Endpoints for farmers to create, retrieve, and cancel transport bookings")
@SecurityRequirement(name = "BearerAuth")
public class FarmerBookingController {

    private final BookingService bookingService;

    @PostMapping
    @PreAuthorize("hasRole('FARMER')")
    @Operation(summary = "Create Transport Booking", description = "Creates a new agricultural transport booking with optional package selection")
    public ResponseEntity<ApiResponse<BookingDto>> createBooking(
            @AuthenticationPrincipal Object principal,
            @Valid @RequestBody CreateBookingRequest request,
            HttpServletRequest servletRequest) {

        UUID farmerUserId = extractFarmerId(principal);
        BookingDto booking = bookingService.createBooking(farmerUserId, request);
        return new ResponseEntity<>(
                ApiResponse.created(booking, "Booking created successfully", servletRequest.getRequestURI()),
                HttpStatus.CREATED
        );
    }

    @GetMapping
    @PreAuthorize("hasRole('FARMER')")
    @Operation(summary = "List Farmer Bookings", description = "Retrieves all transport bookings created by the authenticated farmer")
    public ResponseEntity<ApiResponse<List<BookingDto>>> getFarmerBookings(
            @AuthenticationPrincipal Object principal,
            HttpServletRequest servletRequest) {

        UUID farmerUserId = extractFarmerId(principal);
        List<BookingDto> list = bookingService.getFarmerBookings(farmerUserId);
        return ResponseEntity.ok(ApiResponse.ok(list, "Bookings retrieved successfully", servletRequest.getRequestURI()));
    }

    @GetMapping("/my-bookings")
    @PreAuthorize("hasRole('FARMER')")
    @Operation(summary = "List My Bookings", description = "Convenience endpoint to retrieve all transport bookings created by authenticated farmer")
    public ResponseEntity<ApiResponse<List<BookingDto>>> getMyBookings(
            @AuthenticationPrincipal Object principal,
            HttpServletRequest servletRequest) {

        return getFarmerBookings(principal, servletRequest);
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasRole('FARMER')")
    @Operation(summary = "Get Booking Details", description = "Retrieves complete booking details if owned by the authenticated farmer")
    public ResponseEntity<ApiResponse<BookingDto>> getBookingById(
            @AuthenticationPrincipal Object principal,
            @PathVariable UUID id,
            HttpServletRequest servletRequest) {

        UUID farmerUserId = extractFarmerId(principal);
        BookingDto booking = bookingService.getBookingById(id, farmerUserId);
        return ResponseEntity.ok(ApiResponse.ok(booking, "Booking retrieved successfully", servletRequest.getRequestURI()));
    }

    @PostMapping("/{id}/cancel")
    @PreAuthorize("hasRole('FARMER')")
    @Operation(summary = "Cancel Booking (POST)", description = "Cancels a pending transport booking")
    public ResponseEntity<ApiResponse<BookingDto>> cancelBookingPost(
            @AuthenticationPrincipal Object principal,
            @PathVariable UUID id,
            @RequestBody(required = false) CancelBookingRequest cancelRequest,
            HttpServletRequest servletRequest) {

        UUID farmerUserId = extractFarmerId(principal);
        String reason = cancelRequest != null ? cancelRequest.getReason() : null;
        BookingDto booking = bookingService.cancelBooking(id, farmerUserId, reason);
        return ResponseEntity.ok(ApiResponse.ok(booking, "Booking cancelled successfully", servletRequest.getRequestURI()));
    }

    @PutMapping("/{id}/cancel")
    @PreAuthorize("hasRole('FARMER')")
    @Operation(summary = "Cancel Booking (PUT)", description = "Cancels a pending transport booking")
    public ResponseEntity<ApiResponse<BookingDto>> cancelBookingPut(
            @AuthenticationPrincipal Object principal,
            @PathVariable UUID id,
            @RequestBody(required = false) CancelBookingRequest cancelRequest,
            HttpServletRequest servletRequest) {

        return cancelBookingPost(principal, id, cancelRequest, servletRequest);
    }

    /**
     * Extracts the farmer user's UUID from the Spring Security authentication principal.
     */
    public UUID extractFarmerId(Object principal) {
        if (principal instanceof UserPrincipal userPrincipal) {
            return userPrincipal.getId();
        } else if (principal instanceof CustomUserPrincipal customUserPrincipal) {
            return customUserPrincipal.getId();
        } else if (principal instanceof User user) {
            return user.getId();
        }
        throw new UnauthorizedException("Unable to extract farmer ID from principal");
    }
}
