package com.farm2route.agency.repository;

import com.farm2route.agency.entity.Agency;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface AgencyRepository extends JpaRepository<Agency, UUID> {

    boolean existsByEmail(String email);

    boolean existsByPhoneNumber(String phoneNumber);

    boolean existsByBusinessRegNumber(String businessRegNumber);

    Optional<Agency> findByEmail(String email);

    Optional<Agency> findByPhoneNumber(String phoneNumber);

    Optional<Agency> findByBusinessRegNumber(String businessRegNumber);
}
