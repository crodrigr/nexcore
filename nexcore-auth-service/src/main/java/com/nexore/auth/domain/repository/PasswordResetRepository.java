package com.nexore.auth.domain.repository;

import com.nexore.auth.domain.model.PasswordReset;

import java.util.Optional;
import java.util.UUID;

/**
 * Repositorio para gestionar tokens de reset de contraseña
 */
public interface PasswordResetRepository {
    
    PasswordReset save(PasswordReset passwordReset);
    
    Optional<PasswordReset> findByTokenHash(String tokenHash);
    
    void invalidateAllByUserId(UUID userId);
    
    long countResetRequestsByUserSinceLastHour(UUID userId);
}
