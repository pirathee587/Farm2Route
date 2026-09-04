package com.farm2route.vehicle.service;

import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.agency.repository.AgencyProfileRepository;
import com.farm2route.common.enums.KycStatus;
import com.farm2route.common.enums.VehicleStatus;
import com.farm2route.common.event.VehicleKycUpdatedEvent;
import com.farm2route.common.exception.ConflictException;
import com.farm2route.common.exception.ResourceNotFoundException;
import com.farm2route.vehicle.dto.CreateVehicleRequest;
import com.farm2route.vehicle.dto.UpdateVehicleKycRequest;
import com.farm2route.vehicle.dto.UpdateVehicleRequest;
import com.farm2route.vehicle.dto.VehicleDto;
import com.farm2route.vehicle.entity.Vehicle;
import com.farm2route.vehicle.repository.VehicleRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class VehicleService {

    private final VehicleRepository vehicleRepository;
    private final AgencyProfileRepository agencyProfileRepository;

    /**
     * Used to publish Spring internal events — VehicleEventRelay forwards to RabbitMQ AFTER_COMMIT.
     */
    private final ApplicationEventPublisher applicationEventPublisher;

    @Transactional
    public VehicleDto createVehicle(UUID agencyUserId, CreateVehicleRequest request) {
        AgencyProfile agency = agencyProfileRepository.findByUserId(agencyUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Agency profile not found for user: " + agencyUserId));

        if (vehicleRepository.existsByRegistrationNumber(request.getRegistrationNumber())) {
            throw new ConflictException("Vehicle registration number already registered: " + request.getRegistrationNumber());
        }

        Vehicle vehicle = Vehicle.builder()
                .agency(agency)
                .registrationNumber(request.getRegistrationNumber())
                .capacity(request.getCapacity())
                .cargoVolumeCbm(request.getCargoVolumeCbm())
                .vehicleType(request.getVehicleType())
                .isRefrigerated(request.isRefrigerated())
                .insurancePolicyNumber(request.getInsurancePolicyNumber())
                .makeAndModel(request.getMakeAndModel())
                .insuranceExpiryDate(request.getInsuranceExpiryDate())
                .revenueLicenseNumber(request.getRevenueLicenseNumber())
                .revenueLicenseExpiryDate(request.getRevenueLicenseExpiryDate())
                .status(VehicleStatus.AVAILABLE)
                .kycStatus(KycStatus.PENDING_APPROVAL)
                .build();

        vehicle = vehicleRepository.save(vehicle);
        log.info("Successfully created vehicle id={} regNo={} for agencyId={}", vehicle.getId(), vehicle.getRegistrationNumber(), agency.getId());
        return mapToDto(vehicle);
    }

    @Transactional(readOnly = true)
    public List<VehicleDto> getAgencyVehicles(UUID agencyUserId) {
        AgencyProfile agency = agencyProfileRepository.findByUserId(agencyUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Agency profile not found for user: " + agencyUserId));

        return vehicleRepository.findByAgencyId(agency.getId()).stream()
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public VehicleDto getVehicleById(UUID vehicleId, UUID agencyUserId) {
        AgencyProfile agency = agencyProfileRepository.findByUserId(agencyUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Agency profile not found for user: " + agencyUserId));

        Vehicle vehicle = vehicleRepository.findByIdAndAgencyId(vehicleId, agency.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Vehicle not found with id: " + vehicleId));

        return mapToDto(vehicle);
    }

    @Transactional
    public VehicleDto updateVehicle(UUID vehicleId, UUID agencyUserId, UpdateVehicleRequest request) {
        AgencyProfile agency = agencyProfileRepository.findByUserId(agencyUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Agency profile not found for user: " + agencyUserId));

        Vehicle vehicle = vehicleRepository.findByIdAndAgencyId(vehicleId, agency.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Vehicle not found with id: " + vehicleId));

        if (request.getRegistrationNumber() != null && !request.getRegistrationNumber().equals(vehicle.getRegistrationNumber())) {
            if (vehicleRepository.existsByRegistrationNumberAndIdNot(request.getRegistrationNumber(), vehicleId)) {
                throw new ConflictException("Vehicle registration number already registered: " + request.getRegistrationNumber());
            }
            vehicle.setRegistrationNumber(request.getRegistrationNumber());
        }

        if (request.getCapacity() != null) vehicle.setCapacity(request.getCapacity());
        if (request.getCargoVolumeCbm() != null) vehicle.setCargoVolumeCbm(request.getCargoVolumeCbm());
        if (request.getVehicleType() != null) vehicle.setVehicleType(request.getVehicleType());
        if (request.getIsRefrigerated() != null) vehicle.setRefrigerated(request.getIsRefrigerated());
        if (request.getInsurancePolicyNumber() != null) vehicle.setInsurancePolicyNumber(request.getInsurancePolicyNumber());
        if (request.getMakeAndModel() != null) vehicle.setMakeAndModel(request.getMakeAndModel());
        if (request.getInsuranceExpiryDate() != null) vehicle.setInsuranceExpiryDate(request.getInsuranceExpiryDate());
        if (request.getRevenueLicenseNumber() != null) vehicle.setRevenueLicenseNumber(request.getRevenueLicenseNumber());
        if (request.getRevenueLicenseExpiryDate() != null) vehicle.setRevenueLicenseExpiryDate(request.getRevenueLicenseExpiryDate());
        if (request.getStatus() != null) vehicle.setStatus(request.getStatus());

        vehicle = vehicleRepository.save(vehicle);
        log.info("Successfully updated vehicle id={}", vehicleId);
        return mapToDto(vehicle);
    }

    @Transactional
    public void deleteVehicle(UUID vehicleId, UUID agencyUserId) {
        AgencyProfile agency = agencyProfileRepository.findByUserId(agencyUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Agency profile not found for user: " + agencyUserId));

        Vehicle vehicle = vehicleRepository.findByIdAndAgencyId(vehicleId, agency.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Vehicle not found with id: " + vehicleId));

        vehicleRepository.delete(vehicle);
        log.info("Successfully deleted vehicle id={}", vehicleId);
    }

    @Transactional
    public VehicleDto updateVehicleKyc(UUID vehicleId, UUID agencyUserId, UpdateVehicleKycRequest request) {
        AgencyProfile agency = agencyProfileRepository.findByUserId(agencyUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Agency profile not found for user: " + agencyUserId));

        Vehicle vehicle = vehicleRepository.findByIdAndAgencyId(vehicleId, agency.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Vehicle not found with id: " + vehicleId));

        return updateKycInternal(vehicle, request.getKycStatus(), request.getRejectionReason());
    }

    @Transactional
    public VehicleDto updateVehicleKycAdmin(UUID vehicleId, UpdateVehicleKycRequest request) {
        Vehicle vehicle = vehicleRepository.findById(vehicleId)
                .orElseThrow(() -> new ResourceNotFoundException("Vehicle not found with id: " + vehicleId));

        return updateKycInternal(vehicle, request.getKycStatus(), request.getRejectionReason());
    }

    private VehicleDto updateKycInternal(Vehicle vehicle, KycStatus newKycStatus, String rejectionReason) {
        vehicle.setKycStatus(newKycStatus);
        vehicle.setRejectionReason(rejectionReason);
        if (newKycStatus == KycStatus.APPROVED) {
            vehicle.setVerifiedAt(Instant.now());
        }

        vehicle = vehicleRepository.save(vehicle);
        log.info("Updated KYC status for vehicleId={} to status={}", vehicle.getId(), newKycStatus);

        // Publish Spring ApplicationEvent — VehicleEventRelay handles AFTER_COMMIT dispatch to RabbitMQ
        applicationEventPublisher.publishEvent(
                VehicleKycUpdatedEvent.builder()
                        .vehicleId(vehicle.getId())
                        .agencyId(vehicle.getAgency().getId())
                        .kycStatus(vehicle.getKycStatus())
                        .build()
        );

        return mapToDto(vehicle);
    }

    private VehicleDto mapToDto(Vehicle vehicle) {
        return VehicleDto.builder()
                .id(vehicle.getId())
                .agencyId(vehicle.getAgency().getId())
                .registrationNumber(vehicle.getRegistrationNumber())
                .capacity(vehicle.getCapacity())
                .cargoVolumeCbm(vehicle.getCargoVolumeCbm())
                .vehicleType(vehicle.getVehicleType())
                .isRefrigerated(vehicle.isRefrigerated())
                .insurancePolicyNumber(vehicle.getInsurancePolicyNumber())
                .makeAndModel(vehicle.getMakeAndModel())
                .insuranceExpiryDate(vehicle.getInsuranceExpiryDate())
                .revenueLicenseNumber(vehicle.getRevenueLicenseNumber())
                .revenueLicenseExpiryDate(vehicle.getRevenueLicenseExpiryDate())
                .status(vehicle.getStatus())
                .kycStatus(vehicle.getKycStatus())
                .rejectionReason(vehicle.getRejectionReason())
                .verifiedAt(vehicle.getVerifiedAt())
                .createdAt(vehicle.getCreatedAt())
                .updatedAt(vehicle.getUpdatedAt())
                .build();
    }
}

