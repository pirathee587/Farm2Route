package com.farm2route.agency.repository;

import com.farm2route.agency.entity.AgencyProfile;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface AgencyProfileRepository extends JpaRepository<AgencyProfile, UUID> {
    Optional<AgencyProfile> findByUserId(UUID userId);
    Optional<AgencyProfile> findByBusinessRegistrationNumber(String businessRegistrationNumber);
}
