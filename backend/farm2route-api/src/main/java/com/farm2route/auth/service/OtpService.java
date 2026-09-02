package com.farm2route.auth.service;

import com.farm2route.auth.entity.OtpVerification;
import com.farm2route.auth.otp.OtpProvider;
import com.farm2route.auth.repository.OtpVerificationRepository;
import com.farm2route.common.exception.BadRequestException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.Optional;

@Slf4j
@Service
@RequiredArgsConstructor
public class OtpService {

    private final OtpVerificationRepository otpRepository;
    private final OtpProvider otpProvider;

    @Value("${app.otp.length:6}")
    private int otpLength;

    @Value("${app.otp.expiration-minutes:5}")
    private int expirationMinutes;

    @Value("${app.otp.max-attempts:5}")
    private int maxAttempts;

    @Value("${app.otp.rate-limit-seconds:60}")
    private int rateLimitSeconds;

    private final SecureRandom secureRandom = new SecureRandom();

    @Transactional
    public void generateAndSendOtp(String phoneNumber, String purpose) {
        // Rate limiting check
        Optional<OtpVerification> latestOtp = otpRepository.findLatestByPhoneAndPurpose(phoneNumber, purpose);
        if (latestOtp.isPresent()) {
            Instant createdAt = latestOtp.get().getCreatedAt();
            long secondsSinceLast = Duration.between(createdAt, Instant.now()).getSeconds();
            if (secondsSinceLast < rateLimitSeconds) {
                throw new BadRequestException("Please wait " + (rateLimitSeconds - secondsSinceLast) + " seconds before requesting a new OTP.");
            }
        }

        String otpCode = generateNumericOtp(otpLength);
        Instant expiresAt = Instant.now().plus(Duration.ofMinutes(expirationMinutes));

        OtpVerification otp = OtpVerification.builder()
                .phoneNumber(phoneNumber)
                .otpCode(otpCode)
                .purpose(purpose)
                .attempts(0)
                .maxAttempts(maxAttempts)
                .isVerified(false)
                .expiresAt(expiresAt)
                .build();

        otpRepository.save(otp);

        boolean sent = otpProvider.sendOtp(phoneNumber, otpCode, purpose);
        if (!sent) {
            log.error("Failed to deliver OTP to {}", phoneNumber);
        }
    }

    @Transactional
    public boolean verifyOtp(String phoneNumber, String otpCode, String purpose) {
        OtpVerification otp = otpRepository.findLatestActiveOtp(phoneNumber, purpose, Instant.now())
                .orElseThrow(() -> new BadRequestException("No active OTP found or OTP expired. Please request a new one."));

        if (otp.getAttempts() >= otp.getMaxAttempts()) {
            throw new BadRequestException("Maximum verification attempts exceeded. Please request a new OTP.");
        }

        otp.setAttempts(otp.getAttempts() + 1);

        if (!otp.getOtpCode().equals(otpCode.trim())) {
            otpRepository.save(otp);
            throw new BadRequestException("Invalid OTP code. " + (otp.getMaxAttempts() - otp.getAttempts()) + " attempts remaining.");
        }

        otp.setVerified(true);
        otp.setVerifiedAt(Instant.now());
        otpRepository.save(otp);
        return true;
    }

    private String generateNumericOtp(int length) {
        StringBuilder sb = new StringBuilder(length);
        for (int i = 0; i < length; i++) {
            sb.append(secureRandom.nextInt(10));
        }
        return sb.toString();
    }
}
