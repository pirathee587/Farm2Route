package com.farm2route.review.repository;

import com.farm2route.review.entity.Review;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ReviewRepository extends JpaRepository<Review, UUID> {
    Optional<Review> findByBookingId(UUID bookingId);
    boolean existsByBookingId(UUID bookingId);
    List<Review> findByFarmerId(UUID farmerId);
    List<Review> findByAgencyId(UUID agencyId);
    List<Review> findByDriverId(UUID driverId);
}
