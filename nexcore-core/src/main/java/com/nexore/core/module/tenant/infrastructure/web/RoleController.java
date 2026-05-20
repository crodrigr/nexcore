package com.nexore.core.module.tenant.infrastructure.web;

import com.nexore.core.module.tenant.application.dto.request.RoleCreateRequest;
import com.nexore.core.module.tenant.application.dto.response.RoleResponse;
import com.nexore.core.module.tenant.application.service.RoleService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import java.net.URI;
import java.util.List;
import java.util.UUID;

/**
 * Endpoints REST de roles del tenant.
 * X-Tenant-Id  — UUID del tenant activo (temporal; será extraído del JWT).
 * X-Actor-Id   — UUID del usuario autenticado (temporal; será extraído del JWT).
 */
@RestController
@RequestMapping("/api/v1/roles")
@RequiredArgsConstructor
public class RoleController {

    private final RoleService roleService;

    /** GET /api/v1/roles */
    @GetMapping
    public ResponseEntity<List<RoleResponse>> listRoles(
            @RequestHeader("X-Tenant-Id") UUID tenantId) {
        return ResponseEntity.ok(roleService.listRoles(tenantId));
    }

    /** POST /api/v1/roles */
    @PostMapping
    public ResponseEntity<RoleResponse> createRole(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @RequestHeader("X-Actor-Id") UUID actorId,
            @Valid @RequestBody RoleCreateRequest request) {
        RoleResponse response = roleService.createRole(tenantId, request, actorId);
        URI location = ServletUriComponentsBuilder.fromCurrentRequest()
                .path("/{id}").buildAndExpand(response.getId()).toUri();
        return ResponseEntity.created(location).body(response);
    }

    /** GET /api/v1/roles/{id} */
    @GetMapping("/{id}")
    public ResponseEntity<RoleResponse> getRole(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID id) {
        return ResponseEntity.ok(roleService.getRole(tenantId, id));
    }

    /** PATCH /api/v1/roles/{id} */
    @PatchMapping("/{id}")
    public ResponseEntity<RoleResponse> updateRole(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @RequestHeader("X-Actor-Id") UUID actorId,
            @PathVariable UUID id,
            @Valid @RequestBody RoleCreateRequest request) {
        return ResponseEntity.ok(roleService.updateRole(tenantId, id, request, actorId));
    }

    /** DELETE /api/v1/roles/{id} */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteRole(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID id) {
        roleService.deleteRole(tenantId, id);
        return ResponseEntity.noContent().build();
    }
}
