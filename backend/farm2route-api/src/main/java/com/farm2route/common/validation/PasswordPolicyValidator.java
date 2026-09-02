package com.farm2route.common.validation;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.util.Collections;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Component
public class PasswordPolicyValidator {

    private final int minLength;
    private final int maxLength;
    private final Set<String> weakPasswords;

    public PasswordPolicyValidator(
            @Value("${security.password.min-length:8}") int minLength,
            @Value("${security.password.max-length:128}") int maxLength,
            @Value("${security.password.weak-passwords:password,password123,12345678,qwerty123,admin123}") List<String> weakPasswords) {
        this.minLength = minLength;
        this.maxLength = maxLength;
        this.weakPasswords = weakPasswords != null
                ? weakPasswords.stream().map(String::toLowerCase).collect(Collectors.toSet())
                : Collections.emptySet();
    }

    public void validate(String password) {
        if (password == null || password.isBlank()) {
            throw new IllegalArgumentException("Password cannot be null or blank");
        }
        if (password.length() < minLength) {
            throw new IllegalArgumentException("Password must be at least " + minLength + " characters long");
        }
        if (password.length() > maxLength) {
            throw new IllegalArgumentException("Password must not exceed " + maxLength + " characters");
        }
        if (weakPasswords.contains(password.trim().toLowerCase())) {
            throw new IllegalArgumentException("Password is too common or easily guessable. Please choose a stronger password.");
        }
    }

    public boolean isValid(String password) {
        try {
            validate(password);
            return true;
        } catch (IllegalArgumentException e) {
            return false;
        }
    }
}
