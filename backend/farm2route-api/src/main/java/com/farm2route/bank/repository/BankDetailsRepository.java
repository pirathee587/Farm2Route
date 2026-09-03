package com.farm2route.bank.repository;

import com.farm2route.bank.entity.BankDetails;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface BankDetailsRepository extends JpaRepository<BankDetails, UUID> {

    Optional<BankDetails> findByFarmerId(UUID farmerId);

    boolean existsByFarmerId(UUID farmerId);

    void deleteByFarmerId(UUID farmerId);
}
