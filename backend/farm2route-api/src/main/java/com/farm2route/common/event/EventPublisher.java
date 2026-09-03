package com.farm2route.common.event;

import com.farm2route.config.RabbitMQConfig;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.stereotype.Component;

/**
 * Thin wrapper around RabbitTemplate for publishing domain events.
 *
 * All events are published to the single shared topic exchange (farm2route.events).
 * The event's eventType field is used as the routing key and must match a value
 * defined in RabbitMQConfig routing key constants and documented in EVENTS.md.
 *
 * IMPORTANT — MVP Limitation:
 * Publishing failures (RabbitMQ down, network blip) are logged but do NOT
 * propagate back to the caller. This means an event can be permanently lost
 * if the broker is unavailable at publish time. This is acceptable for the
 * current student project MVP. Future: replace with Transactional Outbox Pattern.
 *
 * This class is called from @TransactionalEventListener(AFTER_COMMIT) relays,
 * so it always runs outside any active DB transaction.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class EventPublisher {

    private final RabbitTemplate rabbitTemplate;

    /**
     * Publishes a domain event to the shared topic exchange.
     * Uses event.getEventType() as the routing key.
     *
     * @param event the domain event to publish (must not be null)
     */
    public void publish(DomainEvent event) {
        try {
            rabbitTemplate.convertAndSend(
                    RabbitMQConfig.EXCHANGE,
                    event.getEventType(),
                    event
            );
            log.debug("[EventPublisher] Published event type={} id={} routingKey={}",
                    event.getEventType(), event.getEventId(), event.getEventType());
        } catch (Exception ex) {
            // MVP: log and continue — event is lost if broker is unavailable.
            // TODO (future): write to outbox_events table instead of losing the event.
            log.error("[EventPublisher] FAILED to publish event type={} id={}: {}",
                    event.getEventType(), event.getEventId(), ex.getMessage(), ex);
        }
    }
}
