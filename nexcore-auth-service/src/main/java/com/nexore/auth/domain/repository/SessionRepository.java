package com.nexore.auth.domain.repository;

import com.nexore.auth.domain.model.Session;

import java.util.Optional;
import java.util.UUID;

/**
 * Repositorio para gestionar sesiones de usuario
 */
public interface SessionRepository {
    
    Session save(Session session);
    
    Optional<Session> findById(UUID id);
    
    Optional<Session> findByRefreshTokenHash(String refreshTokenHash);
    
    void revokeAllByUserId(UUID userId);
    
    void revokeAllByUserIdExcept(UUID userId, UUID sessionId);
    
    void revokeById(UUID sessionId);
}
