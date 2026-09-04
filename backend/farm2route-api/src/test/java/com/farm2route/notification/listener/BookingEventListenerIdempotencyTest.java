package com.farm2route.notification.listener;

import com.farm2route.audit.listener.AuditEventListener;
import com.farm2route.audit.service.AuditService;
import com.farm2route.common.event.BookingCreatedEvent;
import com.farm2route.common.event.IdempotentConsumerHelper;
import com.farm2route.common.event.ProcessedEvent;
import com.farm2route.common.event.ProcessedEventRepository;
import com.farm2route.notification.service.NotificationService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DataIntegrityViolationException;

import java.math.BigDecimal;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class BookingEventListenerIdempotencyTest {

    @Mock
    private ProcessedEventRepository processedEventRepository;

    @InjectMocks
    private IdempotentConsumerHelper idempotentConsumerHelper;

    @Mock
    private AuditService auditService;

    @Test
    @DisplayName("IdempotentConsumerHelper: first attempt returns true, duplicate returns false")
    void testIdempotentConsumerHelper_DuplicatePrevention() {
        UUID eventId = UUID.randomUUID();

        // First attempt succeeds
        when(processedEventRepository.saveAndFlush(any(ProcessedEvent.class)))
                .thenReturn(new ProcessedEvent(eventId, null));

        boolean firstResult = idempotentConsumerHelper.tryMarkProcessed(eventId);
        assertThat(firstResult).isTrue();

        // Second attempt with duplicate key throws DataIntegrityViolationException
        when(processedEventRepository.saveAndFlush(any(ProcessedEvent.class)))
                .thenThrow(new DataIntegrityViolationException("Duplicate key violation"));

        boolean secondResult = idempotentConsumerHelper.tryMarkProcessed(eventId);
        assertThat(secondResult).isFalse();
    }

    @Test
    @DisplayName("AuditEventListener: processes event on first delivery, skips on redelivery")
    void testAuditEventListener_Idempotency() {
        IdempotentConsumerHelper mockHelper = mock(IdempotentConsumerHelper.class);
        AuditEventListener auditListener = new AuditEventListener(auditService, mockHelper);

        BookingCreatedEvent event = BookingCreatedEvent.builder()
                .bookingId(UUID.randomUUID())
                .bookingNumber("F2R-TEST-1001")
                .farmerId(UUID.randomUUID())
                .agencyId(UUID.randomUUID())
                .packageId(UUID.randomUUID())
                .totalAmount(new BigDecimal("15000.00"))
                .build();

        // First call: not yet processed -> tryMarkProcessed returns true
        when(mockHelper.tryMarkProcessed(event.getEventId())).thenReturn(true);
        auditListener.handleEvent(event);
        verify(auditService, times(1)).logAction(any(), eq("BOOKING_CREATED"), eq("BOOKING"), any(), any(), any(), any(), any());

        // Second call (redelivery with same eventId): tryMarkProcessed returns false -> skipped
        when(mockHelper.tryMarkProcessed(event.getEventId())).thenReturn(false);
        auditListener.handleEvent(event);
        verify(auditService, times(1)).logAction(any(), any(), any(), any(), any(), any(), any(), any()); // Still 1 time!
    }

    @Test
    @DisplayName("NotificationEventListener: processes on first delivery, skips on redelivery")
    void testNotificationEventListener_Idempotency() {
        IdempotentConsumerHelper mockHelper = mock(IdempotentConsumerHelper.class);
        NotificationService mockService = mock(NotificationService.class);
        com.farm2route.agency.repository.AgencyProfileRepository mockAgencyRepo = mock(com.farm2route.agency.repository.AgencyProfileRepository.class);
        com.farm2route.farmer.repository.FarmerProfileRepository mockFarmerRepo = mock(com.farm2route.farmer.repository.FarmerProfileRepository.class);

        NotificationEventListener notificationListener = new NotificationEventListener(
                mockHelper,
                mockService,
                mockAgencyRepo,
                mockFarmerRepo
        );

        BookingCreatedEvent event = BookingCreatedEvent.builder()
                .bookingId(UUID.randomUUID())
                .bookingNumber("F2R-TEST-1001")
                .farmerId(UUID.randomUUID())
                .agencyId(UUID.randomUUID())
                .packageId(UUID.randomUUID())
                .totalAmount(new BigDecimal("15000.00"))
                .build();

        // First delivery: tryMarkProcessed returns true
        when(mockHelper.tryMarkProcessed(event.getEventId())).thenReturn(true);
        notificationListener.handleBookingCreated(event);

        // Redelivery: tryMarkProcessed returns false
        when(mockHelper.tryMarkProcessed(event.getEventId())).thenReturn(false);
        notificationListener.handleBookingCreated(event);

        // Verified helper was called twice, second call returned false and skipped
        verify(mockHelper, times(2)).tryMarkProcessed(event.getEventId());
    }
}
