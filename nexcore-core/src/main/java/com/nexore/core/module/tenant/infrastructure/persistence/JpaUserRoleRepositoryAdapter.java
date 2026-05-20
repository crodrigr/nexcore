package com.nexore.core.module.tenant.infrastructure.persistence;

import com.nexore.core.module.tenant.domain.model.UserRole;
import com.nexore.core.module.tenant.domain.repository.UserRoleRepository;
import com.nexore.core.module.tenant.infrastructure.persistence.jpa.SpringDataUserRoleRepository;
import com.nexore.core.module.tenant.infrastructure.persistence.mapper.UserRolePersistenceMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Repository
@RequiredArgsConstructor
public class JpaUserRoleRepositoryAdapter implements UserRoleRepository {

    private final SpringDataUserRoleRepository delegate;
    private final UserRolePersistenceMapper mapper;

    @Override
    public UserRole save(UserRole userRole) {
        return mapper.toDomain(delegate.save(mapper.toEntity(userRole)));
    }

    @Override
    public List<UserRole> findByTenantIdAndUserId(UUID tenantId, UUID userId) {
        return delegate.findByTenantIdAndUserId(tenantId, userId).stream().map(mapper::toDomain).toList();
    }

    @Override
    public List<UserRole> findByTenantIdAndRoleId(UUID tenantId, UUID roleId) {
        return delegate.findByTenantIdAndRoleId(tenantId, roleId).stream().map(mapper::toDomain).toList();
    }

    @Override
    @Transactional
    public void deleteByTenantIdAndUserId(UUID tenantId, UUID userId) {
        delegate.deleteByTenantIdAndUserId(tenantId, userId);
    }

    @Override
    public boolean existsActiveTenantAdminRole(UUID tenantId, UUID roleId) {
        return delegate.existsActiveTenantAdminRole(tenantId, roleId);
    }
}
