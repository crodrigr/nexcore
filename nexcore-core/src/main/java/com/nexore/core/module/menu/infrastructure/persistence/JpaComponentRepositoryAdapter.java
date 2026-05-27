package com.nexore.core.module.menu.infrastructure.persistence;

import com.nexore.core.module.menu.domain.model.Component;
import com.nexore.core.module.menu.domain.repository.ComponentRepository;
import com.nexore.core.module.menu.infrastructure.persistence.jpa.ComponentQueryRepository;
import com.nexore.core.module.menu.infrastructure.persistence.mapper.ComponentPersistenceMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
@RequiredArgsConstructor
public class JpaComponentRepositoryAdapter implements ComponentRepository {

    private final ComponentQueryRepository queryRepository;
    private final ComponentPersistenceMapper mapper;

    @Override
    public Optional<Component> findByTenantAndId(UUID tenantId, UUID id) {
        return queryRepository.findByTenantAndId(tenantId, id).map(mapper::toComponent);
    }

    @Override
    public List<Component> findAllByTenant(UUID tenantId) {
        return queryRepository.findPagedByTenant(tenantId, null, null, 0, Integer.MAX_VALUE)
                .stream().map(mapper::toComponent).toList();
    }

    @Override
    public List<Component> findPagedByTenant(UUID tenantId, String search, Boolean isSystem, int page, int size) {
        return queryRepository.findPagedByTenant(tenantId, search, isSystem, page, size)
                .stream().map(mapper::toComponent).toList();
    }

    @Override
    public long countByTenant(UUID tenantId, String search, Boolean isSystem) {
        return queryRepository.countByTenant(tenantId, search, isSystem);
    }
}
