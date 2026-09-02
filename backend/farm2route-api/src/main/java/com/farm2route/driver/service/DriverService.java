package com.farm2route.driver.service;

import com.farm2route.common.enums.DriverAvailability;
import com.farm2route.common.exception.ResourceNotFoundException;
import com.farm2route.driver.dto.DriverProfileDto;
import com.farm2route.driver.entity.DriverProfile;
import com.farm2route.driver.repository.DriverProfileRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class DriverService {

    private final DriverProfileRepository driverProfileRepository;

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

    private DriverProfileDto mapToDto(DriverProfile profile) {
        return DriverProfileDto.builder()
                .id(profile.getId())
                .userId(profile.getUser().getId())
                .agencyId(profile.getAgency().getId())
                .drivingLicenseNumber(profile.getDrivingLicenseNumber())
                .licenseExpiryDate(profile.getLicenseExpiryDate())
                .nicNumber(profile.getNicNumber())
                .kycStatus(profile.getKycStatus())
                .kycDocumentUrl(profile.getKycDocumentUrl())
                .availabilityStatus(profile.getAvailabilityStatus())
                .ratingAverage(profile.getRatingAverage())
                .totalRatingsCount(profile.getTotalRatingsCount())
                .build();
    }
}
