package com.nexore.core.module.menu.infrastructure.persistence;

import com.nexore.core.module.menu.domain.model.ComponentElement;
import com.nexore.core.module.menu.domain.repository.ComponentElementRepository;
import com.nexore.core.module.menu.infrastructure.persistence.jpa.ComponentQueryRepository;
import com.nexore.core.module.menu.infrastructure.persistence.mapper.ComponentPersistenceMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
@RequiredArgsConstructor
public class JpaComponentElementRepositoryAdapter implements ComponentElementRepository {

    private final ComponentQueryRepository queryRepository;
    private final ComponentPersistenceMapper mapper;

    @Override
    public List<ComponentElement> findByComponent(UUID tenantId, UUID componentId) {
        return queryRepository.findByComponent(tenantId, componentId)
                .stream().map(mapper::toComponentElement).toList();
    }

    @Override
    public Optional<ComponentElement> findByTenantAndId(UUID tenantId, UUID elementId) {
        return queryRepository.findElementByTenantAndId(tenantId, elementId)
                .map(mapper::toComponentElement);
    }
}
