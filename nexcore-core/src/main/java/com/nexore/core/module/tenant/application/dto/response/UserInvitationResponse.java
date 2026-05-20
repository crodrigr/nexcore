package com.nexore.core.module.tenant.application.dto.response;

import lombok.Builder;
import lombok.Data;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Data
@Builder
public class UserInvitationResponse {
    private UUID id;
    private UUID tenantId;
    private String email;
    private List<UUID> roleIds;
    private OffsetDateTime invitedAt;
    private OffsetDateTime expiresAt;
    private boolean revoked;
    private OffsetDateTime acceptedAt;
}
