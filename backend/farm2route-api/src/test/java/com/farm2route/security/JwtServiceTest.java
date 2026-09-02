package com.farm2route.security;

import com.farm2route.auth.entity.User;
import com.farm2route.auth.model.Role;
import com.farm2route.auth.model.UserStatus;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class JwtServiceTest {

    @Mock
    private TokenBlacklistService tokenBlacklistService;

    private JwtKeyProvider jwtKeyProvider;
    private JwtService jwtService;

    private User sampleUser;
    private CustomUserPrincipal userPrincipal;

    @BeforeEach
    void setUp() {
        String testSecret = "404E635266556A586E3272357538782F413F4428472B4B6250645367566B5970";
        jwtKeyProvider = new JwtKeyProvider("test-key-2026", testSecret, "");
        jwtService = new JwtService(jwtKeyProvider, tokenBlacklistService, 15, 30, "farm2route-test");

        sampleUser = User.builder()
                .id(UUID.randomUUID())
                .phoneNumber("+94771234567")
                .email("farmer@test.com")
                .role(Role.FARMER)
                .status(UserStatus.ACTIVE)
                .phoneVerified(true)
                .build();

        userPrincipal = new CustomUserPrincipal(sampleUser);
    }

    @Test
    @DisplayName("Should generate valid JWT with kid and claims")
    void testGenerateAndValidateJwt() {
        when(tokenBlacklistService.isBlacklisted(anyString())).thenReturn(false);

        String token = jwtService.generateToken(sampleUser);
        assertNotNull(token);

        String extractedId = jwtService.extractUserId(token);
        assertEquals(sampleUser.getId().toString(), extractedId);

        String jti = jwtService.extractJti(token);
        assertNotNull(jti);

        assertTrue(jwtService.isTokenValid(token, userPrincipal));
    }

    @Test
    @DisplayName("Should reject blacklisted JWT")
    void testBlacklistedJwtRejected() {
        when(tokenBlacklistService.isBlacklisted(anyString())).thenReturn(true);

        String token = jwtService.generateToken(sampleUser);
        assertFalse(jwtService.isTokenValid(token, userPrincipal));
    }
}
