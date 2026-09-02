package com.farm2route.auth.service;

import com.farm2route.common.validation.PasswordPolicyValidator;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class PasswordServiceTest {

    private PasswordService passwordService;
    private PasswordPolicyValidator policyValidator;

    @BeforeEach
    void setUp() {
        policyValidator = new PasswordPolicyValidator(8, 128, List.of("password", "password123", "12345678", "admin123"));
        passwordService = new PasswordService(12, policyValidator);
    }

    @Test
    @DisplayName("Should hash password with BCrypt and verify successfully")
    void testHashAndMatchPassword() {
        String raw = "StrongSecret123!";
        String hash = passwordService.hashPassword(raw);

        assertNotNull(hash);
        assertTrue(hash.startsWith("$2a$12$") || hash.startsWith("$2b$12$"));
        assertTrue(passwordService.matches(raw, hash));
        assertFalse(passwordService.matches("WrongPassword", hash));
    }

    @Test
    @DisplayName("Should reject password shorter than 8 characters")
    void testShortPassword() {
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> passwordService.hashPassword("short1"));
        assertTrue(ex.getMessage().contains("at least 8 characters"));
    }

    @Test
    @DisplayName("Should reject common/weak passwords from blocklist")
    void testWeakPassword() {
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> passwordService.hashPassword("password123"));
        assertTrue(ex.getMessage().contains("too common"));
    }

    @Test
    @DisplayName("Should reject null or blank password")
    void testBlankPassword() {
        assertThrows(IllegalArgumentException.class, () -> passwordService.hashPassword(""));
        assertThrows(IllegalArgumentException.class, () -> passwordService.hashPassword(null));
    }
}
