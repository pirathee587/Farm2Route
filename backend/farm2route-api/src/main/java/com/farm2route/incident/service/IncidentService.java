package com.farm2route.incident.service;

import com.farm2route.auth.entity.User;
import com.farm2route.auth.repository.UserRepository;
import com.farm2route.booking.entity.Booking;
import com.farm2route.booking.repository.BookingRepository;
import com.farm2route.common.enums.IncidentStatus;
import com.farm2route.common.enums.NotificationType;
import com.farm2route.common.event.IncidentSubmittedEvent;
import com.farm2route.common.exception.BadRequestException;
import com.farm2route.common.exception.ForbiddenException;
import com.farm2route.common.exception.ResourceNotFoundException;
import com.farm2route.common.storage.SupabaseStorageService;
import com.farm2route.farmer.entity.FarmerProfile;
import com.farm2route.incident.dto.IncidentResponse;
import com.farm2route.incident.dto.SubmitIncidentRequest;
import com.farm2route.incident.entity.IncidentEvidence;
import com.farm2route.incident.entity.IncidentReport;
import com.farm2route.incident.repository.IncidentEvidenceRepository;
import com.farm2route.incident.repository.IncidentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class IncidentService {

    private final IncidentRepository incidentRepository;
    private final IncidentEvidenceRepository evidenceRepository;
    private final BookingRepository bookingRepository;
    private final UserRepository userRepository;
    private final SupabaseStorageService storageService;
    /** Publishes Spring application events — IncidentEventRelay (future) or
     *  direct relay within this service forwards to RabbitMQ AFTER_COMMIT. */
    private final ApplicationEventPublisher applicationEventPublisher;

    private static final int MAX_EVIDENCE_FILES = 5;
    private static final long MAX_FILE_SIZE_BYTES = 5 * 1024 * 1024; // 5MB

    /**
     * Submits a new incident report for an existing booking.
     * Enforces farmer ownership of the booking and initializes report with status OPEN.
     * Note: Status transitions (INVESTIGATING, RESOLVED, REJECTED) are owned exclusively by Member 3.
     */
    @Transactional
    public IncidentResponse submitIncident(UUID farmerUserId, SubmitIncidentRequest request, MultipartFile[] evidencePhotos) {
        Booking booking = bookingRepository.findById(request.getBookingId())
                .orElseThrow(() -> new ResourceNotFoundException("Booking not found with id: " + request.getBookingId()));

        FarmerProfile farmerProfile = booking.getFarmer();
        if (farmerProfile == null || farmerProfile.getUser() == null || !farmerProfile.getUser().getId().equals(farmerUserId)) {
            log.warn("Farmer {} attempted to report an incident for non-owned booking {}", farmerUserId, booking.getId());
            throw new ForbiddenException("You are not authorized to report an incident for this booking");
        }

        validateEvidencePhotos(evidencePhotos);

        String title = resolveTitle(request, booking);

        IncidentReport incident = IncidentReport.builder()
                .booking(booking)
                .reportedByUserId(farmerUserId)
                .farmer(farmerProfile)
                .incidentType(request.getIncidentType())
                .title(title)
                .description(request.getDescription().trim())
                .status(IncidentStatus.OPEN)
                .evidenceList(new ArrayList<>())
                .build();

        IncidentReport savedIncident = incidentRepository.save(incident);

        // Upload and link evidence photos if provided
        if (evidencePhotos != null && evidencePhotos.length > 0) {
            for (MultipartFile file : evidencePhotos) {
                if (file == null || file.isEmpty()) {
                    continue;
                }
                try {
                    String photoUrl = storageService.uploadFile(
                            SupabaseStorageService.BUCKET_INCIDENT_EVIDENCE,
                            "incidents/" + savedIncident.getId(),
                            file
                    );

                    IncidentEvidence evidence = IncidentEvidence.builder()
                            .incident(savedIncident)
                            .fileUrl(photoUrl)
                            .photoUrl(photoUrl)
                            .fileType("IMAGE")
                            .caption(file.getOriginalFilename())
                            .build();

                    savedIncident.addEvidence(evidence);
                } catch (IOException ex) {
                    log.error("Failed to upload incident evidence photo {}: {}", file.getOriginalFilename(), ex.getMessage());
                    throw new BadRequestException("Failed to upload evidence photo: " + file.getOriginalFilename());
                }
            }
            savedIncident = incidentRepository.save(savedIncident);
        }

        log.info("[NOTIFICATION: {}] Incident report {} successfully created for booking {} by farmer {}",
                NotificationType.INCIDENT_ALERT, savedIncident.getId(), booking.getBookingNumber(), farmerUserId);

        // Publish domain event — AuditEventListener (audit.queue) handles audit logging asynchronously.
        // BookingEventListener (notification.queue) handles admin notification asynchronously.
        // Both listeners are idempotent via processed_events table.
        applicationEventPublisher.publishEvent(
                IncidentSubmittedEvent.builder()
                        .incidentId(savedIncident.getId())
                        .bookingId(booking.getId())
                        .farmerId(farmerUserId)
                        .incidentType(savedIncident.getIncidentType())
                        .title(savedIncident.getTitle())
                        .build()
        );

        return mapToResponse(savedIncident);
    }

    /**
     * Lists incidents reported by the authenticated farmer, optionally filtered by status.
     */
    @Transactional(readOnly = true)
    public Page<IncidentResponse> getFarmerIncidents(UUID farmerUserId, IncidentStatus statusFilter, Pageable pageable) {
        Page<IncidentReport> page;
        if (statusFilter != null) {
            page = incidentRepository.findByReportedByUserIdAndStatusOrderByCreatedAtDesc(farmerUserId, statusFilter, pageable);
        } else {
            page = incidentRepository.findByReportedByUserIdOrderByCreatedAtDesc(farmerUserId, pageable);
        }
        return page.map(this::mapToResponse);
    }

    /**
     * Retrieves an incident report by ID with ownership verification.
     */
    @Transactional(readOnly = true)
    public IncidentResponse getIncidentById(UUID farmerUserId, UUID incidentId) {
        IncidentReport incident = incidentRepository.findById(incidentId)
                .orElseThrow(() -> new ResourceNotFoundException("Incident report not found with id: " + incidentId));

        if (!incident.getReportedByUserId().equals(farmerUserId)) {
            log.warn("Farmer {} unauthorized access attempt to incident report {}", farmerUserId, incidentId);
            throw new ForbiddenException("You are not authorized to view this incident report");
        }

        return mapToResponse(incident);
    }

    private void validateEvidencePhotos(MultipartFile[] evidencePhotos) {
        if (evidencePhotos == null || evidencePhotos.length == 0) {
            return;
        }

        if (evidencePhotos.length > MAX_EVIDENCE_FILES) {
            throw new BadRequestException("Maximum of " + MAX_EVIDENCE_FILES + " evidence photos allowed per incident");
        }

        for (MultipartFile file : evidencePhotos) {
            if (file == null || file.isEmpty()) {
                continue;
            }

            if (file.getSize() > MAX_FILE_SIZE_BYTES) {
                throw new BadRequestException("Evidence file " + file.getOriginalFilename() + " exceeds maximum size of 5MB");
            }

            String contentType = file.getContentType();
            if (contentType != null && !contentType.startsWith("image/")) {
                throw new BadRequestException("Evidence files must be images (received: " + contentType + ")");
            }
        }
    }

    private String resolveTitle(SubmitIncidentRequest request, Booking booking) {
        if (StringUtils.hasText(request.getTitle())) {
            String trimmed = request.getTitle().trim();
            return trimmed.length() > 150 ? trimmed.substring(0, 150) : trimmed;
        }
        String typeName = request.getIncidentType().name().replace('_', ' ');
        String generated = typeName + " - " + booking.getBookingNumber();
        return generated.length() > 150 ? generated.substring(0, 150) : generated;
    }

    private IncidentResponse mapToResponse(IncidentReport incident) {
        Booking booking = incident.getBooking();
        String route = null;
        String cargoType = null;
        String bookingNumber = null;

        if (booking != null) {
            bookingNumber = booking.getBookingNumber();
            cargoType = booking.getCargoType();
            route = (booking.getPickupAddress() != null ? booking.getPickupAddress() : "")
                    + " -> "
                    + (booking.getDeliveryAddress() != null ? booking.getDeliveryAddress() : "");
        }

        List<String> evidenceUrls = incident.getEvidenceList() != null
                ? incident.getEvidenceList().stream()
                .map(e -> StringUtils.hasText(e.getPhotoUrl()) ? e.getPhotoUrl() : e.getFileUrl())
                .filter(StringUtils::hasText)
                .toList()
                : List.of();

        return IncidentResponse.builder()
                .id(incident.getId())
                .bookingId(booking != null ? booking.getId() : null)
                .bookingNumber(bookingNumber)
                .route(route)
                .cargoType(cargoType)
                .incidentType(incident.getIncidentType())
                .title(incident.getTitle())
                .description(incident.getDescription())
                .status(incident.getStatus())
                .evidencePhotoUrls(evidenceUrls)
                .adminNotes(incident.getAdminNotes())
                .investigationNotes(incident.getInvestigationNotes())
                .resolutionOutcome(incident.getResolutionOutcome())
                .refundAmount(incident.getRefundAmount())
                .resolvedAt(incident.getResolvedAt())
                .createdAt(incident.getCreatedAt())
                .updatedAt(incident.getUpdatedAt())
                .build();
    }
}
