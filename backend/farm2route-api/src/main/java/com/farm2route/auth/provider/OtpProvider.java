package com.farm2route.auth.provider;

public interface OtpProvider {
    void sendOtp(String phoneNumber, String otp);
}
