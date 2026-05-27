package com.nexore.core.module.menu.domain.model;

import lombok.Builder;
import lombok.Getter;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Getter
@Builder
public class ComponentPermission {

    // profile fields (used by UserProfileService / UC-MNU-001)
    private final String component;
    private final String route;
    private final AccessLevel access;
    private final List<ElementPermission> elements;

    // management fields (used by PermissionService / UC-PRM-*)
    private final UUID id;
    private final UUID tenantId;
    private final UUID roleId;
    private final UUID componentId;
    private final String name;
    private final OffsetDateTime createdAt;
    private final OffsetDateTime updatedAt;
    private final UUID createdBy;
    private final UUID updatedBy;
}
