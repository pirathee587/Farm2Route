package com.farm2route.farmer.repository;

import com.farm2route.farmer.entity.Farmer;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface FarmerRepository extends JpaRepository<Farmer, UUID> {

    boolean existsByPhoneNumber(String phoneNumber);

    Optional<Farmer> findByPhoneNumber(String phoneNumber);

    boolean existsByNicNumber(String nicNumber);

    Optional<Farmer> findByNicNumber(String nicNumber);
}
