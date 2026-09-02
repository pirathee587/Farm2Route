package com.farm2route.farmer.service;

import com.farm2route.auth.entity.User;
import com.farm2route.auth.repository.UserRepository;
import com.farm2route.common.exception.ResourceNotFoundException;
import com.farm2route.farmer.dto.FarmerProfileDto;
import com.farm2route.farmer.entity.FarmerProfile;
import com.farm2route.farmer.repository.FarmerProfileRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class FarmerService {

    private final FarmerProfileRepository farmerProfileRepository;
    private final UserRepository userRepository;

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
}
