package com.farm2route.common.email;

public interface EmailSender {
    void sendVerificationEmail(String toEmail, String token, String agencyName);
}
