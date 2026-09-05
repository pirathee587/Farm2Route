package com.farm2route.pod.repository;

import com.farm2route.pod.entity.PodRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface PodRecordRepository extends JpaRepository<PodRecord, UUID> {

    Optional<PodRecord> findByBookingId(UUID bookingId);

    boolean existsByBookingId(UUID bookingId);
}
