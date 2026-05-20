package com.nexore.core.module.tenant.application.dto.response;

import com.nexore.core.module.tenant.domain.model.UserStatus;
import lombok.Builder;
import lombok.Data;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Data
@Builder
public class UserResponse {
    private UUID id;
    private UUID tenantId;
    private String username;
    private String email;
    private String fullName;
    private String phone;
    private String photoUrl;
    private UserStatus status;
    private boolean isTenantAdmin;
    private boolean emailVerified;
    private boolean totpEnabled;
    private OffsetDateTime invitedAt;
    private OffsetDateTime activatedAt;
    private OffsetDateTime lastLoginAt;
    private List<RoleSummary> roles;
    private OffsetDateTime createdAt;
    private OffsetDateTime updatedAt;
}
