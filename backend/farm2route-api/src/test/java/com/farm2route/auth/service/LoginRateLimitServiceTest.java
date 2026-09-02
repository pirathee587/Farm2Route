package com.farm2route.auth.service;

import com.farm2route.common.exception.RateLimitExceededException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.redis.RedisConnectionFailureException;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class LoginRateLimitServiceTest {

    @Mock
    private StringRedisTemplate redisTemplate;

    @Mock
    private ValueOperations<String, String> valueOperations;

    private LoginRateLimitService rateLimitService;

    @BeforeEach
    void setUp() {
        rateLimitService = new LoginRateLimitService(redisTemplate, 5, 15);
    }

    @Test
    @DisplayName("Should allow request when attempts within limit")
    void testUnderLimitAllowed() {
        when(redisTemplate.opsForValue()).thenReturn(valueOperations);
        when(valueOperations.increment(anyString())).thenReturn(1L);

        assertDoesNotThrow(() -> rateLimitService.checkAndIncrement("127.0.0.1", "+94771234567"));
        verify(redisTemplate).expire(anyString(), any());
    }

    @Test
    @DisplayName("Should throw RateLimitExceededException when attempts exceed max limit")
    void testExceededLimitThrows() {
        when(redisTemplate.opsForValue()).thenReturn(valueOperations);
        when(valueOperations.increment(anyString())).thenReturn(6L);

        assertThrows(RateLimitExceededException.class,
                () -> rateLimitService.checkAndIncrement("127.0.0.1", "+94771234567"));
    }

    @Test
    @DisplayName("FAIL OPEN: Should allow request to proceed without error when Redis is down")
    void testFailOpenOnRedisOutage() {
        when(redisTemplate.opsForValue()).thenThrow(new RedisConnectionFailureException("Redis connection refused"));

        assertDoesNotThrow(() -> rateLimitService.checkAndIncrement("127.0.0.1", "+94771234567"));
    }
}
