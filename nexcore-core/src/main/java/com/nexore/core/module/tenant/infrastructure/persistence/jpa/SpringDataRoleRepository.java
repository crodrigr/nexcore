package com.nexore.core.module.tenant.infrastructure.persistence.jpa;

import com.nexore.core.module.tenant.infrastructure.persistence.entity.RoleJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface SpringDataRoleRepository extends JpaRepository<RoleJpaEntity, UUID> {

    Optional<RoleJpaEntity> findByTenantIdAndId(UUID tenantId, UUID id);

    Optional<RoleJpaEntity> findByTenantIdAndName(UUID tenantId, String name);

    boolean existsByTenantIdAndNameAndDeletedAtIsNull(UUID tenantId, String name);

    List<RoleJpaEntity> findAllByTenantId(UUID tenantId);

    @Query("SELECT COUNT(ur) FROM UserRole ur " +
           "JOIN User u ON ur.userId = u.id " +
           "WHERE ur.tenantId = :tenantId AND ur.roleId = :roleId " +
           "AND u.deletedAt IS NULL AND u.status <> 'DELETED' " +
           "AND (ur.expiresAt IS NULL OR ur.expiresAt > CURRENT_TIMESTAMP)")
    long countActiveUsersWithRole(@Param("tenantId") UUID tenantId, @Param("roleId") UUID roleId);
}
