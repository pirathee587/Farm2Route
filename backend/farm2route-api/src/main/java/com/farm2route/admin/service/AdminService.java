package com.farm2route.admin.service;

import com.farm2route.admin.dto.AdminStatsDto;
import com.farm2route.admin.dto.KycApprovalDto;
import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.agency.repository.AgencyProfileRepository;
import com.farm2route.auth.repository.UserRepository;
import com.farm2route.auth.model.Role;
import com.farm2route.common.exception.ResourceNotFoundException;
import com.farm2route.driver.entity.DriverProfile;
import com.farm2route.driver.repository.DriverProfileRepository;
import com.farm2route.common.enums.KycStatus;
import com.farm2route.common.validation.KycStatusTransitionValidator;
import com.farm2route.vehicle.entity.Vehicle;
import com.farm2route.vehicle.repository.VehicleRepository;
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
    private final VehicleRepository vehicleRepository;

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
        KycStatusTransitionValidator.requireAdminDecision(agency.getKycStatus(), dto.getStatus());
        agency.setKycStatus(dto.getStatus());
        if (dto.getRejectionReason() != null) {
            agency.setKycRejectionReason(dto.getRejectionReason());
        }
        if (dto.getStatus() == KycStatus.APPROVED) {
            agency.setVerifiedAt(Instant.now());
        } else {
            agency.setVerifiedAt(null);
        }
        agencyProfileRepository.save(agency);
    }

    @Transactional
    public void reviewDriverKyc(KycApprovalDto dto) {
        DriverProfile driver = driverProfileRepository.findById(dto.getEntityId())
                .orElseThrow(() -> new ResourceNotFoundException("Driver not found with ID: " + dto.getEntityId()));
        KycStatusTransitionValidator.requireAdminDecision(driver.getKycStatus(), dto.getStatus());
        driver.setKycStatus(dto.getStatus());
        if (dto.getRejectionReason() != null) {
            driver.setKycRejectionReason(dto.getRejectionReason());
        }
        if (dto.getStatus() == KycStatus.APPROVED) {
            driver.setVerifiedAt(Instant.now());
        } else {
            driver.setVerifiedAt(null);
        }
        driverProfileRepository.save(driver);
    }

    @Transactional
    public void reviewVehicleKyc(KycApprovalDto dto) {
        Vehicle vehicle = vehicleRepository.findById(dto.getEntityId())
                .orElseThrow(() -> new ResourceNotFoundException("Vehicle not found with ID: " + dto.getEntityId()));
        KycStatusTransitionValidator.requireAdminDecision(vehicle.getKycStatus(), dto.getStatus());
        vehicle.setKycStatus(dto.getStatus());
        vehicle.setRejectionReason(dto.getRejectionReason());
        if (dto.getStatus() == KycStatus.APPROVED) {
            vehicle.setVerifiedAt(Instant.now());
        } else {
            vehicle.setVerifiedAt(null);
        }
        vehicleRepository.save(vehicle);
    }
}
