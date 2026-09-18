package com.farm2route.incident.repository;

import com.farm2route.common.enums.IncidentStatus;
import com.farm2route.incident.entity.IncidentReport;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.farm2route.common.enums.IncidentType;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface IncidentRepository extends JpaRepository<IncidentReport, UUID> {

    Page<IncidentReport> findByReportedByUserIdOrderByCreatedAtDesc(UUID reportedByUserId, Pageable pageable);

    Page<IncidentReport> findByReportedByUserIdAndStatusOrderByCreatedAtDesc(UUID reportedByUserId, IncidentStatus status, Pageable pageable);

    Optional<IncidentReport> findByIdAndReportedByUserId(UUID id, UUID reportedByUserId);

    List<IncidentReport> findByBookingId(UUID bookingId);

    long countByReportedByUserIdAndStatus(UUID reportedByUserId, IncidentStatus status);
    long countByStatusIn(List<IncidentStatus> statuses);

    @Query("SELECT i FROM IncidentReport i WHERE " +
           "(cast(:status as String) IS NULL OR i.status = :status) AND " +
           "(cast(:incidentType as String) IS NULL OR i.incidentType = :incidentType) AND " +
           "(cast(:fromDate as timestamp) IS NULL OR i.createdAt >= :fromDate) AND " +
           "(cast(:toDate as timestamp) IS NULL OR i.createdAt <= :toDate) " +
           "ORDER BY i.createdAt DESC")
    Page<IncidentReport> searchAdminIncidents(
            @Param("status") IncidentStatus status,
            @Param("incidentType") IncidentType incidentType,
            @Param("fromDate") Instant fromDate,
            @Param("toDate") Instant toDate,
            Pageable pageable);
}
