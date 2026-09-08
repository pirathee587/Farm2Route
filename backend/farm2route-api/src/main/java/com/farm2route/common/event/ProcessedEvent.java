package com.farm2route.common.event;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.UUID;

/**
 * JPA entity for the processed_events table.
 * Each row represents an (event_id, consumer_name) pair that has been successfully processed.
 * The composite PRIMARY KEY constraint is the per-consumer idempotency guard — duplicate inserts fail fast.
 */
@Entity
@Table(name = "processed_events")
@IdClass(ProcessedEventId.class)
@Getter
@NoArgsConstructor
@AllArgsConstructor
public class ProcessedEvent {

    @Id
    @Column(name = "event_id", nullable = false, updatable = false)
    private UUID eventId;

    @Id
    @Column(name = "consumer_name", length = 100, nullable = false, updatable = false)
    private String consumerName;

    @Column(name = "processed_at", nullable = false, updatable = false)
    private Instant processedAt;
}
