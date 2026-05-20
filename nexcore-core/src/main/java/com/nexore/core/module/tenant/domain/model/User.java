package com.nexore.core.module.tenant.domain.model;

import lombok.*;

import java.time.OffsetDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User {

    private UUID id;
    private UUID tenantId;
    private String username;
    private String email;
    private String passwordHash;
    private String fullName;
    private String phone;
    private String photoUrl;
    private String observaciones;
    private UserStatus status;
    private boolean isTenantAdmin;
    private boolean emailVerified;
    private OffsetDateTime emailVerifiedAt;
    private String totpSecret;
    private boolean totpEnabled;
    private String totpBackupCodes;
    private String temporalCode;
    private OffsetDateTime temporalCodeExpiresAt;
    private UUID invitedBy;
    private OffsetDateTime invitedAt;
    private OffsetDateTime activatedAt;
    private OffsetDateTime lastLoginAt;
    private String lastLoginIp;
    private OffsetDateTime createdAt;
    private OffsetDateTime updatedAt;
    private UUID createdBy;
    private UUID updatedBy;
    private OffsetDateTime deletedAt;
    private int version;
}
