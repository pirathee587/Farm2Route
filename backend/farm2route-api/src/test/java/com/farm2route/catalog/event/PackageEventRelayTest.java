package com.farm2route.catalog.event;

import com.farm2route.common.enums.PackageType;
import com.farm2route.common.event.EventPublisher;
import com.farm2route.common.event.PackageCreatedEvent;
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
class PackageEventRelayTest {

    @Mock
    private EventPublisher eventPublisher;

    @InjectMocks
    private PackageEventRelay packageEventRelay;

    @Test
    @DisplayName("onPackageCreated relays event to EventPublisher")
    void testOnPackageCreated_RelaysEvent() {
        PackageCreatedEvent event = PackageCreatedEvent.builder()
                .packageId(UUID.randomUUID())
                .agencyId(UUID.randomUUID())
                .title("Cold Storage Transport")
                .packageType(PackageType.WEIGHT_BASED)
                .basePrice(new BigDecimal("2500.00"))
                .build();

        packageEventRelay.onPackageCreated(event);

        verify(eventPublisher, times(1)).publish(event);
    }
}
