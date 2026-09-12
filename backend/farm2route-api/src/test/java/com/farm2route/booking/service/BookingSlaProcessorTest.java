package com.farm2route.booking.service;

import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.booking.entity.Booking;
import com.farm2route.booking.repository.BookingRepository;
import com.farm2route.common.enums.BookingStatus;
import com.farm2route.common.event.IdempotentConsumerHelper;
import com.farm2route.notification.service.NotificationService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.lang.reflect.Field;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class BookingSlaProcessorTest {
    @Mock BookingRepository bookingRepository;
    @Mock NotificationService notificationService;
    @Mock IdempotentConsumerHelper idempotentConsumerHelper;

    private BookingSlaProcessor processor;
    private Instant now;

    @BeforeEach
    void setUp() throws Exception {
        processor = new BookingSlaProcessor(bookingRepository, notificationService, idempotentConsumerHelper);
        Field field = BookingSlaProcessor.class.getDeclaredField("slaDuration");
        field.setAccessible(true);
        field.set(processor, Duration.ofHours(24));
        now = Instant.parse("2026-09-08T12:00:00Z");
    }

    @Test
    void expiresPendingBookingAfterResponseWindowAndNotifiesAgency() {
        UUID id = UUID.randomUUID();
        AgencyProfile agency = AgencyProfile.builder().id(UUID.randomUUID()).build();
        Booking booking = Booking.builder().id(id).bookingNumber("B-100")
                .agency(agency).status(BookingStatus.PENDING)
                .createdAt(now.minus(Duration.ofHours(25))).build();
        when(bookingRepository.findByStatusAndCreatedAtBefore(eq(BookingStatus.PENDING), any()))
                .thenReturn(List.of(booking));
        when(bookingRepository.findByIdForUpdate(id)).thenReturn(Optional.of(booking));
        when(idempotentConsumerHelper.tryMarkProcessed(any())).thenReturn(true);

        int expired = processor.processExpiredBookings(now);

        assertThat(expired).isEqualTo(1);
        assertThat(booking.getStatus()).isEqualTo(BookingStatus.REJECTED);
        assertThat(booking.getCancellationReason()).contains("expired");
        verify(notificationService).createForAgency(eq(agency.getId()), any(), eq("Booking request expired"),
                contains("B-100"), eq("BOOKING"), eq(id));
    }

    @Test
    void doesNotExpireBookingStillWithinWindow() {
        Booking booking = Booking.builder().id(UUID.randomUUID()).status(BookingStatus.PENDING)
                .createdAt(now.minus(Duration.ofHours(23))).build();
        when(bookingRepository.findByStatusAndCreatedAtBefore(eq(BookingStatus.PENDING), any()))
                .thenReturn(List.of(booking));

        assertThat(processor.processExpiredBookings(now)).isZero();
        assertThat(booking.getStatus()).isEqualTo(BookingStatus.PENDING);
        verify(bookingRepository).findByIdForUpdate(booking.getId());
        verifyNoInteractions(notificationService);
    }

    @Test
    void rechecksLockedBookingStatusBeforeChangingIt() {
        Booking candidate = Booking.builder().id(UUID.randomUUID()).status(BookingStatus.PENDING)
                .createdAt(now.minus(Duration.ofHours(25))).build();
        Booking accepted = Booking.builder().id(candidate.getId()).status(BookingStatus.ACCEPTED)
                .createdAt(candidate.getCreatedAt()).build();
        when(bookingRepository.findByStatusAndCreatedAtBefore(eq(BookingStatus.PENDING), any()))
                .thenReturn(List.of(candidate));
        when(bookingRepository.findByIdForUpdate(candidate.getId())).thenReturn(Optional.of(accepted));

        assertThat(processor.processExpiredBookings(now)).isZero();
        verify(bookingRepository, never()).save(any());
        verifyNoInteractions(notificationService);
    }

    @Test
    void doesNotDuplicateNotificationWhenIdempotencyClaimIsLost() {
        AgencyProfile agency = AgencyProfile.builder().id(UUID.randomUUID()).build();
        Booking booking = Booking.builder().id(UUID.randomUUID()).bookingNumber("B-101")
                .agency(agency).status(BookingStatus.PENDING)
                .createdAt(now.minus(Duration.ofHours(25))).build();
        when(bookingRepository.findByStatusAndCreatedAtBefore(eq(BookingStatus.PENDING), any()))
                .thenReturn(List.of(booking));
        when(bookingRepository.findByIdForUpdate(booking.getId())).thenReturn(Optional.of(booking));
        when(idempotentConsumerHelper.tryMarkProcessed(any())).thenReturn(false);

        assertThat(processor.processExpiredBookings(now)).isEqualTo(1);
        verify(notificationService, never()).createForAgency(any(), any(), any(), any(), any(), any());
    }
}
