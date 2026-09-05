package com.farm2route.incident.dto;

import com.farm2route.common.enums.IncidentStatus;
import com.farm2route.common.enums.IncidentType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AdminIncidentDetailDto {

    private UUID id;
    private UUID bookingId;
    private String bookingNumber;
    private UUID reportedByUserId;
    private IncidentType incidentType;
    private String title;
    private String description;
    private IncidentStatus status;

    private String adminNotes;
    private String investigationNotes;
    private UUID resolvedByAdminId;
    private String resolutionOutcome;
    private BigDecimal refundAmount;
    private Instant resolvedAt;
    private Instant createdAt;
    private Instant updatedAt;

    private List<EvidenceDto> evidenceList;

    // Joined summary fields
    private FarmerSummary farmerSummary;
    private AgencySummary agencySummary;
    private DriverSummary driverSummary;
    private VehicleSummary vehicleSummary;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class EvidenceDto {
        private UUID id;
        private String fileUrl;
        private String photoUrl;
        private String fileType;
        private String caption;
        private Instant createdAt;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class FarmerSummary {
        private UUID farmerId;
        private UUID userId;
        private String farmName;
        private String farmerName;
        private String farmerEmail;
        private String farmerPhone;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AgencySummary {
        private UUID agencyId;
        private UUID userId;
        private String companyName;
        private String contactPhone;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DriverSummary {
        private UUID driverId;
        private UUID userId;
        private String driverName;
        private String driverPhone;
        private String licenseNumber;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class VehicleSummary {
        private UUID vehicleId;
        private String registrationNumber;
        private String vehicleType;
        private BigDecimal capacityKg;
    }
}
