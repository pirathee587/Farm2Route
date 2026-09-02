package com.farm2route.farmer.repository;

import com.farm2route.farmer.entity.FarmerProfile;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface FarmerProfileRepository extends JpaRepository<FarmerProfile, UUID> {
    Optional<FarmerProfile> findByUserId(UUID userId);
}
