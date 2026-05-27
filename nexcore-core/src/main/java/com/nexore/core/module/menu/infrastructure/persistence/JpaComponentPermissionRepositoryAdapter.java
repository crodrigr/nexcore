package com.nexore.core.module.menu.infrastructure.persistence;

import com.nexore.core.module.menu.domain.model.AccessLevel;
import com.nexore.core.module.menu.domain.model.ComponentPermission;
import com.nexore.core.module.menu.domain.model.ElementPermission;
import com.nexore.core.module.menu.domain.repository.ComponentPermissionRepository;
import com.nexore.core.module.menu.infrastructure.persistence.jpa.PermissionCommandRepository;
import com.nexore.core.module.menu.infrastructure.persistence.jpa.PermissionQueryRepository;
import com.nexore.core.module.menu.infrastructure.persistence.mapper.PermissionPersistenceMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Repository
@RequiredArgsConstructor
public class JpaComponentPermissionRepositoryAdapter implements ComponentPermissionRepository {

    private final PermissionQueryRepository queryRepository;
    private final PermissionCommandRepository commandRepository;
    private final PermissionPersistenceMapper mapper;

    @Override
    public ComponentPermission upsert(ComponentPermission permission) {
        commandRepository.upsertComponentPermission(
                permission.getTenantId(),
                permission.getRoleId(),
                permission.getComponentId(),
                permission.getAccess().name(),
                permission.getCreatedBy(),
                permission.getUpdatedBy());
        return commandRepository.findComponentPermission(
                        permission.getTenantId(), permission.getRoleId(), permission.getComponentId())
                .map(mapper::toComponentPermission)
                .orElseThrow(() -> new IllegalStateException("Upsert succeeded but row not found"));
    }

    @Override
    public List<ComponentPermission> findByRoleId(UUID tenantId, UUID roleId) {
        return queryRepository.findComponentPermissions(tenantId, roleId).stream()
                .map(row -> ComponentPermission.builder()
                        .componentId(row.componentId())
                        .access(AccessLevel.valueOf(row.access()))
                        .build())
                .toList();
    }

    /**
     * Assembles the full permission matrix using exactly 3 queries (CA-PRM-009).
     */
    @Override
    public List<ComponentPermission> loadMatrix(UUID tenantId, UUID roleId) {
        // Query 1
        List<PermissionQueryRepository.ComponentRow> components = queryRepository.findComponents(tenantId);

        // Query 2
        Map<UUID, AccessLevel> compAccessMap = queryRepository.findComponentPermissions(tenantId, roleId)
                .stream()
                .collect(Collectors.toMap(
                        PermissionQueryRepository.CompPermRow::componentId,
                        row -> AccessLevel.valueOf(row.access())));

        // Query 3
        Map<UUID, List<PermissionQueryRepository.ElemPermRow>> elementsByComp =
                queryRepository.findElementsWithPermissions(tenantId, roleId)
                        .stream()
                        .collect(Collectors.groupingBy(PermissionQueryRepository.ElemPermRow::componentId));

        // Assembly
        return components.stream()
                .map(comp -> {
                    AccessLevel compAccess = compAccessMap.getOrDefault(comp.id(), AccessLevel.HIDDEN);

                    List<ElementPermission> elements = elementsByComp.getOrDefault(comp.id(), List.of())
                            .stream()
                            .map(el -> {
                                boolean hasExplicit = el.explicitAccess() != null;
                                AccessLevel elemAccess = hasExplicit
                                        ? AccessLevel.valueOf(el.explicitAccess())
                                        : compAccess;
                                return ElementPermission.builder()
                                        .elementId(el.id())
                                        .elementKey(el.elementKey())
                                        .label(el.label())
                                        .elementType(el.elementType())
                                        .access(elemAccess)
                                        .inherited(!hasExplicit)
                                        .build();
                            })
                            .toList();

                    return ComponentPermission.builder()
                            .componentId(comp.id())
                            .component(comp.moduleKey())
                            .name(comp.name())
                            .route(comp.route())
                            .access(compAccess)
                            .elements(elements)
                            .build();
                })
                .toList();
    }
}
