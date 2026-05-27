package com.nexore.core.module.menu.application.service;

import com.nexore.core.module.menu.application.dto.request.BatchComponentPermissionRequest;
import com.nexore.core.module.menu.application.dto.request.ComponentPermissionUpsertRequest;
import com.nexore.core.module.menu.application.dto.request.ElementPermissionUpsertRequest;
import com.nexore.core.module.menu.application.dto.response.ComponentPermissionResultResponse;
import com.nexore.core.module.menu.application.dto.response.ElementPermissionResultResponse;
import com.nexore.core.module.menu.application.dto.response.RolePermissionMatrixResponse;
import com.nexore.core.module.menu.application.mapper.PermissionMapper;
import com.nexore.core.module.menu.domain.model.AccessLevel;
import com.nexore.core.module.menu.domain.model.ComponentPermission;
import com.nexore.core.module.menu.domain.model.ElementPermission;
import com.nexore.core.module.menu.domain.repository.ComponentElementRepository;
import com.nexore.core.module.menu.domain.repository.ComponentPermissionRepository;
import com.nexore.core.module.menu.domain.repository.ComponentRepository;
import com.nexore.core.module.menu.domain.repository.ElementPermissionRepository;
import com.nexore.core.module.tenant.application.exception.BusinessException;
import com.nexore.core.module.tenant.domain.model.Role;
import com.nexore.core.module.tenant.domain.repository.RoleRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class PermissionService {

    private final ComponentPermissionRepository componentPermissionRepository;
    private final ElementPermissionRepository elementPermissionRepository;
    private final ComponentRepository componentRepository;
    private final ComponentElementRepository componentElementRepository;
    private final RoleRepository roleRepository;
    private final PermissionMapper permissionMapper;

    /** UC-PRM-003 */
    @Transactional(readOnly = true)
    public RolePermissionMatrixResponse getPermissionMatrix(UUID tenantId, UUID roleId) {
        Role role = roleRepository.findByTenantIdAndId(tenantId, roleId)
                .filter(r -> r.getDeletedAt() == null)
                .orElseThrow(BusinessException::permissionRoleNotFound);
        List<ComponentPermission> matrix = componentPermissionRepository.loadMatrix(tenantId, roleId);
        return permissionMapper.toMatrixResponse(role, matrix);
    }

    /** UC-PRM-004 */
    @Transactional
    public ComponentPermissionResultResponse upsertComponentPermission(
            UUID tenantId, UUID roleId, UUID componentId,
            ComponentPermissionUpsertRequest request, UUID actorId) {
        roleRepository.findByTenantIdAndId(tenantId, roleId)
                .filter(r -> r.getDeletedAt() == null)
                .orElseThrow(BusinessException::permissionRoleNotFound);
        componentRepository.findByTenantAndId(tenantId, componentId)
                .orElseThrow(BusinessException::componentNotFound);

        ComponentPermission saved = componentPermissionRepository.upsert(
                ComponentPermission.builder()
                        .tenantId(tenantId)
                        .roleId(roleId)
                        .componentId(componentId)
                        .access(AccessLevel.valueOf(request.getAccess()))
                        .createdBy(actorId)
                        .updatedBy(actorId)
                        .build());
        return permissionMapper.toComponentPermissionResult(saved);
    }

    /** UC-PRM-005 */
    @Transactional
    public List<ComponentPermissionResultResponse> batchUpsertComponentPermissions(
            UUID tenantId, UUID roleId,
            BatchComponentPermissionRequest request, UUID actorId) {
        roleRepository.findByTenantIdAndId(tenantId, roleId)
                .filter(r -> r.getDeletedAt() == null)
                .orElseThrow(BusinessException::permissionRoleNotFound);

        List<UUID> invalidIds = request.getPermissions().stream()
                .map(BatchComponentPermissionRequest.ComponentPermissionItem::getComponentId)
                .filter(id -> componentRepository.findByTenantAndId(tenantId, id).isEmpty())
                .toList();
        if (!invalidIds.isEmpty()) {
            throw BusinessException.permissionInvalidComponentIds(invalidIds);
        }

        return request.getPermissions().stream()
                .map(item -> {
                    ComponentPermission saved = componentPermissionRepository.upsert(
                            ComponentPermission.builder()
                                    .tenantId(tenantId)
                                    .roleId(roleId)
                                    .componentId(item.getComponentId())
                                    .access(AccessLevel.valueOf(item.getAccess()))
                                    .createdBy(actorId)
                                    .updatedBy(actorId)
                                    .build());
                    return permissionMapper.toComponentPermissionResult(saved);
                })
                .toList();
    }

    /** UC-PRM-006 */
    @Transactional
    public ElementPermissionResultResponse upsertElementPermission(
            UUID tenantId, UUID roleId, UUID elementId,
            ElementPermissionUpsertRequest request, UUID actorId) {
        roleRepository.findByTenantIdAndId(tenantId, roleId)
                .filter(r -> r.getDeletedAt() == null)
                .orElseThrow(BusinessException::permissionRoleNotFound);
        componentElementRepository.findByTenantAndId(tenantId, elementId)
                .orElseThrow(BusinessException::elementNotFound);

        ElementPermission saved = elementPermissionRepository.upsert(
                ElementPermission.builder()
                        .tenantId(tenantId)
                        .roleId(roleId)
                        .elementId(elementId)
                        .access(AccessLevel.valueOf(request.getAccess()))
                        .createdBy(actorId)
                        .updatedBy(actorId)
                        .build());
        return permissionMapper.toElementPermissionResult(saved);
    }
}
