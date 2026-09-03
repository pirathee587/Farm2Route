package com.farm2route.booking.event;

import com.farm2route.common.event.BookingCancelledEvent;
import com.farm2route.common.event.BookingCreatedEvent;
import com.farm2route.common.event.EventPublisher;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.UUID;

import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
class BookingEventRelayTest {

    @Mock
    private EventPublisher eventPublisher;

    @InjectMocks
    private BookingEventRelay bookingEventRelay;

    @Test
    @DisplayName("onBookingCreated relays event to EventPublisher")
    void testOnBookingCreated_RelaysEvent() {
        BookingCreatedEvent event = BookingCreatedEvent.builder()
                .bookingId(UUID.randomUUID())
                .bookingNumber("F2R-TEST-1001")
                .farmerId(UUID.randomUUID())
                .agencyId(UUID.randomUUID())
                .packageId(UUID.randomUUID())
                .totalAmount(new BigDecimal("15000.00"))
                .build();

        bookingEventRelay.onBookingCreated(event);

        verify(eventPublisher, times(1)).publish(event);
    }

    @Test
    @DisplayName("onBookingCancelled relays event to EventPublisher")
    void testOnBookingCancelled_RelaysEvent() {
        BookingCancelledEvent event = BookingCancelledEvent.builder()
                .bookingId(UUID.randomUUID())
                .bookingNumber("F2R-TEST-1001")
                .farmerId(UUID.randomUUID())
                .agencyId(UUID.randomUUID())
                .driverId(UUID.randomUUID())
                .cancellationReason("Cancelled by farmer")
                .build();

        bookingEventRelay.onBookingCancelled(event);

        verify(eventPublisher, times(1)).publish(event);
    }
}
