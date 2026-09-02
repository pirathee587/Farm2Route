package com.farm2route.booking.service;

import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.agency.repository.AgencyProfileRepository;
import com.farm2route.booking.dto.BookingDto;
import com.farm2route.booking.dto.CreateBookingRequest;
import com.farm2route.booking.entity.Booking;
import com.farm2route.booking.repository.BookingRepository;
import com.farm2route.common.enums.BookingStatus;
import com.farm2route.common.exception.ResourceNotFoundException;
import com.farm2route.farmer.entity.FarmerProfile;
import com.farm2route.farmer.repository.FarmerProfileRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class BookingService {

    private final BookingRepository bookingRepository;
    private final FarmerProfileRepository farmerProfileRepository;
    private final AgencyProfileRepository agencyProfileRepository;

    @Transactional
    public BookingDto createBooking(UUID farmerUserId, CreateBookingRequest request) {
        FarmerProfile farmer = farmerProfileRepository.findByUserId(farmerUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Farmer profile not found for user: " + farmerUserId));

        AgencyProfile agency = agencyProfileRepository.findById(request.getAgencyId())
                .orElseThrow(() -> new ResourceNotFoundException("Agency not found: " + request.getAgencyId()));

        String bookingNumber = "F2R-" + System.currentTimeMillis();

        Booking booking = Booking.builder()
                .bookingNumber(bookingNumber)
                .farmer(farmer)
                .agency(agency)
                .pickupAddress(request.getPickupAddress())
                .pickupLatitude(request.getPickupLatitude())
                .pickupLongitude(request.getPickupLongitude())
                .deliveryAddress(request.getDeliveryAddress())
                .deliveryLatitude(request.getDeliveryLatitude())
                .deliveryLongitude(request.getDeliveryLongitude())
                .recipientName(request.getRecipientName())
                .recipientPhone(request.getRecipientPhone())
                .cargoType(request.getCargoType())
                .cargoWeightKg(request.getCargoWeightKg())
                .isFragile(request.isFragile())
                .requiresRefrigeration(request.isRequiresRefrigeration())
                .specialInstructions(request.getSpecialInstructions())
                .totalAmount(request.getTotalAmount())
                .status(BookingStatus.PENDING)
                .scheduledPickupAt(request.getScheduledPickupAt())
                .build();

        booking = bookingRepository.save(booking);
        return mapToDto(booking);
    }

    @Transactional(readOnly = true)
    public List<BookingDto> getFarmerBookings(UUID farmerUserId) {
        FarmerProfile farmer = farmerProfileRepository.findByUserId(farmerUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Farmer profile not found for user: " + farmerUserId));
        return bookingRepository.findByFarmerId(farmer.getId()).stream()
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public BookingDto getBookingById(UUID bookingId) {
        Booking booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new ResourceNotFoundException("Booking not found: " + bookingId));
        return mapToDto(booking);
    }

    private BookingDto mapToDto(Booking booking) {
        return BookingDto.builder()
                .id(booking.getId())
                .bookingNumber(booking.getBookingNumber())
                .farmerId(booking.getFarmer().getId())
                .agencyId(booking.getAgency().getId())
                .driverId(booking.getDriver() != null ? booking.getDriver().getId() : null)
                .pickupAddress(booking.getPickupAddress())
                .pickupLatitude(booking.getPickupLatitude())
                .pickupLongitude(booking.getPickupLongitude())
                .deliveryAddress(booking.getDeliveryAddress())
                .deliveryLatitude(booking.getDeliveryLatitude())
                .deliveryLongitude(booking.getDeliveryLongitude())
                .recipientName(booking.getRecipientName())
                .recipientPhone(booking.getRecipientPhone())
                .cargoType(booking.getCargoType())
                .cargoWeightKg(booking.getCargoWeightKg())
                .isFragile(booking.isFragile())
                .requiresRefrigeration(booking.isRequiresRefrigeration())
                .totalAmount(booking.getTotalAmount())
                .status(booking.getStatus())
                .scheduledPickupAt(booking.getScheduledPickupAt())
                .createdAt(booking.getCreatedAt())
                .build();
    }
}
