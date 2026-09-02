package com.farm2route.security;

import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class TokenBlacklistService {

    // In-memory blacklist for invalidated JWT tokens (or backed by Redis in production cluster)
    private final Map<String, Instant> blacklistedTokens = new ConcurrentHashMap<>();

    public void blacklistToken(String token, Instant expirationTime) {
        blacklistedTokens.put(token, expirationTime);
    }

    public boolean isBlacklisted(String token) {
        Instant expiry = blacklistedTokens.get(token);
        if (expiry == null) {
            return false;
        }
        if (Instant.now().isAfter(expiry)) {
            blacklistedTokens.remove(token);
            return false;
        }
        return true;
    }

    public void purgeExpiredTokens() {
        Instant now = Instant.now();
        blacklistedTokens.entrySet().removeIf(entry -> now.isAfter(entry.getValue()));
    }
}
