package com.nexore.core.module.tenant.application.service;

import com.nexore.core.module.tenant.application.dto.request.TenantCreateRequest;
import com.nexore.core.module.tenant.application.dto.request.TenantUpdateRequest;
import com.nexore.core.module.tenant.application.dto.response.PageResponse;
import com.nexore.core.module.tenant.application.dto.response.TenantResponse;
import com.nexore.core.module.tenant.application.exception.BusinessException;
import com.nexore.core.module.tenant.application.mapper.TenantMapper;
import com.nexore.core.module.tenant.domain.model.Tenant;
import com.nexore.core.module.tenant.domain.model.TenantStatus;
import com.nexore.core.module.tenant.domain.repository.TenantRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.regex.Pattern;

@Service
@RequiredArgsConstructor
public class TenantService {

    private static final Pattern SLUG_PATTERN = Pattern.compile("^[a-z0-9]+(-[a-z0-9]+)*$");
    private static final List<String> PROTECTED_SLUGS = List.of("system");

    private final TenantRepository tenantRepository;
    private final TenantMapper tenantMapper;

    /** UC-001 */
    @Transactional
    public TenantResponse createTenant(TenantCreateRequest request) {
        if (!SLUG_PATTERN.matcher(request.getSlug()).matches()) {
            throw BusinessException.tenantInvalidSlug(request.getSlug());
        }
        if (tenantRepository.existsBySlugAndDeletedAtIsNull(request.getSlug())) {
            throw BusinessException.tenantSlugAlreadyExists(request.getSlug());
        }

        Tenant tenant = tenantMapper.toEntity(request);
        tenant.setStatus(TenantStatus.TRIAL);
        Tenant saved = tenantRepository.save(tenant);
        return tenantMapper.toResponse(saved);
    }

    /** UC-002 */
    @Transactional(readOnly = true)
    public TenantResponse getTenant(UUID id) {
        Tenant tenant = tenantRepository.findById(id)
                .filter(t -> t.getDeletedAt() == null)
                .orElseThrow(BusinessException::tenantNotFound);
        return tenantMapper.toResponse(tenant);
    }

    /** UC-002 - by slug */
    @Transactional(readOnly = true)
    public TenantResponse getTenantBySlug(String slug) {
        Tenant tenant = tenantRepository.findBySlug(slug)
                .filter(t -> t.getDeletedAt() == null)
                .orElseThrow(BusinessException::tenantNotFound);
        return tenantMapper.toResponse(tenant);
    }

    /** UC-003 */
    @Transactional
    public TenantResponse updateTenant(UUID id, TenantUpdateRequest request, boolean isSuperAdmin) {
        Tenant tenant = tenantRepository.findById(id)
                .filter(t -> t.getDeletedAt() == null)
                .orElseThrow(BusinessException::tenantNotFound);

        if (!isSuperAdmin && hasSuperAdminOnlyFields(request)) {
            throw BusinessException.tenantAdminCannotChangePlan();
        }
        if (request.getCustomDomain() != null &&
                !request.getCustomDomain().equals(tenant.getCustomDomain()) &&
                tenantRepository.existsByCustomDomainAndDeletedAtIsNull(request.getCustomDomain())) {
            throw BusinessException.customDomainAlreadyInUse(request.getCustomDomain());
        }

        tenantMapper.applyUpdate(request, tenant, isSuperAdmin);
        Tenant saved = tenantRepository.save(tenant);
        return tenantMapper.toResponse(saved);
    }

    /** UC-004 — suspend */
    @Transactional
    public void suspendTenant(UUID id) {
        Tenant tenant = tenantRepository.findById(id)
                .filter(t -> t.getDeletedAt() == null)
                .orElseThrow(BusinessException::tenantNotFound);
        if (PROTECTED_SLUGS.contains(tenant.getSlug())) {
            throw BusinessException.tenantAccessForbidden();
        }
        tenant.setStatus(TenantStatus.SUSPENDED);
        tenantRepository.save(tenant);
    }

    /** UC-004 — activate */
    @Transactional
    public void activateTenant(UUID id) {
        Tenant tenant = tenantRepository.findById(id)
                .filter(t -> t.getDeletedAt() == null)
                .orElseThrow(BusinessException::tenantNotFound);
        tenant.setStatus(TenantStatus.ACTIVE);
        tenantRepository.save(tenant);
    }

    /** List (SUPER_ADMIN only) */
    @Transactional(readOnly = true)
    public PageResponse<TenantResponse> listTenants(int page, int size) {
        List<Tenant> tenants = tenantRepository.findAllActive(page, size);
        List<TenantResponse> content = tenants.stream().map(tenantMapper::toResponse).toList();
        return PageResponse.<TenantResponse>builder()
                .content(content)
                .page(page)
                .size(size)
                .totalElements(content.size())
                .totalPages(1)
                .last(true)
                .build();
    }

    private boolean hasSuperAdminOnlyFields(TenantUpdateRequest req) {
        return req.getPlan() != null || req.getMode() != null || req.getStatus() != null
                || req.getMaxUsers() != null || req.getAuditRetentionDays() != null
                || req.getTrialEndsAt() != null || req.getSubscriptionEndsAt() != null;
    }
}
