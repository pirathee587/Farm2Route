package com.farm2route.security;

import com.farm2route.common.exception.ServiceUnavailableException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;

@Slf4j
@Service
public class TokenBlacklistService {

    private final StringRedisTemplate redisTemplate;
    private static final String BLACKLIST_PREFIX = "blacklist:";

    @org.springframework.beans.factory.annotation.Value("${security.jwt.blacklist-fail-closed:true}")
    private boolean failClosed = true;

    public TokenBlacklistService(StringRedisTemplate redisTemplate) {
        this.redisTemplate = redisTemplate;
    }

    public void blacklistToken(String jti, long remainingSeconds) {
        if (jti == null || remainingSeconds <= 0) {
            return;
        }
        try {
            redisTemplate.opsForValue().set(
                    BLACKLIST_PREFIX + jti,
                    "1",
                    Duration.ofSeconds(remainingSeconds)
            );
            log.info("Access token with jti {} successfully blacklisted in Redis for {}s", jti, remainingSeconds);
        } catch (Exception ex) {
            log.error("REDIS_BLACKLIST_SET_FAILED: Failed to blacklist token jti {} in Redis: {}", jti, ex.getMessage());
            // In fail-closed policy, log severe alert
        }
    }

    public boolean isBlacklisted(String jti) {
        if (jti == null) {
            return false;
        }
        try {
            Boolean hasKey = redisTemplate.hasKey(BLACKLIST_PREFIX + jti);
            return Boolean.TRUE.equals(hasKey);
        } catch (Exception ex) {
            log.error("REDIS_BLACKLIST_CHECK_FAILED: Cannot verify blacklist status for jti {} due to Redis error: {}",
                    jti, ex.getMessage());
            if (failClosed) {
                throw new ServiceUnavailableException("Authentication service temporarily unavailable");
            }
            return false;
        }
    }
}
