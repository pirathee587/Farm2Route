package com.farm2route.admin.service;

import com.farm2route.agency.repository.AgencyProfileRepository;
import com.farm2route.auth.repository.UserRepository;
import com.farm2route.admin.dto.KycApprovalDto;
import com.farm2route.common.enums.KycStatus;
import com.farm2route.common.exception.BusinessRuleException;
import com.farm2route.driver.entity.DriverProfile;
import com.farm2route.driver.repository.DriverProfileRepository;
import com.farm2route.vehicle.entity.Vehicle;
import com.farm2route.vehicle.repository.VehicleRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AdminKycTransitionTest {
    @Mock UserRepository userRepository;
    @Mock AgencyProfileRepository agencyProfileRepository;
    @Mock DriverProfileRepository driverProfileRepository;
    @Mock VehicleRepository vehicleRepository;
    @InjectMocks AdminService adminService;

    @Test
    void adminCanApproveAndRejectPendingDriver() {
        UUID id = UUID.randomUUID();
        DriverProfile driver = DriverProfile.builder().id(id).kycStatus(KycStatus.PENDING).build();
        when(driverProfileRepository.findById(id)).thenReturn(Optional.of(driver));

        adminService.reviewDriverKyc(KycApprovalDto.builder().entityId(id).status(KycStatus.APPROVED).build());
        assertThat(driver.getKycStatus()).isEqualTo(KycStatus.APPROVED);
        assertThat(driver.getVerifiedAt()).isNotNull();

        driver.setKycStatus(KycStatus.PENDING);
        adminService.reviewDriverKyc(KycApprovalDto.builder().entityId(id).status(KycStatus.REJECTED).build());
        assertThat(driver.getKycStatus()).isEqualTo(KycStatus.REJECTED);
    }

    @Test
    void adminCanApproveAndRejectPendingVehicle() {
        UUID id = UUID.randomUUID();
        Vehicle vehicle = Vehicle.builder().id(id).kycStatus(KycStatus.PENDING_APPROVAL).build();
        when(vehicleRepository.findById(id)).thenReturn(Optional.of(vehicle));

        adminService.reviewVehicleKyc(KycApprovalDto.builder().entityId(id).status(KycStatus.APPROVED).build());
        assertThat(vehicle.getKycStatus()).isEqualTo(KycStatus.APPROVED);
        assertThat(vehicle.getVerifiedAt()).isNotNull();

        vehicle.setKycStatus(KycStatus.PENDING_APPROVAL);
        adminService.reviewVehicleKyc(KycApprovalDto.builder().entityId(id).status(KycStatus.REJECTED).build());
        assertThat(vehicle.getKycStatus()).isEqualTo(KycStatus.REJECTED);
    }

    @Test
    void illegalAdminTransitionIsRejected() {
        UUID id = UUID.randomUUID();
        DriverProfile driver = DriverProfile.builder().id(id).kycStatus(KycStatus.APPROVED).build();
        when(driverProfileRepository.findById(id)).thenReturn(Optional.of(driver));

        assertThatThrownBy(() -> adminService.reviewDriverKyc(
                KycApprovalDto.builder().entityId(id).status(KycStatus.REJECTED).build()))
                .isInstanceOf(BusinessRuleException.class);
        verify(driverProfileRepository, never()).save(any());
    }
}
