package com.farm2route.booking.repository;

import com.farm2route.booking.entity.Booking;
import com.farm2route.common.enums.BookingStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface BookingRepository extends JpaRepository<Booking, UUID> {
    Optional<Booking> findByBookingNumber(String bookingNumber);
    List<Booking> findByFarmerId(UUID farmerId);
    List<Booking> findByAgencyId(UUID agencyId);
    List<Booking> findByDriverId(UUID driverId);
    List<Booking> findByStatus(BookingStatus status);
    long countByStatusNotIn(List<BookingStatus> statuses);
}
