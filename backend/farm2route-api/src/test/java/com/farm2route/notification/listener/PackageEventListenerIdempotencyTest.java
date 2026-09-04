package com.farm2route.notification.listener;

import com.farm2route.common.enums.PackageType;
import com.farm2route.common.event.IdempotentConsumerHelper;
import com.farm2route.common.event.PackageCreatedEvent;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.UUID;

import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class PackageEventListenerIdempotencyTest {

    @Mock
    private IdempotentConsumerHelper idempotentConsumerHelper;

    @InjectMocks
    private BookingEventListener bookingEventListener;

    @Test
    @DisplayName("BookingEventListener: processes package.created on first delivery, skips on redelivery")
    void testPackageCreated_Idempotency() {
        PackageCreatedEvent event = PackageCreatedEvent.builder()
                .packageId(UUID.randomUUID())
                .agencyId(UUID.randomUUID())
                .title("Standard Vegetable Transport")
                .packageType(PackageType.WEIGHT_BASED)
                .basePrice(new BigDecimal("1500.00"))
                .build();

        // First delivery attempt: tryMarkProcessed returns true
        when(idempotentConsumerHelper.tryMarkProcessed(event.getEventId())).thenReturn(true);
        bookingEventListener.handlePackageCreated(event);

        // Redelivery attempt (duplicate eventId): tryMarkProcessed returns false
        when(idempotentConsumerHelper.tryMarkProcessed(event.getEventId())).thenReturn(false);
        bookingEventListener.handlePackageCreated(event);

        // Verify helper was called twice, second call returned false and skipped execution
        verify(idempotentConsumerHelper, times(2)).tryMarkProcessed(event.getEventId());
    }
}
