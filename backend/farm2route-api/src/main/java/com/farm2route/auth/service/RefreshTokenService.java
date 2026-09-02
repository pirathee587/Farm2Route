package com.farm2route.auth.service;

import com.farm2route.auth.entity.RefreshToken;
import com.farm2route.auth.entity.User;
import com.farm2route.auth.repository.RefreshTokenRepository;
import com.farm2route.common.exception.InvalidRefreshTokenException;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class RefreshTokenService {

    private final RefreshTokenRepository refreshTokenRepository;
    private final TokenService tokenService;
    private final AuthenticationAuditService auditService;

    @Value("${security.jwt.refresh-token-expiration-ms:604800000}")
    private long refreshTokenExpirationMs;

    @Getter
    @RequiredArgsConstructor
    public static class CreatedToken {
        private final RefreshToken entity;
        private final String rawToken;
    }

    @Transactional
    public CreatedToken createRefreshToken(User user, String deviceInfo, String ipAddress) {
        String rawToken = tokenService.generateSecureRandomToken(32);
        String tokenHash = tokenService.hashToken(rawToken);
        UUID familyId = UUID.randomUUID();

        RefreshToken refreshToken = RefreshToken.builder()
                .user(user)
                .tokenHash(tokenHash)
                .familyId(familyId)
                .expiresAt(Instant.now().plus(Duration.ofMillis(refreshTokenExpirationMs)))
                .deviceInfo(deviceInfo)
                .ipAddress(ipAddress)
                .build();

        RefreshToken saved = refreshTokenRepository.save(refreshToken);
        return new CreatedToken(saved, rawToken);
    }

    @Transactional
    public CreatedToken verifyAndRotate(String rawRefreshToken, String deviceInfo, String ipAddress) {
        String tokenHash = tokenService.hashToken(rawRefreshToken);
        Instant now = Instant.now();

        RefreshToken token = refreshTokenRepository.findByTokenHashWithLock(tokenHash)
                .orElseThrow(() -> new InvalidRefreshTokenException("Invalid refresh token."));

        if (token.isRevoked()) {
            // Suspicious token reuse detected!
            log.error("SECURITY ALERT: Token reuse detected for user {} in family {}",
                    token.getUser().getId(), token.getFamilyId());
            auditService.logTokenReuseDetected(token.getUser().getId(), token.getFamilyId(), ipAddress);

            // Revoke all tokens belonging to this compromised token family
            refreshTokenRepository.revokeFamily(token.getFamilyId(), now);

            throw new InvalidRefreshTokenException("Suspicious refresh token reuse detected. Entire session invalidated.");
        }

        if (token.isExpired()) {
            throw new InvalidRefreshTokenException("Refresh token has expired. Please login again.");
        }

        // Mark old token revoked
        token.setRevokedAt(now);

        // Generate new token in the same family
        String newRawToken = tokenService.generateSecureRandomToken(32);
        String newTokenHash = tokenService.hashToken(newRawToken);

        RefreshToken newToken = RefreshToken.builder()
                .user(token.getUser())
                .tokenHash(newTokenHash)
                .familyId(token.getFamilyId())
                .expiresAt(now.plus(Duration.ofMillis(refreshTokenExpirationMs)))
                .deviceInfo(deviceInfo)
                .ipAddress(ipAddress)
                .build();

        RefreshToken savedNewToken = refreshTokenRepository.save(newToken);
        token.setReplacedByTokenId(savedNewToken.getId());
        refreshTokenRepository.save(token);

        auditService.logRefreshTokenRotated(token.getUser().getId(), token.getFamilyId(), ipAddress);
        return new CreatedToken(savedNewToken, newRawToken);
    }

    @Transactional
    public void revokeToken(String rawRefreshToken) {
        if (rawRefreshToken == null || rawRefreshToken.isBlank()) {
            return;
        }
        String tokenHash = tokenService.hashToken(rawRefreshToken);
        refreshTokenRepository.findByTokenHash(tokenHash).ifPresent(token -> {
            token.setRevokedAt(Instant.now());
            refreshTokenRepository.save(token);
            log.info("Refresh token revoked for user {}", token.getUser().getId());
        });
    }

    @Transactional
    public void revokeAllUserTokens(User user) {
        refreshTokenRepository.revokeAllUserTokens(user, Instant.now());
    }
}
