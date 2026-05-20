package com.nexore.core.module.tenant.infrastructure.persistence.jpa;

import com.nexore.core.module.tenant.infrastructure.persistence.entity.UserJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface SpringDataUserRepository extends JpaRepository<UserJpaEntity, UUID> {

    Optional<UserJpaEntity> findByTenantIdAndId(UUID tenantId, UUID id);

    Optional<UserJpaEntity> findByTenantIdAndEmail(UUID tenantId, String email);

    Optional<UserJpaEntity> findByTenantIdAndUsername(UUID tenantId, String username);

    boolean existsByTenantIdAndEmailAndDeletedAtIsNull(UUID tenantId, String email);

    boolean existsByTenantIdAndUsernameAndDeletedAtIsNull(UUID tenantId, String username);

    @Query(value = "SELECT COUNT(*) FROM nxc_tenant.users u " +
                   "WHERE u.tenant_id = :tenantId " +
                   "AND u.is_tenant_admin = TRUE " +
                   "AND u.status = CAST('ACTIVE' AS nxc_tenant.user_status) " +
                   "AND u.deleted_at IS NULL",
           nativeQuery = true)
    long countActiveTenantAdmins(@Param("tenantId") UUID tenantId);

    long countByTenantIdAndDeletedAtIsNull(UUID tenantId);

    @Query(value = "SELECT * FROM nxc_tenant.users u " +
                   "WHERE u.tenant_id = :tenantId " +
                   "AND u.deleted_at IS NULL " +
                   "AND (:status IS NULL OR u.status = CAST(:status AS nxc_tenant.user_status)) " +
                   "AND (:search IS NULL " +
                   "     OR LOWER(u.email)     LIKE LOWER(CONCAT('%', :search, '%')) " +
                   "     OR LOWER(u.username)  LIKE LOWER(CONCAT('%', :search, '%')) " +
                   "     OR LOWER(u.full_name) LIKE LOWER(CONCAT('%', :search, '%')))",
           nativeQuery = true)
    List<UserJpaEntity> findByTenantIdWithFilters(
            @Param("tenantId") UUID tenantId,
            @Param("status") String status,
            @Param("search") String search);

    @Query(value = "SELECT COUNT(*) FROM nxc_tenant.users u " +
                   "WHERE u.tenant_id = :tenantId " +
                   "AND u.deleted_at IS NULL " +
                   "AND (:status IS NULL OR u.status = CAST(:status AS nxc_tenant.user_status)) " +
                   "AND (:search IS NULL " +
                   "     OR LOWER(u.email)     LIKE LOWER(CONCAT('%', :search, '%')) " +
                   "     OR LOWER(u.username)  LIKE LOWER(CONCAT('%', :search, '%')) " +
                   "     OR LOWER(u.full_name) LIKE LOWER(CONCAT('%', :search, '%')))",
           nativeQuery = true)
    long countByTenantIdWithFilters(
            @Param("tenantId") UUID tenantId,
            @Param("status") String status,
            @Param("search") String search);
}
