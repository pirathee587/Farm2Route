package com.farm2route.pod.service;

import com.farm2route.booking.entity.Booking;
import com.farm2route.booking.repository.BookingRepository;
import com.farm2route.common.enums.BookingStatus;
import com.farm2route.common.enums.PodConfirmationStatus;
import com.farm2route.common.event.PodConfirmedEvent;
import com.farm2route.common.event.PodSubmittedEvent;
import com.farm2route.common.exception.ForbiddenException;
import com.farm2route.common.exception.ResourceNotFoundException;
import com.farm2route.common.storage.SupabaseStorageService;
import com.farm2route.driver.entity.DriverProfile;
import com.farm2route.pod.dto.ConfirmPodRequest;
import com.farm2route.pod.dto.PodDto;
import com.farm2route.pod.dto.SubmitPodRequest;
import com.farm2route.pod.entity.PodRecord;
import com.farm2route.pod.repository.PodRecordRepository;
import com.farm2route.tracking.entity.TripAssignment;
import com.farm2route.tracking.repository.TripAssignmentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.Instant;
import java.util.UUID;

import com.farm2route.incident.service.AdminIncidentService;

@Slf4j
@Service
@RequiredArgsConstructor
public class PodService {

    private final PodRecordRepository podRecordRepository;
    private final BookingRepository bookingRepository;
    private final TripAssignmentRepository tripAssignmentRepository;
    private final SupabaseStorageService supabaseStorageService;
    private final ApplicationEventPublisher eventPublisher;
    private final AdminIncidentService adminIncidentService;

    @Transactional
    public PodDto submit(UUID bookingId, UUID driverUserId, SubmitPodRequest req, MultipartFile signature, MultipartFile deliveryPhoto) throws IOException {
        Booking booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new ResourceNotFoundException("Booking not found with ID: " + bookingId));

        TripAssignment assignment = tripAssignmentRepository.findByBookingId(bookingId)
                .orElseThrow(() -> new ResourceNotFoundException("No trip assignment found for booking ID: " + bookingId));

        DriverProfile assignedDriver = assignment.getDriver();
        UUID assignedDriverUserId = assignedDriver.getUser() != null ? assignedDriver.getUser().getId() : null;

        if (driverUserId == null || (!driverUserId.equals(assignedDriverUserId) && !driverUserId.equals(assignedDriver.getId()))) {
            throw new ForbiddenException("You are not assigned as the driver for this booking trip");
        }

        String signatureUrl = supabaseStorageService.uploadFile(SupabaseStorageService.BUCKET_POD_PHOTOS, "signatures/" + bookingId, signature);
        String photoUrl = supabaseStorageService.uploadFile(SupabaseStorageService.BUCKET_POD_PHOTOS, "photos/" + bookingId, deliveryPhoto);

        PodRecord pod = PodRecord.builder()
                .booking(booking)
                .driver(assignedDriver)
                .recipientName(req.getRecipientName())
                .recipientPhone(req.getRecipientPhone())
                .recipientSignatureUrl(signatureUrl)
                .deliveryPhotoUrl(photoUrl)
                .deliveryLatitude(req.getDeliveryLatitude())
                .deliveryLongitude(req.getDeliveryLongitude())
                .deliveryTimestamp(Instant.now())
                .farmerConfirmationStatus(PodConfirmationStatus.PENDING)
                .notes(req.getNotes())
                .build();

        PodRecord saved = podRecordRepository.save(pod);
        log.info("Driver userId={} submitted POD for bookingId={}, podId={}", driverUserId, bookingId, saved.getId());

        UUID farmerUserId = booking.getFarmer() != null && booking.getFarmer().getUser() != null ? booking.getFarmer().getUser().getId() : null;
        UUID agencyId = booking.getAgency() != null ? booking.getAgency().getId() : null;

        eventPublisher.publishEvent(PodSubmittedEvent.builder()
                .podId(saved.getId())
                .bookingId(bookingId)
                .farmerUserId(farmerUserId)
                .agencyId(agencyId)
                .driverId(assignedDriver.getId())
                .build());

        return mapToDto(saved);
    }

    @Transactional
    public PodDto confirm(UUID bookingId, UUID farmerUserId, ConfirmPodRequest req) {
        PodRecord pod = podRecordRepository.findByBookingId(bookingId)
                .orElseThrow(() -> new ResourceNotFoundException("POD record not found for booking ID: " + bookingId));

        Booking booking = pod.getBooking();
        UUID actualFarmerUserId = booking.getFarmer() != null && booking.getFarmer().getUser() != null ? booking.getFarmer().getUser().getId() : null;

        if (farmerUserId == null || !farmerUserId.equals(actualFarmerUserId)) {
            throw new ForbiddenException("You are not authorized to confirm POD for this booking");
        }

        pod.setFarmerConfirmationStatus(req.getStatus());
        pod.setFarmerConfirmedAt(Instant.now());
        if (req.getNotes() != null) {
            pod.setNotes(req.getNotes());
        }

        PodRecord saved = podRecordRepository.save(pod);

        if (req.getStatus() == PodConfirmationStatus.CONFIRMED) {
            validateAndMarkDelivered(bookingId);
        } else if (req.getStatus() == PodConfirmationStatus.DISPUTED) {
            openDisputeForPod(saved, req.getNotes());
        }

        UUID agencyId = booking.getAgency() != null ? booking.getAgency().getId() : null;
        UUID driverId = pod.getDriver() != null ? pod.getDriver().getId() : null;

        eventPublisher.publishEvent(PodConfirmedEvent.builder()
                .podId(saved.getId())
                .bookingId(bookingId)
                .farmerId(booking.getFarmer() != null ? booking.getFarmer().getId() : null)
                .agencyId(agencyId)
                .driverId(driverId)
                .confirmedAt(saved.getFarmerConfirmedAt())
                .build());

        return mapToDto(saved);
    }

    @Transactional
    public void validateAndMarkDelivered(UUID bookingId) {
        PodRecord pod = podRecordRepository.findByBookingId(bookingId)
                .orElseThrow(() -> new ResourceNotFoundException("POD record not found for booking ID: " + bookingId));

        if (pod.getFarmerConfirmationStatus() != PodConfirmationStatus.CONFIRMED) {
            throw new IllegalStateException("Booking status cannot be updated to DELIVERED without a CONFIRMED Proof of Delivery record");
        }

        Booking booking = pod.getBooking();
        booking.setStatus(BookingStatus.DELIVERED);
        booking.setActualDeliveryAt(Instant.now());
        bookingRepository.save(booking);
        log.info("Booking bookingId={} status updated to DELIVERED following farmer POD confirmation", bookingId);
    }

    @Transactional(readOnly = true)
    public PodDto getPodByBookingId(UUID bookingId, UUID requestingUserId, String requestingUserRole) {
        PodRecord pod = podRecordRepository.findByBookingId(bookingId)
                .orElseThrow(() -> new ResourceNotFoundException("POD record not found for booking ID: " + bookingId));

        validateOwnership(pod, requestingUserId, requestingUserRole);
        return mapToDto(pod);
    }

    /**
     * Invokes AdminIncidentService to open an incident report for disputed POD delivery.
     */
    public void openDisputeForPod(PodRecord pod, String notes) {
        UUID bookingId = pod.getBooking().getId();
        UUID farmerUserId = pod.getBooking().getFarmer() != null && pod.getBooking().getFarmer().getUser() != null
                ? pod.getBooking().getFarmer().getUser().getId()
                : null;
        adminIncidentService.openFromPodDispute(bookingId, farmerUserId, notes);
    }

    private void validateOwnership(PodRecord pod, UUID requestingUserId, String requestingUserRole) {
        if (requestingUserRole != null && requestingUserRole.toUpperCase().contains("ADMIN")) {
            return;
        }

        Booking booking = pod.getBooking();
        UUID farmerUserId = booking.getFarmer() != null && booking.getFarmer().getUser() != null ? booking.getFarmer().getUser().getId() : null;
        UUID driverUserId = pod.getDriver() != null && pod.getDriver().getUser() != null ? pod.getDriver().getUser().getId() : null;

        if (requestingUserId != null && (requestingUserId.equals(farmerUserId) || requestingUserId.equals(driverUserId))) {
            return;
        }

        throw new ForbiddenException("You are not authorized to view POD for this booking");
    }

    private PodDto mapToDto(PodRecord entity) {
        Booking booking = entity.getBooking();
        DriverProfile driver = entity.getDriver();

        return PodDto.builder()
                .id(entity.getId())
                .bookingId(booking != null ? booking.getId() : null)
                .bookingNumber(booking != null ? booking.getBookingNumber() : null)
                .driverId(driver != null ? driver.getId() : null)
                .driverName(driver != null ? driver.getFullName() : null)
                .recipientName(entity.getRecipientName())
                .recipientPhone(entity.getRecipientPhone())
                .recipientSignatureUrl(entity.getRecipientSignatureUrl())
                .deliveryPhotoUrl(entity.getDeliveryPhotoUrl())
                .deliveryLatitude(entity.getDeliveryLatitude())
                .deliveryLongitude(entity.getDeliveryLongitude())
                .deliveryTimestamp(entity.getDeliveryTimestamp())
                .farmerConfirmationStatus(entity.getFarmerConfirmationStatus())
                .farmerConfirmedAt(entity.getFarmerConfirmedAt())
                .notes(entity.getNotes())
                .createdAt(entity.getCreatedAt())
                .build();
    }
}
