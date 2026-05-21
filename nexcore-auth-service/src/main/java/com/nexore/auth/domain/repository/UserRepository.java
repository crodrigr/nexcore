package com.nexore.auth.domain.repository;

import com.nexore.auth.domain.model.User;

import java.util.Optional;
import java.util.UUID;

public interface UserRepository {
    
    Optional<User> findByTenantIdAndUsername(UUID tenantId, String username);
    
    Optional<User> findByTenantIdAndEmail(UUID tenantId, String email);
    
    Optional<User> findById(UUID userId);
    
    User save(User user);
}
