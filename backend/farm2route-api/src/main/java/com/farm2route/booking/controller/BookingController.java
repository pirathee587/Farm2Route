package com.farm2route.booking.controller;

import com.farm2route.booking.dto.BookingDto;
import com.farm2route.booking.dto.CreateBookingRequest;
import com.farm2route.booking.service.BookingService;
import com.farm2route.common.response.ApiResponse;
import com.farm2route.security.UserPrincipal;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/bookings")
@RequiredArgsConstructor
@Tag(name = "Booking Module", description = "Endpoints for creating, managing, and tracking agricultural transport bookings")
@SecurityRequirement(name = "BearerAuth")
public class BookingController {

    private final BookingService bookingService;

    @PostMapping
    @PreAuthorize("hasRole('FARMER')")
    @Operation(summary = "Create Logistics Booking", description = "Creates a new agricultural transport booking from a farmer to an agency")
    public ResponseEntity<ApiResponse<BookingDto>> createBooking(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody CreateBookingRequest request,
            HttpServletRequest servletRequest) {
        BookingDto booking = bookingService.createBooking(principal.getId(), request);
        return new ResponseEntity<>(
                ApiResponse.created(booking, "Booking created successfully", servletRequest.getRequestURI()),
                HttpStatus.CREATED
        );
    }

    @GetMapping("/my-bookings")
    @PreAuthorize("hasRole('FARMER')")
    @Operation(summary = "Get Farmer Bookings", description = "Retrieves all transport bookings created by the authenticated farmer")
    public ResponseEntity<ApiResponse<List<BookingDto>>> getFarmerBookings(
            @AuthenticationPrincipal UserPrincipal principal,
            HttpServletRequest servletRequest) {
        List<BookingDto> list = bookingService.getFarmerBookings(principal.getId());
        return ResponseEntity.ok(ApiResponse.ok(list, "Bookings retrieved successfully", servletRequest.getRequestURI()));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get Booking by ID", description = "Retrieves complete booking details by UUID")
    public ResponseEntity<ApiResponse<BookingDto>> getBookingById(
            @PathVariable UUID id,
            HttpServletRequest servletRequest) {
        BookingDto booking = bookingService.getBookingById(id);
        return ResponseEntity.ok(ApiResponse.ok(booking, "Booking retrieved successfully", servletRequest.getRequestURI()));
    }
}
