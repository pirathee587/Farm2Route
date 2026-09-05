package com.farm2route.vehicle.repository;

import com.farm2route.common.enums.KycStatus;
import com.farm2route.common.enums.VehicleStatus;
import com.farm2route.common.enums.VehicleType;
import com.farm2route.vehicle.entity.Vehicle;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface VehicleRepository extends JpaRepository<Vehicle, UUID> {
    long countByKycStatus(KycStatus status);
    long countByKycStatusIn(List<KycStatus> statuses);
    List<Vehicle> findByAgencyId(UUID agencyId);
    List<Vehicle> findByStatusAndKycStatusAndCapacityGreaterThanEqual(VehicleStatus status, KycStatus kycStatus, BigDecimal capacity);
    Optional<Vehicle> findByIdAndAgencyId(UUID id, UUID agencyId);
    Optional<Vehicle> findByRegistrationNumber(String registrationNumber);
    boolean existsByRegistrationNumber(String registrationNumber);
    boolean existsByRegistrationNumberAndIdNot(String registrationNumber, UUID id);
}