package com.nexore.core.module.tenant.infrastructure.persistence;

import com.nexore.core.module.tenant.domain.model.Tenant;
import com.nexore.core.module.tenant.domain.repository.TenantRepository;
import com.nexore.core.module.tenant.infrastructure.persistence.jpa.SpringDataTenantRepository;
import com.nexore.core.module.tenant.infrastructure.persistence.mapper.TenantPersistenceMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
@RequiredArgsConstructor
public class JpaTenantRepositoryAdapter implements TenantRepository {

    private final SpringDataTenantRepository delegate;
    private final TenantPersistenceMapper mapper;

    @Override
    public Tenant save(Tenant tenant) {
        return mapper.toDomain(delegate.save(mapper.toEntity(tenant)));
    }

    @Override
    public Optional<Tenant> findById(UUID id) {
        return delegate.findById(id).map(mapper::toDomain);
    }

    @Override
    public Optional<Tenant> findBySlug(String slug) {
        return delegate.findBySlug(slug).map(mapper::toDomain);
    }

    @Override
    public boolean existsBySlugAndDeletedAtIsNull(String slug) {
        return delegate.existsBySlugAndDeletedAtIsNull(slug);
    }

    @Override
    public boolean existsByCustomDomainAndDeletedAtIsNull(String customDomain) {
        return delegate.existsByCustomDomainAndDeletedAtIsNull(customDomain);
    }

    @Override
    public List<Tenant> findAllActive(int page, int size) {
        return delegate.findAllByDeletedAtIsNull(PageRequest.of(page, size))
                .getContent()
                .stream()
                .map(mapper::toDomain)
                .toList();
    }

    @Override
    public void delete(Tenant tenant) {
        delegate.delete(mapper.toEntity(tenant));
    }
}
