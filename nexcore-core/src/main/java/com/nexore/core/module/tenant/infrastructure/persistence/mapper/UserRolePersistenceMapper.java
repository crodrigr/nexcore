package com.nexore.core.module.tenant.infrastructure.persistence.mapper;

import com.nexore.core.module.tenant.domain.model.UserRole;
import com.nexore.core.module.tenant.infrastructure.persistence.entity.UserRoleJpaEntity;
import org.springframework.stereotype.Component;

@Component
public class UserRolePersistenceMapper {

    public UserRoleJpaEntity toEntity(UserRole domain) {
        return UserRoleJpaEntity.builder()
                .id(domain.getId())
                .tenantId(domain.getTenantId())
                .userId(domain.getUserId())
                .roleId(domain.getRoleId())
                .assignedAt(domain.getAssignedAt())
                .assignedBy(domain.getAssignedBy())
                .expiresAt(domain.getExpiresAt())
                .build();
    }

    public UserRole toDomain(UserRoleJpaEntity entity) {
        return UserRole.builder()
                .id(entity.getId())
                .tenantId(entity.getTenantId())
                .userId(entity.getUserId())
                .roleId(entity.getRoleId())
                .assignedAt(entity.getAssignedAt())
                .assignedBy(entity.getAssignedBy())
                .expiresAt(entity.getExpiresAt())
                .build();
    }
}
