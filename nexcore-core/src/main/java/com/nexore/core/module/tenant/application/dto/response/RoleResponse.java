package com.nexore.core.module.tenant.application.dto.response;

import lombok.Builder;
import lombok.Data;

import java.time.OffsetDateTime;
import java.util.UUID;

@Data
@Builder
public class RoleResponse {
    private UUID id;
    private UUID tenantId;
    private String name;
    private String description;
    private boolean isSystemRole;
    private boolean isDefault;
    private long userCount;
    private OffsetDateTime createdAt;
    private OffsetDateTime updatedAt;
}
