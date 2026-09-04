package com.farm2route.vehicle.service;

import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.agency.repository.AgencyProfileRepository;
import com.farm2route.common.enums.KycStatus;
import com.farm2route.common.enums.VehicleStatus;
import com.farm2route.common.enums.VehicleType;
import com.farm2route.common.event.VehicleKycUpdatedEvent;
import com.farm2route.common.exception.ConflictException;
import com.farm2route.common.exception.ResourceNotFoundException;
import com.farm2route.vehicle.dto.CreateVehicleRequest;
import com.farm2route.vehicle.dto.UpdateVehicleKycRequest;
import com.farm2route.vehicle.dto.UpdateVehicleRequest;
import com.farm2route.vehicle.dto.VehicleDto;
import com.farm2route.vehicle.entity.Vehicle;
import com.farm2route.vehicle.repository.VehicleRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class VehicleServiceTest {

    @Mock
    private VehicleRepository vehicleRepository;

    @Mock
    private AgencyProfileRepository agencyProfileRepository;

    @Mock
    private ApplicationEventPublisher applicationEventPublisher;

    @InjectMocks
    private VehicleService vehicleService;

    private UUID agencyUserId;
    private UUID agencyId;
    private UUID vehicleId;
    private AgencyProfile agencyProfile;
    private Vehicle sampleVehicle;
    private CreateVehicleRequest createRequest;

    @BeforeEach
    void setUp() {
        agencyUserId = UUID.randomUUID();
        agencyId = UUID.randomUUID();
        vehicleId = UUID.randomUUID();

        agencyProfile = AgencyProfile.builder()
                .id(agencyId)
                .companyName("Green Route Logistics")
                .build();

        createRequest = CreateVehicleRequest.builder()
                .registrationNumber("WP-CAB-1234")
                .capacity(new BigDecimal("3500.00"))
                .cargoVolumeCbm(new BigDecimal("15.50"))
                .vehicleType(VehicleType.TRUCK)
                .isRefrigerated(true)
                .insurancePolicyNumber("INS-998877")
                .makeAndModel("Isuzu Elf")
                .build();

        sampleVehicle = Vehicle.builder()
                .id(vehicleId)
                .agency(agencyProfile)
                .registrationNumber("WP-CAB-1234")
                .capacity(new BigDecimal("3500.00"))
                .cargoVolumeCbm(new BigDecimal("15.50"))
                .vehicleType(VehicleType.TRUCK)
                .isRefrigerated(true)
                .insurancePolicyNumber("INS-998877")
                .makeAndModel("Isuzu Elf")
                .status(VehicleStatus.AVAILABLE)
                .kycStatus(KycStatus.PENDING_APPROVAL)
                .build();
    }

    @Test
    @DisplayName("Create vehicle successfully")
    void testCreateVehicle_Success() {
        when(agencyProfileRepository.findByUserId(agencyUserId)).thenReturn(Optional.of(agencyProfile));
        when(vehicleRepository.existsByRegistrationNumber(createRequest.getRegistrationNumber())).thenReturn(false);
        when(vehicleRepository.save(any(Vehicle.class))).thenAnswer(invocation -> {
            Vehicle v = invocation.getArgument(0);
            v.setId(vehicleId);
            return v;
        });

        VehicleDto result = vehicleService.createVehicle(agencyUserId, createRequest);

        assertThat(result).isNotNull();
        assertThat(result.getId()).isEqualTo(vehicleId);
        assertThat(result.getRegistrationNumber()).isEqualTo("WP-CAB-1234");
        assertThat(result.getKycStatus()).isEqualTo(KycStatus.PENDING_APPROVAL);
        verify(vehicleRepository, times(1)).save(any(Vehicle.class));
    }

    @Test
    @DisplayName("Create vehicle throws ConflictException when registration number exists")
    void testCreateVehicle_DuplicateRegistration_ThrowsConflictException() {
        when(agencyProfileRepository.findByUserId(agencyUserId)).thenReturn(Optional.of(agencyProfile));
        when(vehicleRepository.existsByRegistrationNumber(createRequest.getRegistrationNumber())).thenReturn(true);

        assertThatThrownBy(() -> vehicleService.createVehicle(agencyUserId, createRequest))
                .isInstanceOf(ConflictException.class)
                .hasMessageContaining("already registered");

        verify(vehicleRepository, never()).save(any());
    }

    @Test
    @DisplayName("Get agency vehicles returns list of vehicles")
    void testGetAgencyVehicles_Success() {
        when(agencyProfileRepository.findByUserId(agencyUserId)).thenReturn(Optional.of(agencyProfile));
        when(vehicleRepository.findByAgencyId(agencyId)).thenReturn(List.of(sampleVehicle));

        List<VehicleDto> result = vehicleService.getAgencyVehicles(agencyUserId);

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getRegistrationNumber()).isEqualTo("WP-CAB-1234");
    }

    @Test
    @DisplayName("Update vehicle KYC publishes VehicleKycUpdatedEvent upon success")
    void testUpdateVehicleKyc_PublishesVehicleKycUpdatedEvent() {
        UpdateVehicleKycRequest kycRequest = UpdateVehicleKycRequest.builder()
                .kycStatus(KycStatus.APPROVED)
                .rejectionReason(null)
                .build();

        when(agencyProfileRepository.findByUserId(agencyUserId)).thenReturn(Optional.of(agencyProfile));
        when(vehicleRepository.findByIdAndAgencyId(vehicleId, agencyId)).thenReturn(Optional.of(sampleVehicle));
        when(vehicleRepository.save(any(Vehicle.class))).thenAnswer(invocation -> invocation.getArgument(0));

        VehicleDto result = vehicleService.updateVehicleKyc(vehicleId, agencyUserId, kycRequest);

        assertThat(result.getKycStatus()).isEqualTo(KycStatus.APPROVED);
        assertThat(result.getVerifiedAt()).isNotNull();

        verify(applicationEventPublisher, times(1)).publishEvent(any(VehicleKycUpdatedEvent.class));
    }

    @Test
    @DisplayName("Update vehicle KYC does not publish event if repository save fails")
    void testUpdateVehicleKyc_WhenSaveFails_DoesNotPublishEvent() {
        UpdateVehicleKycRequest kycRequest = UpdateVehicleKycRequest.builder()
                .kycStatus(KycStatus.APPROVED)
                .build();

        when(agencyProfileRepository.findByUserId(agencyUserId)).thenReturn(Optional.of(agencyProfile));
        when(vehicleRepository.findByIdAndAgencyId(vehicleId, agencyId)).thenReturn(Optional.of(sampleVehicle));
        when(vehicleRepository.save(any(Vehicle.class))).thenThrow(new RuntimeException("Database error"));

        assertThatThrownBy(() -> vehicleService.updateVehicleKyc(vehicleId, agencyUserId, kycRequest))
                .isInstanceOf(RuntimeException.class)
                .hasMessage("Database error");

        verify(applicationEventPublisher, never()).publishEvent(any());
    }

    @Test
    @DisplayName("Delete vehicle successfully removes vehicle")
    void testDeleteVehicle_Success() {
        when(agencyProfileRepository.findByUserId(agencyUserId)).thenReturn(Optional.of(agencyProfile));
        when(vehicleRepository.findByIdAndAgencyId(vehicleId, agencyId)).thenReturn(Optional.of(sampleVehicle));

        vehicleService.deleteVehicle(vehicleId, agencyUserId);

        verify(vehicleRepository, times(1)).delete(sampleVehicle);
    }
}

