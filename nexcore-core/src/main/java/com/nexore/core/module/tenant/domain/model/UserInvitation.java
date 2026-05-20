package com.nexore.core.module.tenant.domain.model;

import lombok.*;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserInvitation {

    private UUID id;
    private UUID tenantId;
    private String email;
    private String tokenHash;
    private List<UUID> roleIds;
    private UUID invitedBy;
    private OffsetDateTime invitedAt;
    private OffsetDateTime expiresAt;
    private OffsetDateTime acceptedAt;
    private UUID userId;
    private boolean isRevoked;
}
