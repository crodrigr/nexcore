package com.nexore.core.module.menu.application.mapper;

import com.nexore.core.module.menu.application.dto.response.ComponentPermissionResultResponse;
import com.nexore.core.module.menu.application.dto.response.ElementPermissionResultResponse;
import com.nexore.core.module.menu.application.dto.response.RoleComponentPermissionResponse;
import com.nexore.core.module.menu.application.dto.response.RoleElementPermissionResponse;
import com.nexore.core.module.menu.application.dto.response.RolePermissionMatrixResponse;
import com.nexore.core.module.menu.domain.model.ComponentPermission;
import com.nexore.core.module.menu.domain.model.ElementPermission;
import com.nexore.core.module.tenant.domain.model.Role;
import org.springframework.stereotype.Component;

import java.time.format.DateTimeFormatter;
import java.util.List;

@Component
public class PermissionMapper {

    private static final DateTimeFormatter ISO = DateTimeFormatter.ISO_OFFSET_DATE_TIME;

    public RolePermissionMatrixResponse toMatrixResponse(Role role, List<ComponentPermission> matrix) {
        return RolePermissionMatrixResponse.builder()
                .roleId(role.getId())
                .roleName(role.getName())
                .tenantId(role.getTenantId())
                .components(matrix.stream().map(this::toComponentPermissionResponse).toList())
                .build();
    }

    private RoleComponentPermissionResponse toComponentPermissionResponse(ComponentPermission cp) {
        return RoleComponentPermissionResponse.builder()
                .componentId(cp.getComponentId())
                .moduleKey(cp.getComponent())
                .name(cp.getName())
                .route(cp.getRoute())
                .access(cp.getAccess().toJson())
                .elements(cp.getElements() != null
                        ? cp.getElements().stream().map(this::toElementPermissionResponse).toList()
                        : List.of())
                .build();
    }

    private RoleElementPermissionResponse toElementPermissionResponse(ElementPermission ep) {
        return RoleElementPermissionResponse.builder()
                .elementId(ep.getElementId())
                .elementKey(ep.getElementKey())
                .label(ep.getLabel())
                .elementType(ep.getElementType())
                .access(ep.getAccess().toJson())
                .inherited(ep.isInherited())
                .build();
    }

    public ComponentPermissionResultResponse toComponentPermissionResult(ComponentPermission cp) {
        return ComponentPermissionResultResponse.builder()
                .componentId(cp.getComponentId())
                .moduleKey(cp.getComponent())
                .access(cp.getAccess().toJson())
                .updatedAt(cp.getUpdatedAt() != null ? cp.getUpdatedAt().format(ISO) : null)
                .build();
    }

    public ElementPermissionResultResponse toElementPermissionResult(ElementPermission ep) {
        return ElementPermissionResultResponse.builder()
                .elementId(ep.getElementId())
                .elementKey(ep.getElementKey())
                .access(ep.getAccess().toJson())
                .inherited(false)
                .updatedAt(ep.getUpdatedAt() != null ? ep.getUpdatedAt().format(ISO) : null)
                .build();
    }
}
