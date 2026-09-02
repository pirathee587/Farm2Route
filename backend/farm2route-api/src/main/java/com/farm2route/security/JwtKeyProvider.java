package com.farm2route.security;

import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;

@Slf4j
@Component
public class JwtKeyProvider {

    private final String activeKeyId;
    private final SecretKey activeKey;
    private final Map<String, SecretKey> keyRing = new HashMap<>();

    public JwtKeyProvider(
            @Value("${security.jwt.active-key-id:farm2route-key-2026-01}") String activeKeyId,
            @Value("${security.jwt.active-secret}") String activeSecret,
            @Value("${security.jwt.previous-keys:}") String previousKeys) {
        this.activeKeyId = activeKeyId;
        this.activeKey = buildSecretKey(activeSecret);
        this.keyRing.put(activeKeyId, activeKey);

        if (previousKeys != null && !previousKeys.isBlank()) {
            String[] entries = previousKeys.split(",");
            for (String entry : entries) {
                String[] parts = entry.split(":");
                if (parts.length == 2) {
                    String kid = parts[0].trim();
                    String secret = parts[1].trim();
                    keyRing.put(kid, buildSecretKey(secret));
                    log.info("Registered historical verification JWT key: {}", kid);
                }
            }
        }
    }

    public SecretKey getActiveKey() {
        return activeKey;
    }

    public String getActiveKeyId() {
        return activeKeyId;
    }

    public SecretKey getKeyById(String kid) {
        if (kid == null || kid.isBlank()) {
            // Default to active key if kid is omitted in legacy tokens
            return activeKey;
        }
        SecretKey key = keyRing.get(kid);
        if (key == null) {
            log.warn("Unknown or unverified JWT key ID (kid): {}", kid);
            throw new JwtException("Unknown or invalid JWT key ID: " + kid);
        }
        return key;
    }

    private SecretKey buildSecretKey(String secret) {
        byte[] keyBytes;
        try {
            keyBytes = Decoders.BASE64.decode(secret);
            if (keyBytes.length < 32) {
                keyBytes = secret.getBytes(StandardCharsets.UTF_8);
            }
        } catch (Exception e) {
            keyBytes = secret.getBytes(StandardCharsets.UTF_8);
        }
        return Keys.hmacShaKeyFor(keyBytes);
    }
}
