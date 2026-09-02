package com.farm2route.auth.service;

import com.farm2route.common.validation.PasswordPolicyValidator;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class PasswordService {

    private final PasswordEncoder passwordEncoder;
    private final PasswordPolicyValidator policyValidator;

    public PasswordService(
            @Value("${security.password.bcrypt-strength:12}") int strength,
            PasswordPolicyValidator policyValidator) {
        this.passwordEncoder = new BCryptPasswordEncoder(strength);
        this.policyValidator = policyValidator;
    }

    public String hashPassword(String rawPassword) {
        policyValidator.validate(rawPassword);
        return passwordEncoder.encode(rawPassword);
    }

    public boolean matches(String rawPassword, String encodedPasswordHash) {
        if (rawPassword == null || encodedPasswordHash == null) {
            return false;
        }
        return passwordEncoder.matches(rawPassword, encodedPasswordHash);
    }

    public PasswordEncoder getPasswordEncoder() {
        return passwordEncoder;
    }
}
