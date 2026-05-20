package com.nexore.core.module.tenant.domain.repository;

import com.nexore.core.module.tenant.domain.model.Role;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface RoleRepository {

    Role save(Role role);

    Optional<Role> findById(UUID id);

    Optional<Role> findByTenantIdAndId(UUID tenantId, UUID id);

    Optional<Role> findByTenantIdAndName(UUID tenantId, String name);

    boolean existsByTenantIdAndNameAndDeletedAtIsNull(UUID tenantId, String name);

    List<Role> findAllByTenantId(UUID tenantId);

    long countActiveUsersWithRole(UUID tenantId, UUID roleId);
}
