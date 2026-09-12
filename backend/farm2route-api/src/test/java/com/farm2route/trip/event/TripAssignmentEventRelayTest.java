package com.farm2route.trip.event;

import com.farm2route.common.event.DriverAssignedEvent;
import com.farm2route.common.event.EventPublisher;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
class TripAssignmentEventRelayTest {
    @Mock
    private EventPublisher eventPublisher;

    @Test
    void relaysDriverAssignedEventWithoutChangingPayload() {
        TripAssignmentEventRelay relay = new TripAssignmentEventRelay(eventPublisher);
        DriverAssignedEvent event = DriverAssignedEvent.builder()
                .assignmentId(UUID.randomUUID())
                .bookingId(UUID.randomUUID())
                .driverId(UUID.randomUUID())
                .vehicleId(UUID.randomUUID())
                .build();

        relay.onDriverAssigned(event);

        ArgumentCaptor<DriverAssignedEvent> captor = ArgumentCaptor.forClass(DriverAssignedEvent.class);
        verify(eventPublisher).publish(captor.capture());
        DriverAssignedEvent published = captor.getValue();
        assertThat(published).isSameAs(event);
        assertThat(published.getEventType()).isEqualTo("driver.assigned");
        assertThat(published.getAssignmentId()).isEqualTo(event.getAssignmentId());
        assertThat(published.getBookingId()).isEqualTo(event.getBookingId());
        assertThat(published.getDriverId()).isEqualTo(event.getDriverId());
        assertThat(published.getVehicleId()).isEqualTo(event.getVehicleId());
    }

    @Test
    void relayRunsAfterCommit() throws NoSuchMethodException {
        TransactionalEventListener annotation = TripAssignmentEventRelay.class
                .getDeclaredMethod("onDriverAssigned", DriverAssignedEvent.class)
                .getAnnotation(TransactionalEventListener.class);

        assertThat(annotation).isNotNull();
        assertThat(annotation.phase()).isEqualTo(TransactionPhase.AFTER_COMMIT);
    }
}
