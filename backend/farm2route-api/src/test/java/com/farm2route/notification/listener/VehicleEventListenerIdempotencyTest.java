package com.farm2route.notification.listener;

import com.farm2route.common.enums.KycStatus;
import com.farm2route.common.event.IdempotentConsumerHelper;
import com.farm2route.common.event.VehicleKycUpdatedEvent;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.UUID;

import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class VehicleEventListenerIdempotencyTest {

    @Mock
    private IdempotentConsumerHelper idempotentConsumerHelper;

    @InjectMocks
    private BookingEventListener bookingEventListener;

    @Test
    @DisplayName("BookingEventListener: processes vehicle.kyc_updated on first delivery, skips on redelivery")
    void testVehicleKycUpdated_Idempotency() {
        VehicleKycUpdatedEvent event = VehicleKycUpdatedEvent.builder()
                .vehicleId(UUID.randomUUID())
                .agencyId(UUID.randomUUID())
                .kycStatus(KycStatus.APPROVED)
                .build();

        // First delivery attempt: tryMarkProcessed returns true
        when(idempotentConsumerHelper.tryMarkProcessed(event.getEventId())).thenReturn(true);
        bookingEventListener.handleVehicleKycUpdated(event);

        // Redelivery attempt (duplicate eventId): tryMarkProcessed returns false
        when(idempotentConsumerHelper.tryMarkProcessed(event.getEventId())).thenReturn(false);
        bookingEventListener.handleVehicleKycUpdated(event);

        // Verify helper was called twice, second call returned false and skipped execution
        verify(idempotentConsumerHelper, times(2)).tryMarkProcessed(event.getEventId());
    }
}

