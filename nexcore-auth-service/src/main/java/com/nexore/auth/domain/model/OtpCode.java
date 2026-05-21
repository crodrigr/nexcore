package com.nexore.auth.domain.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.UUID;

/**
 * Código de un solo uso enviado por email para 2FA
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OtpCode {
    
    private UUID id;
    private UUID userId;
    private UUID tenantId;
    private String codeHash;
    private String purpose;  // LOGIN_2FA, PASSWORD_RESET
    private Instant expiresAt;
    private Instant usedAt;
    private Integer attempts;
    private Instant createdAt;
    
    // Campo transient para el código en texto plano (solo para enviar por email)
    private transient String plainCode;
}
