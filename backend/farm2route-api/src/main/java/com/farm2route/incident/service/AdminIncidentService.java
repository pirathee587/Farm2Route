package com.farm2route.incident.service;

import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.booking.entity.Booking;
import com.farm2route.common.enums.IncidentStatus;
import com.farm2route.common.enums.IncidentType;
import com.farm2route.common.event.IncidentEscalatedEvent;
import com.farm2route.common.event.IncidentStatusChangedEvent;
import com.farm2route.common.exception.ResourceNotFoundException;
import com.farm2route.driver.entity.DriverProfile;
import com.farm2route.farmer.entity.FarmerProfile;
import com.farm2route.incident.dto.AdminIncidentDetailDto;
import com.farm2route.incident.dto.ResolveIncidentRequest;
import com.farm2route.incident.entity.IncidentEvidence;
import com.farm2route.incident.entity.IncidentReport;
import com.farm2route.incident.repository.IncidentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Collections;
import java.util.List;
import java.util.UUID;
import com.farm2route.booking.repository.BookingRepository;
import com.farm2route.finance.FinanceService;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class AdminIncidentService {

    private final IncidentRepository incidentRepository;
    private final BookingRepository bookingRepository;
    private final FinanceService financeService;
    private final ApplicationEventPublisher eventPublisher;

    @Transactional(readOnly = true)
    public Page<AdminIncidentDetailDto> search(IncidentStatus status, IncidentType incidentType, Instant fromDate, Instant toDate, Pageable pageable) {
        Page<IncidentReport> page = incidentRepository.searchAdminIncidents(status, incidentType, fromDate, toDate, pageable);
        return page.map(this::mapToDetailDto);
    }

    @Transactional(readOnly = true)
    public AdminIncidentDetailDto getDetail(UUID incidentId) {
        IncidentReport incident = incidentRepository.findById(incidentId)
                .orElseThrow(() -> new ResourceNotFoundException("Incident report not found with ID: " + incidentId));
        return mapToDetailDto(incident);
    }

    @Transactional
    public AdminIncidentDetailDto openFromPodDispute(UUID bookingId, UUID farmerUserId, String reason) {
        Booking booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new ResourceNotFoundException("Booking not found with ID: " + bookingId));

        IncidentReport incident = IncidentReport.builder()
                .booking(booking)
                .reportedByUserId(farmerUserId)
                .incidentType(IncidentType.CARGO_DAMAGE)
                .title("POD Delivery Disputed")
                .description(reason)
                .status(IncidentStatus.OPEN)
                .adminNotes("Opened automatically from POD dispute")
                .build();

        IncidentReport saved = incidentRepository.save(incident);
        log.info("Opened dispute incidentId={} for bookingId={} via POD dispute", saved.getId(), bookingId);

        notifyAllParties(saved, null, IncidentStatus.OPEN, farmerUserId);
        return mapToDetailDto(saved);
    }

    @Transactional
    public AdminIncidentDetailDto recordAgencyResponse(UUID incidentId, UUID agencyUserId, String response) {
        IncidentReport incident = incidentRepository.findById(incidentId)
                .orElseThrow(() -> new ResourceNotFoundException("Incident report not found with ID: " + incidentId));

        String existing = incident.getAdminNotes();
        String entry = "AGENCY RESPONSE [" + Instant.now() + "]: " + response;
        incident.setAdminNotes(existing != null && !existing.isEmpty() ? existing + "\n" + entry : entry);

        IncidentReport saved = incidentRepository.save(incident);
        log.info("Recorded agency response for incidentId={} by agencyUserId={}", incidentId, agencyUserId);
        return mapToDetailDto(saved);
    }

    @Transactional
    public AdminIncidentDetailDto decideRefund(UUID incidentId, UUID adminId, BigDecimal amount, String decision) {
        IncidentReport incident = incidentRepository.findById(incidentId)
                .orElseThrow(() -> new ResourceNotFoundException("Incident report not found with ID: " + incidentId));

        Booking booking = incident.getBooking();
        UUID bookingId = booking != null ? booking.getId() : null;
        UUID farmerId = booking != null && booking.getFarmer() != null ? booking.getFarmer().getId() : null;
        UUID agencyId = booking != null && booking.getAgency() != null ? booking.getAgency().getId() : null;

        // Delegate to FinanceService.refund — throws BadRequestException if amount is null/zero/negative
        FinanceService.RefundResult refundResult = financeService.refund(bookingId, farmerId, agencyId, amount, adminId, decision);

        IncidentStatus oldStatus = incident.getStatus();
        incident.setRefundAmount(amount);
        incident.setResolutionOutcome(decision != null && !decision.isBlank() ? decision : refundResult.status().name());
        incident.setStatus(IncidentStatus.RESOLVED);
        incident.setResolvedByAdminId(adminId);
        incident.setResolvedAt(Instant.now());

        String existingNotes = incident.getAdminNotes();
        String refundNote = "REFUND DECISION [" + Instant.now() + "]: Status=" + refundResult.status() + ", Amount=" + amount;
        incident.setAdminNotes(existingNotes != null && !existingNotes.isEmpty() ? existingNotes + "\n" + refundNote : refundNote);

        IncidentReport saved = incidentRepository.save(incident);
        log.info("Decided refund for incidentId={}, amount={}, status=RESOLVED by adminId={}", incidentId, amount, adminId);

        notifyAllParties(saved, oldStatus, IncidentStatus.RESOLVED, adminId);
        return mapToDetailDto(saved);
    }

    @Transactional
    public AdminIncidentDetailDto addInvestigationNote(UUID incidentId, String note, UUID adminId) {
        IncidentReport incident = incidentRepository.findById(incidentId)
                .orElseThrow(() -> new ResourceNotFoundException("Incident report not found with ID: " + incidentId));

        String existing = incident.getInvestigationNotes();
        String entry = "[" + Instant.now() + " Note by Admin " + adminId + "]: " + note;
        incident.setInvestigationNotes(existing != null ? existing + "\n" + entry : entry);

        IncidentStatus oldStatus = incident.getStatus();
        if (oldStatus == IncidentStatus.OPEN) {
            incident.setStatus(IncidentStatus.INVESTIGATING);
            log.info("Transitioned incidentId={} from OPEN to INVESTIGATING", incidentId);
        }

        IncidentReport saved = incidentRepository.save(incident);

        if (oldStatus != saved.getStatus()) {
            notifyAllParties(saved, oldStatus, saved.getStatus(), adminId);
        }

        return mapToDetailDto(saved);
    }

    @Transactional
    public AdminIncidentDetailDto resolve(UUID incidentId, ResolveIncidentRequest req, UUID adminId) {
        IncidentReport incident = incidentRepository.findById(incidentId)
                .orElseThrow(() -> new ResourceNotFoundException("Incident report not found with ID: " + incidentId));

        if (req.getStatus() != IncidentStatus.RESOLVED && req.getStatus() != IncidentStatus.REJECTED) {
            throw new IllegalArgumentException("Resolution status must be RESOLVED or REJECTED");
        }

        IncidentStatus oldStatus = incident.getStatus();
        IncidentStatus newStatus = req.getStatus();

        incident.setStatus(newStatus);
        incident.setResolutionOutcome(req.getNotes());
        incident.setResolvedByAdminId(adminId);
        incident.setResolvedAt(Instant.now());

        if (req.getRefundAmount() != null) {
            incident.setRefundAmount(req.getRefundAmount());
            processDisputeRefund(incident, req.getRefundAmount());
        }

        IncidentReport saved = incidentRepository.save(incident);
        log.info("Resolved incidentId={} to status={} by adminId={}", incidentId, newStatus, adminId);

        notifyAllParties(saved, oldStatus, newStatus, adminId);

        return mapToDetailDto(saved);
    }

    @Transactional
    public AdminIncidentDetailDto escalate(UUID incidentId, String notes, UUID adminId) {
        IncidentReport incident = incidentRepository.findById(incidentId)
                .orElseThrow(() -> new ResourceNotFoundException("Incident report not found with ID: " + incidentId));

        String existing = incident.getInvestigationNotes();
        String entry = "ESCALATED: " + notes + " (by Admin: " + adminId + " at " + Instant.now() + ")";
        incident.setInvestigationNotes(existing != null ? existing + "\n" + entry : entry);

        IncidentReport saved = incidentRepository.save(incident);
        log.info("Escalated incidentId={} by adminId={}", incidentId, adminId);

        UUID reporterUserId = saved.getReportedByUserId();
        UUID bookingId = saved.getBooking() != null ? saved.getBooking().getId() : null;

        eventPublisher.publishEvent(IncidentEscalatedEvent.builder()
                .incidentId(saved.getId())
                .bookingId(bookingId)
                .reporterUserId(reporterUserId)
                .adminId(adminId)
                .notes(notes)
                .build());

        return mapToDetailDto(saved);
    }

    /**
     * Invoke real FinanceService for processing dispute refunds.
     */
    public void processDisputeRefund(IncidentReport incident, BigDecimal refundAmount) {
        Booking booking = incident.getBooking();
        UUID bookingId = booking != null ? booking.getId() : null;
        UUID farmerId = booking != null && booking.getFarmer() != null ? booking.getFarmer().getId() : null;
        UUID agencyId = booking != null && booking.getAgency() != null ? booking.getAgency().getId() : null;
        UUID adminId = incident.getResolvedByAdminId();
        String reason = incident.getResolutionOutcome();

        FinanceService.RefundResult result = financeService.refund(bookingId, farmerId, agencyId, refundAmount, adminId, reason);
        log.info("Processed dispute refund of {} for incidentId={}, status={}", refundAmount, incident.getId(), result.status());
    }

    /**
     * Publishes IncidentStatusChangedEvent via domain event relay to alert all parties.
     */
    public void notifyAllParties(IncidentReport incident, IncidentStatus oldStatus, IncidentStatus newStatus, UUID adminId) {
        publishStatusChangedEvent(incident, oldStatus, newStatus, adminId);
    }

    /**
     * Stubbed method reference for Member 1 User account suspension.
     */
    public void suspendUserAccount(UUID userId, String reason, UUID adminId) {
        log.info("[TODO] Member 1 integration point: suspending user account userId={} for reason='{}' by adminId={}", userId, reason, adminId);
        // TODO: Invoke Member 1 UserService.updateStatus(userId, UserStatus.SUSPENDED) when built.
    }

    private void publishStatusChangedEvent(IncidentReport incident, IncidentStatus oldStatus, IncidentStatus newStatus, UUID adminId) {
        UUID bookingId = incident.getBooking() != null ? incident.getBooking().getId() : null;
        eventPublisher.publishEvent(IncidentStatusChangedEvent.builder()
                .incidentId(incident.getId())
                .bookingId(bookingId)
                .reporterUserId(incident.getReportedByUserId())
                .oldStatus(oldStatus)
                .newStatus(newStatus)
                .adminId(adminId)
                .build());
    }

    private AdminIncidentDetailDto mapToDetailDto(IncidentReport entity) {
        Booking booking = entity.getBooking();

        AdminIncidentDetailDto.FarmerSummary farmerSummary = null;
        AdminIncidentDetailDto.AgencySummary agencySummary = null;
        AdminIncidentDetailDto.DriverSummary driverSummary = null;
        AdminIncidentDetailDto.VehicleSummary vehicleSummary = null;

        if (booking != null) {
            FarmerProfile fp = booking.getFarmer();
            if (fp != null) {
                farmerSummary = AdminIncidentDetailDto.FarmerSummary.builder()
                        .farmerId(fp.getId())
                        .userId(fp.getUser() != null ? fp.getUser().getId() : null)
                        .farmName(fp.getFarmName())
                        .farmerEmail(fp.getUser() != null ? fp.getUser().getEmail() : null)
                        .farmerPhone(fp.getUser() != null ? fp.getUser().getPhoneNumber() : null)
                        .build();
            }

            AgencyProfile ap = booking.getAgency();
            if (ap != null) {
                agencySummary = AdminIncidentDetailDto.AgencySummary.builder()
                        .agencyId(ap.getId())
                        .userId(ap.getUser() != null ? ap.getUser().getId() : null)
                        .companyName(ap.getCompanyName())
                        .contactPhone(ap.getContactPersonPhone())
                        .build();
            }

            DriverProfile dp = booking.getDriver();
            if (dp != null) {
                driverSummary = AdminIncidentDetailDto.DriverSummary.builder()
                        .driverId(dp.getId())
                        .userId(dp.getUser() != null ? dp.getUser().getId() : null)
                        .driverName(dp.getFullName())
                        .driverPhone(dp.getUser() != null ? dp.getUser().getPhoneNumber() : null)
                        .licenseNumber(dp.getDrivingLicenseNumber())
                        .build();
            }
        }

        List<AdminIncidentDetailDto.EvidenceDto> evidenceDtos = entity.getEvidenceList() != null
                ? entity.getEvidenceList().stream().map(e -> AdminIncidentDetailDto.EvidenceDto.builder()
                        .id(e.getId())
                        .fileUrl(e.getFileUrl())
                        .photoUrl(e.getPhotoUrl())
                        .fileType(e.getFileType())
                        .caption(e.getCaption())
                        .createdAt(e.getCreatedAt())
                        .build())
                .collect(Collectors.toList())
                : Collections.emptyList();

        return AdminIncidentDetailDto.builder()
                .id(entity.getId())
                .bookingId(booking != null ? booking.getId() : null)
                .bookingNumber(booking != null ? booking.getBookingNumber() : null)
                .reportedByUserId(entity.getReportedByUserId())
                .incidentType(entity.getIncidentType())
                .title(entity.getTitle())
                .description(entity.getDescription())
                .status(entity.getStatus())
                .adminNotes(entity.getAdminNotes())
                .investigationNotes(entity.getInvestigationNotes())
                .resolvedByAdminId(entity.getResolvedByAdminId())
                .resolutionOutcome(entity.getResolutionOutcome())
                .refundAmount(entity.getRefundAmount())
                .resolvedAt(entity.getResolvedAt())
                .createdAt(entity.getCreatedAt())
                .updatedAt(entity.getUpdatedAt())
                .evidenceList(evidenceDtos)
                .farmerSummary(farmerSummary)
                .agencySummary(agencySummary)
                .driverSummary(driverSummary)
                .vehicleSummary(vehicleSummary)
                .build();
    }
}
