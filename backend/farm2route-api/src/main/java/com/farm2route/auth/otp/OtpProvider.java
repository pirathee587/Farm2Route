package com.farm2route.auth.otp;

public interface OtpProvider {
    /**
     * Sends an OTP to the given phone number.
     * @param phoneNumber Target phone number in E.164 format
     * @param otpCode 6-digit numeric OTP code
     * @param purpose Reason for sending OTP (REGISTRATION, LOGIN, etc.)
     * @return true if successfully dispatched
     */
    boolean sendOtp(String phoneNumber, String otpCode, String purpose);
}
