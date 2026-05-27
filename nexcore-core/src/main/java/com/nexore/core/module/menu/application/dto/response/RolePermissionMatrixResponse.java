package com.nexore.core.module.menu.application.dto.response;

import lombok.Builder;
import lombok.Data;

import java.util.List;
import java.util.UUID;

@Data
@Builder
public class RolePermissionMatrixResponse {
    private UUID roleId;
    private String roleName;
    private UUID tenantId;
    private List<RoleComponentPermissionResponse> components;
}
