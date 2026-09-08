package com.farm2route.agency.repository;

import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.common.enums.KycStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import jakarta.persistence.LockModeType;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface AgencyProfileRepository extends JpaRepository<AgencyProfile, UUID> {

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select a from AgencyProfile a where a.id = :id")
    Optional<AgencyProfile> findByIdForUpdate(@Param("id") UUID id);
    Optional<AgencyProfile> findByUserId(UUID userId);
    Optional<AgencyProfile> findByBusinessRegistrationNumber(String businessRegistrationNumber);
    long countByKycStatusIn(List<KycStatus> statuses);
}
