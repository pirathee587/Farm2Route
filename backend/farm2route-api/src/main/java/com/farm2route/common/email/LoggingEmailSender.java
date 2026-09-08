package com.farm2route.common.email;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

@Slf4j
@Component
public class LoggingEmailSender implements EmailSender {

    @Override
    public void sendVerificationEmail(String toEmail, String token, String agencyName) {
        log.info("[EmailSender] Verification email dispatched to: {} for agency: {} [token: {}]",
                toEmail, agencyName, token);
    }
}
