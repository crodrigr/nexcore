package com.nexore.core.module.tenant.application.mapper;

import com.nexore.core.module.tenant.application.dto.response.RoleSummary;
import com.nexore.core.module.tenant.application.dto.response.UserResponse;
import com.nexore.core.module.tenant.domain.model.User;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class UserMapper {

    public UserResponse toResponse(User user, List<RoleSummary> roles) {
        return UserResponse.builder()
                .id(user.getId())
                .tenantId(user.getTenantId())
                .username(user.getUsername())
                .email(user.getEmail())
                .fullName(user.getFullName())
                .phone(user.getPhone())
                .photoUrl(user.getPhotoUrl())
                .status(user.getStatus())
                .isTenantAdmin(user.isTenantAdmin())
                .emailVerified(user.isEmailVerified())
                .totpEnabled(user.isTotpEnabled())
                .invitedAt(user.getInvitedAt())
                .activatedAt(user.getActivatedAt())
                .lastLoginAt(user.getLastLoginAt())
                .roles(roles)
                .createdAt(user.getCreatedAt())
                .updatedAt(user.getUpdatedAt())
                .build();
    }
}
