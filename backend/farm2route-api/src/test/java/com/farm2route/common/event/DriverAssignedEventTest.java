package com.farm2route.common.event;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class DriverAssignedEventTest {
    private final ObjectMapper objectMapper = new ObjectMapper().findAndRegisterModules();

    @Test
    void roundTripsAllIdentifiersAndEventMetadataAsJson() throws Exception {
        DriverAssignedEvent source = DriverAssignedEvent.builder()
                .assignmentId(UUID.randomUUID())
                .bookingId(UUID.randomUUID())
                .driverId(UUID.randomUUID())
                .vehicleId(UUID.randomUUID())
                .build();

        String json = objectMapper.writeValueAsString(source);
        DriverAssignedEvent restored = objectMapper.readValue(json, DriverAssignedEvent.class);

        assertThat(restored.getEventId()).isEqualTo(source.getEventId());
        assertThat(restored.getOccurredAt()).isEqualTo(source.getOccurredAt());
        assertThat(restored.getEventType()).isEqualTo("driver.assigned");
        assertThat(restored.getAssignmentId()).isEqualTo(source.getAssignmentId());
        assertThat(restored.getBookingId()).isEqualTo(source.getBookingId());
        assertThat(restored.getDriverId()).isEqualTo(source.getDriverId());
        assertThat(restored.getVehicleId()).isEqualTo(source.getVehicleId());
    }
}
