package com.farm2route.agency.service;

import com.farm2route.agency.dto.AgencyProfileDto;
import com.farm2route.agency.dto.AgencyResponse;
import com.farm2route.agency.dto.AgencySignupRequest;
import com.farm2route.agency.dto.AgencyStatusResponse;
import com.farm2route.agency.entity.Agency;
import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.agency.entity.AgencyStatusHistory;
import com.farm2route.agency.enums.AgencyStatus;
import com.farm2route.agency.enums.AgencyType;
import com.farm2route.agency.repository.AgencyProfileRepository;
import com.farm2route.agency.repository.AgencyRepository;
import com.farm2route.agency.repository.AgencyStatusHistoryRepository;
import com.farm2route.auth.entity.User;
import com.farm2route.auth.model.OtpPurpose;
import com.farm2route.auth.repository.UserRepository;
import com.farm2route.auth.service.OtpService;
import com.farm2route.common.email.EmailSender;
import com.farm2route.common.enums.KycStatus;
import com.farm2route.common.event.AgencyRegisteredEvent;
import com.farm2route.common.exception.BadRequestException;
import com.farm2route.common.exception.ConflictException;
import com.farm2route.common.exception.DuplicateResourceException;
import com.farm2route.common.exception.ResourceNotFoundException;
import com.farm2route.common.storage.SupabaseStorageService;
import jakarta.validation.ValidationException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.Duration;
import java.time.Instant;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class AgencyService {

    private final AgencyProfileRepository agencyProfileRepository;
    private final UserRepository userRepository;
    private final SupabaseStorageService storageService;
    private final AgencyRepository agencyRepository;
    private final AgencyStatusHistoryRepository agencyStatusHistoryRepository;
    private final PasswordEncoder passwordEncoder;
    private final ApplicationEventPublisher applicationEventPublisher;
    private final OtpService otpService;
    private final EmailSender emailSender;

    @Transactional
    public AgencyProfileDto uploadKycDocument(UUID userId, MultipartFile file) {
        AgencyProfile profile = agencyProfileRepository.findByUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Agency profile not found for user ID: " + userId));
        try {
            profile.setKycDocumentUrl(storageService.uploadPrivateFile(
                    SupabaseStorageService.BUCKET_KYC_DOCUMENTS, "agencies/" + profile.getId(), file));
        } catch (IOException ex) {
            throw new BadRequestException("Unable to upload agency KYC document");
        }
        profile.setKycStatus(KycStatus.PENDING);
        return mapToDto(agencyProfileRepository.save(profile));
    }

    @Transactional(readOnly = true)
    public String getKycDocumentUrl(UUID userId) {
        AgencyProfile profile = agencyProfileRepository.findByUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Agency profile not found for user ID: " + userId));
        return storageService.createSignedUrl(SupabaseStorageService.BUCKET_KYC_DOCUMENTS,
                profile.getKycDocumentUrl(), 300);
    }

    @Transactional
    public void logStatusChange(Agency agency, AgencyStatus oldStatus, AgencyStatus newStatus, String changedBy, String notes) {
        agency.setStatus(newStatus);
        agencyRepository.save(agency);

        AgencyStatusHistory history = AgencyStatusHistory.builder()
                .agency(agency)
                .oldStatus(oldStatus != null ? oldStatus.name() : null)
                .newStatus(newStatus.name())
                .changedBy(changedBy != null ? changedBy : "SYSTEM")
                .notes(notes)
                .build();
        agencyStatusHistoryRepository.save(history);
        log.info("[AgencyStatusChange] AgencyId={} transitioned from {} to {} by {}",
                agency.getId(), oldStatus, newStatus, changedBy);
    }

    @Transactional
    public AgencyResponse signup(AgencySignupRequest request) {
        if (request.getPassword() == null || !request.getPassword().equals(request.getConfirmPassword())) {
            throw new BadRequestException("Password and confirm password do not match");
        }

        // Cross-field requirement: businessRegNumber mandatory for COMPANY and PARTNERSHIP
        if ((request.getAgencyType() == AgencyType.COMPANY || request.getAgencyType() == AgencyType.PARTNERSHIP)
                && (request.getBusinessRegNumber() == null || request.getBusinessRegNumber().trim().isEmpty())) {
            throw new ValidationException("Business registration number is mandatory for " + request.getAgencyType());
        }

        if (agencyRepository.existsByEmail(request.getEmail())) {
            throw new DuplicateResourceException("Agency with email " + request.getEmail() + " already exists");
        }

        if (agencyRepository.existsByPhoneNumber(request.getPhoneNumber())) {
            throw new DuplicateResourceException("Agency with phone number " + request.getPhoneNumber() + " already exists");
        }

        if (request.getBusinessRegNumber() != null && !request.getBusinessRegNumber().trim().isEmpty()
                && agencyRepository.existsByBusinessRegNumber(request.getBusinessRegNumber().trim())) {
            throw new DuplicateResourceException("Agency with business registration number " + request.getBusinessRegNumber() + " already exists");
        }

        String passwordHash = passwordEncoder.encode(request.getPassword());
        String emailToken = UUID.randomUUID().toString();

        Agency agency = Agency.builder()
                .agencyName(request.getAgencyName())
                .email(request.getEmail())
                .passwordHash(passwordHash)
                .phoneNumber(request.getPhoneNumber())
                .agencyType(request.getAgencyType())
                .businessRegNumber(request.getBusinessRegNumber() != null && !request.getBusinessRegNumber().trim().isEmpty() ? request.getBusinessRegNumber().trim() : null)
                .district(request.getDistrict())
                .address(request.getAddress())
                .contactPersonName(request.getContactPersonName())
                .status(AgencyStatus.ACCOUNT_CREATED)
                .emailVerified(false)
                .phoneVerified(false)
                .emailVerificationToken(emailToken)
                .emailVerificationExpiresAt(Instant.now().plus(Duration.ofHours(24)))
                .build();

        agency = agencyRepository.save(agency);
        logStatusChange(agency, null, AgencyStatus.ACCOUNT_CREATED, "SYSTEM", "Initial agency account creation");

        // Send email verification link/token
        emailSender.sendVerificationEmail(agency.getEmail(), emailToken, agency.getAgencyName());

        // Send SMS OTP via existing OTP infra
        try {
            otpService.generateAndSendOtp(agency.getPhoneNumber(), OtpPurpose.PHONE_VERIFICATION, agency.getId());
        } catch (Exception e) {
            log.warn("Failed to send phone verification OTP on signup for agencyId={}: {}", agency.getId(), e.getMessage());
        }

        return mapToAgencyResponse(agency);
    }

    @Transactional
    public AgencyStatusResponse verifyEmail(UUID agencyId, String emailToken) {
        Agency agency = agencyRepository.findById(agencyId)
                .orElseThrow(() -> new ResourceNotFoundException("Agency not found with ID: " + agencyId));

        if (agency.isEmailVerified()) {
            return mapToStatusResponse(agency);
        }

        if (agency.getEmailVerificationToken() == null || !agency.getEmailVerificationToken().equals(emailToken)) {
            throw new BadRequestException("Invalid email verification token");
        }

        if (agency.getEmailVerificationExpiresAt() != null && agency.getEmailVerificationExpiresAt().isBefore(Instant.now())) {
            throw new BadRequestException("Email verification token has expired. Please request a new one.");
        }

        agency.setEmailVerified(true);
        agency.setEmailVerificationToken(null);
        agency.setEmailVerificationExpiresAt(null);
        agencyRepository.save(agency);

        checkDualVerificationCompleted(agency);
        return mapToStatusResponse(agency);
    }

    @Transactional
    public AgencyStatusResponse verifyPhone(UUID agencyId, String otp) {
        Agency agency = agencyRepository.findById(agencyId)
                .orElseThrow(() -> new ResourceNotFoundException("Agency not found with ID: " + agencyId));

        if (agency.isPhoneVerified()) {
            return mapToStatusResponse(agency);
        }

        boolean verified = otpService.verifyOtp(agency.getPhoneNumber(), otp, OtpPurpose.PHONE_VERIFICATION);
        if (!verified) {
            throw new BadRequestException("Invalid OTP code");
        }

        agency.setPhoneVerified(true);
        agencyRepository.save(agency);

        checkDualVerificationCompleted(agency);
        return mapToStatusResponse(agency);
    }

    @Transactional
    public void resendEmail(UUID agencyId) {
        Agency agency = agencyRepository.findById(agencyId)
                .orElseThrow(() -> new ResourceNotFoundException("Agency not found with ID: " + agencyId));

        if (agency.isEmailVerified()) {
            throw new BadRequestException("Email is already verified");
        }

        String emailToken = UUID.randomUUID().toString();
        agency.setEmailVerificationToken(emailToken);
        agency.setEmailVerificationExpiresAt(Instant.now().plus(Duration.ofHours(24)));
        agencyRepository.save(agency);

        emailSender.sendVerificationEmail(agency.getEmail(), emailToken, agency.getAgencyName());
    }

    @Transactional
    public void resendPhoneOtp(UUID agencyId) {
        Agency agency = agencyRepository.findById(agencyId)
                .orElseThrow(() -> new ResourceNotFoundException("Agency not found with ID: " + agencyId));

        if (agency.isPhoneVerified()) {
            throw new BadRequestException("Phone number is already verified");
        }

        otpService.generateAndSendOtp(agency.getPhoneNumber(), OtpPurpose.PHONE_VERIFICATION, agency.getId());
    }

    @Transactional(readOnly = true)
    public AgencyStatusResponse getAgencyStatus(UUID agencyId) {
        Agency agency = agencyRepository.findById(agencyId)
                .orElseThrow(() -> new ResourceNotFoundException("Agency not found with ID: " + agencyId));
        return mapToStatusResponse(agency);
    }

    @Transactional
    public AgencyResponse approveAgency(UUID agencyId, UUID adminUserId) {
        Agency agency = agencyRepository.findById(agencyId)
                .orElseThrow(() -> new ResourceNotFoundException("Agency not found with ID: " + agencyId));

        AgencyStatus oldStatus = agency.getStatus();
        logStatusChange(agency, oldStatus, AgencyStatus.APPROVED, adminUserId != null ? adminUserId.toString() : "ADMIN", "Approved by admin");
        return mapToAgencyResponse(agency);
    }

    @Transactional
    public AgencyResponse rejectAgency(UUID agencyId, String reason, UUID adminUserId) {
        Agency agency = agencyRepository.findById(agencyId)
                .orElseThrow(() -> new ResourceNotFoundException("Agency not found with ID: " + agencyId));

        AgencyStatus oldStatus = agency.getStatus();
        agency.setRejectionReason(reason);
        agency.setRejectedAt(Instant.now());
        agency.setRejectedBy(adminUserId);

        logStatusChange(agency, oldStatus, AgencyStatus.REJECTED, adminUserId != null ? adminUserId.toString() : "ADMIN", reason);
        return mapToAgencyResponse(agency);
    }

    private void checkDualVerificationCompleted(Agency agency) {
        if (agency.isEmailVerified() && agency.isPhoneVerified() && agency.getStatus() == AgencyStatus.ACCOUNT_CREATED) {
            logStatusChange(agency, AgencyStatus.ACCOUNT_CREATED, AgencyStatus.PENDING_VERIFICATION, "SYSTEM", "Dual verification completed (email + phone)");

            // Publish AFTER_COMMIT domain event for downstream notifications/audit
            applicationEventPublisher.publishEvent(
                    AgencyRegisteredEvent.builder()
                            .agencyId(agency.getId())
                            .agencyName(agency.getAgencyName())
                            .email(agency.getEmail())
                            .phoneNumber(agency.getPhoneNumber())
                            .agencyType(agency.getAgencyType())
                            .build()
            );
        }
    }

    @Transactional(readOnly = true)
    public AgencyProfileDto getProfileByUserId(UUID userId) {
        AgencyProfile profile = agencyProfileRepository.findByUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Agency profile not found for user ID: " + userId));
        return mapToDto(profile);
    }

    @Transactional
    public AgencyProfileDto updateProfile(UUID userId, AgencyProfileDto dto) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userId));

        AgencyProfile profile = agencyProfileRepository.findByUserId(userId)
                .orElse(AgencyProfile.builder().user(user).build());

        if (dto.getBusinessRegistrationNumber() != null &&
                !dto.getBusinessRegistrationNumber().equals(profile.getBusinessRegistrationNumber())) {
            UUID currentProfileId = profile.getId();
            agencyProfileRepository.findByBusinessRegistrationNumber(dto.getBusinessRegistrationNumber())
                    .ifPresent(existing -> {
                        if (currentProfileId != null && !existing.getId().equals(currentProfileId)) {
                            throw new ConflictException("Business registration number already registered");
                        }
                    });
        }

        profile.setCompanyName(dto.getCompanyName());
        profile.setBusinessRegistrationNumber(dto.getBusinessRegistrationNumber());
        profile.setTaxIdentificationNumber(dto.getTaxIdentificationNumber());
        profile.setOfficeAddress(dto.getOfficeAddress());
        profile.setDistrict(dto.getDistrict());
        profile.setContactPersonName(dto.getContactPersonName());
        profile.setContactPersonPhone(dto.getContactPersonPhone());
        profile = agencyProfileRepository.save(profile);
        return mapToDto(profile);
    }

    private AgencyProfileDto mapToDto(AgencyProfile profile) {
        return AgencyProfileDto.builder()
                .id(profile.getId())
                .userId(profile.getUser().getId())
                .companyName(profile.getCompanyName())
                .businessRegistrationNumber(profile.getBusinessRegistrationNumber())
                .taxIdentificationNumber(profile.getTaxIdentificationNumber())
                .officeAddress(profile.getOfficeAddress())
                .district(profile.getDistrict())
                .contactPersonName(profile.getContactPersonName())
                .contactPersonPhone(profile.getContactPersonPhone())
                .kycStatus(profile.getKycStatus())
                // The private storage path is intentionally omitted. Use /kyc/document
                // to obtain a short-lived signed URL after ownership checks.
                .kycDocumentUrl(null)
                .commissionRatePercentage(profile.getCommissionRatePercentage())
                .build();
    }

    private AgencyResponse mapToAgencyResponse(Agency agency) {
        return AgencyResponse.builder()
                .id(agency.getId())
                .agencyName(agency.getAgencyName())
                .email(agency.getEmail())
                .phoneNumber(agency.getPhoneNumber())
                .agencyType(agency.getAgencyType())
                .businessRegNumber(agency.getBusinessRegNumber())
                .district(agency.getDistrict())
                .address(agency.getAddress())
                .contactPersonName(agency.getContactPersonName())
                .status(agency.getStatus())
                .emailVerified(agency.isEmailVerified())
                .phoneVerified(agency.isPhoneVerified())
                .rejectionReason(agency.getRejectionReason())
                .rejectedAt(agency.getRejectedAt())
                .createdAt(agency.getCreatedAt())
                .updatedAt(agency.getUpdatedAt())
                .build();
    }

    private AgencyStatusResponse mapToStatusResponse(Agency agency) {
        return AgencyStatusResponse.builder()
                .agencyId(agency.getId())
                .email(agency.getEmail())
                .phoneNumber(agency.getPhoneNumber())
                .status(agency.getStatus())
                .emailVerified(agency.isEmailVerified())
                .phoneVerified(agency.isPhoneVerified())
                .rejectionReason(agency.getRejectionReason())
                .build();
    }
}
