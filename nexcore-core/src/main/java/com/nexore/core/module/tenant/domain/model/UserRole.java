package com.nexore.core.module.tenant.domain.model;

import lombok.*;

import java.time.OffsetDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserRole {

    private UUID id;
    private UUID tenantId;
    private UUID userId;
    private UUID roleId;
    private OffsetDateTime assignedAt;
    private UUID assignedBy;
    private OffsetDateTime expiresAt;
}
