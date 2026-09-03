package com.farm2route.finance;

import com.farm2route.common.exception.BadRequestException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.UUID;

@Service
@Slf4j
public class LoggingFinanceService implements FinanceService {

    @Override
    public RefundResult refund(UUID bookingId, UUID farmerId, UUID agencyId, BigDecimal amount,
                               UUID adminId, String reason) {
        if (amount == null || amount.signum() <= 0) {
            throw new BadRequestException("Refund amount must be positive");
        }

        // Placeholder until the full finance and payment persistence workflow is implemented.
        log.info("Refund accepted pending processing: bookingId={}, farmerId={}, agencyId={}, amount={}, adminId={}, reason={}",
                bookingId, farmerId, agencyId, amount, adminId, reason);
        return new RefundResult(bookingId, amount, RefundStatus.ACCEPTED_PENDING_PROCESSING);
    }
}