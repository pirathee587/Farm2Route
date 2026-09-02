package com.farm2route.auth.provider;

import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@ConditionalOnProperty(name = "security.otp.provider", havingValue = "mock", matchIfMissing = true)
public class MockOtpProvider implements OtpProvider {

    @Override
    public void sendOtp(String phoneNumber, String otp) {
        log.info("[MOCK OTP] Sent verification code to {}: {}", phoneNumber, otp);
    }
}
