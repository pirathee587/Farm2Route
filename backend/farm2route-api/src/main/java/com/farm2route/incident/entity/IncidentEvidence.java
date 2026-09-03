package com.farm2route.incident.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "incident_evidence", indexes = {
        @Index(name = "idx_evidence_incident", columnList = "incident_id")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class IncidentEvidence {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "incident_id", nullable = false)
    private IncidentReport incident;

    @Column(name = "file_url", nullable = false, length = 500)
    private String fileUrl;

    @Column(name = "photo_url", length = 500)
    private String photoUrl;

    @Column(name = "file_type", length = 50)
    @Builder.Default
    private String fileType = "IMAGE";

    @Column(name = "caption", length = 255)
    private String caption;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;
}
