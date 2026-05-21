package com.nexore.auth.domain.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.UUID;

/**
 * Registro de cada intento de autenticación para protección anti-fuerza-bruta
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LoginAttempt {
    
    private UUID id;
    private UUID userId;  // Puede ser null si el username no existe
    private UUID tenantId;
    private String username;
    private Boolean success;
    private String stage;  // CREDENTIALS, OTP
    private String ipAddress;
    private Instant attemptedAt;
}
