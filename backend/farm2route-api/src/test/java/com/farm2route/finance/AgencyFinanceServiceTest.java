package com.farm2route.finance;

import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.agency.repository.AgencyProfileRepository;
import com.farm2route.auth.entity.User;
import com.farm2route.auth.model.Role;
import com.farm2route.bank.entity.BankDetails;
import com.farm2route.bank.repository.BankDetailsRepository;
import com.farm2route.booking.entity.Booking;
import com.farm2route.booking.repository.BookingRepository;
import com.farm2route.common.enums.BookingStatus;
import com.farm2route.common.exception.BusinessRuleException;
import com.farm2route.finance.dto.AgencyEarningsSummaryDto;
import com.farm2route.finance.dto.WithdrawalRequestDto;
import com.farm2route.finance.entity.WithdrawalRequest;
import com.farm2route.finance.entity.WithdrawalRequestStatus;
import com.farm2route.finance.repository.FinancialTransactionRepository;
import com.farm2route.finance.repository.WithdrawalRequestRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AgencyFinanceServiceTest {
    @Mock AgencyProfileRepository agencyProfileRepository;
    @Mock BookingRepository bookingRepository;
    @Mock BankDetailsRepository bankDetailsRepository;
    @Mock WithdrawalRequestRepository withdrawalRequestRepository;
    @Mock FinancialTransactionRepository financialTransactionRepository;
    @InjectMocks AgencyFinanceService financeService;

    private UUID agencyUserId;
    private UUID agencyId;
    private AgencyProfile agency;

    @BeforeEach
    void setUp() {
        agencyUserId = UUID.randomUUID();
        agencyId = UUID.randomUUID();
        agency = AgencyProfile.builder().id(agencyId)
                .user(User.builder().id(agencyUserId).role(Role.AGENCY).build())
                .commissionRatePercentage(new BigDecimal("10.00")).build();
        when(agencyProfileRepository.findByUserId(agencyUserId)).thenReturn(Optional.of(agency));
        lenient().when(withdrawalRequestRepository.sumAmountsByAgencyIdAndStatusIn(eq(agencyId), anyList()))
                .thenReturn(BigDecimal.ZERO);
    }

    @Test
    void noDeliveredBookingsProduceZeroEarnings() {
        when(bookingRepository.findByAgencyId(agencyId)).thenReturn(List.of(
                booking(BookingStatus.PENDING, "100.00"),
                booking(BookingStatus.REJECTED, "200.00"),
                booking(BookingStatus.CANCELLED, "300.00")));

        AgencyEarningsSummaryDto result = financeService.getSummary(agencyUserId);

        assertThat(result.getGrossEarnings()).isEqualByComparingTo("0.00");
        assertThat(result.getCommission()).isEqualByComparingTo("0.00");
        assertThat(result.getNetEarnings()).isEqualByComparingTo("0.00");
    }

    @Test
    void deliveredBookingUsesStoredAmountsAndExcludesRefundsFromPositiveEarnings() {
        Booking delivered = booking(BookingStatus.DELIVERED, "1000.00");
        delivered.setCommissionAmount(new BigDecimal("100.00"));
        delivered.setAgencyEarnings(new BigDecimal("900.00"));
        Booking cancelled = booking(BookingStatus.CANCELLED, "500.00");
        when(bookingRepository.findByAgencyId(agencyId)).thenReturn(List.of(delivered, cancelled));

        AgencyEarningsSummaryDto result = financeService.getSummary(agencyUserId);

        assertThat(result.getGrossEarnings()).isEqualByComparingTo("1000.00");
        assertThat(result.getCommission()).isEqualByComparingTo("100.00");
        assertThat(result.getNetEarnings()).isEqualByComparingTo("900.00");
        assertThat(result.getAvailableBalance()).isEqualByComparingTo("900.00");
    }

    @Test
    void commissionUsesConfiguredRateWithDeterministicRounding() {
        when(bookingRepository.findByAgencyId(agencyId)).thenReturn(List.of(booking(BookingStatus.DELIVERED, "100.05")));

        AgencyEarningsSummaryDto result = financeService.getSummary(agencyUserId);

        assertThat(result.getCommission()).isEqualByComparingTo("10.01");
        assertThat(result.getNetEarnings()).isEqualByComparingTo("90.04");
    }

    @Test
    void validWithdrawalReservesFundsAndLocksAgencyBalance() {
        when(agencyProfileRepository.findByIdForUpdate(agencyId)).thenReturn(Optional.of(agency));
        when(bookingRepository.findByAgencyId(agencyId)).thenReturn(List.of(booking(BookingStatus.DELIVERED, "1000.00")));
        User agencyUser = agency.getUser();
        BankDetails bank = BankDetails.builder().id(UUID.randomUUID()).user(agencyUser).bankName("Bank").accountNumber("123456").build();
        when(bankDetailsRepository.findByUserIdAndIsPrimaryTrue(agencyUserId)).thenReturn(Optional.of(bank));
        when(withdrawalRequestRepository.save(any(WithdrawalRequest.class))).thenAnswer(invocation -> {
            WithdrawalRequest saved = invocation.getArgument(0);
            saved.setId(UUID.randomUUID());
            return saved;
        });
        WithdrawalRequestDto request = new WithdrawalRequestDto();
        request.setAmount(new BigDecimal("500.00"));

        var result = financeService.requestWithdrawal(agencyUserId, request);

        assertThat(result.getAmount()).isEqualByComparingTo("500.00");
        ArgumentCaptor<WithdrawalRequest> captor = ArgumentCaptor.forClass(WithdrawalRequest.class);
        verify(withdrawalRequestRepository).save(captor.capture());
        assertThat(captor.getValue().getStatus()).isEqualTo(WithdrawalRequestStatus.PENDING);
        verify(agencyProfileRepository).findByIdForUpdate(agencyId);
    }

    @Test
    void secondWithdrawalCannotOverdrawReservedBalance() {
        when(agencyProfileRepository.findByIdForUpdate(agencyId)).thenReturn(Optional.of(agency));
        when(bookingRepository.findByAgencyId(agencyId)).thenReturn(List.of(booking(BookingStatus.DELIVERED, "1000.00")));
        when(withdrawalRequestRepository.sumAmountsByAgencyIdAndStatusIn(eq(agencyId), anyList()))
                .thenReturn(BigDecimal.ZERO, new BigDecimal("900.00"));
        BankDetails bank = BankDetails.builder().id(UUID.randomUUID()).user(agency.getUser()).bankName("Bank").accountNumber("123456").build();
        when(bankDetailsRepository.findByUserIdAndIsPrimaryTrue(agencyUserId)).thenReturn(Optional.of(bank));
        WithdrawalRequestDto request = new WithdrawalRequestDto();
        request.setAmount(new BigDecimal("200.00"));

        assertThatThrownBy(() -> financeService.requestWithdrawal(agencyUserId, request))
                .isInstanceOf(BusinessRuleException.class).hasMessageContaining("Insufficient");
        verify(withdrawalRequestRepository, never()).save(any());
    }

    @Test
    void foreignAgencyBankDetailsAreRejected() {
        when(agencyProfileRepository.findByIdForUpdate(agencyId)).thenReturn(Optional.of(agency));
        BankDetails bank = BankDetails.builder().id(UUID.randomUUID())
                .user(User.builder().id(UUID.randomUUID()).role(Role.AGENCY).build())
                .bankName("Bank").accountNumber("123456").build();
        when(bankDetailsRepository.findById(any())).thenReturn(Optional.of(bank));
        WithdrawalRequestDto request = new WithdrawalRequestDto();
        request.setAmount(BigDecimal.ONE);
        request.setBankDetailId(bank.getId());

        assertThatThrownBy(() -> financeService.requestWithdrawal(agencyUserId, request))
                .isInstanceOf(BusinessRuleException.class).hasMessageContaining("do not belong");
    }

    private Booking booking(BookingStatus status, String amount) {
        return Booking.builder().id(UUID.randomUUID()).agency(agency).status(status)
                .totalAmount(new BigDecimal(amount)).build();
    }
}
