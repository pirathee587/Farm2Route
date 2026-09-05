package com.farm2route.review.event;

import com.farm2route.common.event.EventPublisher;
import com.farm2route.common.event.ReviewModeratedEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * Relay between Spring's internal application event bus and RabbitMQ for Review Moderation events.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class ReviewModerationEventRelay {

    private final EventPublisher eventPublisher;

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onReviewModerated(ReviewModeratedEvent event) {
        log.info("[ReviewModerationEventRelay] Relaying review.moderated for reviewId={}, action={}, adminId={}",
                event.getReviewId(), event.getAction(), event.getAdminId());
        eventPublisher.publish(event);
    }
}
