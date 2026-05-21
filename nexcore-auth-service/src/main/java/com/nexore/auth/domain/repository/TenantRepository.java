package com.nexore.auth.domain.repository;

import com.nexore.auth.domain.model.Tenant;

import java.util.Optional;
import java.util.UUID;

public interface TenantRepository {
    
    Optional<Tenant> findById(UUID tenantId);
}
