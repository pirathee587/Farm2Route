package com.farm2route.auth.service;

import com.farm2route.auth.entity.RefreshToken;
import com.farm2route.auth.entity.User;
import com.farm2route.auth.model.Role;
import com.farm2route.auth.model.UserStatus;
import com.farm2route.auth.repository.RefreshTokenRepository;
import com.farm2route.common.exception.InvalidRefreshTokenException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class RefreshTokenServiceTest {

    @Mock
    private RefreshTokenRepository refreshTokenRepository;

    @Mock
    private AuthenticationAuditService auditService;

    private TokenService tokenService;
    private RefreshTokenService refreshTokenService;

    private User sampleUser;

    @BeforeEach
    void setUp() {
        tokenService = new TokenService();
        refreshTokenService = new RefreshTokenService(refreshTokenRepository, tokenService, auditService);
        ReflectionTestUtils.setField(refreshTokenService, "refreshTokenExpirationMs", 604800000L);

        sampleUser = User.builder()
                .id(UUID.randomUUID())
                .phoneNumber("+94771234567")
                .role(Role.FARMER)
                .status(UserStatus.ACTIVE)
                .build();
    }

    @Test
    @DisplayName("Should create refresh token with familyId and hash")
    void testCreateRefreshToken() {
        when(refreshTokenRepository.save(any(RefreshToken.class))).thenAnswer(i -> i.getArgument(0));

        RefreshTokenService.CreatedToken created = refreshTokenService.createRefreshToken(sampleUser, "Pixel 7", "127.0.0.1");

        assertNotNull(created.getRawToken());
        assertNotNull(created.getEntity());
        assertNotNull(created.getEntity().getFamilyId());
        assertEquals(64, created.getEntity().getTokenHash().length());
        verify(refreshTokenRepository).save(any(RefreshToken.class));
    }

    @Test
    @DisplayName("Should rotate active token and link replacedByTokenId within same familyId")
    void testVerifyAndRotateActiveToken() {
        String rawToken = "initial-raw-token-1234567890123456";
        String tokenHash = tokenService.hashToken(rawToken);
        UUID familyId = UUID.randomUUID();

        RefreshToken oldToken = RefreshToken.builder()
                .id(UUID.randomUUID())
                .user(sampleUser)
                .tokenHash(tokenHash)
                .familyId(familyId)
                .expiresAt(Instant.now().plusSeconds(3600))
                .build();

        when(refreshTokenRepository.findByTokenHashWithLock(eq(tokenHash))).thenReturn(Optional.of(oldToken));
        when(refreshTokenRepository.save(any(RefreshToken.class))).thenAnswer(i -> {
            RefreshToken t = i.getArgument(0);
            if (t.getId() == null) t.setId(UUID.randomUUID());
            return t;
        });

        RefreshTokenService.CreatedToken rotated = refreshTokenService.verifyAndRotate(rawToken, "Pixel 7", "127.0.0.1");

        assertNotNull(rotated.getRawToken());
        assertNotEquals(rawToken, rotated.getRawToken());
        assertEquals(familyId, rotated.getEntity().getFamilyId());
        assertNotNull(oldToken.getRevokedAt());
        assertNotNull(oldToken.getReplacedByTokenId());
        verify(auditService).logRefreshTokenRotated(eq(sampleUser.getId()), eq(familyId), anyString());
    }

    @Test
    @DisplayName("TOKEN REUSE DETECTION: Should revoke entire family when revoked token is used")
    void testTokenReuseDetection() {
        String rawToken = "compromised-raw-token";
        String tokenHash = tokenService.hashToken(rawToken);
        UUID familyId = UUID.randomUUID();

        RefreshToken revokedToken = RefreshToken.builder()
                .id(UUID.randomUUID())
                .user(sampleUser)
                .tokenHash(tokenHash)
                .familyId(familyId)
                .expiresAt(Instant.now().plusSeconds(3600))
                .revokedAt(Instant.now().minusSeconds(100))
                .build();

        when(refreshTokenRepository.findByTokenHashWithLock(eq(tokenHash))).thenReturn(Optional.of(revokedToken));

        InvalidRefreshTokenException ex = assertThrows(InvalidRefreshTokenException.class,
                () -> refreshTokenService.verifyAndRotate(rawToken, "Attacker Device", "192.168.1.100"));

        assertTrue(ex.getMessage().contains("reuse detected"));
        verify(refreshTokenRepository).revokeFamily(eq(familyId), any(Instant.class));
        verify(auditService).logTokenReuseDetected(eq(sampleUser.getId()), eq(familyId), anyString());
    }
}
