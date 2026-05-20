package com.nexore.core.module.tenant.infrastructure.persistence;

import com.nexore.core.module.tenant.domain.model.UserInvitation;
import com.nexore.core.module.tenant.domain.repository.UserInvitationRepository;
import com.nexore.core.module.tenant.infrastructure.persistence.jpa.SpringDataUserInvitationRepository;
import com.nexore.core.module.tenant.infrastructure.persistence.mapper.UserInvitationPersistenceMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
@RequiredArgsConstructor
public class JpaUserInvitationRepositoryAdapter implements UserInvitationRepository {

    private final SpringDataUserInvitationRepository delegate;
    private final UserInvitationPersistenceMapper mapper;

    @Override
    public UserInvitation save(UserInvitation invitation) {
        return mapper.toDomain(delegate.save(mapper.toEntity(invitation)));
    }

    @Override
    public Optional<UserInvitation> findById(UUID id) {
        return delegate.findById(id).map(mapper::toDomain);
    }

    @Override
    public Optional<UserInvitation> findByTenantIdAndId(UUID tenantId, UUID id) {
        return delegate.findByTenantIdAndId(tenantId, id).map(mapper::toDomain);
    }

    @Override
    public Optional<UserInvitation> findByTokenHash(String tokenHash) {
        return delegate.findByTokenHash(tokenHash).map(mapper::toDomain);
    }

    @Override
    public boolean existsPendingByTenantIdAndEmail(UUID tenantId, String email) {
        return delegate.existsPendingByTenantIdAndEmail(tenantId, email);
    }

    @Override
    public List<UserInvitation> findByTenantId(UUID tenantId) {
        return delegate.findByTenantId(tenantId).stream().map(mapper::toDomain).toList();
    }
}
