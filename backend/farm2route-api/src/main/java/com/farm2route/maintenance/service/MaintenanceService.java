package com.farm2route.maintenance.service;

import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.agency.repository.AgencyProfileRepository;
import com.farm2route.common.enums.MaintenanceStatus;
import com.farm2route.common.enums.VehicleStatus;
import com.farm2route.common.exception.BusinessRuleException;
import com.farm2route.common.exception.ResourceNotFoundException;
import com.farm2route.maintenance.dto.CreateMaintenanceRequest;
import com.farm2route.maintenance.dto.MaintenanceResponse;
import com.farm2route.maintenance.dto.UpdateMaintenanceRequest;
import com.farm2route.maintenance.entity.VehicleMaintenance;
import com.farm2route.maintenance.repository.VehicleMaintenanceRepository;
import com.farm2route.vehicle.entity.Vehicle;
import com.farm2route.vehicle.repository.VehicleRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class MaintenanceService {
    private final VehicleMaintenanceRepository maintenanceRepository;
    private final VehicleRepository vehicleRepository;
    private final AgencyProfileRepository agencyProfileRepository;

    @Transactional
    public MaintenanceResponse create(UUID agencyUserId, UUID vehicleId, CreateMaintenanceRequest request) {
        Vehicle vehicle = vehicleForAgency(vehicleId, agencyUserId);
        MaintenanceStatus status = request.getStatus() == null ? MaintenanceStatus.COMPLETED : request.getStatus();
        validateDates(request.getMaintenanceDate(), request.getNextDueDate());
        validateActiveStatus(vehicle, status);

        VehicleMaintenance record = VehicleMaintenance.builder()
                .vehicle(vehicle)
                .maintenanceType(request.getMaintenanceType().trim())
                .title(request.getTitle().trim())
                .description(trimToNull(request.getDescription()))
                .cost(request.getCost())
                .maintenanceDate(request.getMaintenanceDate())
                .nextDueDate(request.getNextDueDate())
                .serviceCenterName(trimToNull(request.getServiceCenterName()))
                .invoiceDocumentUrl(trimToNull(request.getInvoiceDocumentUrl()))
                .status(status)
                .build();
        syncVehicleStatus(vehicle, status);
        return MaintenanceResponse.fromEntity(maintenanceRepository.save(record));
    }

    @Transactional(readOnly = true)
    public List<MaintenanceResponse> listForVehicle(UUID agencyUserId, UUID vehicleId) {
        vehicleForAgency(vehicleId, agencyUserId);
        return maintenanceRepository.findByVehicleIdOrderByMaintenanceDateDesc(vehicleId)
                .stream().map(MaintenanceResponse::fromEntity).toList();
    }

    @Transactional(readOnly = true)
    public List<MaintenanceResponse> listActiveForAgency(UUID agencyUserId) {
        AgencyProfile agency = agencyForUser(agencyUserId);
        return maintenanceRepository.findByVehicleAgencyIdAndStatusOrderByMaintenanceDateDesc(
                        agency.getId(), MaintenanceStatus.IN_PROGRESS)
                .stream().map(MaintenanceResponse::fromEntity).toList();
    }

    @Transactional
    public MaintenanceResponse update(UUID agencyUserId, UUID maintenanceId, UpdateMaintenanceRequest request) {
        VehicleMaintenance record = maintenanceRepository.findById(maintenanceId)
                .orElseThrow(() -> new ResourceNotFoundException("Maintenance record not found: " + maintenanceId));
        Vehicle vehicle = vehicleForAgency(record.getVehicle().getId(), agencyUserId);
        LocalDate date = request.getMaintenanceDate() == null ? record.getMaintenanceDate() : request.getMaintenanceDate();
        LocalDate nextDue = request.getNextDueDate() == null ? record.getNextDueDate() : request.getNextDueDate();
        validateDates(date, nextDue);

        MaintenanceStatus newStatus = request.getStatus() == null ? record.getStatus() : request.getStatus();
        validateTransition(record.getStatus(), newStatus);
        validateActiveStatus(vehicle, newStatus);
        if (request.getMaintenanceType() != null) record.setMaintenanceType(request.getMaintenanceType().trim());
        if (request.getTitle() != null) record.setTitle(request.getTitle().trim());
        if (request.getDescription() != null) record.setDescription(trimToNull(request.getDescription()));
        if (request.getCost() != null) record.setCost(request.getCost());
        record.setMaintenanceDate(date);
        record.setNextDueDate(nextDue);
        if (request.getServiceCenterName() != null) record.setServiceCenterName(trimToNull(request.getServiceCenterName()));
        if (request.getInvoiceDocumentUrl() != null) record.setInvoiceDocumentUrl(trimToNull(request.getInvoiceDocumentUrl()));
        record.setStatus(newStatus);
        syncVehicleStatus(vehicle, newStatus);
        return MaintenanceResponse.fromEntity(maintenanceRepository.save(record));
    }

    private Vehicle vehicleForAgency(UUID vehicleId, UUID agencyUserId) {
        AgencyProfile agency = agencyForUser(agencyUserId);
        return vehicleRepository.findByIdAndAgencyId(vehicleId, agency.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Vehicle not found with id: " + vehicleId));
    }

    private AgencyProfile agencyForUser(UUID userId) {
        return agencyProfileRepository.findByUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Agency profile not found for user: " + userId));
    }

    private void validateDates(LocalDate maintenanceDate, LocalDate nextDueDate) {
        if (maintenanceDate == null) throw new BusinessRuleException("Maintenance date is required");
        if (nextDueDate != null && nextDueDate.isBefore(maintenanceDate)) {
            throw new BusinessRuleException("Next due date cannot be before maintenance date");
        }
    }

    private void validateActiveStatus(Vehicle vehicle, MaintenanceStatus status) {
        if (status != MaintenanceStatus.SCHEDULED && status != MaintenanceStatus.IN_PROGRESS) return;
        if (vehicle.getStatus() == VehicleStatus.IN_USE) {
            throw new BusinessRuleException("Vehicle in use cannot be placed under maintenance");
        }
    }

    private void validateTransition(MaintenanceStatus oldStatus, MaintenanceStatus newStatus) {
        if (oldStatus == newStatus) return;
        boolean valid = (oldStatus == MaintenanceStatus.SCHEDULED &&
                (newStatus == MaintenanceStatus.IN_PROGRESS || newStatus == MaintenanceStatus.CANCELLED))
                || (oldStatus == MaintenanceStatus.IN_PROGRESS &&
                (newStatus == MaintenanceStatus.COMPLETED || newStatus == MaintenanceStatus.CANCELLED));
        if (!valid) throw new BusinessRuleException("Invalid maintenance status transition: " + oldStatus + " -> " + newStatus);
    }

    private void syncVehicleStatus(Vehicle vehicle, MaintenanceStatus status) {
        if (status == MaintenanceStatus.SCHEDULED || status == MaintenanceStatus.IN_PROGRESS) {
            vehicle.setStatus(VehicleStatus.UNDER_MAINTENANCE);
        } else if ((status == MaintenanceStatus.COMPLETED || status == MaintenanceStatus.CANCELLED)
                && vehicle.getStatus() == VehicleStatus.UNDER_MAINTENANCE) {
            vehicle.setStatus(VehicleStatus.AVAILABLE);
        }
        vehicleRepository.save(vehicle);
    }

    private String trimToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
