package com.nexore.auth.domain.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PasswordReset {
    private UUID id;
    private UUID userId;
    private UUID tenantId;
    private String tokenHash;
    private Instant expiresAt;
    private Instant usedAt;
    private String ipAddress;
    private Instant createdAt;
}
