package com.farm2route.auth.service;

import com.farm2route.common.exception.RateLimitExceededException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;

@Slf4j
@Service
public class LoginRateLimitService {

    private final StringRedisTemplate redisTemplate;
    private final int maxAttempts;
    private final int windowMinutes;

    private static final String KEY_PREFIX = "ratelimit:login:";

    public LoginRateLimitService(
            StringRedisTemplate redisTemplate,
            @Value("${security.rate-limit.login.max-attempts:5}") int maxAttempts,
            @Value("${security.rate-limit.login.window-minutes:15}") int windowMinutes) {
        this.redisTemplate = redisTemplate;
        this.maxAttempts = maxAttempts;
        this.windowMinutes = windowMinutes;
    }

    public void checkAndIncrement(String clientIp, String identifier) {
        String key = KEY_PREFIX + clientIp + ":" + (identifier != null ? identifier.trim() : "anonymous");
        try {
            Long count = redisTemplate.opsForValue().increment(key);
            if (count != null && count == 1) {
                redisTemplate.expire(key, Duration.ofMinutes(windowMinutes));
            }
            if (count != null && count > maxAttempts) {
                log.warn("LOGIN_RATE_LIMIT_EXCEEDED for IP {} and identifier {}", clientIp, identifier);
                throw new RateLimitExceededException("Too many login attempts. Please try again after " + windowMinutes + " minutes.");
            }
        } catch (RateLimitExceededException rle) {
            throw rle;
        } catch (Exception ex) {
            // FAIL OPEN POLICY: If Redis is unavailable, log warning and let request proceed
            log.warn("REDIS_RATE_LIMIT_CHECK_FAILED: Distributed rate limiter failed for login. Allowing request to proceed. Error: {}", ex.getMessage());
        }
    }

    public void reset(String clientIp, String identifier) {
        String key = KEY_PREFIX + clientIp + ":" + (identifier != null ? identifier.trim() : "anonymous");
        try {
            redisTemplate.delete(key);
        } catch (Exception ex) {
            log.warn("Failed to reset login rate limit in Redis: {}", ex.getMessage());
        }
    }
}
