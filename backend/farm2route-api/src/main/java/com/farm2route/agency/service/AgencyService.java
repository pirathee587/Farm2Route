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
import com.farm2route.common.exception.BadRequestException;
import com.farm2route.common.storage.SupabaseStorageService;
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
