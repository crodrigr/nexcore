package com.nexore.core.module.tenant.infrastructure.persistence.jpa;

import com.nexore.core.module.tenant.infrastructure.persistence.entity.TenantJpaEntity;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface SpringDataTenantRepository extends JpaRepository<TenantJpaEntity, UUID> {

    Optional<TenantJpaEntity> findBySlug(String slug);

    boolean existsBySlugAndDeletedAtIsNull(String slug);

    boolean existsByCustomDomainAndDeletedAtIsNull(String customDomain);

    Page<TenantJpaEntity> findAllByDeletedAtIsNull(Pageable pageable);

    long countByDeletedAtIsNull();
}
