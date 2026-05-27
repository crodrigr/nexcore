package com.nexore.core.module.menu.infrastructure.web;

import com.nexore.core.module.menu.application.dto.request.BatchComponentPermissionRequest;
import com.nexore.core.module.menu.application.dto.request.ComponentPermissionUpsertRequest;
import com.nexore.core.module.menu.application.dto.request.ElementPermissionUpsertRequest;
import com.nexore.core.module.menu.application.dto.response.ComponentPermissionResultResponse;
import com.nexore.core.module.menu.application.dto.response.ElementPermissionResultResponse;
import com.nexore.core.module.menu.application.dto.response.RolePermissionMatrixResponse;
import com.nexore.core.module.menu.application.service.PermissionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * Permission management endpoints.
 * All endpoints require TENANT_ADMIN role (enforced via X-Is-Tenant-Admin header in MVP phase).
 *
 * Auth headers (MVP — replaced by JWT when module-auth is implemented):
 *   X-Tenant-Id       : UUID of the caller's tenant
 *   X-Actor-Id        : UUID of the authenticated user
 *   X-Is-Tenant-Admin : true if the caller has TENANT_ADMIN role
 */
@RestController
@RequestMapping("/api/v1/menu/permissions")
@RequiredArgsConstructor
public class PermissionController {

    private final PermissionService permissionService;

    /** UC-PRM-003 — full permission matrix for a role */
    @GetMapping("/roles/{roleId}")
    public ResponseEntity<RolePermissionMatrixResponse> getPermissionMatrix(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID roleId) {
        return ResponseEntity.ok(permissionService.getPermissionMatrix(tenantId, roleId));
    }

    /** UC-PRM-004 — upsert component permission for a role */
    @PutMapping("/roles/{roleId}/components/{componentId}")
    public ResponseEntity<ComponentPermissionResultResponse> upsertComponentPermission(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @RequestHeader("X-Actor-Id") UUID actorId,
            @PathVariable UUID roleId,
            @PathVariable UUID componentId,
            @Valid @RequestBody ComponentPermissionUpsertRequest request) {
        return ResponseEntity.ok(
                permissionService.upsertComponentPermission(tenantId, roleId, componentId, request, actorId));
    }

    /** UC-PRM-005 — batch upsert component permissions for a role */
    @PutMapping("/roles/{roleId}/components/batch")
    public ResponseEntity<List<ComponentPermissionResultResponse>> batchUpsertComponentPermissions(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @RequestHeader("X-Actor-Id") UUID actorId,
            @PathVariable UUID roleId,
            @Valid @RequestBody BatchComponentPermissionRequest request) {
        return ResponseEntity.ok(
                permissionService.batchUpsertComponentPermissions(tenantId, roleId, request, actorId));
    }

    /** UC-PRM-006 — upsert element permission for a role */
    @PutMapping("/roles/{roleId}/elements/{elementId}")
    public ResponseEntity<ElementPermissionResultResponse> upsertElementPermission(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @RequestHeader("X-Actor-Id") UUID actorId,
            @PathVariable UUID roleId,
            @PathVariable UUID elementId,
            @Valid @RequestBody ElementPermissionUpsertRequest request) {
        return ResponseEntity.ok(
                permissionService.upsertElementPermission(tenantId, roleId, elementId, request, actorId));
    }
}
