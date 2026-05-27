package com.nexore.core.module.tenant.domain.repository;

import com.nexore.core.module.tenant.domain.model.UserInvitation;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface UserInvitationRepository {

    UserInvitation save(UserInvitation invitation);

    Optional<UserInvitation> findById(UUID id);

    Optional<UserInvitation> findByTenantIdAndId(UUID tenantId, UUID id);

    Optional<UserInvitation> findByTokenHash(String tokenHash);

    boolean existsPendingByTenantIdAndEmail(UUID tenantId, String email);

    int resendUpdateToken(UUID tenantId, UUID id, String tokenHash, OffsetDateTime expiresAt);

    List<UserInvitation> findByTenantId(UUID tenantId);
}
