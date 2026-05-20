package com.nexore.core.module.tenant.infrastructure.persistence;

import com.nexore.core.module.tenant.domain.model.User;
import com.nexore.core.module.tenant.domain.model.UserStatus;
import com.nexore.core.module.tenant.domain.repository.UserRepository;
import com.nexore.core.module.tenant.infrastructure.persistence.jpa.SpringDataUserRepository;
import com.nexore.core.module.tenant.infrastructure.persistence.mapper.UserPersistenceMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
@RequiredArgsConstructor
public class JpaUserRepositoryAdapter implements UserRepository {

    private final SpringDataUserRepository delegate;
    private final UserPersistenceMapper mapper;

    @Override
    public User save(User user) {
        return mapper.toDomain(delegate.save(mapper.toEntity(user)));
    }

    @Override
    public Optional<User> findById(UUID id) {
        return delegate.findById(id).map(mapper::toDomain);
    }

    @Override
    public Optional<User> findByTenantIdAndId(UUID tenantId, UUID id) {
        return delegate.findByTenantIdAndId(tenantId, id).map(mapper::toDomain);
    }

    @Override
    public Optional<User> findByTenantIdAndEmail(UUID tenantId, String email) {
        return delegate.findByTenantIdAndEmail(tenantId, email).map(mapper::toDomain);
    }

    @Override
    public Optional<User> findByTenantIdAndUsername(UUID tenantId, String username) {
        return delegate.findByTenantIdAndUsername(tenantId, username).map(mapper::toDomain);
    }

    @Override
    public boolean existsByTenantIdAndEmailAndDeletedAtIsNull(UUID tenantId, String email) {
        return delegate.existsByTenantIdAndEmailAndDeletedAtIsNull(tenantId, email);
    }

    @Override
    public boolean existsByTenantIdAndUsernameAndDeletedAtIsNull(UUID tenantId, String username) {
        return delegate.existsByTenantIdAndUsernameAndDeletedAtIsNull(tenantId, username);
    }

    @Override
    public long countActiveTenantAdmins(UUID tenantId) {
        return delegate.countActiveTenantAdmins(tenantId);
    }

    @Override
    public long countByTenantIdAndDeletedAtIsNull(UUID tenantId) {
        return delegate.countByTenantIdAndDeletedAtIsNull(tenantId);
    }

    @Override
    public List<User> findByTenantId(UUID tenantId, UserStatus status, String search, int page, int size) {
        String statusStr = status != null ? status.name() : null;
        List<User> all = delegate.findByTenantIdWithFilters(tenantId, statusStr, search)
                .stream().map(mapper::toDomain).toList();
        int fromIdx = Math.min(page * size, all.size());
        int toIdx = Math.min(fromIdx + size, all.size());
        return all.subList(fromIdx, toIdx);
    }

    @Override
    public long countByTenantId(UUID tenantId, UserStatus status, String search) {
        String statusStr = status != null ? status.name() : null;
        return delegate.countByTenantIdWithFilters(tenantId, statusStr, search);
    }
}
