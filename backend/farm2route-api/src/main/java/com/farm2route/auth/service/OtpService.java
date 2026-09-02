package com.farm2route.auth.service;

import com.farm2route.auth.entity.OtpVerification;
import com.farm2route.auth.model.OtpPurpose;
import com.farm2route.auth.provider.OtpProvider;
import com.farm2route.auth.repository.OtpVerificationRepository;
import com.farm2route.common.exception.ExpiredOtpException;
import com.farm2route.common.exception.InvalidOtpException;
import com.farm2route.common.exception.RateLimitExceededException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.UUID;

@Slf4j
@Service
public class OtpService {

    private final OtpVerificationRepository otpRepository;
    private final OtpProvider otpProvider;
    private final TokenService tokenService;
    private final int otpLength;
    private final int expiryMinutes;
    private final int maxAttempts;
    private final int maxRequests;
    private final int requestWindowMinutes;

    private final SecureRandom secureRandom = new SecureRandom();

    public OtpService(
            OtpVerificationRepository otpRepository,
            OtpProvider otpProvider,
            TokenService tokenService,
            @Value("${security.otp.length:6}") int otpLength,
            @Value("${security.otp.expiry-minutes:5}") int expiryMinutes,
            @Value("${security.otp.max-attempts:5}") int maxAttempts,
            @Value("${security.otp.max-requests:3}") int maxRequests,
            @Value("${security.otp.request-window-minutes:10}") int requestWindowMinutes) {
        this.otpRepository = otpRepository;
        this.otpProvider = otpProvider;
        this.tokenService = tokenService;
        this.otpLength = otpLength;
        this.expiryMinutes = expiryMinutes;
        this.maxAttempts = maxAttempts;
        this.maxRequests = maxRequests;
        this.requestWindowMinutes = requestWindowMinutes;
    }

    @Transactional
    public void generateAndSendOtp(String phoneNumber, OtpPurpose purpose, UUID userId) {
        Instant now = Instant.now();
        Instant windowStart = now.minus(Duration.ofMinutes(requestWindowMinutes));

        long recentCount = otpRepository.countRecentRequests(phoneNumber, purpose, windowStart);
        if (recentCount >= maxRequests) {
            log.warn("OTP rate limit exceeded for phone: {} purpose: {}", phoneNumber, purpose);
            throw new RateLimitExceededException("Too many OTP requests. Please wait " + requestWindowMinutes + " minutes.");
        }

        String rawOtp = generateSecureOtpCode(otpLength);
        String otpHash = hashOtp(rawOtp);

        OtpVerification verification = OtpVerification.builder()
                .userId(userId)
                .phoneNumber(phoneNumber)
                .otpHash(otpHash)
                .purpose(purpose)
                .expiresAt(now.plus(Duration.ofMinutes(expiryMinutes)))
                .maxAttempts(maxAttempts)
                .attemptCount(0)
                .build();

        otpRepository.save(verification);
        otpProvider.sendOtp(phoneNumber, rawOtp);
        log.info("OTP generated and dispatched for phone: {} [purpose: {}]", phoneNumber, purpose);
    }

    @Transactional
    public boolean verifyOtp(String phoneNumber, String submittedOtp, OtpPurpose purpose) {
        Instant now = Instant.now();

        OtpVerification verification = otpRepository.findLatestActiveOtp(phoneNumber, purpose, now)
                .orElseThrow(() -> new InvalidOtpException("No valid active OTP found for this phone number and purpose"));

        if (verification.isExpired()) {
            throw new ExpiredOtpException("OTP has expired. Please request a new verification code.");
        }

        if (verification.getAttemptCount() >= verification.getMaxAttempts()) {
            throw new InvalidOtpException("Maximum OTP verification attempts exceeded. Please request a new code.");
        }

        // Timing-safe comparison using MessageDigest.isEqual
        byte[] storedHashBytes = verification.getOtpHash().getBytes(StandardCharsets.UTF_8);
        byte[] submittedHashBytes = hashOtp(submittedOtp).getBytes(StandardCharsets.UTF_8);

        boolean isMatch = MessageDigest.isEqual(storedHashBytes, submittedHashBytes);

        if (!isMatch) {
            verification.setAttemptCount(verification.getAttemptCount() + 1);
            otpRepository.save(verification);
            log.warn("Failed OTP verification attempt {} of {} for phone: {}",
                    verification.getAttemptCount(), verification.getMaxAttempts(), phoneNumber);
            throw new InvalidOtpException("Invalid OTP code. " +
                    (verification.getMaxAttempts() - verification.getAttemptCount()) + " attempts remaining.");
        }

        // Mark single-use verified
        verification.setVerifiedAt(now);
        otpRepository.save(verification);
        log.info("OTP successfully verified for phone: {} [purpose: {}]", phoneNumber, purpose);
        return true;
    }

    public String generateSecureOtpCode(int length) {
        StringBuilder sb = new StringBuilder(length);
        for (int i = 0; i < length; i++) {
            sb.append(secureRandom.nextInt(10));
        }
        return sb.toString();
    }

    public String hashOtp(String rawOtp) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(rawOtp.getBytes(StandardCharsets.UTF_8));
            StringBuilder hexString = new StringBuilder();
            for (byte b : hash) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) hexString.append('0');
                hexString.append(hex);
            }
            return hexString.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("SHA-256 algorithm not available", e);
        }
    }
}
