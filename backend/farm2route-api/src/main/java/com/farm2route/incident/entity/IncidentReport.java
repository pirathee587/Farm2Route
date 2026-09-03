package com.farm2route.incident.entity;

import com.farm2route.booking.entity.Booking;
import com.farm2route.common.enums.IncidentStatus;
import com.farm2route.common.enums.IncidentType;
import com.farm2route.farmer.entity.FarmerProfile;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "incident_reports", indexes = {
        @Index(name = "idx_incidents_booking", columnList = "booking_id"),
        @Index(name = "idx_incidents_reporter", columnList = "reported_by_user_id"),
        @Index(name = "idx_incidents_status", columnList = "status"),
        @Index(name = "idx_incidents_farmer", columnList = "farmer_id")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class IncidentReport {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "booking_id", nullable = false)
    private Booking booking;

    @Column(name = "reported_by_user_id", nullable = false)
    private UUID reportedByUserId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "farmer_id")
    private FarmerProfile farmer;

    @Enumerated(EnumType.STRING)
    @Column(name = "incident_type", nullable = false, length = 50)
    private IncidentType incidentType;

    @Column(name = "title", length = 150)
    private String title;

    @Column(name = "description", nullable = false, columnDefinition = "TEXT")
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 30)
    @Builder.Default
    private IncidentStatus status = IncidentStatus.OPEN;

    @OneToMany(mappedBy = "incident", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @Builder.Default
    private List<IncidentEvidence> evidenceList = new ArrayList<>();

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    // =========================================================================
    // MEMBER 3 ADMIN MODERATION FIELDS (Reserved for Member 3's write-side):
    // Member 1 (Farmer Module) code only reads or leaves these null.
    // Member 3 owns the investigation and resolution lifecycle transitions.
    // =========================================================================
    @Column(name = "admin_notes", columnDefinition = "TEXT")
    private String adminNotes;

    @Column(name = "investigation_notes", columnDefinition = "TEXT")
    private String investigationNotes;

    @Column(name = "resolved_by_admin_id")
    private UUID resolvedByAdminId;

    @Column(name = "resolution_outcome", length = 100)
    private String resolutionOutcome;

    @Column(name = "refund_amount", precision = 12, scale = 2)
    private BigDecimal refundAmount;

    @Column(name = "resolved_at")
    private Instant resolvedAt;

    public void addEvidence(IncidentEvidence evidence) {
        if (this.evidenceList == null) {
            this.evidenceList = new ArrayList<>();
        }
        this.evidenceList.add(evidence);
        evidence.setIncident(this);
    }
}
