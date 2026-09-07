package com.farm2route.common.event;

import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.UUID;

/**
 * Fired after farmer bank details are successfully created or updated (AFTER_COMMIT).
 * Relayed to audit.queue.
 * Contains ONLY safe metadata (NO full account number).
 */
@Getter
@NoArgsConstructor
public class BankDetailsUpdatedEvent extends DomainEvent {

    public static final String ROUTING_KEY = "bank.details.updated";

    private UUID farmerId;
    private UUID bankDetailsId;
    private String bankName;
    private String maskedAccountNumber;

    @Builder
    public BankDetailsUpdatedEvent(UUID farmerId, UUID bankDetailsId, String bankName, String maskedAccountNumber) {
        super(ROUTING_KEY);
        this.farmerId = farmerId;
        this.bankDetailsId = bankDetailsId;
        this.bankName = bankName;
        this.maskedAccountNumber = maskedAccountNumber;
    }
}
