package com.nexore.core.module.tenant.infrastructure.persistence;

import com.nexore.core.module.tenant.domain.model.Role;
import com.nexore.core.module.tenant.domain.repository.RoleRepository;
import com.nexore.core.module.tenant.infrastructure.persistence.jpa.SpringDataRoleRepository;
import com.nexore.core.module.tenant.infrastructure.persistence.mapper.RolePersistenceMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
@RequiredArgsConstructor
public class JpaRoleRepositoryAdapter implements RoleRepository {

    private final SpringDataRoleRepository delegate;
    private final RolePersistenceMapper mapper;

    @Override
    public Role save(Role role) {
        return mapper.toDomain(delegate.save(mapper.toEntity(role)));
    }

    @Override
    public Optional<Role> findById(UUID id) {
        return delegate.findById(id).map(mapper::toDomain);
    }

    @Override
    public Optional<Role> findByTenantIdAndId(UUID tenantId, UUID id) {
        return delegate.findByTenantIdAndId(tenantId, id).map(mapper::toDomain);
    }

    @Override
    public Optional<Role> findByTenantIdAndName(UUID tenantId, String name) {
        return delegate.findByTenantIdAndName(tenantId, name).map(mapper::toDomain);
    }

    @Override
    public boolean existsByTenantIdAndNameAndDeletedAtIsNull(UUID tenantId, String name) {
        return delegate.existsByTenantIdAndNameAndDeletedAtIsNull(tenantId, name);
    }

    @Override
    public List<Role> findAllByTenantId(UUID tenantId) {
        return delegate.findAllByTenantId(tenantId).stream().map(mapper::toDomain).toList();
    }

    @Override
    public long countActiveUsersWithRole(UUID tenantId, UUID roleId) {
        return delegate.countActiveUsersWithRole(tenantId, roleId);
    }
}
