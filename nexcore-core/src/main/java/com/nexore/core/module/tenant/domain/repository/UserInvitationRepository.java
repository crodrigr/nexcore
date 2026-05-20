package com.nexore.core.module.tenant.domain.repository;

import com.nexore.core.module.tenant.domain.model.UserInvitation;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface UserInvitationRepository {

    UserInvitation save(UserInvitation invitation);

    Optional<UserInvitation> findById(UUID id);

    Optional<UserInvitation> findByTenantIdAndId(UUID tenantId, UUID id);

    Optional<UserInvitation> findByTokenHash(String tokenHash);

    boolean existsPendingByTenantIdAndEmail(UUID tenantId, String email);

    List<UserInvitation> findByTenantId(UUID tenantId);
}
