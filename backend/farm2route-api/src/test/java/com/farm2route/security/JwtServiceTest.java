package com.farm2route.security;

import com.farm2route.auth.entity.User;
import com.farm2route.common.enums.Role;
import com.farm2route.common.enums.UserStatus;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class JwtServiceTest {

    @Mock
    private TokenBlacklistService tokenBlacklistService;

    private JwtService jwtService;
    private User sampleUser;

    private static final String TEST_SECRET = "404E635266556A586E3272357538782F413F4428472B4B6250645367566B5970";

    @BeforeEach
    void setUp() {
        jwtService = new JwtService(TEST_SECRET, 900000L, tokenBlacklistService);

        sampleUser = User.builder()
                .id(UUID.randomUUID())
                .phoneNumber("+94779876543")
                .email("user@farm2route.com")
                .fullName("Sunil Bandara")
                .role(Role.FARMER)
                .status(UserStatus.ACTIVE)
                .build();
    }

    @Test
    @DisplayName("Should generate valid JWT token with claims and extract username")
    void generateAndValidateToken() {
        String token = jwtService.generateToken(sampleUser);

        assertNotNull(token);
        String extractedSubject = jwtService.extractUsername(token);
        assertEquals("+94779876543", extractedSubject);

        UserDetails userPrincipal = new UserPrincipal(sampleUser);
        when(tokenBlacklistService.isBlacklisted(token)).thenReturn(false);

        boolean isValid = jwtService.isTokenValid(token, userPrincipal);
        assertTrue(isValid);
    }

    @Test
    @DisplayName("Should reject token when blacklisted")
    void isTokenValid_Blacklisted_ReturnsFalse() {
        String token = jwtService.generateToken(sampleUser);
        UserDetails userPrincipal = new UserPrincipal(sampleUser);
        when(tokenBlacklistService.isBlacklisted(token)).thenReturn(true);

        boolean isValid = jwtService.isTokenValid(token, userPrincipal);
        assertFalse(isValid);
    }
}
