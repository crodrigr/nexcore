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

    boolean existsByTenantIdAndUserIdAndRoleId(UUID tenantId, UUID userId, UUID roleId);

    @Query(value = """
            SELECT r.name
            FROM nxc_tenant.user_roles ur
            JOIN nxc_tenant.roles r ON r.id = ur.role_id
            WHERE ur.user_id = :userId
              AND ur.tenant_id = :tenantId
              AND r.deleted_at IS NULL
              AND (ur.expires_at IS NULL OR ur.expires_at > NOW())
            """, nativeQuery = true)
    List<String> findRoleNamesByUserIdAndTenantId(
            @Param("userId") UUID userId,
            @Param("tenantId") UUID tenantId
    );

    @Modifying
    @Query(value = """
        INSERT INTO nxc_tenant.user_roles
            (id, tenant_id, user_id, role_id, assigned_by, assigned_at, expires_at)
        VALUES
            (:id, :tenantId, :userId, :roleId, :assignedBy, NOW(), :expiresAt)
        ON CONFLICT (tenant_id, user_id, role_id) DO NOTHING
        """, nativeQuery = true)
    void insertIgnoreDuplicate(
        @Param("id")         UUID id,
        @Param("tenantId")   UUID tenantId,
        @Param("userId")     UUID userId,
        @Param("roleId")     UUID roleId,
        @Param("assignedBy") UUID assignedBy,
        @Param("expiresAt")  java.time.OffsetDateTime expiresAt
    );
}
