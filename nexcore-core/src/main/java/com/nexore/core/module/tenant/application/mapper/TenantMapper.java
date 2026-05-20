package com.nexore.core.module.tenant.application.mapper;

import com.nexore.core.module.tenant.application.dto.request.TenantCreateRequest;
import com.nexore.core.module.tenant.application.dto.request.TenantUpdateRequest;
import com.nexore.core.module.tenant.application.dto.response.TenantResponse;
import com.nexore.core.module.tenant.domain.model.Tenant;
import com.nexore.core.module.tenant.domain.model.TenantMode;
import com.nexore.core.module.tenant.domain.model.TenantPlan;
import org.springframework.stereotype.Component;

@Component
public class TenantMapper {

    public Tenant toEntity(TenantCreateRequest req) {
        return Tenant.builder()
                .slug(req.getSlug())
                .name(req.getName())
                .legalName(req.getLegalName())
                .taxId(req.getTaxId())
                .plan(req.getPlan() != null ? req.getPlan() : TenantPlan.FREE)
                .mode(req.getMode() != null ? req.getMode() : TenantMode.SAAS_SHARED)
                .timezone(req.getTimezone() != null ? req.getTimezone() : "UTC")
                .locale(req.getLocale() != null ? req.getLocale() : "es-CO")
                .dateFormat(req.getDateFormat() != null ? req.getDateFormat() : "DD/MM/YYYY")
                .currency(req.getCurrency() != null ? req.getCurrency() : "COP")
                .sessionTimeoutMinutes(480)
                .maxLoginAttempts(5)
                .passwordMinLength(8)
                .auditRetentionDays(90)
                .build();
    }

    public TenantResponse toResponse(Tenant tenant) {
        return TenantResponse.builder()
                .id(tenant.getId())
                .slug(tenant.getSlug())
                .name(tenant.getName())
                .legalName(tenant.getLegalName())
                .taxId(tenant.getTaxId())
                .plan(tenant.getPlan())
                .mode(tenant.getMode())
                .status(tenant.getStatus())
                .logoUrl(tenant.getLogoUrl())
                .primaryColor(tenant.getPrimaryColor())
                .customDomain(tenant.getCustomDomain())
                .timezone(tenant.getTimezone())
                .locale(tenant.getLocale())
                .dateFormat(tenant.getDateFormat())
                .currency(tenant.getCurrency())
                .mfaRequired(tenant.isMfaRequired())
                .sessionTimeoutMinutes(tenant.getSessionTimeoutMinutes())
                .maxLoginAttempts(tenant.getMaxLoginAttempts())
                .passwordMinLength(tenant.getPasswordMinLength())
                .passwordRequiresUpper(tenant.isPasswordRequiresUpper())
                .passwordRequiresSpecial(tenant.isPasswordRequiresSpecial())
                .passwordExpiryDays(tenant.getPasswordExpiryDays())
                .maxUsers(tenant.getMaxUsers())
                .auditRetentionDays(tenant.getAuditRetentionDays())
                .trialEndsAt(tenant.getTrialEndsAt())
                .subscriptionEndsAt(tenant.getSubscriptionEndsAt())
                .createdAt(tenant.getCreatedAt())
                .updatedAt(tenant.getUpdatedAt())
                .build();
    }

    public void applyUpdate(TenantUpdateRequest req, Tenant tenant, boolean isSuperAdmin) {
        if (req.getName() != null) tenant.setName(req.getName());
        if (req.getLegalName() != null) tenant.setLegalName(req.getLegalName());
        if (req.getTaxId() != null) tenant.setTaxId(req.getTaxId());
        if (req.getLogoUrl() != null) tenant.setLogoUrl(req.getLogoUrl());
        if (req.getPrimaryColor() != null) tenant.setPrimaryColor(req.getPrimaryColor());
        if (req.getCustomDomain() != null) tenant.setCustomDomain(req.getCustomDomain());
        if (req.getTimezone() != null) tenant.setTimezone(req.getTimezone());
        if (req.getLocale() != null) tenant.setLocale(req.getLocale());
        if (req.getDateFormat() != null) tenant.setDateFormat(req.getDateFormat());
        if (req.getCurrency() != null) tenant.setCurrency(req.getCurrency());
        if (req.getMfaRequired() != null) tenant.setMfaRequired(req.getMfaRequired());
        if (req.getSessionTimeoutMinutes() != null) tenant.setSessionTimeoutMinutes(req.getSessionTimeoutMinutes());
        if (req.getMaxLoginAttempts() != null) tenant.setMaxLoginAttempts(req.getMaxLoginAttempts());
        if (req.getPasswordMinLength() != null) tenant.setPasswordMinLength(req.getPasswordMinLength());
        if (req.getPasswordRequiresUpper() != null) tenant.setPasswordRequiresUpper(req.getPasswordRequiresUpper());
        if (req.getPasswordRequiresSpecial() != null) tenant.setPasswordRequiresSpecial(req.getPasswordRequiresSpecial());
        if (req.getPasswordExpiryDays() != null) tenant.setPasswordExpiryDays(req.getPasswordExpiryDays());

        if (isSuperAdmin) {
            if (req.getPlan() != null) tenant.setPlan(req.getPlan());
            if (req.getMode() != null) tenant.setMode(req.getMode());
            if (req.getStatus() != null) tenant.setStatus(req.getStatus());
            if (req.getMaxUsers() != null) tenant.setMaxUsers(req.getMaxUsers());
            if (req.getAuditRetentionDays() != null) tenant.setAuditRetentionDays(req.getAuditRetentionDays());
        }
    }
}
