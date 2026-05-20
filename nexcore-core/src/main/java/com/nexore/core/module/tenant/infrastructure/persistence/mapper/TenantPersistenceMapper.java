package com.nexore.core.module.tenant.infrastructure.persistence.mapper;

import com.nexore.core.module.tenant.domain.model.Tenant;
import com.nexore.core.module.tenant.infrastructure.persistence.entity.TenantJpaEntity;
import org.springframework.stereotype.Component;

@Component
public class TenantPersistenceMapper {

    public TenantJpaEntity toEntity(Tenant domain) {
        return TenantJpaEntity.builder()
                .id(domain.getId())
                .slug(domain.getSlug())
                .name(domain.getName())
                .legalName(domain.getLegalName())
                .taxId(domain.getTaxId())
                .plan(domain.getPlan())
                .mode(domain.getMode())
                .status(domain.getStatus())
                .logoUrl(domain.getLogoUrl())
                .primaryColor(domain.getPrimaryColor())
                .customDomain(domain.getCustomDomain())
                .timezone(domain.getTimezone())
                .locale(domain.getLocale())
                .dateFormat(domain.getDateFormat())
                .currency(domain.getCurrency())
                .mfaRequired(domain.isMfaRequired())
                .sessionTimeoutMinutes(domain.getSessionTimeoutMinutes())
                .maxLoginAttempts(domain.getMaxLoginAttempts())
                .passwordMinLength(domain.getPasswordMinLength())
                .passwordRequiresUpper(domain.isPasswordRequiresUpper())
                .passwordRequiresSpecial(domain.isPasswordRequiresSpecial())
                .passwordExpiryDays(domain.getPasswordExpiryDays())
                .maxUsers(domain.getMaxUsers())
                .auditRetentionDays(domain.getAuditRetentionDays())
                .trialEndsAt(domain.getTrialEndsAt())
                .subscriptionEndsAt(domain.getSubscriptionEndsAt())
                .createdAt(domain.getCreatedAt())
                .updatedAt(domain.getUpdatedAt())
                .deletedAt(domain.getDeletedAt())
                .version(domain.getVersion())
                .build();
    }

    public Tenant toDomain(TenantJpaEntity entity) {
        return Tenant.builder()
                .id(entity.getId())
                .slug(entity.getSlug())
                .name(entity.getName())
                .legalName(entity.getLegalName())
                .taxId(entity.getTaxId())
                .plan(entity.getPlan())
                .mode(entity.getMode())
                .status(entity.getStatus())
                .logoUrl(entity.getLogoUrl())
                .primaryColor(entity.getPrimaryColor())
                .customDomain(entity.getCustomDomain())
                .timezone(entity.getTimezone())
                .locale(entity.getLocale())
                .dateFormat(entity.getDateFormat())
                .currency(entity.getCurrency())
                .mfaRequired(entity.isMfaRequired())
                .sessionTimeoutMinutes(entity.getSessionTimeoutMinutes())
                .maxLoginAttempts(entity.getMaxLoginAttempts())
                .passwordMinLength(entity.getPasswordMinLength())
                .passwordRequiresUpper(entity.isPasswordRequiresUpper())
                .passwordRequiresSpecial(entity.isPasswordRequiresSpecial())
                .passwordExpiryDays(entity.getPasswordExpiryDays())
                .maxUsers(entity.getMaxUsers())
                .auditRetentionDays(entity.getAuditRetentionDays())
                .trialEndsAt(entity.getTrialEndsAt())
                .subscriptionEndsAt(entity.getSubscriptionEndsAt())
                .createdAt(entity.getCreatedAt())
                .updatedAt(entity.getUpdatedAt())
                .deletedAt(entity.getDeletedAt())
                .version(entity.getVersion())
                .build();
    }
}
