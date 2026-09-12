package com.farm2route.finance.repository;

import com.farm2route.finance.entity.AgencyEarning;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface AgencyEarningRepository extends JpaRepository<AgencyEarning, UUID> {
    boolean existsByBookingId(UUID bookingId);
}
