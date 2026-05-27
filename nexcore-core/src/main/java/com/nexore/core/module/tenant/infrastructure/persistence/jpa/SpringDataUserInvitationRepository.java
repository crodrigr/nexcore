package com.nexore.core.module.tenant.infrastructure.persistence.jpa;

import com.nexore.core.module.tenant.infrastructure.persistence.entity.UserInvitationJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface SpringDataUserInvitationRepository extends JpaRepository<UserInvitationJpaEntity, UUID> {

    Optional<UserInvitationJpaEntity> findByTenantIdAndId(UUID tenantId, UUID id);

    Optional<UserInvitationJpaEntity> findByTokenHash(String tokenHash);

    @Query("SELECT COUNT(i) > 0 FROM UserInvitation i WHERE i.tenantId = :tenantId AND i.email = :email " +
           "AND i.acceptedAt IS NULL AND i.isRevoked = FALSE AND i.expiresAt > CURRENT_TIMESTAMP")
    boolean existsPendingByTenantIdAndEmail(@Param("tenantId") UUID tenantId, @Param("email") String email);

    @Modifying
    @Query("UPDATE UserInvitation i SET i.tokenHash = :tokenHash, i.expiresAt = :expiresAt, i.isRevoked = false " +
           "WHERE i.tenantId = :tenantId AND i.id = :id")
    int resendUpdateToken(@Param("tenantId") UUID tenantId, @Param("id") UUID id,
                          @Param("tokenHash") String tokenHash, @Param("expiresAt") OffsetDateTime expiresAt);

    List<UserInvitationJpaEntity> findByTenantId(UUID tenantId);
}
