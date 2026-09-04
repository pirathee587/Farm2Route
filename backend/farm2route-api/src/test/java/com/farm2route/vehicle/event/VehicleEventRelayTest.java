package com.farm2route.vehicle.event;

import com.farm2route.common.enums.KycStatus;
import com.farm2route.common.event.EventPublisher;
import com.farm2route.common.event.VehicleKycUpdatedEvent;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.UUID;

import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
class VehicleEventRelayTest {

    @Mock
    private EventPublisher eventPublisher;

    @InjectMocks
    private VehicleEventRelay vehicleEventRelay;

    @Test
    @DisplayName("onVehicleKycUpdated relays event to EventPublisher")
    void testOnVehicleKycUpdated_RelaysEvent() {
        VehicleKycUpdatedEvent event = VehicleKycUpdatedEvent.builder()
                .vehicleId(UUID.randomUUID())
                .agencyId(UUID.randomUUID())
                .kycStatus(KycStatus.APPROVED)
                .build();

        vehicleEventRelay.onVehicleKycUpdated(event);

        verify(eventPublisher, times(1)).publish(event);
    }
}

