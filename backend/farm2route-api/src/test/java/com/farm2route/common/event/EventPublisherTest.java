package com.farm2route.common.event;

import com.farm2route.config.RabbitMQConfig;
import org.junit.jupiter.api.Test;
import org.springframework.amqp.rabbit.core.RabbitTemplate;

import java.util.UUID;

import static org.mockito.Mockito.*;

class EventPublisherTest {
    @Test
    void publishesUsingSharedExchangeAndEventTypeRoutingKey() {
        RabbitTemplate rabbitTemplate = mock(RabbitTemplate.class);
        EventPublisher publisher = new EventPublisher(rabbitTemplate);
        DriverAssignedEvent event = DriverAssignedEvent.builder()
                .assignmentId(UUID.randomUUID()).bookingId(UUID.randomUUID())
                .driverId(UUID.randomUUID()).vehicleId(UUID.randomUUID()).build();

        publisher.publish(event);

        verify(rabbitTemplate).convertAndSend(RabbitMQConfig.EXCHANGE, "driver.assigned", event);
        verifyNoMoreInteractions(rabbitTemplate);
    }

    @Test
    void brokerFailureDoesNotChangeCommittedBusinessResult() {
        RabbitTemplate rabbitTemplate = mock(RabbitTemplate.class);
        doThrow(new IllegalStateException("broker unavailable"))
                .when(rabbitTemplate).convertAndSend(anyString(), anyString(), (Object) any(DriverAssignedEvent.class));

        new EventPublisher(rabbitTemplate).publish(DriverAssignedEvent.builder()
                .assignmentId(UUID.randomUUID()).bookingId(UUID.randomUUID())
                .driverId(UUID.randomUUID()).vehicleId(UUID.randomUUID()).build());

        verify(rabbitTemplate).convertAndSend(anyString(), eq("driver.assigned"), any(DriverAssignedEvent.class));
    }
}
