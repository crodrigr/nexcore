package com.nexore.core.module.menu.application.mapper;

import com.nexore.core.module.menu.application.dto.response.ComponentDetailResponse;
import com.nexore.core.module.menu.application.dto.response.ComponentElementResponse;
import com.nexore.core.module.menu.application.dto.response.ComponentSummaryResponse;
import com.nexore.core.module.menu.domain.model.Component;
import com.nexore.core.module.menu.domain.model.ComponentElement;

import java.time.format.DateTimeFormatter;
import java.util.List;

@org.springframework.stereotype.Component
public class ComponentMapper {

    private static final DateTimeFormatter ISO = DateTimeFormatter.ISO_OFFSET_DATE_TIME;

    public ComponentSummaryResponse toSummaryResponse(Component comp) {
        return ComponentSummaryResponse.builder()
                .id(comp.getId())
                .tenantId(comp.getTenantId())
                .moduleKey(comp.getModuleKey())
                .name(comp.getName())
                .route(comp.getRoute())
                .description(comp.getDescription())
                .isSystem(comp.isSystem())
                .elementCount(comp.getElementCount())
                .createdAt(comp.getCreatedAt() != null ? comp.getCreatedAt().format(ISO) : null)
                .updatedAt(comp.getUpdatedAt() != null ? comp.getUpdatedAt().format(ISO) : null)
                .build();
    }

    public ComponentDetailResponse toDetailResponse(Component comp, List<ComponentElement> elements) {
        return ComponentDetailResponse.builder()
                .id(comp.getId())
                .tenantId(comp.getTenantId())
                .moduleKey(comp.getModuleKey())
                .name(comp.getName())
                .route(comp.getRoute())
                .description(comp.getDescription())
                .isSystem(comp.isSystem())
                .elements(elements.stream().map(this::toElementResponse).toList())
                .createdAt(comp.getCreatedAt() != null ? comp.getCreatedAt().format(ISO) : null)
                .updatedAt(comp.getUpdatedAt() != null ? comp.getUpdatedAt().format(ISO) : null)
                .build();
    }

    public ComponentElementResponse toElementResponse(ComponentElement el) {
        return ComponentElementResponse.builder()
                .id(el.getId())
                .componentId(el.getComponentId())
                .elementKey(el.getElementKey())
                .label(el.getLabel())
                .elementType(el.getElementType())
                .build();
    }
}
