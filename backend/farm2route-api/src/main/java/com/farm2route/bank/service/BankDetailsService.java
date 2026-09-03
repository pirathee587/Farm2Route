package com.farm2route.bank.service;

import com.farm2route.bank.dto.BankDetailsRequest;
import com.farm2route.bank.dto.BankDetailsResponse;
import com.farm2route.bank.entity.BankDetails;
import com.farm2route.bank.repository.BankDetailsRepository;
import com.farm2route.common.event.BankDetailsUpdatedEvent;
import com.farm2route.common.exception.BusinessRuleException;
import com.farm2route.common.exception.ResourceNotFoundException;
import com.farm2route.farmer.entity.FarmerProfile;
import com.farm2route.farmer.repository.FarmerProfileRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;
import java.util.regex.Pattern;

@Slf4j
@Service
@RequiredArgsConstructor
public class BankDetailsService {

    private static final Pattern ACCOUNT_NUMBER_PATTERN = Pattern.compile("^[0-9A-Za-z]{6,34}$");

    private final BankDetailsRepository bankDetailsRepository;
    private final FarmerProfileRepository farmerProfileRepository;
    private final ApplicationEventPublisher applicationEventPublisher;

    @Transactional(readOnly = true)
    public BankDetailsResponse getFarmerBankDetails(UUID farmerUserId) {
        FarmerProfile farmer = resolveFarmer(farmerUserId);
        BankDetails details = bankDetailsRepository.findByFarmerId(farmer.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Bank details not found for this farmer"));

        return BankDetailsResponse.fromEntity(details);
    }

    @Transactional
    public BankDetailsResponse createBankDetails(UUID farmerUserId, BankDetailsRequest request) {
        FarmerProfile farmer = resolveFarmer(farmerUserId);

        if (bankDetailsRepository.existsByFarmerId(farmer.getId())) {
            throw new BusinessRuleException("Bank details already exist for this farmer");
        }

        String normalizedAccountNumber = normalizeAndValidateAccountNumber(request.getAccountNumber());

        BankDetails bankDetails = BankDetails.builder()
                .farmer(farmer)
                .accountHolderName(request.getAccountHolderName().trim())
                .bankName(request.getBankName().trim())
                .branchName(request.getBranchName() != null ? request.getBranchName().trim() : null)
                .accountNumber(normalizedAccountNumber)
                .accountType(request.getAccountType())
                .branchCode(request.getBranchCode() != null ? request.getBranchCode().trim() : null)
                .isPrimary(true)
                .build();

        BankDetails saved = bankDetailsRepository.save(bankDetails);
        log.info("Bank details successfully registered for farmerId={}", farmer.getId());

        publishUpdatedEvent(farmer.getId(), saved.getId(), saved.getBankName(), saved.getAccountNumber());

        return BankDetailsResponse.fromEntity(saved);
    }

    @Transactional
    public BankDetailsResponse updateBankDetails(UUID farmerUserId, BankDetailsRequest request) {
        FarmerProfile farmer = resolveFarmer(farmerUserId);

        BankDetails existing = bankDetailsRepository.findByFarmerId(farmer.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Bank details not found for this farmer"));

        String normalizedAccountNumber = normalizeAndValidateAccountNumber(request.getAccountNumber());

        existing.setAccountHolderName(request.getAccountHolderName().trim());
        existing.setBankName(request.getBankName().trim());
        existing.setBranchName(request.getBranchName() != null ? request.getBranchName().trim() : null);
        existing.setAccountNumber(normalizedAccountNumber);
        existing.setAccountType(request.getAccountType());
        existing.setBranchCode(request.getBranchCode() != null ? request.getBranchCode().trim() : null);

        BankDetails updated = bankDetailsRepository.save(existing);
        log.info("Bank details successfully updated for farmerId={}", farmer.getId());

        publishUpdatedEvent(farmer.getId(), updated.getId(), updated.getBankName(), updated.getAccountNumber());

        return BankDetailsResponse.fromEntity(updated);
    }

    @Transactional
    public void deleteBankDetails(UUID farmerUserId) {
        FarmerProfile farmer = resolveFarmer(farmerUserId);

        BankDetails existing = bankDetailsRepository.findByFarmerId(farmer.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Bank details not found for this farmer"));

        bankDetailsRepository.delete(existing);
        log.info("Bank details deleted for farmerId={}", farmer.getId());
    }

    private FarmerProfile resolveFarmer(UUID farmerUserId) {
        return farmerProfileRepository.findByUserId(farmerUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Farmer profile not found for user: " + farmerUserId));
    }

    private String normalizeAndValidateAccountNumber(String raw) {
        if (raw == null) {
            throw new BusinessRuleException("Account number is required");
        }
        String normalized = raw.replaceAll("\\s+", "").trim();
        if (!ACCOUNT_NUMBER_PATTERN.matcher(normalized).matches()) {
            throw new BusinessRuleException("Account number must be between 6 and 34 alphanumeric characters without spaces");
        }
        return normalized;
    }

    private void publishUpdatedEvent(UUID farmerId, UUID bankDetailsId, String bankName, String rawAccountNumber) {
        String masked = BankDetailsResponse.maskAccountNumber(rawAccountNumber);
        applicationEventPublisher.publishEvent(
                BankDetailsUpdatedEvent.builder()
                        .farmerId(farmerId)
                        .bankDetailsId(bankDetailsId)
                        .bankName(bankName)
                        .maskedAccountNumber(masked)
                        .build()
        );
    }
}
