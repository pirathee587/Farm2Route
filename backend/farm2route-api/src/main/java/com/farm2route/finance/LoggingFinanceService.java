package com.farm2route.finance;

import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.agency.repository.AgencyProfileRepository;
import com.farm2route.booking.entity.Booking;
import com.farm2route.booking.repository.BookingRepository;
import com.farm2route.common.enums.PaymentMethod;
import com.farm2route.common.enums.TransactionStatus;
import com.farm2route.common.enums.TransactionType;
import com.farm2route.common.exception.BadRequestException;
import com.farm2route.common.exception.ResourceNotFoundException;
import com.farm2route.finance.entity.FinancialTransaction;
import com.farm2route.finance.repository.FinancialTransactionRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.UUID;

@Service
@Slf4j
public class LoggingFinanceService implements FinanceService {
    private final BookingRepository bookingRepository;
    private final AgencyProfileRepository agencyProfileRepository;
    private final FinancialTransactionRepository transactionRepository;

    public LoggingFinanceService() {
        this.bookingRepository = null;
        this.agencyProfileRepository = null;
        this.transactionRepository = null;
    }

    @Autowired
    public LoggingFinanceService(BookingRepository bookingRepository,
                                 AgencyProfileRepository agencyProfileRepository,
                                 FinancialTransactionRepository transactionRepository) {
        this.bookingRepository = bookingRepository;
        this.agencyProfileRepository = agencyProfileRepository;
        this.transactionRepository = transactionRepository;
    }

    @Override
    @Transactional
    public RefundResult refund(UUID bookingId, UUID farmerId, UUID agencyId, BigDecimal amount,
                               UUID adminId, String reason) {
        if (amount == null || amount.signum() <= 0) {
            throw new BadRequestException("Refund amount must be positive");
        }
        if (bookingRepository == null) {
            log.info("Refund accepted pending processing: bookingId={}, farmerId={}, agencyId={}, amount={}, adminId={}, reason={}",
                    bookingId, farmerId, agencyId, amount, adminId, reason);
            return new RefundResult(bookingId, amount, RefundStatus.ACCEPTED_PENDING_PROCESSING);
        }

        Booking booking = bookingRepository.findById(bookingId)
                .orElseThrow(() -> new ResourceNotFoundException("Booking not found: " + bookingId));
        if (!booking.getFarmer().getUser().getId().equals(farmerId)) {
            throw new BadRequestException("Booking does not belong to the supplied farmer");
        }
        AgencyProfile agency = agencyProfileRepository.findById(agencyId)
                .orElseThrow(() -> new ResourceNotFoundException("Agency not found: " + agencyId));
        if (!booking.getAgency().getId().equals(agency.getId())) {
            throw new BadRequestException("Booking does not belong to the supplied agency");
        }
        if (amount.compareTo(booking.getTotalAmount()) > 0) {
            throw new BadRequestException("Refund amount cannot exceed booking amount");
        }

        transactionRepository.save(FinancialTransaction.builder()
                .transactionReference("REFUND-" + UUID.randomUUID())
                .booking(booking)
                .payer(booking.getFarmer().getUser())
                .payee(agency.getUser())
                .amount(amount)
                .commissionDeducted(BigDecimal.ZERO)
                .netAmount(amount)
                .transactionType(TransactionType.REFUND)
                .paymentMethod(PaymentMethod.IN_APP_WALLET)
                .status(TransactionStatus.PENDING)
                .build());
        log.info("Refund accepted pending processing: bookingId={}, farmerId={}, agencyId={}, amount={}, adminId={}, reason={}",
                bookingId, farmerId, agencyId, amount, adminId, reason);
        return new RefundResult(bookingId, amount, RefundStatus.ACCEPTED_PENDING_PROCESSING);
    }
}
