package com.nexore.core.module.tenant.domain.repository;

import com.nexore.core.module.tenant.domain.model.User;
import com.nexore.core.module.tenant.domain.model.UserStatus;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface UserRepository {

    User save(User user);

    Optional<User> findById(UUID id);

    Optional<User> findByTenantIdAndId(UUID tenantId, UUID id);

    Optional<User> findByTenantIdAndEmail(UUID tenantId, String email);

    Optional<User> findByTenantIdAndUsername(UUID tenantId, String username);

    boolean existsByTenantIdAndEmailAndDeletedAtIsNull(UUID tenantId, String email);

    boolean existsByTenantIdAndUsernameAndDeletedAtIsNull(UUID tenantId, String username);

    long countActiveTenantAdmins(UUID tenantId);

    long countByTenantIdAndDeletedAtIsNull(UUID tenantId);

    List<User> findByTenantId(UUID tenantId, UserStatus status, String search, int page, int size);

    long countByTenantId(UUID tenantId, UserStatus status, String search);
}
