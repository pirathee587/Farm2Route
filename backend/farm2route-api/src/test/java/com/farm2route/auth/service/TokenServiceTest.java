package com.farm2route.auth.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class TokenServiceTest {

    private TokenService tokenService;

    @BeforeEach
    void setUp() {
        tokenService = new TokenService();
    }

    @Test
    @DisplayName("Should generate cryptographically random token string")
    void testGenerateSecureRandomToken() {
        String token1 = tokenService.generateSecureRandomToken(32);
        String token2 = tokenService.generateSecureRandomToken(32);

        assertNotNull(token1);
        assertNotNull(token2);
        assertNotEquals(token1, token2);
        assertTrue(token1.length() >= 32);
    }

    @Test
    @DisplayName("Should deterministically hash token using SHA-256")
    void testHashToken() {
        String raw = "sample-token-string";
        String hash1 = tokenService.hashToken(raw);
        String hash2 = tokenService.hashToken(raw);

        assertNotNull(hash1);
        assertEquals(hash1, hash2);
        assertEquals(64, hash1.length()); // SHA-256 hex length
    }
}
