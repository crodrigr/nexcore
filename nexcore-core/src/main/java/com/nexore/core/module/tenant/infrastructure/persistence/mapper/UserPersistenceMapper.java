package com.nexore.core.module.tenant.infrastructure.persistence.mapper;

import com.nexore.core.module.tenant.domain.model.User;
import com.nexore.core.module.tenant.infrastructure.persistence.entity.UserJpaEntity;
import org.springframework.stereotype.Component;

@Component
public class UserPersistenceMapper {

    public UserJpaEntity toEntity(User domain) {
        return UserJpaEntity.builder()
                .id(domain.getId())
                .tenantId(domain.getTenantId())
                .username(domain.getUsername())
                .email(domain.getEmail())
                .passwordHash(domain.getPasswordHash())
                .fullName(domain.getFullName())
                .phone(domain.getPhone())
                .photoUrl(domain.getPhotoUrl())
                .observaciones(domain.getObservaciones())
                .status(domain.getStatus())
                .isTenantAdmin(domain.isTenantAdmin())
                .emailVerified(domain.isEmailVerified())
                .emailVerifiedAt(domain.getEmailVerifiedAt())
                .totpSecret(domain.getTotpSecret())
                .totpEnabled(domain.isTotpEnabled())
                .totpBackupCodes(domain.getTotpBackupCodes())
                .temporalCode(domain.getTemporalCode())
                .temporalCodeExpiresAt(domain.getTemporalCodeExpiresAt())
                .invitedBy(domain.getInvitedBy())
                .invitedAt(domain.getInvitedAt())
                .activatedAt(domain.getActivatedAt())
                .lastLoginAt(domain.getLastLoginAt())
                .lastLoginIp(domain.getLastLoginIp())
                .createdAt(domain.getCreatedAt())
                .updatedAt(domain.getUpdatedAt())
                .createdBy(domain.getCreatedBy())
                .updatedBy(domain.getUpdatedBy())
                .deletedAt(domain.getDeletedAt())
                .version(domain.getVersion())
                .build();
    }

    public User toDomain(UserJpaEntity entity) {
        return User.builder()
                .id(entity.getId())
                .tenantId(entity.getTenantId())
                .username(entity.getUsername())
                .email(entity.getEmail())
                .passwordHash(entity.getPasswordHash())
                .fullName(entity.getFullName())
                .phone(entity.getPhone())
                .photoUrl(entity.getPhotoUrl())
                .observaciones(entity.getObservaciones())
                .status(entity.getStatus())
                .isTenantAdmin(entity.isTenantAdmin())
                .emailVerified(entity.isEmailVerified())
                .emailVerifiedAt(entity.getEmailVerifiedAt())
                .totpSecret(entity.getTotpSecret())
                .totpEnabled(entity.isTotpEnabled())
                .totpBackupCodes(entity.getTotpBackupCodes())
                .temporalCode(entity.getTemporalCode())
                .temporalCodeExpiresAt(entity.getTemporalCodeExpiresAt())
                .invitedBy(entity.getInvitedBy())
                .invitedAt(entity.getInvitedAt())
                .activatedAt(entity.getActivatedAt())
                .lastLoginAt(entity.getLastLoginAt())
                .lastLoginIp(entity.getLastLoginIp())
                .createdAt(entity.getCreatedAt())
                .updatedAt(entity.getUpdatedAt())
                .createdBy(entity.getCreatedBy())
                .updatedBy(entity.getUpdatedBy())
                .deletedAt(entity.getDeletedAt())
                .version(entity.getVersion())
                .build();
    }
}
