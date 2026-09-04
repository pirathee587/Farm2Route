package com.farm2route.tracking.repository;

import com.farm2route.tracking.entity.GpsLocation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface GpsLocationRepository extends JpaRepository<GpsLocation, UUID> {

    Optional<GpsLocation> findTop1ByTripIdOrderByRecordedAtDesc(UUID tripId);

    List<GpsLocation> findByTripIdAndRecordedAtBetweenOrderByRecordedAtAsc(UUID tripId, Instant from, Instant to);

    List<GpsLocation> findByTripIdOrderByRecordedAtAsc(UUID tripId);
}
