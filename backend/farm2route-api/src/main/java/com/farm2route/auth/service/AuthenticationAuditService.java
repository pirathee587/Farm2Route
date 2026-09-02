package com.farm2route.auth.service;

import com.farm2route.common.filter.RequestCorrelationFilter;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.UUID;

@Slf4j
@Service
public class AuthenticationAuditService {

    public void logUserRegistered(UUID userId, String phoneNumber, String role, String ipAddress) {
        logAuditEvent("USER_REGISTERED", userId, "role=" + role + ", phone=" + maskPhone(phoneNumber), ipAddress);
    }

    public void logLoginSuccess(UUID userId, String role, String ipAddress) {
        logAuditEvent("LOGIN_SUCCESS", userId, "role=" + role, ipAddress);
    }

    public void logLoginFailed(String identifier, String reason, String ipAddress) {
        logAuditEvent("LOGIN_FAILED", null, "identifier=" + maskPhone(identifier) + ", reason=" + reason, ipAddress);
    }

    public void logAccountLocked(UUID userId, String identifier, int durationMinutes, String ipAddress) {
        logAuditEvent("ACCOUNT_LOCKED", userId, "identifier=" + maskPhone(identifier) + ", lockDuration=" + durationMinutes + "m", ipAddress);
    }

    public void logOtpRequested(String phoneNumber, String purpose, String ipAddress) {
        logAuditEvent("OTP_REQUESTED", null, "phone=" + maskPhone(phoneNumber) + ", purpose=" + purpose, ipAddress);
    }

    public void logOtpVerified(UUID userId, String phoneNumber, String purpose, String ipAddress) {
        logAuditEvent("OTP_VERIFIED", userId, "phone=" + maskPhone(phoneNumber) + ", purpose=" + purpose, ipAddress);
    }

    public void logOtpFailed(String phoneNumber, String purpose, int attemptCount, String ipAddress) {
        logAuditEvent("OTP_FAILED", null, "phone=" + maskPhone(phoneNumber) + ", purpose=" + purpose + ", attempt=" + attemptCount, ipAddress);
    }

    public void logRefreshTokenRotated(UUID userId, UUID familyId, String ipAddress) {
        logAuditEvent("REFRESH_TOKEN_ROTATED", userId, "familyId=" + familyId, ipAddress);
    }

    public void logTokenReuseDetected(UUID userId, UUID familyId, String ipAddress) {
        logAuditEvent("TOKEN_REUSE_DETECTED", userId, "familyId=" + familyId, ipAddress);
    }

    public void logLogout(UUID userId, String ipAddress) {
        logAuditEvent("LOGOUT", userId, "status=revoked", ipAddress);
    }

    private void logAuditEvent(String eventType, UUID userId, String details, String ipAddress) {
        String requestId = RequestCorrelationFilter.getCorrelationId();
        log.info("[AUTH_AUDIT] event={} | requestId={} | userId={} | ip={} | timestamp={} | details=[{}]",
                eventType, requestId, (userId != null ? userId : "ANONYMOUS"), ipAddress, Instant.now(), details);
    }

    private String maskPhone(String phone) {
        if (phone == null || phone.length() < 4) return "***";
        return phone.substring(0, Math.min(3, phone.length())) + "****" + phone.substring(phone.length() - 2);
    }
}
