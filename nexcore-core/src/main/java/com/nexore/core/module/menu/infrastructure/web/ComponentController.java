package com.nexore.core.module.menu.infrastructure.web;

import com.nexore.core.module.menu.application.dto.response.ComponentDetailResponse;
import com.nexore.core.module.menu.application.dto.response.ComponentElementResponse;
import com.nexore.core.module.menu.application.dto.response.ComponentSummaryResponse;
import com.nexore.core.module.menu.application.service.ComponentService;
import com.nexore.core.module.tenant.application.dto.response.PageResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * Read-only endpoints for components and their elements.
 * Components are registered via seed/script in Phase 1; no write endpoints exposed.
 *
 * Auth headers (MVP — replaced by JWT when module-auth is implemented):
 *   X-Tenant-Id       : UUID of the caller's tenant
 *   X-Is-Tenant-Admin : true if the caller has TENANT_ADMIN role
 */
@RestController
@RequestMapping("/api/v1/menu/components")
@RequiredArgsConstructor
public class ComponentController {

    private final ComponentService componentService;

    /** UC-PRM-001 — paginated component list */
    @GetMapping
    public ResponseEntity<PageResponse<ComponentSummaryResponse>> listComponents(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) Boolean isSystem,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(componentService.listComponents(tenantId, search, isSystem, page, size));
    }

    /** UC-PRM-002 — component detail with elements */
    @GetMapping("/{componentId}")
    public ResponseEntity<ComponentDetailResponse> getComponent(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID componentId) {
        return ResponseEntity.ok(componentService.getComponent(tenantId, componentId));
    }

    /** UC-PRM-002 — elements of a component */
    @GetMapping("/{componentId}/elements")
    public ResponseEntity<List<ComponentElementResponse>> listElements(
            @RequestHeader("X-Tenant-Id") UUID tenantId,
            @PathVariable UUID componentId) {
        return ResponseEntity.ok(componentService.listElements(tenantId, componentId));
    }
}
