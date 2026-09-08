package com.farm2route.maintenance.dto;

import com.farm2route.common.enums.MaintenanceStatus;
import com.farm2route.maintenance.entity.VehicleMaintenance;
import lombok.Builder;
import lombok.Value;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Value
@Builder
public class MaintenanceResponse {
    UUID id;
    UUID vehicleId;
    String maintenanceType;
    String title;
    String description;
    BigDecimal cost;
    LocalDate maintenanceDate;
    LocalDate nextDueDate;
    String serviceCenterName;
    String invoiceDocumentUrl;
    MaintenanceStatus status;
    Instant createdAt;
    Instant updatedAt;

    public static MaintenanceResponse fromEntity(VehicleMaintenance maintenance) {
        return MaintenanceResponse.builder()
                .id(maintenance.getId())
                .vehicleId(maintenance.getVehicle().getId())
                .maintenanceType(maintenance.getMaintenanceType())
                .title(maintenance.getTitle())
                .description(maintenance.getDescription())
                .cost(maintenance.getCost())
                .maintenanceDate(maintenance.getMaintenanceDate())
                .nextDueDate(maintenance.getNextDueDate())
                .serviceCenterName(maintenance.getServiceCenterName())
                .invoiceDocumentUrl(maintenance.getInvoiceDocumentUrl())
                .status(maintenance.getStatus())
                .createdAt(maintenance.getCreatedAt())
                .updatedAt(maintenance.getUpdatedAt())
                .build();
    }
}
