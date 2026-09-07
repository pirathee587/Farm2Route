package com.farm2route.bank.event;

import com.farm2route.common.event.BankDetailsUpdatedEvent;
import com.farm2route.common.event.EventPublisher;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

@Slf4j
@Component
@RequiredArgsConstructor
public class BankDetailsEventRelay {

    private final EventPublisher eventPublisher;

    /**
     * Triggered AFTER the bank details transaction commits.
     * Publishes BankDetailsUpdatedEvent to RabbitMQ routing key "bank.details.updated".
     */
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onBankDetailsUpdated(BankDetailsUpdatedEvent event) {
        log.info("[BankDetailsEventRelay] Relaying bank.details.updated for farmerId={}, bankDetailsId={}",
                event.getFarmerId(), event.getBankDetailsId());
        eventPublisher.publish(event);
    }
}
