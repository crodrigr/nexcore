package com.nexore.core.module.tenant.infrastructure.web;

import com.nexore.core.module.tenant.application.dto.request.TenantCreateRequest;
import com.nexore.core.module.tenant.application.dto.request.TenantUpdateRequest;
import com.nexore.core.module.tenant.application.dto.response.PageResponse;
import com.nexore.core.module.tenant.application.dto.response.TenantResponse;
import com.nexore.core.module.tenant.application.service.TenantService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import java.net.URI;
import java.util.UUID;

/**
 * Endpoints REST del módulo tenant.
 * Autenticación/autorización (JWT + roles) se implementará en una capa de seguridad separada.
 * El header X-Actor-Super-Admin se usa temporalmente para diferenciar SUPER_ADMIN de TENANT_ADMIN.
 */
@RestController
@RequestMapping("/api/v1/tenants")
@RequiredArgsConstructor
public class TenantController {

    private final TenantService tenantService;

    /** GET /api/v1/tenants  — SUPER_ADMIN */
    @GetMapping
    public ResponseEntity<PageResponse<TenantResponse>> listTenants(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(tenantService.listTenants(page, size));
    }

    /** POST /api/v1/tenants  — SUPER_ADMIN */
    @PostMapping
    public ResponseEntity<TenantResponse> createTenant(@Valid @RequestBody TenantCreateRequest request) {
        TenantResponse response = tenantService.createTenant(request);
        URI location = ServletUriComponentsBuilder.fromCurrentRequest()
                .path("/{id}").buildAndExpand(response.getId()).toUri();
        return ResponseEntity.created(location).body(response);
    }

    /** GET /api/v1/tenants/{id} */
    @GetMapping("/{id}")
    public ResponseEntity<TenantResponse> getTenant(@PathVariable UUID id) {
        return ResponseEntity.ok(tenantService.getTenant(id));
    }

    /** PATCH /api/v1/tenants/{id} */
    @PatchMapping("/{id}")
    public ResponseEntity<TenantResponse> updateTenant(
            @PathVariable UUID id,
            @Valid @RequestBody TenantUpdateRequest request,
            @RequestHeader(value = "X-Actor-Super-Admin", defaultValue = "false") boolean isSuperAdmin) {
        return ResponseEntity.ok(tenantService.updateTenant(id, request, isSuperAdmin));
    }

    /** POST /api/v1/tenants/{id}/suspend  — SUPER_ADMIN */
    @PostMapping("/{id}/suspend")
    public ResponseEntity<Void> suspendTenant(@PathVariable UUID id) {
        tenantService.suspendTenant(id);
        return ResponseEntity.noContent().build();
    }

    /** POST /api/v1/tenants/{id}/activate  — SUPER_ADMIN */
    @PostMapping("/{id}/activate")
    public ResponseEntity<Void> activateTenant(@PathVariable UUID id) {
        tenantService.activateTenant(id);
        return ResponseEntity.noContent().build();
    }
}
