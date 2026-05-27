package com.nexore.core.module.tenant.domain.repository;

import com.nexore.core.module.tenant.domain.model.UserRole;

import java.util.List;
import java.util.UUID;

public interface UserRoleRepository {

    UserRole save(UserRole userRole);

    List<UserRole> findByTenantIdAndUserId(UUID tenantId, UUID userId);

    List<UserRole> findByTenantIdAndRoleId(UUID tenantId, UUID roleId);

    void deleteByTenantIdAndUserId(UUID tenantId, UUID userId);

    boolean existsActiveTenantAdminRole(UUID tenantId, UUID roleId);

    boolean existsByTenantIdAndUserIdAndRoleId(UUID tenantId, UUID userId, UUID roleId);

    void insertIgnoreDuplicate(UUID id, UUID tenantId, UUID userId, UUID roleId, UUID assignedBy, java.time.OffsetDateTime expiresAt);
}
