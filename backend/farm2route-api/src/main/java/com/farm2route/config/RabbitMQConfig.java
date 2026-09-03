package com.farm2route.config;

import org.springframework.amqp.core.*;
import org.springframework.amqp.rabbit.config.SimpleRabbitListenerContainerFactory;
import org.springframework.amqp.rabbit.connection.ConnectionFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.HashMap;
import java.util.Map;

/**
 * RabbitMQ topology configuration for Farm2Route.
 *
 * Exchange topology:
 *   farm2route.events  (topic) ─── main exchange, all publishers send here
 *   farm2route.dlx     (direct) ── dead letter exchange, receives poison messages after retry exhaustion
 *
 * Queue topology:
 *   notification.queue     ← booking.created | booking.cancelled | incident.submitted | pod.confirmed | review.submitted
 *   audit.queue            ← # (all events)
 *   notification.queue.dlq ← farm2route.dlx routing key "notification.queue.dlq"
 *   audit.queue.dlq        ← farm2route.dlx routing key "audit.queue.dlq"
 *
 * CRITICAL: default-requeue-rejected=false is set in application.yml.
 * Without it, a rejected message goes back to the original queue and loops forever,
 * never reaching the DLQ.
 */
@Configuration
public class RabbitMQConfig {

    // ─────────────────────────────────────────────────────────────────────────
    // Exchange names
    // ─────────────────────────────────────────────────────────────────────────

    public static final String EXCHANGE = "farm2route.events";
    public static final String DLX      = "farm2route.dlx";

    // ─────────────────────────────────────────────────────────────────────────
    // Queue names
    // ─────────────────────────────────────────────────────────────────────────

    public static final String NOTIFICATION_QUEUE     = "notification.queue";
    public static final String AUDIT_QUEUE            = "audit.queue";
    public static final String NOTIFICATION_DLQ       = "notification.queue.dlq";
    public static final String AUDIT_DLQ              = "audit.queue.dlq";

    // ─────────────────────────────────────────────────────────────────────────
    // Routing keys  (matches EVENTS.md)
    // ─────────────────────────────────────────────────────────────────────────

    public static final String RK_BOOKING_CREATED     = "booking.created";
    public static final String RK_BOOKING_CANCELLED   = "booking.cancelled";
    public static final String RK_INCIDENT_SUBMITTED  = "incident.submitted";
    public static final String RK_POD_CONFIRMED       = "pod.confirmed";
    public static final String RK_REVIEW_SUBMITTED    = "review.submitted";

    // ─────────────────────────────────────────────────────────────────────────
    // Exchanges
    // ─────────────────────────────────────────────────────────────────────────

    @Bean
    public TopicExchange mainExchange() {
        return ExchangeBuilder.topicExchange(EXCHANGE).durable(true).build();
    }

    /** Dead Letter Exchange — direct type so routing key == queue name. */
    @Bean
    public DirectExchange deadLetterExchange() {
        return ExchangeBuilder.directExchange(DLX).durable(true).build();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Queues — each declares x-dead-letter-exchange and x-dead-letter-routing-key
    // so RabbitMQ automatically routes exhausted messages to the DLQ.
    // ─────────────────────────────────────────────────────────────────────────

    @Bean
    public Queue notificationQueue() {
        Map<String, Object> args = new HashMap<>();
        args.put("x-dead-letter-exchange", DLX);
        args.put("x-dead-letter-routing-key", NOTIFICATION_DLQ);
        return QueueBuilder.durable(NOTIFICATION_QUEUE).withArguments(args).build();
    }

    @Bean
    public Queue auditQueue() {
        Map<String, Object> args = new HashMap<>();
        args.put("x-dead-letter-exchange", DLX);
        args.put("x-dead-letter-routing-key", AUDIT_DLQ);
        return QueueBuilder.durable(AUDIT_QUEUE).withArguments(args).build();
    }

    @Bean
    public Queue notificationDlq() {
        return QueueBuilder.durable(NOTIFICATION_DLQ).build();
    }

    @Bean
    public Queue auditDlq() {
        return QueueBuilder.durable(AUDIT_DLQ).build();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Bindings — notification.queue listens for specific routing keys
    // ─────────────────────────────────────────────────────────────────────────

    @Bean
    public Binding notificationBindingBookingCreated(Queue notificationQueue, TopicExchange mainExchange) {
        return BindingBuilder.bind(notificationQueue).to(mainExchange).with(RK_BOOKING_CREATED);
    }

    @Bean
    public Binding notificationBindingBookingCancelled(Queue notificationQueue, TopicExchange mainExchange) {
        return BindingBuilder.bind(notificationQueue).to(mainExchange).with(RK_BOOKING_CANCELLED);
    }

    @Bean
    public Binding notificationBindingIncidentSubmitted(Queue notificationQueue, TopicExchange mainExchange) {
        return BindingBuilder.bind(notificationQueue).to(mainExchange).with(RK_INCIDENT_SUBMITTED);
    }

    @Bean
    public Binding notificationBindingPodConfirmed(Queue notificationQueue, TopicExchange mainExchange) {
        return BindingBuilder.bind(notificationQueue).to(mainExchange).with(RK_POD_CONFIRMED);
    }

    @Bean
    public Binding notificationBindingReviewSubmitted(Queue notificationQueue, TopicExchange mainExchange) {
        return BindingBuilder.bind(notificationQueue).to(mainExchange).with(RK_REVIEW_SUBMITTED);
    }

    // audit.queue uses wildcard "#" — receives every event regardless of routing key
    @Bean
    public Binding auditBindingAll(Queue auditQueue, TopicExchange mainExchange) {
        return BindingBuilder.bind(auditQueue).to(mainExchange).with("#");
    }

    // DLQ bindings — bound to DLX (direct exchange), routing key == queue name
    @Bean
    public Binding notificationDlqBinding(Queue notificationDlq, DirectExchange deadLetterExchange) {
        return BindingBuilder.bind(notificationDlq).to(deadLetterExchange).with(NOTIFICATION_DLQ);
    }

    @Bean
    public Binding auditDlqBinding(Queue auditDlq, DirectExchange deadLetterExchange) {
        return BindingBuilder.bind(auditDlq).to(deadLetterExchange).with(AUDIT_DLQ);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Message conversion — all messages serialized as JSON
    // ─────────────────────────────────────────────────────────────────────────

    @Bean
    public MessageConverter jacksonMessageConverter() {
        return new Jackson2JsonMessageConverter();
    }

    @Bean
    public RabbitTemplate rabbitTemplate(ConnectionFactory connectionFactory) {
        RabbitTemplate template = new RabbitTemplate(connectionFactory);
        template.setMessageConverter(jacksonMessageConverter());
        return template;
    }

    @Bean
    public SimpleRabbitListenerContainerFactory rabbitListenerContainerFactory(
            org.springframework.boot.autoconfigure.amqp.SimpleRabbitListenerContainerFactoryConfigurer configurer,
            ConnectionFactory connectionFactory) {
        SimpleRabbitListenerContainerFactory factory = new SimpleRabbitListenerContainerFactory();
        configurer.configure(factory, connectionFactory);
        factory.setMessageConverter(jacksonMessageConverter());
        return factory;
    }
}
