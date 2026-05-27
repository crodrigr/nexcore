package com.nexore.core.module.tenant.infrastructure.persistence;

import com.nexore.core.module.tenant.domain.model.User;
import com.nexore.core.module.tenant.domain.model.UserStatus;
import com.nexore.core.module.tenant.domain.repository.UserRepository;
import com.nexore.core.module.tenant.infrastructure.persistence.jpa.SpringDataUserRepository;
import com.nexore.core.module.tenant.infrastructure.persistence.mapper.UserPersistenceMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.Comparator;
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
    public List<User> findByTenantId(UUID tenantId, UserStatus status, String search, int page, int size, String sort, String dir) {
        String statusStr = status != null ? status.name() : null;
        List<User> all = delegate.findByTenantIdWithFilters(tenantId, statusStr, search)
                .stream().map(mapper::toDomain).toList();

        Comparator<User> comparator = switch (sort != null ? sort : "fullName") {
            case "username"  -> Comparator.comparing(User::getUsername,  Comparator.nullsLast(String.CASE_INSENSITIVE_ORDER));
            case "email"     -> Comparator.comparing(User::getEmail,     Comparator.nullsLast(String.CASE_INSENSITIVE_ORDER));
            case "status"    -> Comparator.comparing((User u) -> u.getStatus() != null ? u.getStatus().name() : "");
            case "createdAt" -> Comparator.comparing(User::getCreatedAt, Comparator.nullsLast(Comparator.naturalOrder()));
            default          -> Comparator.comparing(User::getFullName,  Comparator.nullsLast(String.CASE_INSENSITIVE_ORDER));
        };
        if ("desc".equalsIgnoreCase(dir)) comparator = comparator.reversed();

        List<User> sorted = all.stream().sorted(comparator).toList();
        int fromIdx = Math.min(page * size, sorted.size());
        int toIdx = Math.min(fromIdx + size, sorted.size());
        return sorted.subList(fromIdx, toIdx);
    }

    @Override
    public long countByTenantId(UUID tenantId, UserStatus status, String search) {
        String statusStr = status != null ? status.name() : null;
        return delegate.countByTenantIdWithFilters(tenantId, statusStr, search);
    }
}
