package com.nexore.auth.domain.repository;

import com.nexore.auth.domain.model.LoginAttempt;

import java.time.Instant;

/**
 * Repositorio para gestionar intentos de login
 */
public interface LoginAttemptRepository {
    
    LoginAttempt save(LoginAttempt loginAttempt);
    
    long countFailedAttemptsSince(java.util.UUID userId, Instant since);
    
    long countFailedAttemptsByIpSince(String ipAddress, Instant since);
}
