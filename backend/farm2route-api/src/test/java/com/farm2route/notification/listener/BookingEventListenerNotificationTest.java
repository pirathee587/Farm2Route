package com.farm2route.notification.listener;

import com.farm2route.booking.repository.BookingRepository;
import com.farm2route.common.event.BookingCreatedEvent;
import com.farm2route.common.event.IdempotentConsumerHelper;
import com.farm2route.notification.service.NotificationService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.UUID;

import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class BookingEventListenerNotificationTest {
    @Mock IdempotentConsumerHelper helper;
    @Mock NotificationService notificationService;
    @Mock BookingRepository bookingRepository;

    @Test
    void bookingCreatedPersistsAgencyNotification() {
        UUID agencyId = UUID.randomUUID();
        BookingCreatedEvent event = BookingCreatedEvent.builder().bookingId(UUID.randomUUID())
                .bookingNumber("BK-1").agencyId(agencyId).build();
        when(helper.tryMarkProcessed(event.getEventId())).thenReturn(true);

        new BookingEventListener(helper, notificationService, bookingRepository).handleBookingCreated(event);

        verify(notificationService).createForAgency(eq(agencyId), any(), eq("New booking received"),
                anyString(), eq("BOOKING"), eq(event.getBookingId()));
    }

    @Test
    void duplicateDeliveryDoesNotPersistAgain() {
        BookingCreatedEvent event = BookingCreatedEvent.builder().bookingId(UUID.randomUUID())
                .bookingNumber("BK-1").agencyId(UUID.randomUUID()).build();
        when(helper.tryMarkProcessed(event.getEventId())).thenReturn(false);

        new BookingEventListener(helper, notificationService, bookingRepository).handleBookingCreated(event);

        verifyNoInteractions(notificationService);
    }
}
