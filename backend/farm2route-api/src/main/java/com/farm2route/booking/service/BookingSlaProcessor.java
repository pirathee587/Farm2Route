package com.farm2route.booking.service;

import com.farm2route.booking.entity.Booking;
import com.farm2route.booking.repository.BookingRepository;
import com.farm2route.common.enums.BookingStatus;
import com.farm2route.common.enums.NotificationType;
import com.farm2route.common.event.IdempotentConsumerHelper;
import com.farm2route.notification.service.NotificationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class BookingSlaProcessor {
    private final BookingRepository bookingRepository;
    private final NotificationService notificationService;
    private final IdempotentConsumerHelper idempotentConsumerHelper;

    @Value("${farm2route.booking.sla-duration:PT24H}")
    private Duration slaDuration;

    @Scheduled(
            fixedDelayString = "${farm2route.booking.sla-check-interval-ms:300000}",
            initialDelayString = "${farm2route.booking.sla-initial-delay-ms:60000}")
    public void scheduledProcess() {
        processExpiredBookings(Instant.now());
    }

    @Transactional
    public int processExpiredBookings(Instant now) {
        Instant deadline = now.minus(slaDuration);
        List<Booking> candidates = bookingRepository.findByStatusAndCreatedAtBefore(BookingStatus.PENDING, deadline);
        int expired = 0;
        for (Booking candidate : candidates) {
            Booking booking = bookingRepository.findByIdForUpdate(candidate.getId()).orElse(null);
            if (booking == null || booking.getStatus() != BookingStatus.PENDING || booking.getCreatedAt() == null
                    || booking.getCreatedAt().plus(slaDuration).isAfter(now)) continue;

            booking.setStatus(BookingStatus.REJECTED);
            booking.setCancellationReason("Booking request expired after the agency response window");
            bookingRepository.save(booking);
            UUID notificationKey = UUID.nameUUIDFromBytes(
                    ("booking-sla-expired:" + booking.getId()).getBytes(StandardCharsets.UTF_8));
            if (idempotentConsumerHelper.tryMarkProcessed(notificationKey)) {
                notificationService.createForAgency(booking.getAgency().getId(), NotificationType.BOOKING_UPDATE,
                        "Booking request expired", "Booking " + booking.getBookingNumber()
                                + " expired without an agency response.", "BOOKING", booking.getId());
            }
            expired++;
        }
        log.info("Booking SLA processing completed: candidates={}, expired={}", candidates.size(), expired);
        return expired;
    }
}
