package com.nexore.auth.domain.service;

import com.nexore.auth.domain.repository.LoginAttemptRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@Service
@RequiredArgsConstructor
public class BruteForceProtection {
    
    private static final int MAX_ATTEMPTS = 10;
    private static final int WINDOW_MINUTES = 15;
    
    private final LoginAttemptRepository attemptRepository;
    private final ConcurrentHashMap<String, Integer> attemptCache = new ConcurrentHashMap<>();
    
    /**
     * Verifica si un usuario o IP ha excedido el límite de intentos
     */
    public void checkRateLimit(UUID userId, String ipAddress) {
        Instant windowStart = Instant.now().minus(Duration.ofMinutes(WINDOW_MINUTES));
        
        long attempts;
        if (userId != null) {
            attempts = attemptRepository.countFailedAttemptsSince(userId, windowStart);
        } else {
            attempts = attemptRepository.countFailedAttemptsByIpSince(ipAddress, windowStart);
        }
        
        if (attempts >= MAX_ATTEMPTS) {
            log.warn("Rate limit exceeded: userId={}, ipAddress={}, attempts={}", userId, ipAddress, attempts);
            throw new TooManyAttemptsException(
                    String.format("Too many failed login attempts. Please try again after %d minutes", WINDOW_MINUTES));
        }
    }
    
    /**
     * Registra un intento fallido
     */
    public void recordFailedAttempt(UUID userId, String ipAddress) {
        String key = buildCacheKey(userId, ipAddress);
        attemptCache.merge(key, 1, Integer::sum);
        log.debug("Failed attempt recorded: userId={}, ipAddress={}", userId, ipAddress);
    }
    
    /**
     * Resetea los intentos después de un login exitoso
     */
    public void resetAttempts(UUID userId, String ipAddress) {
        String key = buildCacheKey(userId, ipAddress);
        attemptCache.remove(key);
        log.debug("Attempts reset: userId={}, ipAddress={}", userId, ipAddress);
    }
    
    private String buildCacheKey(UUID userId, String ipAddress) {
        return (userId != null ? userId.toString() : "unknown") + ":" + ipAddress;
    }
    
    public static class TooManyAttemptsException extends RuntimeException {
        public TooManyAttemptsException(String message) {
            super(message);
        }
    }
}

