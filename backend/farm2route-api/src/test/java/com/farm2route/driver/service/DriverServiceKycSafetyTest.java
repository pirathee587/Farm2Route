package com.farm2route.driver.service;

import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.agency.repository.AgencyProfileRepository;
import com.farm2route.auth.entity.User;
import com.farm2route.auth.model.UserStatus;
import com.farm2route.auth.repository.UserRepository;
import com.farm2route.auth.service.PasswordService;
import com.farm2route.common.enums.KycStatus;
import com.farm2route.common.exception.ForbiddenException;
import com.farm2route.common.storage.SupabaseStorageService;
import com.farm2route.driver.dto.RegisterDriverRequest;
import com.farm2route.driver.dto.UpdateDriverKycRequest;
import com.farm2route.driver.entity.DriverProfile;
import com.farm2route.driver.repository.DriverProfileRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class DriverServiceKycSafetyTest {
    @Mock DriverProfileRepository driverProfileRepository;
    @Mock AgencyProfileRepository agencyProfileRepository;
    @Mock UserRepository userRepository;
    @Mock PasswordService passwordService;
    @Mock SupabaseStorageService supabaseStorageService;
    @InjectMocks DriverService driverService;

    @Test
    void agencyCanSubmitPendingKycButCannotDecideIt() {
        UUID driverId = UUID.randomUUID();
        UUID agencyUserId = UUID.randomUUID();
        AgencyProfile agency = AgencyProfile.builder().id(UUID.randomUUID()).build();
        DriverProfile profile = DriverProfile.builder().id(driverId).agency(agency).kycStatus(KycStatus.PENDING).build();
        when(agencyProfileRepository.findByUserId(agencyUserId)).thenReturn(Optional.of(agency));
        when(driverProfileRepository.findByIdAndAgencyId(driverId, agency.getId())).thenReturn(Optional.of(profile));
        when(driverProfileRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        driverService.updateDriverKyc(driverId, agencyUserId,
                UpdateDriverKycRequest.builder().kycStatus(KycStatus.PENDING).build());
        assertThat(profile.getKycStatus()).isEqualTo(KycStatus.PENDING);

        for (KycStatus unsafe : new KycStatus[]{KycStatus.APPROVED, KycStatus.REJECTED, KycStatus.SUSPENDED}) {
            assertThatThrownBy(() -> driverService.updateDriverKyc(driverId, agencyUserId,
                    UpdateDriverKycRequest.builder().kycStatus(unsafe).build()))
                    .isInstanceOf(ForbiddenException.class);
        }
    }

    @Test
    void registeringDriverKeepsUserActiveWhileProfileKycIsPending() {
        UUID agencyUserId = UUID.randomUUID();
        AgencyProfile agency = AgencyProfile.builder().id(UUID.randomUUID()).build();
        when(agencyProfileRepository.findByUserId(agencyUserId)).thenReturn(Optional.of(agency));
        when(passwordService.hashPassword(any())).thenReturn("hashed");
        when(userRepository.save(any(User.class))).thenAnswer(i -> {
            User user = i.getArgument(0);
            user.setId(UUID.randomUUID());
            return user;
        });
        when(driverProfileRepository.save(any(DriverProfile.class))).thenAnswer(i -> {
            DriverProfile profile = i.getArgument(0);
            profile.setId(UUID.randomUUID());
            return profile;
        });
        RegisterDriverRequest request = RegisterDriverRequest.builder().fullName("Driver One")
                .phoneNumber("+94771234567").drivingLicenseNumber("DL-1")
                .licenseExpiryDate(LocalDate.now().plusYears(1)).nicNumber("NIC-1").build();

        driverService.registerDriver(agencyUserId, request);

        ArgumentCaptor<User> userCaptor = ArgumentCaptor.forClass(User.class);
        verify(userRepository).save(userCaptor.capture());
        assertThat(userCaptor.getValue().getStatus()).isEqualTo(UserStatus.ACTIVE);
        ArgumentCaptor<DriverProfile> profileCaptor = ArgumentCaptor.forClass(DriverProfile.class);
        verify(driverProfileRepository).save(profileCaptor.capture());
        assertThat(profileCaptor.getValue().getKycStatus()).isEqualTo(KycStatus.PENDING);
    }

    @Test
    void profileResponseOmitsPrivateStoragePath() {
        UUID userId = UUID.randomUUID();
        DriverProfile profile = DriverProfile.builder().id(UUID.randomUUID())
                .user(User.builder().id(userId).build())
                .kycDocumentUrl("drivers/private-document.pdf")
                .build();
        when(driverProfileRepository.findByUserId(userId)).thenReturn(Optional.of(profile));

        assertThat(driverService.getProfileByUserId(userId).getKycDocumentUrl()).isNull();
    }
}
