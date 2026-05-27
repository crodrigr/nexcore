package com.nexore.core.module.menu.infrastructure.persistence.mapper;

import com.nexore.core.module.menu.domain.model.ComponentElement;
import com.nexore.core.module.menu.infrastructure.persistence.jpa.ComponentQueryRepository.ComponentRow;
import com.nexore.core.module.menu.infrastructure.persistence.jpa.ComponentQueryRepository.ElementRow;

@org.springframework.stereotype.Component
public class ComponentPersistenceMapper {

    public com.nexore.core.module.menu.domain.model.Component toComponent(ComponentRow row) {
        return com.nexore.core.module.menu.domain.model.Component.builder()
                .id(row.id())
                .tenantId(row.tenantId())
                .moduleKey(row.moduleKey())
                .name(row.name())
                .route(row.route())
                .description(row.description())
                .isSystem(row.isSystem())
                .elementCount(row.elementCount())
                .createdAt(row.createdAt())
                .updatedAt(row.updatedAt())
                .deletedAt(row.deletedAt())
                .build();
    }

    public ComponentElement toComponentElement(ElementRow row) {
        return ComponentElement.builder()
                .id(row.id())
                .tenantId(row.tenantId())
                .componentId(row.componentId())
                .elementKey(row.elementKey())
                .label(row.label())
                .elementType(row.elementType())
                .deletedAt(row.deletedAt())
                .build();
    }
}
