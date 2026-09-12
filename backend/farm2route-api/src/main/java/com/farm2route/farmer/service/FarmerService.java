package com.farm2route.farmer.service;

import com.farm2route.auth.entity.User;
import com.farm2route.auth.model.OtpPurpose;
import com.farm2route.auth.model.Role;
import com.farm2route.auth.model.UserStatus;
import com.farm2route.auth.repository.UserRepository;
import com.farm2route.auth.service.OtpService;
import com.farm2route.common.event.FarmerRegisteredEvent;
import com.farm2route.common.exception.DuplicatePhoneException;
import com.farm2route.common.exception.ExpiredOtpException;
import com.farm2route.common.exception.InvalidOtpException;
import com.farm2route.common.exception.OtpExpiredException;
import com.farm2route.common.exception.OtpMismatchException;
import com.farm2route.common.exception.ResourceNotFoundException;
import com.farm2route.farmer.dto.*;
import com.farm2route.farmer.entity.Farmer;
import com.farm2route.farmer.entity.FarmerProfile;
import com.farm2route.farmer.enums.CropType;
import com.farm2route.farmer.enums.FarmerStatus;
import com.farm2route.farmer.enums.PreferredLanguage;
import com.farm2route.farmer.repository.FarmerProfileRepository;
import com.farm2route.farmer.repository.FarmerRepository;
import com.farm2route.security.JwtService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashSet;
import java.util.Set;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class FarmerService {

    private final FarmerProfileRepository farmerProfileRepository;
    private final UserRepository userRepository;
    private final FarmerRepository farmerRepository;
    private final OtpService otpService;
    private final JwtService jwtService;
    private final ApplicationEventPublisher applicationEventPublisher;
    private final PasswordEncoder passwordEncoder;

    @Transactional
    public FarmerOtpResponse requestOtp(FarmerOtpRequest request) {
        String phoneNumber = request.getPhoneNumber();
        if (farmerRepository.existsByPhoneNumber(phoneNumber)) {
            throw new DuplicatePhoneException("Farmer with phone number " + phoneNumber + " already exists");
        }

        otpService.generateAndSendOtp(phoneNumber, OtpPurpose.REGISTRATION, null);

        return FarmerOtpResponse.builder()
                .phoneNumber(phoneNumber)
                .message("OTP sent successfully to " + phoneNumber)
                .build();
    }

    @Transactional
    public FarmerResponse verifyAndSignup(FarmerVerifyRequest request) {
        String phoneNumber = request.getPhoneNumber();
        if (farmerRepository.existsByPhoneNumber(phoneNumber)) {
            throw new DuplicatePhoneException("Farmer with phone number " + phoneNumber + " already exists");
        }

        // Verify OTP code
        try {
            otpService.verifyOtp(phoneNumber, request.getOtp(), OtpPurpose.REGISTRATION);
        } catch (ExpiredOtpException ex) {
            throw new OtpExpiredException("OTP has expired. Please request a new verification code.");
        } catch (InvalidOtpException ex) {
            throw new OtpMismatchException("Invalid OTP code. " + ex.getMessage());
        }

        PreferredLanguage lang = request.getPreferredLanguage() != null
                ? request.getPreferredLanguage()
                : PreferredLanguage.TA;

        Set<CropType> crops = request.getPrimaryCrops() != null
                ? new HashSet<>(request.getPrimaryCrops())
                : new HashSet<>();

        Farmer farmer = Farmer.builder()
                .fullName(request.getFullName())
                .nicNumber(request.getNicNumber())
                .phoneNumber(phoneNumber)
                .email(request.getEmail())
                .district(request.getDistrict())
                .gnDivision(request.getGnDivision())
                .address(request.getAddress())
                .latitude(request.getLatitude())
                .longitude(request.getLongitude())
                .farmSizeAcres(request.getFarmSizeAcres())
                .primaryCrops(crops)
                .preferredLanguage(lang)
                .bankAccountNumber(request.getBankAccountNumber())
                .mobileWalletNumber(request.getMobileWalletNumber())
                .phoneVerified(true)
                .status(FarmerStatus.ACTIVE)
                .build();

        farmer = farmerRepository.save(farmer);

        // Provision/synchronize User identity for Spring Security
        User user = userRepository.findByPhoneNumber(phoneNumber)
                .orElseGet(() -> User.builder()
                        .phoneNumber(phoneNumber)
                        .passwordHash(passwordEncoder.encode(UUID.randomUUID().toString()))
                        .role(Role.FARMER)
                        .build());
        user.setPhoneVerified(true);
        user.setStatus(UserStatus.ACTIVE);
        if (request.getEmail() != null && !request.getEmail().isBlank()) {
            user.setEmail(request.getEmail());
        }
        user = userRepository.save(user);

        // Publish Spring Domain Event (relayed to RabbitMQ AFTER_COMMIT)
        applicationEventPublisher.publishEvent(
                FarmerRegisteredEvent.builder()
                        .farmerId(farmer.getId())
                        .fullName(farmer.getFullName())
                        .phoneNumber(farmer.getPhoneNumber())
                        .district(farmer.getDistrict())
                        .preferredLanguage(farmer.getPreferredLanguage())
                        .primaryCrops(farmer.getPrimaryCrops())
                        .build()
        );

        // Generate JWT token with FARMER authority for immediate login
        String token = jwtService.generateToken(user.getId(), Role.FARMER.name(), phoneNumber);

        return mapToFarmerResponse(farmer, token);
    }

    @Transactional(readOnly = true)
    public FarmerProfileDto getProfileByUserId(UUID userId) {
        FarmerProfile profile = farmerProfileRepository.findByUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Farmer profile not found for user ID: " + userId));
        return mapToDto(profile);
    }

    @Transactional
    public FarmerProfileDto updateProfile(UUID userId, FarmerProfileDto dto) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userId));

        FarmerProfile profile = farmerProfileRepository.findByUserId(userId)
                .orElse(FarmerProfile.builder().user(user).build());

        profile.setFarmName(dto.getFarmName());
        profile.setAddress(dto.getAddress());
        profile.setDistrict(dto.getDistrict());
        profile.setProvince(dto.getProvince());
        profile.setLatitude(dto.getLatitude());
        profile.setLongitude(dto.getLongitude());
        profile.setFarmSizeHectares(dto.getFarmSizeHectares());

        profile = farmerProfileRepository.save(profile);
        return mapToDto(profile);
    }

    private FarmerProfileDto mapToDto(FarmerProfile profile) {
        return FarmerProfileDto.builder()
                .id(profile.getId())
                .userId(profile.getUser().getId())
                .farmName(profile.getFarmName())
                .address(profile.getAddress())
                .district(profile.getDistrict())
                .province(profile.getProvince())
                .latitude(profile.getLatitude())
                .longitude(profile.getLongitude())
                .farmSizeHectares(profile.getFarmSizeHectares())
                .build();
    }

    private FarmerResponse mapToFarmerResponse(Farmer farmer, String token) {
        return FarmerResponse.builder()
                .id(farmer.getId())
                .fullName(farmer.getFullName())
                .phoneNumber(farmer.getPhoneNumber())
                .email(farmer.getEmail())
                .district(farmer.getDistrict())
                .gnDivision(farmer.getGnDivision())
                .address(farmer.getAddress())
                .latitude(farmer.getLatitude())
                .longitude(farmer.getLongitude())
                .farmSizeAcres(farmer.getFarmSizeAcres())
                .primaryCrops(farmer.getPrimaryCrops())
                .preferredLanguage(farmer.getPreferredLanguage())
                .phoneVerified(farmer.isPhoneVerified())
                .status(farmer.getStatus())
                .token(token)
                .tokenType("Bearer")
                .createdAt(farmer.getCreatedAt())
                .updatedAt(farmer.getUpdatedAt())
                .build();
    }
}
