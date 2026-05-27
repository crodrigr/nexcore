package com.nexore.core.module.menu.infrastructure.persistence.mapper;

import com.nexore.core.module.menu.domain.model.AccessLevel;
import com.nexore.core.module.menu.domain.model.ComponentPermission;
import com.nexore.core.module.menu.domain.model.ElementPermission;
import com.nexore.core.module.menu.infrastructure.persistence.jpa.PermissionCommandRepository.CompPermResultRow;
import com.nexore.core.module.menu.infrastructure.persistence.jpa.PermissionCommandRepository.ElemPermResultRow;
import org.springframework.stereotype.Component;

@Component
public class PermissionPersistenceMapper {

    public ComponentPermission toComponentPermission(CompPermResultRow row) {
        return ComponentPermission.builder()
                .id(row.id())
                .componentId(row.componentId())
                .component(row.moduleKey())
                .access(AccessLevel.valueOf(row.access()))
                .createdAt(row.createdAt())
                .updatedAt(row.updatedAt())
                .createdBy(row.createdBy())
                .updatedBy(row.updatedBy())
                .build();
    }

    public ElementPermission toElementPermission(ElemPermResultRow row) {
        return ElementPermission.builder()
                .id(row.id())
                .elementId(row.elementId())
                .elementKey(row.elementKey())
                .access(AccessLevel.valueOf(row.access()))
                .inherited(false)
                .createdAt(row.createdAt())
                .updatedAt(row.updatedAt())
                .createdBy(row.createdBy())
                .updatedBy(row.updatedBy())
                .build();
    }
}
