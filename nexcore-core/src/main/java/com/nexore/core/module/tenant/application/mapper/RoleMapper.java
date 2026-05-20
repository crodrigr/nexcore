package com.nexore.core.module.tenant.application.mapper;

import com.nexore.core.module.tenant.application.dto.response.RoleResponse;
import com.nexore.core.module.tenant.domain.model.Role;
import org.springframework.stereotype.Component;

@Component
public class RoleMapper {

    public RoleResponse toResponse(Role role, long userCount) {
        return RoleResponse.builder()
                .id(role.getId())
                .tenantId(role.getTenantId())
                .name(role.getName())
                .description(role.getDescription())
                .isSystemRole(role.isSystemRole())
                .isDefault(role.isDefault())
                .userCount(userCount)
                .createdAt(role.getCreatedAt())
                .updatedAt(role.getUpdatedAt())
                .build();
    }
}
