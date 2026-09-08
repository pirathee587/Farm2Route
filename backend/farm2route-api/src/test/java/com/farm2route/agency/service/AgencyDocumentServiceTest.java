package com.farm2route.agency.service;

import com.farm2route.agency.entity.AgencyProfile;
import com.farm2route.agency.repository.AgencyProfileRepository;
import com.farm2route.auth.repository.UserRepository;
import com.farm2route.auth.entity.User;
import com.farm2route.common.storage.SupabaseStorageService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AgencyDocumentServiceTest {
    @Mock AgencyProfileRepository agencyRepository;
    @Mock UserRepository userRepository;
    @Mock SupabaseStorageService storageService;
    @InjectMocks AgencyService agencyService;

    @Test
    void storesOpaquePrivatePathAndRequestsSignedUrlForOwnedAgency() throws Exception {
        UUID userId = UUID.randomUUID();
        AgencyProfile profile = AgencyProfile.builder().id(UUID.randomUUID()).user(User.builder().id(userId).build()).build();
        when(agencyRepository.findByUserId(userId)).thenReturn(Optional.of(profile));
        when(storageService.uploadPrivateFile(eq(SupabaseStorageService.BUCKET_KYC_DOCUMENTS), anyString(), any()))
                .thenReturn("agencies/" + profile.getId() + "/opaque.pdf");
        when(agencyRepository.save(profile)).thenReturn(profile);
        MockMultipartFile file = new MockMultipartFile("file", "../../secret.pdf", "application/pdf", "pdf".getBytes());

        agencyService.uploadKycDocument(userId, file);
        assertThat(profile.getKycDocumentUrl()).doesNotContain("/storage/v1/object/public/");
        verify(storageService).uploadPrivateFile(eq(SupabaseStorageService.BUCKET_KYC_DOCUMENTS),
                eq("agencies/" + profile.getId()), eq(file));

        when(storageService.createSignedUrl(SupabaseStorageService.BUCKET_KYC_DOCUMENTS,
                profile.getKycDocumentUrl(), 300)).thenReturn("signed-url");
        assertThat(agencyService.getKycDocumentUrl(userId)).isEqualTo("signed-url");
    }

    @Test
    void profileResponseOmitsPrivateStoragePath() {
        UUID userId = UUID.randomUUID();
        AgencyProfile profile = AgencyProfile.builder().id(UUID.randomUUID())
                .user(User.builder().id(userId).build())
                .companyName("Agency").businessRegistrationNumber("BR-1")
                .officeAddress("Address").district("District")
                .contactPersonName("Contact").contactPersonPhone("+94770000000")
                .kycDocumentUrl("agencies/private-document.pdf")
                .build();
        when(agencyRepository.findByUserId(userId)).thenReturn(Optional.of(profile));

        assertThat(agencyService.getProfileByUserId(userId).getKycDocumentUrl()).isNull();
    }
}
