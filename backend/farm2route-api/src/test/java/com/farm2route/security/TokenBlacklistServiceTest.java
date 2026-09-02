package com.farm2route.security;

import com.farm2route.common.exception.ServiceUnavailableException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.redis.RedisConnectionFailureException;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;

import java.time.Duration;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class TokenBlacklistServiceTest {

    @Mock
    private StringRedisTemplate redisTemplate;

    @Mock
    private ValueOperations<String, String> valueOperations;

    private TokenBlacklistService blacklistService;

    @BeforeEach
    void setUp() {
        blacklistService = new TokenBlacklistService(redisTemplate);
    }

    @Test
    @DisplayName("Should successfully blacklist JTI in Redis with TTL")
    void testBlacklistToken() {
        when(redisTemplate.opsForValue()).thenReturn(valueOperations);

        blacklistService.blacklistToken("test-jti-123", 900);

        verify(valueOperations).set(eq("blacklist:test-jti-123"), eq("1"), eq(Duration.ofSeconds(900)));
    }

    @Test
    @DisplayName("Should return true when token is blacklisted in Redis")
    void testIsBlacklistedTrue() {
        when(redisTemplate.hasKey("blacklist:test-jti-123")).thenReturn(true);

        assertTrue(blacklistService.isBlacklisted("test-jti-123"));
    }

    @Test
    @DisplayName("FAIL CLOSED: Should throw ServiceUnavailableException when Redis is down during blacklist check")
    void testFailClosedOnRedisOutage() {
        when(redisTemplate.hasKey(anyString())).thenThrow(new RedisConnectionFailureException("Redis connection refused"));

        ServiceUnavailableException ex = assertThrows(ServiceUnavailableException.class,
                () -> blacklistService.isBlacklisted("test-jti-123"));

        assertEquals("Authentication service temporarily unavailable", ex.getMessage());
    }
}
