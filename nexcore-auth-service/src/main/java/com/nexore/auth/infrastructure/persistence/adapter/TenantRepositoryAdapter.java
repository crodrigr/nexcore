package com.nexore.auth.infrastructure.persistence.adapter;

import com.nexore.auth.domain.model.Tenant;
import com.nexore.auth.domain.repository.TenantRepository;
import com.nexore.auth.infrastructure.persistence.jpa.TenantJpaRepository;
import com.nexore.auth.infrastructure.persistence.mapper.EntityMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Optional;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class TenantRepositoryAdapter implements TenantRepository {
    
    private final TenantJpaRepository jpaRepository;
    private final EntityMapper mapper;
    
    @Override
    public Optional<Tenant> findById(UUID tenantId) {
        return jpaRepository.findById(tenantId).map(mapper::toDomain);
    }
}
