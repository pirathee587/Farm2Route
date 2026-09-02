package com.farm2route.auth.service;

import com.farm2route.common.exception.RateLimitExceededException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;

@Slf4j
@Service
public class PasswordResetRateLimitService {

    private final StringRedisTemplate redisTemplate;
    private final int maxAttempts;
    private final int windowMinutes;

    private static final String KEY_PREFIX = "ratelimit:pwreset:";

    public PasswordResetRateLimitService(
            StringRedisTemplate redisTemplate,
            @Value("${security.rate-limit.password-reset.max-attempts:3}") int maxAttempts,
            @Value("${security.rate-limit.password-reset.window-minutes:10}") int windowMinutes) {
        this.redisTemplate = redisTemplate;
        this.maxAttempts = maxAttempts;
        this.windowMinutes = windowMinutes;
    }

    public void checkAndIncrement(String clientIp, String phoneNumber) {
        String key = KEY_PREFIX + clientIp + ":" + (phoneNumber != null ? phoneNumber.trim() : "anonymous");
        try {
            Long count = redisTemplate.opsForValue().increment(key);
            if (count != null && count == 1) {
                redisTemplate.expire(key, Duration.ofMinutes(windowMinutes));
            }
            if (count != null && count > maxAttempts) {
                log.warn("PASSWORD_RESET_RATE_LIMIT_EXCEEDED for IP {} and phone {}", clientIp, phoneNumber);
                throw new RateLimitExceededException("Too many password reset requests. Please try again after " + windowMinutes + " minutes.");
            }
        } catch (RateLimitExceededException rle) {
            throw rle;
        } catch (Exception ex) {
            // FAIL OPEN POLICY: Allow request to proceed on Redis outage with warning log
            log.warn("REDIS_RATE_LIMIT_CHECK_FAILED: Distributed rate limiter failed for password reset. Allowing request to proceed. Error: {}", ex.getMessage());
        }
    }
}
