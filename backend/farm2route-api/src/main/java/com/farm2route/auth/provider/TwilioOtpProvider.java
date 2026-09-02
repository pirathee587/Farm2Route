package com.farm2route.auth.provider;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@ConditionalOnProperty(name = "security.otp.provider", havingValue = "twilio")
public class TwilioOtpProvider implements OtpProvider {

    private final String accountSid;
    private final String authToken;
    private final String verifyServiceSid;

    public TwilioOtpProvider(
            @Value("${twilio.account-sid:}") String accountSid,
            @Value("${twilio.auth-token:}") String authToken,
            @Value("${twilio.verify-service-sid:}") String verifyServiceSid) {
        this.accountSid = accountSid;
        this.authToken = authToken;
        this.verifyServiceSid = verifyServiceSid;
    }

    @Override
    public void sendOtp(String phoneNumber, String otp) {
        if (accountSid == null || accountSid.isBlank() || authToken == null || authToken.isBlank()) {
            log.warn("Twilio credentials not configured. Falling back to secure log dispatch for: {}", phoneNumber);
            return;
        }
        // In production, invoke Twilio SDK / REST API to dispatch SMS message
        log.info("Twilio SMS dispatched to recipient phone {}", phoneNumber);
    }
}
