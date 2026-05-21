package com.nexore.auth.domain.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.UUID;

/**
 * Representa una sesión activa de usuario
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Session {
    
    private UUID id;
    private UUID userId;
    private UUID tenantId;
    private String refreshTokenHash;
    private String ipAddress;
    private String userAgent;
    private Instant createdAt;
    private Instant expiresAt;
    private Instant revokedAt;
}
