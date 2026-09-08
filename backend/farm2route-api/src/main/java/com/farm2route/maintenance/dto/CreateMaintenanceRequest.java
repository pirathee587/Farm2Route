package com.farm2route.maintenance.dto;

import com.farm2route.common.enums.MaintenanceStatus;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateMaintenanceRequest {
    @NotBlank(message = "Maintenance type is required")
    private String maintenanceType;

    @NotBlank(message = "Maintenance title is required")
    private String title;

    private String description;

    @NotNull(message = "Maintenance cost is required")
    @DecimalMin(value = "0.00", message = "Maintenance cost cannot be negative")
    private BigDecimal cost;

    @NotNull(message = "Maintenance date is required")
    private LocalDate maintenanceDate;

    private LocalDate nextDueDate;
    private String serviceCenterName;
    private String invoiceDocumentUrl;
    private MaintenanceStatus status;
}
