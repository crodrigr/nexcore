package com.nexore.core.module.menu.domain.repository;

import com.nexore.core.module.menu.domain.model.Component;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ComponentRepository {
    Optional<Component> findByTenantAndId(UUID tenantId, UUID id);
    List<Component> findAllByTenant(UUID tenantId);
    List<Component> findPagedByTenant(UUID tenantId, String search, Boolean isSystem, int page, int size);
    long countByTenant(UUID tenantId, String search, Boolean isSystem);
}
