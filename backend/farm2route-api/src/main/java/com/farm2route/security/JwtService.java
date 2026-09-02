package com.farm2route.security;

import com.farm2route.auth.entity.User;
import com.farm2route.common.exception.AuthenticationException;
import com.farm2route.common.exception.ServiceUnavailableException;
import io.jsonwebtoken.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;

@Slf4j
@Service
public class JwtService {

    private final JwtKeyProvider jwtKeyProvider;
    private final TokenBlacklistService tokenBlacklistService;
    private final long accessTokenMinutes;
    private final long clockSkewSeconds;
    private final String issuer;

    public static final String CLAIM_PURPOSE = "purpose";
    public static final String PURPOSE_PASSWORD_RESET = "PASSWORD_RESET";

    public JwtService(
            JwtKeyProvider jwtKeyProvider,
            TokenBlacklistService tokenBlacklistService,
            @Value("${security.jwt.access-token-minutes:15}") long accessTokenMinutes,
            @Value("${security.jwt.clock-skew-seconds:30}") long clockSkewSeconds,
            @Value("${security.jwt.issuer:farm2route}") String issuer) {
        this.jwtKeyProvider = jwtKeyProvider;
        this.tokenBlacklistService = tokenBlacklistService;
        this.accessTokenMinutes = accessTokenMinutes;
        this.clockSkewSeconds = Math.min(Math.max(clockSkewSeconds, 0), 60);
        this.issuer = issuer;
    }

    public String generateToken(User user) {
        Map<String, Object> extraClaims = new HashMap<>();
        String jti = UUID.randomUUID().toString();
        extraClaims.put("userId", user.getId().toString());
        extraClaims.put("role", user.getRole().name());
        extraClaims.put("phoneNumber", user.getPhoneNumber());

        Instant now = Instant.now();
        Instant expiry = now.plus(Duration.ofMinutes(accessTokenMinutes));

        return Jwts.builder()
                .header()
                .keyId(jwtKeyProvider.getActiveKeyId())
                .and()
                .claims(extraClaims)
                .id(jti)
                .subject(user.getId().toString())
                .issuer(issuer)
                .issuedAt(Date.from(now))
                .expiration(Date.from(expiry))
                .signWith(jwtKeyProvider.getActiveKey())
                .compact();
    }

    public String generatePasswordResetToken(User user) {
        Map<String, Object> extraClaims = new HashMap<>();
        String jti = UUID.randomUUID().toString();
        extraClaims.put("userId", user.getId().toString());
        extraClaims.put("phoneNumber", user.getPhoneNumber());
        extraClaims.put(CLAIM_PURPOSE, PURPOSE_PASSWORD_RESET);

        Instant now = Instant.now();
        Instant expiry = now.plus(Duration.ofMinutes(10)); // 10 minute reset window

        return Jwts.builder()
                .header()
                .keyId(jwtKeyProvider.getActiveKeyId())
                .and()
                .claims(extraClaims)
                .id(jti)
                .subject(user.getId().toString())
                .issuer(issuer)
                .issuedAt(Date.from(now))
                .expiration(Date.from(expiry))
                .signWith(jwtKeyProvider.getActiveKey())
                .compact();
    }

    public Claims validatePasswordResetToken(String token) {
        Claims claims = extractAllClaims(token);
        String jti = claims.getId();

        // Check if token was already used / blacklisted (Fail-Closed)
        if (jti != null && tokenBlacklistService.isBlacklisted(jti)) {
            log.warn("Password reset token with jti {} has already been used or blacklisted", jti);
            throw new AuthenticationException("Password reset token has already been used or is invalid.");
        }

        String purpose = claims.get(CLAIM_PURPOSE, String.class);
        if (!PURPOSE_PASSWORD_RESET.equals(purpose)) {
            log.warn("Token presented for password reset has invalid purpose: {}", purpose);
            throw new AuthenticationException("Invalid token purpose. Must be a password reset token.");
        }

        if (isTokenExpired(claims)) {
            throw new AuthenticationException("Password reset token has expired.");
        }

        return claims;
    }

    public boolean isTokenValid(String token, UserDetails userDetails) {
        try {
            Claims claims = extractAllClaims(token);
            String jti = claims.getId();

            // Ensure reset tokens cannot be used as normal access tokens!
            String purpose = claims.get(CLAIM_PURPOSE, String.class);
            if (PURPOSE_PASSWORD_RESET.equals(purpose)) {
                log.warn("Password reset token cannot be used as an API access token");
                return false;
            }

            // Fail-closed Redis blacklist check
            if (jti != null && tokenBlacklistService.isBlacklisted(jti)) {
                log.warn("Access token with jti {} is blacklisted", jti);
                return false;
            }

            String userId = claims.getSubject();
            if (userDetails instanceof CustomUserPrincipal principal) {
                return userId.equals(principal.getId().toString()) && !isTokenExpired(claims);
            }
            return !isTokenExpired(claims);
        } catch (ServiceUnavailableException sue) {
            throw sue;
        } catch (JwtException | IllegalArgumentException e) {
            log.debug("JWT validation failed: {}", e.getMessage());
            return false;
        }
    }

    public boolean isTokenExpired(Claims claims) {
        Date expiration = claims.getExpiration();
        if (expiration == null) {
            return true;
        }
        Instant expirationInstant = expiration.toInstant().plusSeconds(clockSkewSeconds);
        return Instant.now().isAfter(expirationInstant);
    }

    public String extractUserId(String token) {
        return extractClaim(token, Claims::getSubject);
    }

    public String extractJti(String token) {
        return extractClaim(token, Claims::getId);
    }

    public Date extractExpiration(String token) {
        return extractClaim(token, Claims::getExpiration);
    }

    public <T> T extractClaim(String token, Function<Claims, T> claimsResolver) {
        final Claims claims = extractAllClaims(token);
        return claimsResolver.apply(claims);
    }

    public Claims extractAllClaims(String token) {
        return Jwts.parser()
                .clockSkewSeconds(clockSkewSeconds)
                .keyLocator(header -> {
                    String kid = header instanceof JwsHeader ? ((JwsHeader) header).getKeyId() : null;
                    return jwtKeyProvider.getKeyById(kid);
                })
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    public long getAccessTokenExpirationMs() {
        return accessTokenMinutes * 60 * 1000L;
    }
}
