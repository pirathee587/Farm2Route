package com.farm2route.agency.service;

import com.farm2route.agency.dto.AgencyProfileDto;
import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.agency.repository.AgencyProfileRepository;
import com.farm2route.auth.entity.User;
import com.farm2route.auth.repository.UserRepository;
import com.farm2route.common.enums.KycStatus;
import com.farm2route.common.exception.ConflictException;
import com.farm2route.common.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AgencyService {

    private final AgencyProfileRepository agencyProfileRepository;
    private final UserRepository userRepository;

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
        if (dto.getKycDocumentUrl() != null) {
            profile.setKycDocumentUrl(dto.getKycDocumentUrl());
            profile.setKycStatus(KycStatus.PENDING);
        }

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
                .kycDocumentUrl(profile.getKycDocumentUrl())
                .commissionRatePercentage(profile.getCommissionRatePercentage())
                .build();
    }
}
