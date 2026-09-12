package com.farm2route.finance;

import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.agency.repository.AgencyProfileRepository;
import com.farm2route.bank.entity.BankDetails;
import com.farm2route.bank.repository.BankDetailsRepository;
import com.farm2route.booking.entity.Booking;
import com.farm2route.booking.repository.BookingRepository;
import com.farm2route.common.enums.BookingStatus;
import com.farm2route.common.exception.BusinessRuleException;
import com.farm2route.common.exception.ResourceNotFoundException;
import com.farm2route.finance.dto.AgencyEarningsSummaryDto;
import com.farm2route.finance.dto.FinancialTransactionDto;
import com.farm2route.finance.dto.WithdrawalRequestDto;
import com.farm2route.finance.dto.WithdrawalResponseDto;
import com.farm2route.finance.entity.WithdrawalRequest;
import com.farm2route.finance.entity.WithdrawalRequestStatus;
import com.farm2route.finance.repository.FinancialTransactionRepository;
import com.farm2route.finance.repository.WithdrawalRequestRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AgencyFinanceService {
    private static final BigDecimal HUNDRED = BigDecimal.valueOf(100);
    private static final List<WithdrawalRequestStatus> RESERVED_STATUSES =
            List.of(WithdrawalRequestStatus.PENDING, WithdrawalRequestStatus.APPROVED, WithdrawalRequestStatus.PROCESSED);

    private final AgencyProfileRepository agencyProfileRepository;
    private final BookingRepository bookingRepository;
    private final BankDetailsRepository bankDetailsRepository;
    private final WithdrawalRequestRepository withdrawalRequestRepository;
    private final FinancialTransactionRepository financialTransactionRepository;

    @Transactional(readOnly = true)
    public AgencyEarningsSummaryDto getSummary(UUID agencyUserId) {
        AgencyProfile agency = resolveAgency(agencyUserId);
        return summaryFor(agency);
    }

    @Transactional(readOnly = true)
    public List<FinancialTransactionDto> getTransactions(UUID agencyUserId) {
        resolveAgency(agencyUserId);
        return financialTransactionRepository.findByPayeeIdOrderByCreatedAtDesc(agencyUserId).stream()
                .map(FinancialTransactionDto::from).collect(Collectors.toList());
    }

    @Transactional
    public WithdrawalResponseDto requestWithdrawal(UUID agencyUserId, WithdrawalRequestDto request) {
        if (request.getAmount() == null || request.getAmount().signum() <= 0) {
            throw new BusinessRuleException("Withdrawal amount must be positive");
        }

        AgencyProfile agency = agencyProfileRepository.findByUserId(agencyUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Agency profile not found for user: " + agencyUserId));
        UUID agencyId = agency.getId();
        AgencyProfile lockedAgency = agencyProfileRepository.findByIdForUpdate(agencyId)
                .orElseThrow(() -> new ResourceNotFoundException("Agency not found: " + agencyId));
        agency = lockedAgency;

        BankDetails bankDetails = request.getBankDetailId() == null
                ? bankDetailsRepository.findByUserIdAndIsPrimaryTrue(agencyUserId)
                    .orElseThrow(() -> new BusinessRuleException("A primary agency bank account is required"))
                : bankDetailsRepository.findById(request.getBankDetailId())
                    .orElseThrow(() -> new ResourceNotFoundException("Bank details not found"));
        if (bankDetails.getUser() == null || !agencyUserId.equals(bankDetails.getUser().getId())) {
            throw new BusinessRuleException("Bank details do not belong to this agency");
        }

        AgencyEarningsSummaryDto summary = summaryFor(agency);
        if (request.getAmount().compareTo(summary.getAvailableBalance()) > 0) {
            throw new BusinessRuleException("Insufficient available balance");
        }

        Instant now = Instant.now();
        WithdrawalRequest withdrawal = WithdrawalRequest.builder()
                .agency(agency).bankDetails(bankDetails).amount(money(request.getAmount()))
                .status(WithdrawalRequestStatus.PENDING).createdAt(now).updatedAt(now).build();
        return WithdrawalResponseDto.from(withdrawalRequestRepository.save(withdrawal));
    }

    @Transactional(readOnly = true)
    public List<WithdrawalResponseDto> getWithdrawals(UUID agencyUserId) {
        AgencyProfile agency = resolveAgency(agencyUserId);
        return withdrawalRequestRepository.findByAgencyIdOrderByCreatedAtDesc(agency.getId()).stream()
                .map(WithdrawalResponseDto::from).collect(Collectors.toList());
    }

    private AgencyProfile resolveAgency(UUID agencyUserId) {
        return agencyProfileRepository.findByUserId(agencyUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Agency profile not found for user: " + agencyUserId));
    }

    private AgencyEarningsSummaryDto summaryFor(AgencyProfile agency) {
        BigDecimal gross = BigDecimal.ZERO;
        BigDecimal commission = BigDecimal.ZERO;
        BigDecimal net = BigDecimal.ZERO;
        for (Booking booking : bookingRepository.findByAgencyId(agency.getId())) {
            if (booking.getStatus() != BookingStatus.DELIVERED) continue;
            BigDecimal bookingGross = money(booking.getTotalAmount());
            BigDecimal bookingCommission = booking.getCommissionAmount() != null && booking.getCommissionAmount().signum() > 0
                    ? money(booking.getCommissionAmount())
                    : money(bookingGross.multiply(agency.getCommissionRatePercentage()).divide(HUNDRED, 2, RoundingMode.HALF_UP));
            BigDecimal bookingNet = booking.getAgencyEarnings() != null && booking.getAgencyEarnings().signum() > 0
                    ? money(booking.getAgencyEarnings()) : money(bookingGross.subtract(bookingCommission));
            gross = gross.add(bookingGross);
            commission = commission.add(bookingCommission);
            net = net.add(bookingNet);
        }
        BigDecimal withdrawn = money(withdrawalRequestRepository.sumAmountsByAgencyIdAndStatusIn(
                agency.getId(), List.of(WithdrawalRequestStatus.PROCESSED)));
        BigDecimal reserved = money(withdrawalRequestRepository.sumAmountsByAgencyIdAndStatusIn(
                agency.getId(), RESERVED_STATUSES));
        return AgencyEarningsSummaryDto.builder().grossEarnings(money(gross)).commission(money(commission))
                .netEarnings(money(net)).withdrawn(withdrawn)
                .availableBalance(money(net.subtract(reserved))).build();
    }

    private BigDecimal money(BigDecimal value) {
        return (value == null ? BigDecimal.ZERO : value).setScale(2, RoundingMode.HALF_UP);
    }
}
