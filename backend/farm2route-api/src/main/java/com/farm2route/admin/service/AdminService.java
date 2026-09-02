package com.farm2route.admin.service;

import com.farm2route.admin.dto.AdminStatsDto;
import com.farm2route.admin.dto.KycApprovalDto;
import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.agency.repository.AgencyProfileRepository;
import com.farm2route.auth.repository.UserRepository;
import com.farm2route.common.enums.Role;
import com.farm2route.common.exception.ResourceNotFoundException;
import com.farm2route.driver.entity.DriverProfile;
import com.farm2route.driver.repository.DriverProfileRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;

@Service
@RequiredArgsConstructor
public class AdminService {

    private final UserRepository userRepository;
    private final AgencyProfileRepository agencyProfileRepository;
    private final DriverProfileRepository driverProfileRepository;

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
        AgencyProfile agency = agencyProfileRepository.findById(dto.getEntityId())
                .orElseThrow(() -> new ResourceNotFoundException("Agency not found with ID: " + dto.getEntityId()));
        agency.setKycStatus(dto.getStatus());
        if (dto.getRejectionReason() != null) {
            agency.setKycRejectionReason(dto.getRejectionReason());
        }
        if (dto.getStatus() == com.farm2route.common.enums.KycStatus.APPROVED) {
            agency.setVerifiedAt(Instant.now());
        }
        agencyProfileRepository.save(agency);
    }

    @Transactional
    public void reviewDriverKyc(KycApprovalDto dto) {
        DriverProfile driver = driverProfileRepository.findById(dto.getEntityId())
                .orElseThrow(() -> new ResourceNotFoundException("Driver not found with ID: " + dto.getEntityId()));
        driver.setKycStatus(dto.getStatus());
        if (dto.getRejectionReason() != null) {
            driver.setKycRejectionReason(dto.getRejectionReason());
        }
        if (dto.getStatus() == com.farm2route.common.enums.KycStatus.APPROVED) {
            driver.setVerifiedAt(Instant.now());
        }
        driverProfileRepository.save(driver);
    }
}
