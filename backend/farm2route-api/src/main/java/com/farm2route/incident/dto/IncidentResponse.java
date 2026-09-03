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
public class IncidentResponse {

    private UUID id;
    private UUID bookingId;
    private String bookingNumber;
    private String route;
    private String cargoType;
    private IncidentType incidentType;
    private String title;
    private String description;
    private IncidentStatus status;
    private List<String> evidencePhotoUrls;

    // Read-only resolution info populated by Member 3's moderation lifecycle
    private String adminNotes;
    private String investigationNotes;
    private String resolutionOutcome;
    private BigDecimal refundAmount;
    private Instant resolvedAt;

    private Instant createdAt;
    private Instant updatedAt;
}
