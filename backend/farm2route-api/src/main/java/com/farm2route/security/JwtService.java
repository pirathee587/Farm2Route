package com.farm2route.security;

import com.farm2route.auth.entity.User;
import com.farm2route.common.exception.ServiceUnavailableException;
import io.jsonwebtoken.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
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

    public boolean isTokenValid(String token, UserDetails userDetails) {
        try {
            Claims claims = extractAllClaims(token);
            String jti = claims.getId();

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
            // Propagate 503 fail-closed service unavailable
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
        // Apply clock-skew tolerance
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
        // Resolve header to find kid for signing key lookup
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
