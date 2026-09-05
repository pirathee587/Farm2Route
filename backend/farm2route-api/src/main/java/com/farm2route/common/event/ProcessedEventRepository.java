package com.farm2route.common.event;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

/**
 * Repository for the processed_events idempotency table.
 * Only needs saveAndFlush — no query methods required for the INSERT-first pattern.
 */
@Repository
public interface ProcessedEventRepository extends JpaRepository<ProcessedEvent, ProcessedEventId> {
}
