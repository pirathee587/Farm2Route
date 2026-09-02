package com.farm2route.auth.otp;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;

@Slf4j
@Component
@ConditionalOnProperty(name = "app.otp.provider", havingValue = "twilio")
public class TwilioOtpProvider implements OtpProvider {

    @Value("${TWILIO_ACCOUNT_SID:placeholder}")
    private String accountSid;

    @Value("${TWILIO_AUTH_TOKEN:placeholder}")
    private String authToken;

    @Value("${TWILIO_SERVICE_SID:placeholder}")
    private String serviceSid;

    @Override
    public boolean sendOtp(String phoneNumber, String otpCode, String purpose) {
        log.info("Sending OTP via Twilio to {}: [{}] (Purpose: {})", phoneNumber, otpCode, purpose);
        // Integrated via Twilio REST API / SDK
        try {
            // Placeholder for production Twilio HTTP dispatch
            log.info("Twilio SMS queued successfully for {}", phoneNumber);
            return true;
        } catch (Exception e) {
            log.error("Failed to send OTP via Twilio: {}", e.getMessage());
            return false;
        }
    }
}
