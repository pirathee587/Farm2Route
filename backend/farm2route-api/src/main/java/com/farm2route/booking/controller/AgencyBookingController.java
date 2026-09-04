package com.farm2route.booking.controller;

import com.farm2route.booking.dto.BookingDto;
import com.farm2route.booking.dto.RejectBookingRequest;
import com.farm2route.booking.service.BookingService;
import com.farm2route.common.response.ApiResponse;
import com.farm2route.security.UserPrincipal;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/agency/bookings")
@RequiredArgsConstructor
@Tag(name = "Agency Booking Management", description = "Agency endpoints for reviewing, accepting, and rejecting transport bookings")
@SecurityRequirement(name = "BearerAuth")
public class AgencyBookingController {

    private final BookingService bookingService;

    @GetMapping
    @PreAuthorize("hasAnyRole('AGENCY', 'ADMIN')")
    @Operation(summary = "Get Agency Bookings", description = "Retrieves all bookings submitted to the authenticated agency")
    public ResponseEntity<ApiResponse<List<BookingDto>>> getAgencyBookings(
            @AuthenticationPrincipal UserPrincipal principal,
            HttpServletRequest request) {
        List<BookingDto> list = bookingService.getAgencyBookings(principal.getId());
        return ResponseEntity.ok(ApiResponse.ok(list, "Agency bookings retrieved successfully", request.getRequestURI()));
    }

    @PostMapping("/{id}/accept")
    @PreAuthorize("hasAnyRole('AGENCY', 'ADMIN')")
    @Operation(summary = "Accept Booking", description = "Accepts a pending transport booking")
    public ResponseEntity<ApiResponse<BookingDto>> acceptBooking(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID id,
            HttpServletRequest request) {
        BookingDto dto = bookingService.acceptBooking(principal.getId(), id);
        return ResponseEntity.ok(ApiResponse.ok(dto, "Booking accepted successfully", request.getRequestURI()));
    }

    @PutMapping("/{id}/accept")
    @PreAuthorize("hasAnyRole('AGENCY', 'ADMIN')")
    @Operation(summary = "Accept Booking (PUT alias)", description = "Accepts a pending transport booking")
    public ResponseEntity<ApiResponse<BookingDto>> acceptBookingPut(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID id,
            HttpServletRequest request) {
        return acceptBooking(principal, id, request);
    }

    @PostMapping("/{id}/reject")
    @PreAuthorize("hasAnyRole('AGENCY', 'ADMIN')")
    @Operation(summary = "Reject Booking", description = "Rejects a pending transport booking with an optional reason")
    public ResponseEntity<ApiResponse<BookingDto>> rejectBooking(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID id,
            @RequestBody(required = false) RejectBookingRequest rejectRequest,
            HttpServletRequest request) {
        String reason = rejectRequest != null ? rejectRequest.getReason() : null;
        BookingDto dto = bookingService.rejectBooking(principal.getId(), id, reason);
        return ResponseEntity.ok(ApiResponse.ok(dto, "Booking rejected successfully", request.getRequestURI()));
    }

    @PutMapping("/{id}/reject")
    @PreAuthorize("hasAnyRole('AGENCY', 'ADMIN')")
    @Operation(summary = "Reject Booking (PUT alias)", description = "Rejects a pending transport booking with an optional reason")
    public ResponseEntity<ApiResponse<BookingDto>> rejectBookingPut(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable UUID id,
            @RequestBody(required = false) RejectBookingRequest rejectRequest,
            HttpServletRequest request) {
        return rejectBooking(principal, id, rejectRequest, request);
    }
}
