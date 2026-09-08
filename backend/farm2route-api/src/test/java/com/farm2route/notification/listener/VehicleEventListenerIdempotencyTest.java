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

    @Mock
    private com.farm2route.notification.service.NotificationService notificationService;

    @Mock
    private com.farm2route.agency.repository.AgencyProfileRepository agencyProfileRepository;

    @Mock
    private com.farm2route.farmer.repository.FarmerProfileRepository farmerProfileRepository;

    @InjectMocks
    private NotificationEventListener notificationEventListener;

    @Test
    @DisplayName("NotificationEventListener: processes vehicle.kyc_updated on first delivery, skips on redelivery")
    void testVehicleKycUpdated_Idempotency() {
        VehicleKycUpdatedEvent event = VehicleKycUpdatedEvent.builder()
                .vehicleId(UUID.randomUUID())
                .agencyId(UUID.randomUUID())
                .kycStatus(KycStatus.APPROVED)
                .build();

        // First delivery attempt: tryMarkProcessed returns true
        when(idempotentConsumerHelper.tryMarkProcessed(event.getEventId(), NotificationEventListener.CONSUMER_NAME)).thenReturn(true);
        notificationEventListener.handleVehicleKycUpdated(event);

        // Redelivery attempt (duplicate eventId): tryMarkProcessed returns false
        when(idempotentConsumerHelper.tryMarkProcessed(event.getEventId(), NotificationEventListener.CONSUMER_NAME)).thenReturn(false);
        notificationEventListener.handleVehicleKycUpdated(event);

        // Verify helper was called twice, second call returned false and skipped execution
        verify(idempotentConsumerHelper, times(2)).tryMarkProcessed(event.getEventId(), NotificationEventListener.CONSUMER_NAME);
    }
}

