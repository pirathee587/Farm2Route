package com.farm2route.bank.service;

import com.farm2route.auth.entity.User;
import com.farm2route.bank.dto.BankDetailsRequest;
import com.farm2route.bank.dto.BankDetailsResponse;
import com.farm2route.bank.entity.BankAccountType;
import com.farm2route.bank.entity.BankDetails;
import com.farm2route.bank.repository.BankDetailsRepository;
import com.farm2route.common.event.BankDetailsUpdatedEvent;
import com.farm2route.common.exception.BusinessRuleException;
import com.farm2route.common.exception.ResourceNotFoundException;
import com.farm2route.farmer.entity.FarmerProfile;
import com.farm2route.farmer.repository.FarmerProfileRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class BankDetailsServiceTest {

    @Mock
    private BankDetailsRepository bankDetailsRepository;

    @Mock
    private FarmerProfileRepository farmerProfileRepository;

    @Mock
    private ApplicationEventPublisher applicationEventPublisher;

    @InjectMocks
    private BankDetailsService bankDetailsService;

    private UUID userId;
    private UUID farmerId;
    private FarmerProfile mockFarmer;
    private BankDetails mockDetails;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        farmerId = UUID.randomUUID();

        User user = User.builder().id(userId).email("farmer@farm2route.lk").build();
        mockFarmer = FarmerProfile.builder().id(farmerId).user(user).farmName("Greens Farm").build();

        mockDetails = BankDetails.builder()
                .id(UUID.randomUUID())
                .farmer(mockFarmer)
                .accountHolderName("Nimal Bandara")
                .bankName("Bank of Ceylon")
                .branchName("Kurunegala City")
                .accountNumber("8102938475")
                .accountType(BankAccountType.SAVINGS)
                .branchCode("BOC014")
                .isPrimary(true)
                .createdAt(Instant.now())
                .updatedAt(Instant.now())
                .build();
    }

    @Test
    @DisplayName("Should successfully create bank details and publish audit event with masked number")
    void shouldCreateBankDetailsSuccessfully() {
        BankDetailsRequest request = BankDetailsRequest.builder()
                .accountHolderName("Nimal Bandara")
                .bankName("Bank of Ceylon")
                .branchName("Kurunegala City")
                .accountNumber("8102938475")
                .accountType(BankAccountType.SAVINGS)
                .branchCode("BOC014")
                .build();

        when(farmerProfileRepository.findByUserId(userId)).thenReturn(Optional.of(mockFarmer));
        when(bankDetailsRepository.existsByFarmerId(farmerId)).thenReturn(false);
        when(bankDetailsRepository.save(any(BankDetails.class))).thenReturn(mockDetails);

        BankDetailsResponse response = bankDetailsService.createBankDetails(userId, request);

        assertThat(response).isNotNull();
        assertThat(response.getAccountHolderName()).isEqualTo("Nimal Bandara");
        assertThat(response.getBankName()).isEqualTo("Bank of Ceylon");
        assertThat(response.getMaskedAccountNumber()).isEqualTo("******8475");
        assertThat(response.getAccountType()).isEqualTo(BankAccountType.SAVINGS);

        ArgumentCaptor<BankDetailsUpdatedEvent> eventCaptor = ArgumentCaptor.forClass(BankDetailsUpdatedEvent.class);
        verify(applicationEventPublisher).publishEvent(eventCaptor.capture());
        BankDetailsUpdatedEvent event = eventCaptor.getValue();
        assertThat(event.getFarmerId()).isEqualTo(farmerId);
        assertThat(event.getMaskedAccountNumber()).isEqualTo("******8475");
        // Verify full account number is NEVER in the event
        assertThat(event.getMaskedAccountNumber()).doesNotContain("810293");
    }

    @Test
    @DisplayName("Should reject duplicate bank details creation when farmer already has an account")
    void shouldRejectDuplicateBankDetailsCreation() {
        BankDetailsRequest request = BankDetailsRequest.builder()
                .accountHolderName("Nimal Bandara")
                .bankName("Commercial Bank")
                .accountNumber("1234567890")
                .accountType(BankAccountType.CURRENT)
                .build();

        when(farmerProfileRepository.findByUserId(userId)).thenReturn(Optional.of(mockFarmer));
        when(bankDetailsRepository.existsByFarmerId(farmerId)).thenReturn(true);

        assertThatThrownBy(() -> bankDetailsService.createBankDetails(userId, request))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("Bank details already exist for this farmer");

        verify(bankDetailsRepository, never()).save(any());
        verify(applicationEventPublisher, never()).publishEvent(any());
    }

    @Test
    @DisplayName("Should successfully retrieve the farmer's bank details with masked account number")
    void shouldGetFarmerBankDetailsSuccessfully() {
        when(farmerProfileRepository.findByUserId(userId)).thenReturn(Optional.of(mockFarmer));
        when(bankDetailsRepository.findByFarmerId(farmerId)).thenReturn(Optional.of(mockDetails));

        BankDetailsResponse response = bankDetailsService.getFarmerBankDetails(userId);

        assertThat(response).isNotNull();
        assertThat(response.getMaskedAccountNumber()).isEqualTo("******8475");
        assertThat(response.getBankName()).isEqualTo("Bank of Ceylon");
    }

    @Test
    @DisplayName("Should throw ResourceNotFoundException when bank details do not exist")
    void shouldThrowNotFoundWhenDetailsDoNotExist() {
        when(farmerProfileRepository.findByUserId(userId)).thenReturn(Optional.of(mockFarmer));
        when(bankDetailsRepository.findByFarmerId(farmerId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> bankDetailsService.getFarmerBankDetails(userId))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Bank details not found for this farmer");
    }

    @Test
    @DisplayName("Should successfully update existing bank details")
    void shouldUpdateBankDetailsSuccessfully() {
        BankDetailsRequest updateReq = BankDetailsRequest.builder()
                .accountHolderName("Nimal B. Bandara")
                .bankName("People's Bank")
                .branchName("Colombo Fort")
                .accountNumber("9988776655")
                .accountType(BankAccountType.CURRENT)
                .branchCode("PB001")
                .build();

        when(farmerProfileRepository.findByUserId(userId)).thenReturn(Optional.of(mockFarmer));
        when(bankDetailsRepository.findByFarmerId(farmerId)).thenReturn(Optional.of(mockDetails));
        when(bankDetailsRepository.save(any(BankDetails.class))).thenAnswer(invocation -> invocation.getArgument(0));

        BankDetailsResponse response = bankDetailsService.updateBankDetails(userId, updateReq);

        assertThat(response).isNotNull();
        assertThat(response.getAccountHolderName()).isEqualTo("Nimal B. Bandara");
        assertThat(response.getBankName()).isEqualTo("People's Bank");
        assertThat(response.getMaskedAccountNumber()).isEqualTo("******6655");
        assertThat(response.getAccountType()).isEqualTo(BankAccountType.CURRENT);

        verify(applicationEventPublisher).publishEvent(any(BankDetailsUpdatedEvent.class));
    }

    @Test
    @DisplayName("Should successfully delete existing bank details")
    void shouldDeleteBankDetailsSuccessfully() {
        when(farmerProfileRepository.findByUserId(userId)).thenReturn(Optional.of(mockFarmer));
        when(bankDetailsRepository.findByFarmerId(farmerId)).thenReturn(Optional.of(mockDetails));

        bankDetailsService.deleteBankDetails(userId);

        verify(bankDetailsRepository).delete(mockDetails);
    }

    @Test
    @DisplayName("Should reject invalid account numbers with spaces or invalid characters")
    void shouldRejectInvalidAccountNumbers() {
        BankDetailsRequest invalidReq = BankDetailsRequest.builder()
                .accountHolderName("Nimal Bandara")
                .bankName("Bank of Ceylon")
                .accountNumber("123") // too short (< 6 chars)
                .accountType(BankAccountType.SAVINGS)
                .build();

        when(farmerProfileRepository.findByUserId(userId)).thenReturn(Optional.of(mockFarmer));
        when(bankDetailsRepository.existsByFarmerId(farmerId)).thenReturn(false);

        assertThatThrownBy(() -> bankDetailsService.createBankDetails(userId, invalidReq))
                .isInstanceOf(BusinessRuleException.class)
                .hasMessageContaining("Account number must be between 6 and 34 alphanumeric characters");
    }

    @Test
    @DisplayName("Masking logic should safely handle various string lengths without exposing full number")
    void shouldMaskAccountNumbersSafely() {
        assertThat(BankDetailsResponse.maskAccountNumber("1234567890")).isEqualTo("******7890");
        assertThat(BankDetailsResponse.maskAccountNumber("8102938475")).isEqualTo("******8475");
        assertThat(BankDetailsResponse.maskAccountNumber("1234")).isEqualTo("******1234");
        assertThat(BankDetailsResponse.maskAccountNumber("")).isEqualTo("******");
        assertThat(BankDetailsResponse.maskAccountNumber(null)).isEqualTo("******");
    }
}
