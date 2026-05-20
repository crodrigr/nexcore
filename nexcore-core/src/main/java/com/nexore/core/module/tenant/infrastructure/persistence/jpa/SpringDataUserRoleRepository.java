package com.nexore.core.module.tenant.infrastructure.persistence.jpa;

import com.nexore.core.module.tenant.infrastructure.persistence.entity.UserRoleJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

public interface SpringDataUserRoleRepository extends JpaRepository<UserRoleJpaEntity, UUID> {

    List<UserRoleJpaEntity> findByTenantIdAndUserId(UUID tenantId, UUID userId);

    List<UserRoleJpaEntity> findByTenantIdAndRoleId(UUID tenantId, UUID roleId);

    @Modifying
    @Query("DELETE FROM UserRole ur WHERE ur.tenantId = :tenantId AND ur.userId = :userId")
    void deleteByTenantIdAndUserId(@Param("tenantId") UUID tenantId, @Param("userId") UUID userId);

    @Query("SELECT COUNT(ur) > 0 FROM UserRole ur WHERE ur.tenantId = :tenantId AND ur.roleId = :roleId " +
           "AND (ur.expiresAt IS NULL OR ur.expiresAt > CURRENT_TIMESTAMP)")
    boolean existsActiveTenantAdminRole(@Param("tenantId") UUID tenantId, @Param("roleId") UUID roleId);
}
