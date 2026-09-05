package com.farm2route.admin.event;

import com.farm2route.common.event.EventPublisher;
import com.farm2route.common.event.KycReviewedEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * Relay between Spring's internal application event bus and RabbitMQ for Admin KYC events.
 * Listens for KycReviewedEvent AFTER_COMMIT and relays it to RabbitMQ.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class AdminKycEventRelay {

    private final EventPublisher eventPublisher;

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onKycReviewed(KycReviewedEvent event) {
        log.info("[AdminKycEventRelay] Relaying kyc.reviewed for entityType={} entityId={}", event.getEntityType(), event.getEntityId());
        eventPublisher.publish(event);
    }
}
