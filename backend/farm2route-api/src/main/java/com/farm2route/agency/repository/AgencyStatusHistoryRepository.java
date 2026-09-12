package com.farm2route.agency.repository;

import com.farm2route.agency.entity.AgencyStatusHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface AgencyStatusHistoryRepository extends JpaRepository<AgencyStatusHistory, UUID> {
    List<AgencyStatusHistory> findByAgencyIdOrderByChangedAtDesc(UUID agencyId);
}
