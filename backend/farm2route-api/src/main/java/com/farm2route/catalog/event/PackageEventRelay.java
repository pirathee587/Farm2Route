package com.farm2route.catalog.event;

import com.farm2route.common.event.EventPublisher;
import com.farm2route.common.event.PackageCreatedEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * Relay between Spring's internal application event bus and RabbitMQ for Package domain events.
 *
 * PackageService publishes a Spring ApplicationEvent. This relay receives it via
 * @TransactionalEventListener(phase = AFTER_COMMIT), guaranteeing that the message
 * is published to RabbitMQ only after the DB transaction commits.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class PackageEventRelay {

    private final EventPublisher eventPublisher;

    /**
     * Triggered AFTER the package creation transaction commits.
     * Publishes PackageCreatedEvent to RabbitMQ routing key "package.created".
     */
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onPackageCreated(PackageCreatedEvent event) {
        log.info("[PackageEventRelay] Relaying package.created for packageId={}, agencyId={}, title='{}'",
                event.getPackageId(), event.getAgencyId(), event.getTitle());
        eventPublisher.publish(event);
    }
}
