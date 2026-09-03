package com.farm2route.admin.service;

import com.farm2route.admin.dto.AdminStatsDto;
import com.farm2route.admin.dto.KycApprovalDto;
import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.agency.repository.AgencyProfileRepository;
import com.farm2route.audit.service.AuditService;
import com.farm2route.auth.entity.User;
import com.farm2route.auth.repository.UserRepository;
import com.farm2route.auth.model.Role;
import com.farm2route.common.exception.ResourceNotFoundException;
import com.farm2route.driver.entity.DriverProfile;
import com.farm2route.driver.repository.DriverProfileRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.HashMap;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class AdminService {

    private final UserRepository userRepository;
    private final AgencyProfileRepository agencyProfileRepository;
    private final DriverProfileRepository driverProfileRepository;
    private final AuditService auditService;
    private final ObjectMapper objectMapper;

    @Transactional(readOnly = true)
    public AdminStatsDto getDashboardStats() {
        return AdminStatsDto.builder()
                .totalUsers(userRepository.count())
                .totalFarmers(userRepository.findByRole(Role.FARMER).size())
                .totalAgencies(userRepository.findByRole(Role.AGENCY).size())
                .totalDrivers(userRepository.findByRole(Role.DRIVER).size())
                .pendingKycs(0)
                .activeBookings(0)
                .openIncidents(0)
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

        String oldValue = serializeKycState(agency.getKycStatus(), agency.getKycRejectionReason(), agency.getVerifiedAt());

        agency.setKycStatus(dto.getStatus());
        if (dto.getRejectionReason() != null) {
            agency.setKycRejectionReason(dto.getRejectionReason());
        }
        if (dto.getStatus() == com.farm2route.common.enums.KycStatus.APPROVED) {
            agency.setVerifiedAt(Instant.now());
        }
        AgencyProfile savedAgency = agencyProfileRepository.save(agency);

        String newValue = serializeKycState(savedAgency.getKycStatus(), savedAgency.getKycRejectionReason(), savedAgency.getVerifiedAt());

        auditService.logAction(
                actor,
                "REVIEW_AGENCY_KYC",
                "AgencyProfile",
                savedAgency.getId().toString(),
                oldValue,
                newValue,
                ipAddress,
                userAgent
        );
    }

    @Transactional
    public void reviewDriverKyc(KycApprovalDto dto) {
        reviewDriverKyc(dto, null, null, null);
    }

    @Transactional
    public void reviewDriverKyc(KycApprovalDto dto, User actor, String ipAddress, String userAgent) {
        DriverProfile driver = driverProfileRepository.findById(dto.getEntityId())
                .orElseThrow(() -> new ResourceNotFoundException("Driver not found with ID: " + dto.getEntityId()));

        String oldValue = serializeKycState(driver.getKycStatus(), driver.getKycRejectionReason(), driver.getVerifiedAt());

        driver.setKycStatus(dto.getStatus());
        if (dto.getRejectionReason() != null) {
            driver.setKycRejectionReason(dto.getRejectionReason());
        }
        if (dto.getStatus() == com.farm2route.common.enums.KycStatus.APPROVED) {
            driver.setVerifiedAt(Instant.now());
        }
        DriverProfile savedDriver = driverProfileRepository.save(driver);

        String newValue = serializeKycState(savedDriver.getKycStatus(), savedDriver.getKycRejectionReason(), savedDriver.getVerifiedAt());

        auditService.logAction(
                actor,
                "REVIEW_DRIVER_KYC",
                "DriverProfile",
                savedDriver.getId().toString(),
                oldValue,
                newValue,
                ipAddress,
                userAgent
        );
    }

    // TODO: Add vehicle KYC review audit logging when vehicle KYC review endpoint is implemented

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
