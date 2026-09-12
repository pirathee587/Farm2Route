package com.farm2route.agency.repository;

import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.common.enums.KycStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface AgencyProfileRepository extends JpaRepository<AgencyProfile, UUID> {
    Optional<AgencyProfile> findByUserId(UUID userId);
    Optional<AgencyProfile> findByBusinessRegistrationNumber(String businessRegistrationNumber);
    long countByKycStatusIn(List<KycStatus> statuses);
    Page<AgencyProfile> findByKycStatusIn(List<KycStatus> statuses, Pageable pageable);
}
