package com.farm2route.auth.otp;

import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@ConditionalOnProperty(name = "app.otp.provider", havingValue = "mock", matchIfMissing = true)
public class MockOtpProvider implements OtpProvider {

    @Override
    public boolean sendOtp(String phoneNumber, String otpCode, String purpose) {
        log.info("================================================================================");
        log.info("[MOCK OTP PROVIDER] Dispatching OTP for Phone: {}, Purpose: {}, Code: [{}]",
                phoneNumber, purpose, otpCode);
        log.info("================================================================================");
        return true;
    }
}
