package com.nexore.core.module.tenant.infrastructure.persistence.mapper;

import com.nexore.core.module.tenant.domain.model.Role;
import com.nexore.core.module.tenant.infrastructure.persistence.entity.RoleJpaEntity;
import org.springframework.stereotype.Component;

@Component
public class RolePersistenceMapper {

    public RoleJpaEntity toEntity(Role domain) {
        return RoleJpaEntity.builder()
                .id(domain.getId())
                .tenantId(domain.getTenantId())
                .name(domain.getName())
                .description(domain.getDescription())
                .isSystemRole(domain.isSystemRole())
                .isDefault(domain.isDefault())
                .createdAt(domain.getCreatedAt())
                .updatedAt(domain.getUpdatedAt())
                .createdBy(domain.getCreatedBy())
                .updatedBy(domain.getUpdatedBy())
                .deletedAt(domain.getDeletedAt())
                .version(domain.getVersion())
                .build();
    }

    public Role toDomain(RoleJpaEntity entity) {
        return Role.builder()
                .id(entity.getId())
                .tenantId(entity.getTenantId())
                .name(entity.getName())
                .description(entity.getDescription())
                .isSystemRole(entity.isSystemRole())
                .isDefault(entity.isDefault())
                .createdAt(entity.getCreatedAt())
                .updatedAt(entity.getUpdatedAt())
                .createdBy(entity.getCreatedBy())
                .updatedBy(entity.getUpdatedBy())
                .deletedAt(entity.getDeletedAt())
                .version(entity.getVersion())
                .build();
    }
}
