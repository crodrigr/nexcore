package com.nexore.core.module.menu.domain.repository;

import com.nexore.core.module.menu.domain.model.ComponentPermission;

import java.util.List;
import java.util.UUID;

public interface ComponentPermissionRepository {
    ComponentPermission upsert(ComponentPermission permission);
    List<ComponentPermission> findByRoleId(UUID tenantId, UUID roleId);
    List<ComponentPermission> loadMatrix(UUID tenantId, UUID roleId);
}
