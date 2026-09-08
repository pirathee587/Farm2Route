package com.farm2route.trip.repository;

import com.farm2route.trip.entity.TripAssignment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import com.farm2route.common.enums.TripStatus;

@Repository
public interface TripAssignmentRepository extends JpaRepository<TripAssignment, UUID> {
    Optional<TripAssignment> findByBookingId(UUID bookingId);
    boolean existsByDriverIdAndStatusIn(UUID driverId, List<String> statuses);
    boolean existsByVehicleIdAndStatusIn(UUID vehicleId, List<String> statuses);
    long countByBookingAgencyId(UUID agencyId);
    long countByBookingAgencyIdAndStatus(UUID agencyId, TripStatus status);
}
