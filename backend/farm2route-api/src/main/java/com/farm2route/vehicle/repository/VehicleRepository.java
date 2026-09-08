package com.farm2route.vehicle.repository;

import com.farm2route.common.enums.KycStatus;
import com.farm2route.common.enums.VehicleStatus;
import com.farm2route.common.enums.VehicleType;
import com.farm2route.vehicle.entity.Vehicle;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import jakarta.persistence.LockModeType;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface VehicleRepository extends JpaRepository<Vehicle, UUID> {
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select v from Vehicle v where v.id = :id")
    Optional<Vehicle> findByIdForUpdate(@Param("id") UUID id);

    long countByKycStatus(KycStatus status);
    List<Vehicle> findByAgencyId(UUID agencyId);
    List<Vehicle> findByStatusAndKycStatusAndCapacityGreaterThanEqual(VehicleStatus status, KycStatus kycStatus, BigDecimal capacity);
    Optional<Vehicle> findByIdAndAgencyId(UUID id, UUID agencyId);
    Optional<Vehicle> findByRegistrationNumber(String registrationNumber);
    long countByAgencyId(UUID agencyId);
    long countByAgencyIdAndKycStatus(UUID agencyId, KycStatus kycStatus);
    long countByAgencyIdAndStatus(UUID agencyId, VehicleStatus status);
    boolean existsByRegistrationNumber(String registrationNumber);
    boolean existsByRegistrationNumberAndIdNot(String registrationNumber, UUID id);
}
