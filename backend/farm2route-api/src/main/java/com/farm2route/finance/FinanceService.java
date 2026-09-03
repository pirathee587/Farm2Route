package com.farm2route.finance;

import java.math.BigDecimal;
import java.util.UUID;

public interface FinanceService {

    RefundResult refund(UUID bookingId, UUID farmerId, UUID agencyId, BigDecimal amount,
                        UUID adminId, String reason);

    enum RefundStatus {
        ACCEPTED_PENDING_PROCESSING
    }

    record RefundResult(UUID bookingId, BigDecimal amount, RefundStatus status) {
    }
}