package com.farm2route.auth.service;

import com.farm2route.auth.entity.OtpVerification;
import com.farm2route.auth.model.OtpPurpose;
import com.farm2route.auth.provider.OtpProvider;
import com.farm2route.auth.repository.OtpVerificationRepository;
import com.farm2route.common.exception.ExpiredOtpException;
import com.farm2route.common.exception.InvalidOtpException;
import com.farm2route.common.exception.RateLimitExceededException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class OtpServiceTest {

    @Mock
    private OtpVerificationRepository otpRepository;

    @Mock
    private OtpProvider otpProvider;

    private TokenService tokenService;
    private OtpService otpService;

    @BeforeEach
    void setUp() {
        tokenService = new TokenService();
        otpService = new OtpService(otpRepository, otpProvider, tokenService, 6, 5, 5, 3, 10);
    }

    @Test
    @DisplayName("Should generate secure 6-digit numeric OTP and hash before saving")
    void testGenerateAndSendOtp() {
        when(otpRepository.countRecentRequests(anyString(), any(), any())).thenReturn(0L);

        otpService.generateAndSendOtp("+94771234567", OtpPurpose.REGISTRATION, UUID.randomUUID());

        ArgumentCaptor<OtpVerification> captor = ArgumentCaptor.forClass(OtpVerification.class);
        verify(otpRepository).save(captor.capture());
        verify(otpProvider).sendOtp(eq("+94771234567"), anyString());

        OtpVerification saved = captor.getValue();
        assertEquals("+94771234567", saved.getPhoneNumber());
        assertEquals(OtpPurpose.REGISTRATION, saved.getPurpose());
        assertNotNull(saved.getOtpHash());
        assertEquals(64, saved.getOtpHash().length()); // SHA-256 hash
    }

    @Test
    @DisplayName("Should enforce OTP rate limit within window")
    void testRateLimitExceeded() {
        when(otpRepository.countRecentRequests(anyString(), any(), any())).thenReturn(3L);

        assertThrows(RateLimitExceededException.class, () ->
                otpService.generateAndSendOtp("+94771234567", OtpPurpose.REGISTRATION, UUID.randomUUID())
        );
    }

    @Test
    @DisplayName("Should verify valid OTP timing-safely and mark single-use verified")
    void testVerifyValidOtp() {
        String rawOtp = "654321";
        String otpHash = otpService.hashOtp(rawOtp);

        OtpVerification record = OtpVerification.builder()
                .phoneNumber("+94771234567")
                .otpHash(otpHash)
                .purpose(OtpPurpose.REGISTRATION)
                .expiresAt(Instant.now().plusSeconds(300))
                .attemptCount(0)
                .maxAttempts(5)
                .build();

        when(otpRepository.findLatestActiveOtp(eq("+94771234567"), eq(OtpPurpose.REGISTRATION), any()))
                .thenReturn(Optional.of(record));

        boolean verified = otpService.verifyOtp("+94771234567", rawOtp, OtpPurpose.REGISTRATION);

        assertTrue(verified);
        assertNotNull(record.getVerifiedAt());
        verify(otpRepository).save(record);
    }

    @Test
    @DisplayName("Should increment attempt count and reject invalid OTP")
    void testInvalidOtpIncrementsAttempt() {
        String rawOtp = "654321";
        String otpHash = otpService.hashOtp(rawOtp);

        OtpVerification record = OtpVerification.builder()
                .phoneNumber("+94771234567")
                .otpHash(otpHash)
                .purpose(OtpPurpose.REGISTRATION)
                .expiresAt(Instant.now().plusSeconds(300))
                .attemptCount(0)
                .maxAttempts(5)
                .build();

        when(otpRepository.findLatestActiveOtp(eq("+94771234567"), eq(OtpPurpose.REGISTRATION), any()))
                .thenReturn(Optional.of(record));

        assertThrows(InvalidOtpException.class, () ->
                otpService.verifyOtp("+94771234567", "000000", OtpPurpose.REGISTRATION)
        );

        assertEquals(1, record.getAttemptCount());
        verify(otpRepository).save(record);
    }

    @Test
    @DisplayName("Should reject expired OTP")
    void testExpiredOtp() {
        OtpVerification record = OtpVerification.builder()
                .phoneNumber("+94771234567")
                .otpHash("hash")
                .purpose(OtpPurpose.REGISTRATION)
                .expiresAt(Instant.now().minusSeconds(10))
                .attemptCount(0)
                .maxAttempts(5)
                .build();

        when(otpRepository.findLatestActiveOtp(eq("+94771234567"), eq(OtpPurpose.REGISTRATION), any()))
                .thenReturn(Optional.of(record));

        assertThrows(ExpiredOtpException.class, () ->
                otpService.verifyOtp("+94771234567", "123456", OtpPurpose.REGISTRATION)
        );
    }
}
