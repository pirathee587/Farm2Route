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
            log.warn("REDIS_BLACKLIST_CHECK_UNAVAILABLE: Redis unavailable ({}), proceeding without blacklist check for jti {}",
                    ex.getMessage(), jti);
            return false;
        }
    }
}
