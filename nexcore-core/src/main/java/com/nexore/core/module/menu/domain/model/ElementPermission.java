package com.nexore.core.module.menu.domain.model;

import lombok.Builder;
import lombok.Getter;

import java.time.OffsetDateTime;
import java.util.UUID;

@Getter
@Builder
public class ElementPermission {

    // profile fields (used by UserProfileService / UC-MNU-001)
    private final String elementKey;
    private final AccessLevel access;

    // management fields (used by PermissionService / UC-PRM-*)
    private final UUID id;
    private final UUID tenantId;
    private final UUID roleId;
    private final UUID elementId;
    private final UUID componentId;
    private final String label;
    private final String elementType;
    private final boolean inherited;
    private final OffsetDateTime createdAt;
    private final OffsetDateTime updatedAt;
    private final UUID createdBy;
    private final UUID updatedBy;
}
