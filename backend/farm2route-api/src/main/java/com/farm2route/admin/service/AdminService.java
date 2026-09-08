package com.farm2route.admin.service;

import com.farm2route.admin.dto.AdminStatsDto;
import com.farm2route.admin.dto.KycApprovalDto;
import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.agency.repository.AgencyProfileRepository;
import com.farm2route.audit.service.AuditService;
import com.farm2route.auth.entity.User;
import com.farm2route.auth.model.Role;
import com.farm2route.auth.repository.UserRepository;
import com.farm2route.booking.repository.BookingRepository;
import com.farm2route.common.enums.BookingStatus;
import com.farm2route.common.enums.IncidentStatus;
import com.farm2route.common.enums.KycStatus;
import com.farm2route.common.event.KycReviewedEvent;
import com.farm2route.common.exception.ResourceNotFoundException;
import com.farm2route.driver.entity.DriverProfile;
import com.farm2route.driver.repository.DriverProfileRepository;
import com.farm2route.common.validation.KycStatusTransitionValidator;
import com.farm2route.vehicle.entity.Vehicle;
import com.farm2route.vehicle.repository.VehicleRepository;
import com.farm2route.incident.repository.IncidentRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AdminService {

    private final UserRepository userRepository;
    private final AgencyProfileRepository agencyProfileRepository;
    private final DriverProfileRepository driverProfileRepository;
    private final VehicleRepository vehicleRepository;
    private final BookingRepository bookingRepository;
    private final IncidentRepository incidentRepository;
    private final AuditService auditService;
    private final ObjectMapper objectMapper;
    private final ApplicationEventPublisher applicationEventPublisher;

    @Transactional(readOnly = true)
    public AdminStatsDto getDashboardStats() {
        // NOTE: AgencyProfile and DriverProfile default kycStatus to PENDING, whereas Vehicle defaults to PENDING_APPROVAL.
        // Counting both statuses across all 3 entity repositories to accommodate existing schema inconsistency.
        List<KycStatus> pendingStatuses = List.of(KycStatus.PENDING, KycStatus.PENDING_APPROVAL);

        long pendingKycs = agencyProfileRepository.countByKycStatusIn(pendingStatuses)
                + driverProfileRepository.countByKycStatusIn(pendingStatuses)
                + vehicleRepository.countByKycStatusIn(pendingStatuses);

        long activeBookings = bookingRepository.countByStatusNotIn(List.of(
                BookingStatus.DELIVERED,
                BookingStatus.CANCELLED,
                BookingStatus.REJECTED
        ));

        long openIncidents = incidentRepository.countByStatusIn(List.of(
                IncidentStatus.OPEN,
                IncidentStatus.INVESTIGATING
        ));

        return AdminStatsDto.builder()
                .totalUsers(userRepository.count())
                .totalFarmers((long) userRepository.findByRole(Role.FARMER).size())
                .totalAgencies((long) userRepository.findByRole(Role.AGENCY).size())
                .totalDrivers((long) userRepository.findByRole(Role.DRIVER).size())
                .pendingKycs(pendingKycs)
                .activeBookings(activeBookings)
                .openIncidents(openIncidents)
                .build();
    }

    @Transactional
    public void reviewAgencyKyc(KycApprovalDto dto) {
        reviewAgencyKyc(dto, null, null, null);
    }

    @Transactional
    public void reviewAgencyKyc(KycApprovalDto dto, User actor, String ipAddress, String userAgent) {
        AgencyProfile agency = agencyProfileRepository.findById(dto.getEntityId())
                .orElseThrow(() -> new ResourceNotFoundException("Agency not found with ID: " + dto.getEntityId()));
        KycStatusTransitionValidator.requireAdminDecision(agency.getKycStatus(), dto.getStatus());
        String oldValue = serializeKycState(agency.getKycStatus(), agency.getKycRejectionReason(), agency.getVerifiedAt());
        agency.setKycStatus(dto.getStatus());
        if (dto.getRejectionReason() != null) {
            agency.setKycRejectionReason(dto.getRejectionReason());
        }
        if (dto.getStatus() == KycStatus.APPROVED) {
            agency.setVerifiedAt(Instant.now());
        } else {
            agency.setVerifiedAt(null);
        }
        AgencyProfile savedAgency = agencyProfileRepository.save(agency);
        if (savedAgency == null) savedAgency = agency;

        String newValue = serializeKycState(savedAgency.getKycStatus(), savedAgency.getKycRejectionReason(), savedAgency.getVerifiedAt());

        if (auditService != null) {
            auditService.logAction(actor, "REVIEW_AGENCY_KYC", "AgencyProfile", savedAgency.getId().toString(),
                    oldValue, newValue, ipAddress, userAgent);
        }

        UUID ownerUserId = savedAgency.getUser() != null ? savedAgency.getUser().getId() : null;
        if (applicationEventPublisher != null) {
            applicationEventPublisher.publishEvent(KycReviewedEvent.builder().entityType("AGENCY")
                    .entityId(savedAgency.getId()).ownerUserId(ownerUserId).status(savedAgency.getKycStatus())
                    .rejectionReason(savedAgency.getKycRejectionReason()).build());
        }
    }

    @Transactional
    public void reviewDriverKyc(KycApprovalDto dto) {
        reviewDriverKyc(dto, null, null, null);
    }

    @Transactional
    public void reviewDriverKyc(KycApprovalDto dto, User actor, String ipAddress, String userAgent) {
        DriverProfile driver = driverProfileRepository.findById(dto.getEntityId())
                .orElseThrow(() -> new ResourceNotFoundException("Driver not found with ID: " + dto.getEntityId()));
        KycStatusTransitionValidator.requireAdminDecision(driver.getKycStatus(), dto.getStatus());
        String oldValue = serializeKycState(driver.getKycStatus(), driver.getKycRejectionReason(), driver.getVerifiedAt());
        driver.setKycStatus(dto.getStatus());
        if (dto.getRejectionReason() != null) {
            driver.setKycRejectionReason(dto.getRejectionReason());
        }
        if (dto.getStatus() == KycStatus.APPROVED) {
            driver.setVerifiedAt(Instant.now());
        } else {
            driver.setVerifiedAt(null);
        }
        DriverProfile savedDriver = driverProfileRepository.save(driver);
        if (savedDriver == null) savedDriver = driver;

        String newValue = serializeKycState(savedDriver.getKycStatus(), savedDriver.getKycRejectionReason(), savedDriver.getVerifiedAt());

        if (auditService != null) {
            auditService.logAction(actor, "REVIEW_DRIVER_KYC", "DriverProfile", savedDriver.getId().toString(),
                    oldValue, newValue, ipAddress, userAgent);
        }

        UUID ownerUserId = savedDriver.getUser() != null ? savedDriver.getUser().getId() : null;
        if (applicationEventPublisher != null) {
            applicationEventPublisher.publishEvent(KycReviewedEvent.builder().entityType("DRIVER")
                    .entityId(savedDriver.getId()).ownerUserId(ownerUserId).status(savedDriver.getKycStatus())
                    .rejectionReason(savedDriver.getKycRejectionReason()).build());
        }
    }

    @Transactional
    public void reviewVehicleKyc(KycApprovalDto dto) {
        reviewVehicleKyc(dto, null, null, null);
    }

    @Transactional
    public void reviewVehicleKyc(KycApprovalDto dto, User actor, String ipAddress, String userAgent) {
        Vehicle vehicle = vehicleRepository.findById(dto.getEntityId())
                .orElseThrow(() -> new ResourceNotFoundException("Vehicle not found with ID: " + dto.getEntityId()));
        KycStatusTransitionValidator.requireAdminDecision(vehicle.getKycStatus(), dto.getStatus());

        String oldValue = serializeKycState(vehicle.getKycStatus(), vehicle.getRejectionReason(), vehicle.getVerifiedAt());

        vehicle.setKycStatus(dto.getStatus());
        if (dto.getRejectionReason() != null) {
            vehicle.setRejectionReason(dto.getRejectionReason());
        }
        if (dto.getStatus() == KycStatus.APPROVED) {
            vehicle.setVerifiedAt(Instant.now());
        }
        Vehicle savedVehicle = vehicleRepository.save(vehicle);
        if (savedVehicle == null) savedVehicle = vehicle;

        String newValue = serializeKycState(savedVehicle.getKycStatus(), savedVehicle.getRejectionReason(), savedVehicle.getVerifiedAt());

        if (auditService != null) {
            auditService.logAction(actor, "REVIEW_VEHICLE_KYC", "Vehicle", savedVehicle.getId().toString(),
                    oldValue, newValue, ipAddress, userAgent);
        }

        UUID ownerUserId = savedVehicle.getAgency() != null && savedVehicle.getAgency().getUser() != null
                ? savedVehicle.getAgency().getUser().getId()
                : null;

        if (applicationEventPublisher != null) {
            applicationEventPublisher.publishEvent(KycReviewedEvent.builder().entityType("VEHICLE")
                    .entityId(savedVehicle.getId()).ownerUserId(ownerUserId).status(savedVehicle.getKycStatus())
                    .rejectionReason(savedVehicle.getRejectionReason()).build());
        }
    }

    private String serializeKycState(Object status, String rejectionReason, Instant verifiedAt) {
        try {
            Map<String, Object> stateMap = new HashMap<>();
            stateMap.put("kycStatus", status != null ? status.toString() : null);
            stateMap.put("kycRejectionReason", rejectionReason);
            stateMap.put("verifiedAt", verifiedAt != null ? verifiedAt.toString() : null);
            return objectMapper.writeValueAsString(stateMap);
        } catch (Exception e) {
            return "{}";
        }
    }

}
