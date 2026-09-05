package com.farm2route.tracking.repository;

import com.farm2route.tracking.entity.TripAssignment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface TripAssignmentRepository extends JpaRepository<TripAssignment, UUID> {

    Optional<TripAssignment> findByBookingId(UUID bookingId);

    Optional<TripAssignment> findByIdAndDriverId(UUID id, UUID driverId);
}
