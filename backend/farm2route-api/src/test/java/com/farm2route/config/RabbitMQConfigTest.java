package com.farm2route.config;

import org.junit.jupiter.api.Test;
import org.springframework.amqp.core.Binding;
import org.springframework.amqp.core.DirectExchange;
import org.springframework.amqp.core.Queue;
import org.springframework.amqp.core.TopicExchange;

import static org.assertj.core.api.Assertions.assertThat;

class RabbitMQConfigTest {
    private final RabbitMQConfig config = new RabbitMQConfig();

    @Test
    void declaresDriverAssignedTopologyOnTheNotificationQueue() {
        TopicExchange exchange = config.mainExchange();
        Queue queue = config.notificationQueue();
        Binding binding = config.notificationBindingDriverAssigned(queue, exchange);

        assertThat(exchange.getName()).isEqualTo(RabbitMQConfig.EXCHANGE);
        assertThat(exchange.isDurable()).isTrue();
        assertThat(queue.getName()).isEqualTo(RabbitMQConfig.NOTIFICATION_QUEUE);
        assertThat(queue.isDurable()).isTrue();
        assertThat(binding.getExchange()).isEqualTo(RabbitMQConfig.EXCHANGE);
        assertThat(binding.getDestination()).isEqualTo(RabbitMQConfig.NOTIFICATION_QUEUE);
        assertThat(binding.getRoutingKey()).isEqualTo(RabbitMQConfig.RK_DRIVER_ASSIGNED);
    }

    @Test
    void declaresAuditWildcardAndDeadLetterTopology() {
        TopicExchange exchange = config.mainExchange();
        Queue auditQueue = config.auditQueue();
        DirectExchange dlx = config.deadLetterExchange();
        Queue notificationDlq = config.notificationDlq();

        assertThat(config.auditBindingAll(auditQueue, exchange).getRoutingKey()).isEqualTo("#");
        assertThat(config.notificationDlqBinding(notificationDlq, dlx).getExchange()).isEqualTo(RabbitMQConfig.DLX);
        assertThat(config.notificationQueue().getArguments())
                .containsEntry("x-dead-letter-exchange", RabbitMQConfig.DLX)
                .containsEntry("x-dead-letter-routing-key", RabbitMQConfig.NOTIFICATION_DLQ);
    }
}
