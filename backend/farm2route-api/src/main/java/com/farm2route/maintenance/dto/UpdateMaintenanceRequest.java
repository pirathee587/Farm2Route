package com.farm2route.maintenance.dto;

import com.farm2route.common.enums.MaintenanceStatus;
import jakarta.validation.constraints.DecimalMin;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdateMaintenanceRequest {
    private String maintenanceType;
    private String title;
    private String description;

    @DecimalMin(value = "0.00", message = "Maintenance cost cannot be negative")
    private BigDecimal cost;

    private LocalDate maintenanceDate;
    private LocalDate nextDueDate;
    private String serviceCenterName;
    private String invoiceDocumentUrl;
    private MaintenanceStatus status;
}
