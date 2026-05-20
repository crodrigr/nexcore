package com.nexore.core.module.tenant.infrastructure.persistence.mapper;

import com.nexore.core.module.tenant.domain.model.UserInvitation;
import com.nexore.core.module.tenant.infrastructure.persistence.entity.UserInvitationJpaEntity;
import org.springframework.stereotype.Component;

@Component
public class UserInvitationPersistenceMapper {

    public UserInvitationJpaEntity toEntity(UserInvitation domain) {
        return UserInvitationJpaEntity.builder()
                .id(domain.getId())
                .tenantId(domain.getTenantId())
                .email(domain.getEmail())
                .tokenHash(domain.getTokenHash())
                .roleIds(domain.getRoleIds())
                .invitedBy(domain.getInvitedBy())
                .invitedAt(domain.getInvitedAt())
                .expiresAt(domain.getExpiresAt())
                .acceptedAt(domain.getAcceptedAt())
                .userId(domain.getUserId())
                .isRevoked(domain.isRevoked())
                .build();
    }

    public UserInvitation toDomain(UserInvitationJpaEntity entity) {
        return UserInvitation.builder()
                .id(entity.getId())
                .tenantId(entity.getTenantId())
                .email(entity.getEmail())
                .tokenHash(entity.getTokenHash())
                .roleIds(entity.getRoleIds())
                .invitedBy(entity.getInvitedBy())
                .invitedAt(entity.getInvitedAt())
                .expiresAt(entity.getExpiresAt())
                .acceptedAt(entity.getAcceptedAt())
                .userId(entity.getUserId())
                .isRevoked(entity.isRevoked())
                .build();
    }
}
