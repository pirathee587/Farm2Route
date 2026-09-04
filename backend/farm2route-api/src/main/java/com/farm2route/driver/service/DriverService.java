package com.farm2route.driver.service;

import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.agency.repository.AgencyProfileRepository;
import com.farm2route.auth.entity.User;
import com.farm2route.auth.model.Role;
import com.farm2route.auth.model.UserStatus;
import com.farm2route.auth.repository.UserRepository;
import com.farm2route.auth.service.PasswordService;
import com.farm2route.common.enums.DriverAvailability;
import com.farm2route.common.enums.KycStatus;
import com.farm2route.common.exception.ConflictException;
import com.farm2route.common.exception.ResourceNotFoundException;
import com.farm2route.common.storage.SupabaseStorageService;
import com.farm2route.driver.dto.DriverProfileDto;
import com.farm2route.driver.dto.RegisterDriverRequest;
import com.farm2route.driver.dto.UpdateDriverKycRequest;
import com.farm2route.driver.dto.UpdateDriverRequest;
import com.farm2route.driver.entity.DriverProfile;
import com.farm2route.driver.repository.DriverProfileRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class DriverService {

    private final DriverProfileRepository driverProfileRepository;
    private final AgencyProfileRepository agencyProfileRepository;
    private final UserRepository userRepository;
    private final PasswordService passwordService;
    private final SupabaseStorageService supabaseStorageService;

    @Transactional(readOnly = true)
    public DriverProfileDto getProfileByUserId(UUID userId) {
        DriverProfile profile = driverProfileRepository.findByUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Driver profile not found for user ID: " + userId));
        return mapToDto(profile);
    }

    @Transactional(readOnly = true)
    public List<DriverProfileDto> getDriversByAgency(UUID agencyId) {
        return driverProfileRepository.findByAgencyId(agencyId).stream()
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public DriverProfileDto updateAvailability(UUID userId, DriverAvailability availability) {
        DriverProfile profile = driverProfileRepository.findByUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Driver profile not found for user ID: " + userId));
        profile.setAvailabilityStatus(availability);
        profile = driverProfileRepository.save(profile);
        return mapToDto(profile);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Agency-Scoped Driver Management
    // ─────────────────────────────────────────────────────────────────────────

    @Transactional
    public DriverProfileDto registerDriver(UUID agencyUserId, RegisterDriverRequest request) {
        AgencyProfile agency = agencyProfileRepository.findByUserId(agencyUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Agency profile not found for user: " + agencyUserId));

        if (driverProfileRepository.existsByDrivingLicenseNumber(request.getDrivingLicenseNumber())) {
            throw new ConflictException("Driving license number already registered: " + request.getDrivingLicenseNumber());
        }

        if (driverProfileRepository.existsByNicNumber(request.getNicNumber())) {
            throw new ConflictException("NIC number already registered: " + request.getNicNumber());
        }

        if (userRepository.existsByPhoneNumber(request.getPhoneNumber())) {
            throw new ConflictException("User with this phone number already registered: " + request.getPhoneNumber());
        }

        if (request.getEmail() != null && !request.getEmail().isBlank() && userRepository.existsByEmail(request.getEmail())) {
            throw new ConflictException("User with this email address already registered: " + request.getEmail());
        }

        String rawPassword = request.getPassword() != null && !request.getPassword().isBlank()
                ? request.getPassword()
                : "Driver@123456";

        User user = User.builder()
                .fullName(request.getFullName())
                .phoneNumber(request.getPhoneNumber())
                .email(request.getEmail())
                .role(Role.DRIVER)
                .status(UserStatus.ACTIVE)
                .passwordHash(passwordService.encodePassword(rawPassword))
                .build();

        user = userRepository.save(user);

        DriverProfile profile = DriverProfile.builder()
                .user(user)
                .agency(agency)
                .drivingLicenseNumber(request.getDrivingLicenseNumber())
                .licenseExpiryDate(request.getLicenseExpiryDate())
                .nicNumber(request.getNicNumber())
                .kycStatus(KycStatus.PENDING)
                .kycDocumentUrl(request.getKycDocumentUrl())
                .availabilityStatus(DriverAvailability.AVAILABLE)
                .build();

        profile = driverProfileRepository.save(profile);
        log.info("Registered new driver profile id={} for agencyId={}", profile.getId(), agency.getId());
        return mapToDto(profile);
    }

    @Transactional(readOnly = true)
    public List<DriverProfileDto> getAgencyDrivers(UUID agencyUserId) {
        AgencyProfile agency = agencyProfileRepository.findByUserId(agencyUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Agency profile not found for user: " + agencyUserId));

        return driverProfileRepository.findByAgencyId(agency.getId()).stream()
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<DriverProfileDto> getAvailableAgencyDrivers(UUID agencyUserId) {
        AgencyProfile agency = agencyProfileRepository.findByUserId(agencyUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Agency profile not found for user: " + agencyUserId));

        return driverProfileRepository.findByAgencyIdAndAvailabilityStatus(agency.getId(), DriverAvailability.AVAILABLE).stream()
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public DriverProfileDto getDriverById(UUID driverId, UUID agencyUserId) {
        AgencyProfile agency = agencyProfileRepository.findByUserId(agencyUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Agency profile not found for user: " + agencyUserId));

        DriverProfile profile = driverProfileRepository.findByIdAndAgencyId(driverId, agency.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Driver not found with id: " + driverId));

        return mapToDto(profile);
    }

    @Transactional
    public DriverProfileDto updateDriver(UUID driverId, UUID agencyUserId, UpdateDriverRequest request) {
        AgencyProfile agency = agencyProfileRepository.findByUserId(agencyUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Agency profile not found for user: " + agencyUserId));

        DriverProfile profile = driverProfileRepository.findByIdAndAgencyId(driverId, agency.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Driver not found with id: " + driverId));

        if (request.getDrivingLicenseNumber() != null && !request.getDrivingLicenseNumber().equals(profile.getDrivingLicenseNumber())) {
            if (driverProfileRepository.existsByDrivingLicenseNumberAndIdNot(request.getDrivingLicenseNumber(), driverId)) {
                throw new ConflictException("Driving license number already registered: " + request.getDrivingLicenseNumber());
            }
            profile.setDrivingLicenseNumber(request.getDrivingLicenseNumber());
        }

        if (request.getNicNumber() != null && !request.getNicNumber().equals(profile.getNicNumber())) {
            if (driverProfileRepository.existsByNicNumberAndIdNot(request.getNicNumber(), driverId)) {
                throw new ConflictException("NIC number already registered: " + request.getNicNumber());
            }
            profile.setNicNumber(request.getNicNumber());
        }

        if (request.getLicenseExpiryDate() != null) {
            profile.setLicenseExpiryDate(request.getLicenseExpiryDate());
        }

        if (request.getAvailabilityStatus() != null) {
            profile.setAvailabilityStatus(request.getAvailabilityStatus());
        }

        if (request.getFullName() != null && !request.getFullName().isBlank()) {
            profile.getUser().setFullName(request.getFullName());
            userRepository.save(profile.getUser());
        }

        profile = driverProfileRepository.save(profile);
        log.info("Updated driver profile id={} for agencyId={}", driverId, agency.getId());
        return mapToDto(profile);
    }

    @Transactional
    public void deleteDriver(UUID driverId, UUID agencyUserId) {
        AgencyProfile agency = agencyProfileRepository.findByUserId(agencyUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Agency profile not found for user: " + agencyUserId));

        DriverProfile profile = driverProfileRepository.findByIdAndAgencyId(driverId, agency.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Driver not found with id: " + driverId));

        driverProfileRepository.delete(profile);
        log.info("Deleted driver profile id={} for agencyId={}", driverId, agency.getId());
    }

    @Transactional
    public DriverProfileDto updateDriverKyc(UUID driverId, UUID agencyUserId, UpdateDriverKycRequest request) {
        AgencyProfile agency = agencyProfileRepository.findByUserId(agencyUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Agency profile not found for user: " + agencyUserId));

        DriverProfile profile = driverProfileRepository.findByIdAndAgencyId(driverId, agency.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Driver not found with id: " + driverId));

        if (request.getKycStatus() != null) {
            profile.setKycStatus(request.getKycStatus());
            if (request.getKycStatus() == KycStatus.APPROVED) {
                profile.setVerifiedAt(Instant.now());
            }
        }

        if (request.getKycDocumentUrl() != null) {
            profile.setKycDocumentUrl(request.getKycDocumentUrl());
        }

        if (request.getRejectionReason() != null) {
            profile.setKycRejectionReason(request.getRejectionReason());
        }

        profile = driverProfileRepository.save(profile);
        log.info("Updated KYC status for driver id={} to {}", driverId, profile.getKycStatus());
        return mapToDto(profile);
    }

    @Transactional
    public DriverProfileDto uploadDriverKycDocument(UUID driverId, UUID agencyUserId, MultipartFile file) throws IOException {
        AgencyProfile agency = agencyProfileRepository.findByUserId(agencyUserId)
                .orElseThrow(() -> new ResourceNotFoundException("Agency profile not found for user: " + agencyUserId));

        DriverProfile profile = driverProfileRepository.findByIdAndAgencyId(driverId, agency.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Driver not found with id: " + driverId));

        String documentUrl = supabaseStorageService.uploadFile(
                SupabaseStorageService.BUCKET_KYC_DOCUMENTS,
                "drivers/" + driverId,
                file
        );

        profile.setKycDocumentUrl(documentUrl);
        profile.setKycStatus(KycStatus.PENDING);
        profile = driverProfileRepository.save(profile);
        log.info("Uploaded KYC document for driver id={}", driverId);
        return mapToDto(profile);
    }

    private DriverProfileDto mapToDto(DriverProfile profile) {
        return DriverProfileDto.builder()
                .id(profile.getId())
                .userId(profile.getUser() != null ? profile.getUser().getId() : null)
                .agencyId(profile.getAgency() != null ? profile.getAgency().getId() : null)
                .fullName(profile.getUser() != null ? profile.getUser().getFullName() : null)
                .email(profile.getUser() != null ? profile.getUser().getEmail() : null)
                .phoneNumber(profile.getUser() != null ? profile.getUser().getPhoneNumber() : null)
                .drivingLicenseNumber(profile.getDrivingLicenseNumber())
                .licenseExpiryDate(profile.getLicenseExpiryDate())
                .nicNumber(profile.getNicNumber())
                .kycStatus(profile.getKycStatus())
                .kycDocumentUrl(profile.getKycDocumentUrl())
                .kycRejectionReason(profile.getKycRejectionReason())
                .availabilityStatus(profile.getAvailabilityStatus())
                .ratingAverage(profile.getRatingAverage())
                .totalRatingsCount(profile.getTotalRatingsCount())
                .verifiedAt(profile.getVerifiedAt())
                .createdAt(profile.getCreatedAt())
                .updatedAt(profile.getUpdatedAt())
                .build();
    }
}
