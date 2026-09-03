package com.farm2route.farmer.review.event;

import com.farm2route.common.event.EventPublisher;
import com.farm2route.common.event.ReviewSubmittedEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * Relay between Spring's internal application event bus and RabbitMQ for Review events.
 * Listens for ReviewSubmittedEvent AFTER_COMMIT and relays it to RabbitMQ.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class ReviewEventRelay {

    private final EventPublisher eventPublisher;

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onReviewSubmitted(ReviewSubmittedEvent event) {
        log.info("[ReviewEventRelay] Relaying review.submitted for reviewId={}", event.getReviewId());
        eventPublisher.publish(event);
    }
}
