package com.farm2route.auth;

import com.farm2route.auth.entity.OtpVerification;
import com.farm2route.auth.otp.OtpProvider;
import com.farm2route.auth.repository.OtpVerificationRepository;
import com.farm2route.auth.service.OtpService;
import com.farm2route.common.exception.BadRequestException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

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

    @InjectMocks
    private OtpService otpService;

    @BeforeEach
    void setUp() {
        ReflectionTestUtils.setField(otpService, "otpLength", 6);
        ReflectionTestUtils.setField(otpService, "expirationMinutes", 5);
        ReflectionTestUtils.setField(otpService, "maxAttempts", 5);
        ReflectionTestUtils.setField(otpService, "rateLimitSeconds", 60);
    }

    @Test
    @DisplayName("Should successfully generate and dispatch OTP when not rate limited")
    void generateAndSendOtp_Success() {
        when(otpRepository.findLatestByPhoneAndPurpose(anyString(), anyString())).thenReturn(Optional.empty());
        when(otpRepository.save(any(OtpVerification.class))).thenAnswer(i -> i.getArgument(0));
        when(otpProvider.sendOtp(anyString(), anyString(), anyString())).thenReturn(true);

        assertDoesNotThrow(() -> otpService.generateAndSendOtp("+94771234567", "REGISTRATION"));

        verify(otpRepository, times(1)).save(any(OtpVerification.class));
        verify(otpProvider, times(1)).sendOtp(eq("+94771234567"), anyString(), eq("REGISTRATION"));
    }

    @Test
    @DisplayName("Should enforce rate limiting when requesting OTP too quickly")
    void generateAndSendOtp_RateLimited_ThrowsException() {
        OtpVerification recentOtp = OtpVerification.builder()
                .phoneNumber("+94771234567")
                .purpose("REGISTRATION")
                .createdAt(Instant.now().minusSeconds(10)) // 10 seconds ago (under 60s)
                .build();

        when(otpRepository.findLatestByPhoneAndPurpose("+94771234567", "REGISTRATION"))
                .thenReturn(Optional.of(recentOtp));

        assertThrows(BadRequestException.class, () -> otpService.generateAndSendOtp("+94771234567", "REGISTRATION"));
        verify(otpRepository, never()).save(any(OtpVerification.class));
    }

    @Test
    @DisplayName("Should verify valid OTP successfully")
    void verifyOtp_Valid_Success() {
        OtpVerification activeOtp = OtpVerification.builder()
                .id(UUID.randomUUID())
                .phoneNumber("+94771234567")
                .otpCode("847291")
                .purpose("REGISTRATION")
                .attempts(0)
                .maxAttempts(5)
                .isVerified(false)
                .expiresAt(Instant.now().plusSeconds(300))
                .build();

        when(otpRepository.findLatestActiveOtp(eq("+94771234567"), eq("REGISTRATION"), any(Instant.class)))
                .thenReturn(Optional.of(activeOtp));

        boolean verified = otpService.verifyOtp("+94771234567", "847291", "REGISTRATION");

        assertTrue(verified);
        assertTrue(activeOtp.isVerified());
        assertNotNull(activeOtp.getVerifiedAt());
        verify(otpRepository, times(1)).save(activeOtp);
    }

    @Test
    @DisplayName("Should reject invalid OTP and increment attempt count")
    void verifyOtp_InvalidCode_ThrowsException() {
        OtpVerification activeOtp = OtpVerification.builder()
                .id(UUID.randomUUID())
                .phoneNumber("+94771234567")
                .otpCode("847291")
                .purpose("REGISTRATION")
                .attempts(1)
                .maxAttempts(5)
                .isVerified(false)
                .expiresAt(Instant.now().plusSeconds(300))
                .build();

        when(otpRepository.findLatestActiveOtp(eq("+94771234567"), eq("REGISTRATION"), any(Instant.class)))
                .thenReturn(Optional.of(activeOtp));

        BadRequestException exception = assertThrows(BadRequestException.class,
                () -> otpService.verifyOtp("+94771234567", "000000", "REGISTRATION"));

        assertTrue(exception.getMessage().contains("Invalid OTP"));
        assertEquals(2, activeOtp.getAttempts());
        verify(otpRepository, times(1)).save(activeOtp);
    }
}
