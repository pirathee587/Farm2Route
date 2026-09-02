package com.farm2route.auth.service;

import com.farm2route.auth.entity.RefreshToken;
import com.farm2route.auth.entity.User;
import com.farm2route.auth.repository.RefreshTokenRepository;
import com.farm2route.common.exception.UnauthorizedException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;

@Slf4j
@Service
@RequiredArgsConstructor
public class RefreshTokenService {

    private final RefreshTokenRepository refreshTokenRepository;
    private final TokenService tokenService;

    @Value("${app.jwt.refresh-expiration-ms:604800000}")
    private long refreshExpirationMs;

    @Transactional
    public String createRefreshToken(User user, String clientIp) {
        String rawToken = tokenService.generateSecureToken(32);
        String tokenHash = tokenService.hashToken(rawToken);

        RefreshToken refreshToken = RefreshToken.builder()
                .user(user)
                .tokenHash(tokenHash)
                .expiresAt(Instant.now().plusMillis(refreshExpirationMs))
                .revoked(false)
                .createdByIp(clientIp)
                .build();

        refreshTokenRepository.save(refreshToken);
        return rawToken;
    }

    @Transactional
    public RefreshToken verifyAndRotate(String rawRefreshToken, String clientIp) {
        String tokenHash = tokenService.hashToken(rawRefreshToken);
        RefreshToken token = refreshTokenRepository.findByTokenHash(tokenHash)
                .orElseThrow(() -> new UnauthorizedException("Invalid refresh token"));

        if (token.isRevoked()) {
            log.warn("Attempted reuse of revoked refresh token for user {}", token.getUser().getId());
            // Possible token theft: revoke all tokens for this user
            refreshTokenRepository.revokeAllUserTokens(token.getUser(), Instant.now());
            throw new UnauthorizedException("Revoked refresh token used. Please login again.");
        }

        if (token.isExpired()) {
            token.setRevoked(true);
            token.setRevokedAt(Instant.now());
            refreshTokenRepository.save(token);
            throw new UnauthorizedException("Refresh token has expired. Please login again.");
        }

        // Revoke the old token (Token Rotation)
        token.setRevoked(true);
        token.setRevokedAt(Instant.now());
        refreshTokenRepository.save(token);

        return token;
    }

    @Transactional
    public void revokeToken(String rawRefreshToken) {
        String tokenHash = tokenService.hashToken(rawRefreshToken);
        refreshTokenRepository.findByTokenHash(tokenHash).ifPresent(token -> {
            token.setRevoked(true);
            token.setRevokedAt(Instant.now());
            refreshTokenRepository.save(token);
        });
    }

    @Transactional
    public void revokeAllUserTokens(User user) {
        refreshTokenRepository.revokeAllUserTokens(user, Instant.now());
    }
}
