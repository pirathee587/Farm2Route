package com.farm2route.finance;

import com.farm2route.common.exception.BadRequestException;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertThrows;

class LoggingFinanceServiceTest {

    private final LoggingFinanceService financeService = new LoggingFinanceService();

    @Test
    void refundRejectsNonPositiveAmount() {
        UUID bookingId = UUID.randomUUID();

        assertThrows(BadRequestException.class, () -> financeService.refund(
                bookingId,
                UUID.randomUUID(),
                UUID.randomUUID(),
                BigDecimal.ZERO,
                UUID.randomUUID(),
                "Duplicate booking"));

        assertThrows(BadRequestException.class, () -> financeService.refund(
                bookingId,
                UUID.randomUUID(),
                UUID.randomUUID(),
                BigDecimal.valueOf(-1),
                UUID.randomUUID(),
                "Duplicate booking"));
    }
}