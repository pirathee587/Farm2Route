package com.farm2route.booking.repository;

import com.farm2route.booking.entity.Booking;
import com.farm2route.common.enums.BookingStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import jakarta.persistence.LockModeType;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.time.Instant;

@Repository
public interface BookingRepository extends JpaRepository<Booking, UUID> {
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select b from Booking b where b.id = :id")
    Optional<Booking> findByIdForUpdate(@Param("id") UUID id);

    Optional<Booking> findByBookingNumber(String bookingNumber);
    List<Booking> findByFarmerId(UUID farmerId);
    List<Booking> findByAgencyId(UUID agencyId);
    List<Booking> findByDriverId(UUID driverId);
    List<Booking> findByStatus(BookingStatus status);
    long countByAgencyId(UUID agencyId);
    long countByAgencyIdAndStatus(UUID agencyId, BookingStatus status);
    List<Booking> findByStatusAndCreatedAtBefore(BookingStatus status, Instant deadline);
    long countByStatusNotIn(List<BookingStatus> statuses);
}
