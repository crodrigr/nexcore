package com.nexore.core.module.tenant.domain.repository;

import com.nexore.core.module.tenant.domain.model.Tenant;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface TenantRepository {

    Tenant save(Tenant tenant);

    Optional<Tenant> findById(UUID id);

    Optional<Tenant> findBySlug(String slug);

    boolean existsBySlugAndDeletedAtIsNull(String slug);

    boolean existsByCustomDomainAndDeletedAtIsNull(String customDomain);

    List<Tenant> findAllActive(int page, int size);

    void delete(Tenant tenant);
}
