package com.farm2route.auth;

import com.farm2route.auth.service.TokenService;
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
    @DisplayName("Should generate non-null secure token of specified length")
    void generateSecureToken() {
        String token1 = tokenService.generateSecureToken(32);
        String token2 = tokenService.generateSecureToken(32);

        assertNotNull(token1);
        assertNotNull(token2);
        assertNotEquals(token1, token2);
        assertTrue(token1.length() >= 32);
    }

    @Test
    @DisplayName("Should hash token deterministically with SHA-256")
    void hashToken() {
        String raw = "sample-secret-token-12345";
        String hash1 = tokenService.hashToken(raw);
        String hash2 = tokenService.hashToken(raw);

        assertNotNull(hash1);
        assertEquals(64, hash1.length()); // SHA-256 is 64 hex characters
        assertEquals(hash1, hash2);
    }
}
