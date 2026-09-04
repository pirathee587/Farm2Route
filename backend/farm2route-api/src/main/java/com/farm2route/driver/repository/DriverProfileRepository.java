package com.farm2route.driver.repository;

import com.farm2route.common.enums.DriverAvailability;
import com.farm2route.driver.entity.DriverProfile;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DriverProfileRepository extends JpaRepository<DriverProfile, UUID> {
    Optional<DriverProfile> findByUserId(UUID userId);
    List<DriverProfile> findByAgencyId(UUID agencyId);
    Optional<DriverProfile> findByDrivingLicenseNumber(String drivingLicenseNumber);

    Optional<DriverProfile> findByIdAndAgencyId(UUID id, UUID agencyId);
    List<DriverProfile> findByAgencyIdAndAvailabilityStatus(UUID agencyId, DriverAvailability availabilityStatus);
    boolean existsByDrivingLicenseNumber(String drivingLicenseNumber);
    boolean existsByDrivingLicenseNumberAndIdNot(String drivingLicenseNumber, UUID id);
    boolean existsByNicNumber(String nicNumber);
    boolean existsByNicNumberAndIdNot(String nicNumber, UUID id);
}
