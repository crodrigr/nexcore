package com.nexore.core.module.menu.domain.repository;

import com.nexore.core.module.menu.domain.model.ComponentElement;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ComponentElementRepository {
    List<ComponentElement> findByComponent(UUID tenantId, UUID componentId);
    Optional<ComponentElement> findByTenantAndId(UUID tenantId, UUID elementId);
}
