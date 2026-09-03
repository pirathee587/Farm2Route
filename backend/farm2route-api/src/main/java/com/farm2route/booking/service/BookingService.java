package com.farm2route.booking.service;

import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.agency.repository.AgencyProfileRepository;
import com.farm2route.auth.entity.User;
import com.farm2route.auth.repository.UserRepository;
import com.farm2route.booking.dto.BookingDto;
import com.farm2route.booking.dto.CreateBookingRequest;
import com.farm2route.booking.entity.Booking;
import com.farm2route.booking.repository.BookingRepository;
import com.farm2route.catalog.entity.TransportPackage;
import com.farm2route.catalog.repository.PackageRepository;
import com.farm2route.common.enums.BookingStatus;
import com.farm2route.common.exception.BusinessRuleException;
import com.farm2route.common.exception.ForbiddenException;
import com.farm2route.common.exception.ResourceNotFoundException;
import com.farm2route.common.util.GeoUtils;
import com.farm2route.farmer.entity.FarmerProfile;
import com.farm2route.farmer.repository.FarmerProfileRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class BookingService {

    private final BookingRepository bookingRepository;
    private final FarmerProfileRepository farmerProfileRepository;
    private final AgencyProfileRepository agencyProfileRepository;
    private final PackageRepository packageRepository;
    private final UserRepository userRepository;

    @Transactional
    public BookingDto createBooking(UUID farmerUserId, CreateBookingRequest request) {
        FarmerProfile farmer = farmerProfileRepository.findByUserId(farmerUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Farmer profile not found for user: " + farmerUserId));

        AgencyProfile agency = agencyProfileRepository.findById(request.getAgencyId())
                .orElseThrow(() -> new ResourceNotFoundException("Agency not found: " + request.getAgencyId()));

        TransportPackage pkg = null;
        if (request.getPackageId() != null) {
            pkg = packageRepository.findById(request.getPackageId())
                    .orElseThrow(() -> new ResourceNotFoundException("Transport package not found with id: " + request.getPackageId()));

            if (!pkg.isActive()) {
                throw new BusinessRuleException("Selected transport package is not active");
            }
            if (!pkg.getAgency().getId().equals(agency.getId())) {
                throw new BusinessRuleException("Package does not belong to the selected agency");
            }
        }

        BigDecimal distanceKm = GeoUtils.calculateDistanceKm(
                request.getPickupLatitude(),
                request.getPickupLongitude(),
                request.getDeliveryLatitude(),
                request.getDeliveryLongitude()
        );

        BigDecimal totalAmount = request.getTotalAmount();
        if ((totalAmount == null || totalAmount.compareTo(BigDecimal.ZERO) <= 0) && pkg != null) {
            totalAmount = GeoUtils.estimateTotalCost(
                    pkg.getBasePrice(),
                    pkg.getPricePerKm(),
                    pkg.getPricePerKg(),
                    distanceKm,
                    request.getCargoWeightKg()
            );
        }

        String bookingNumber = "F2R-" + System.currentTimeMillis();

        Booking booking = Booking.builder()
                .bookingNumber(bookingNumber)
                .farmer(farmer)
                .agency(agency)
                .transportPackage(pkg)
                .pickupAddress(request.getPickupAddress())
                .pickupLatitude(request.getPickupLatitude())
                .pickupLongitude(request.getPickupLongitude())
                .pickupContactName(request.getPickupContactName())
                .pickupContactPhone(request.getPickupContactPhone())
                .deliveryAddress(request.getDeliveryAddress())
                .deliveryLatitude(request.getDeliveryLatitude())
                .deliveryLongitude(request.getDeliveryLongitude())
                .recipientName(request.getRecipientName())
                .recipientPhone(request.getRecipientPhone())
                .cargoType(request.getCargoType())
                .cargoWeightKg(request.getCargoWeightKg())
                .cargoVolumeCbm(request.getCargoVolumeCbm())
                .isFragile(request.isFragile())
                .requiresRefrigeration(request.isRequiresRefrigeration())
                .specialInstructions(request.getSpecialInstructions())
                .estimatedDistanceKm(distanceKm)
                .totalAmount(totalAmount)
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

    @Transactional(readOnly = true)
    public BookingDto getBookingById(UUID bookingId, UUID farmerUserId) {
        Booking booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new ResourceNotFoundException("Booking not found: " + bookingId));

        if (!booking.getFarmer().getUser().getId().equals(farmerUserId)) {
            throw new ForbiddenException("You are not authorized to view this booking");
        }
        return mapToDto(booking);
    }

    @Transactional
    public BookingDto cancelBooking(UUID bookingId, UUID farmerUserId, String reason) {
        Booking booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new ResourceNotFoundException("Booking not found with id: " + bookingId));

        if (!booking.getFarmer().getUser().getId().equals(farmerUserId)) {
            throw new ForbiddenException("You are not authorized to cancel this booking");
        }

        if (booking.getStatus() == BookingStatus.CANCELLED) {
            throw new BusinessRuleException("Booking is already cancelled");
        }

        if (booking.getStatus() == BookingStatus.DELIVERED) {
            throw new BusinessRuleException("Cannot cancel a completed delivery");
        }

        if (booking.getStatus() == BookingStatus.IN_TRANSIT) {
            throw new BusinessRuleException("Cannot cancel a booking that is currently in transit");
        }

        User user = userRepository.findById(farmerUserId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + farmerUserId));

        booking.setStatus(BookingStatus.CANCELLED);
        booking.setCancellationReason(reason != null && !reason.isBlank() ? reason : "Cancelled by farmer");
        booking.setCancelledBy(user);

        booking = bookingRepository.save(booking);
        log.info("Booking {} successfully cancelled by farmer {}", booking.getBookingNumber(), farmerUserId);
        return mapToDto(booking);
    }

    private BookingDto mapToDto(Booking booking) {
        return BookingDto.builder()
                .id(booking.getId())
                .bookingNumber(booking.getBookingNumber())
                .farmerId(booking.getFarmer().getId())
                .agencyId(booking.getAgency().getId())
                .driverId(booking.getDriver() != null ? booking.getDriver().getId() : null)
                .packageId(booking.getTransportPackage() != null ? booking.getTransportPackage().getId() : null)
                .packageName(booking.getTransportPackage() != null ? booking.getTransportPackage().getTitle() : null)
                .pickupAddress(booking.getPickupAddress())
                .pickupLatitude(booking.getPickupLatitude())
                .pickupLongitude(booking.getPickupLongitude())
                .pickupContactName(booking.getPickupContactName())
                .pickupContactPhone(booking.getPickupContactPhone())
                .deliveryAddress(booking.getDeliveryAddress())
                .deliveryLatitude(booking.getDeliveryLatitude())
                .deliveryLongitude(booking.getDeliveryLongitude())
                .recipientName(booking.getRecipientName())
                .recipientPhone(booking.getRecipientPhone())
                .cargoType(booking.getCargoType())
                .cargoWeightKg(booking.getCargoWeightKg())
                .isFragile(booking.isFragile())
                .requiresRefrigeration(booking.isRequiresRefrigeration())
                .specialInstructions(booking.getSpecialInstructions())
                .totalAmount(booking.getTotalAmount())
                .status(booking.getStatus())
                .cancellationReason(booking.getCancellationReason())
                .scheduledPickupAt(booking.getScheduledPickupAt())
                .createdAt(booking.getCreatedAt())
                .build();
    }
}
