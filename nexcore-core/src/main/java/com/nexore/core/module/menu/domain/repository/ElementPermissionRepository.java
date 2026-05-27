package com.nexore.core.module.menu.domain.repository;

import com.nexore.core.module.menu.domain.model.ElementPermission;

public interface ElementPermissionRepository {
    ElementPermission upsert(ElementPermission permission);
}
