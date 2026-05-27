package com.nexore.core.module.menu.application.service;

import com.nexore.core.module.menu.application.dto.response.ComponentDetailResponse;
import com.nexore.core.module.menu.application.dto.response.ComponentElementResponse;
import com.nexore.core.module.menu.application.dto.response.ComponentSummaryResponse;
import com.nexore.core.module.menu.application.mapper.ComponentMapper;
import com.nexore.core.module.menu.domain.model.Component;
import com.nexore.core.module.menu.domain.model.ComponentElement;
import com.nexore.core.module.menu.domain.repository.ComponentElementRepository;
import com.nexore.core.module.menu.domain.repository.ComponentRepository;
import com.nexore.core.module.tenant.application.dto.response.PageResponse;
import com.nexore.core.module.tenant.application.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ComponentService {

    private final ComponentRepository componentRepository;
    private final ComponentElementRepository componentElementRepository;
    private final ComponentMapper componentMapper;

    /** UC-PRM-001 */
    @Transactional(readOnly = true)
    public PageResponse<ComponentSummaryResponse> listComponents(
            UUID tenantId, String search, Boolean isSystem, int page, int size) {
        List<Component> components = componentRepository.findPagedByTenant(tenantId, search, isSystem, page, size);
        long total = componentRepository.countByTenant(tenantId, search, isSystem);
        int totalPages = size > 0 ? (int) Math.ceil((double) total / size) : 0;
        return PageResponse.<ComponentSummaryResponse>builder()
                .content(components.stream().map(componentMapper::toSummaryResponse).toList())
                .page(page)
                .size(size)
                .totalElements(total)
                .totalPages(totalPages)
                .last(page >= totalPages - 1)
                .build();
    }

    /** UC-PRM-002 — component detail with elements */
    @Transactional(readOnly = true)
    public ComponentDetailResponse getComponent(UUID tenantId, UUID componentId) {
        Component component = componentRepository.findByTenantAndId(tenantId, componentId)
                .orElseThrow(BusinessException::componentNotFound);
        List<ComponentElement> elements = componentElementRepository.findByComponent(tenantId, componentId);
        return componentMapper.toDetailResponse(component, elements);
    }

    /** UC-PRM-002 — elements only */
    @Transactional(readOnly = true)
    public List<ComponentElementResponse> listElements(UUID tenantId, UUID componentId) {
        componentRepository.findByTenantAndId(tenantId, componentId)
                .orElseThrow(BusinessException::componentNotFound);
        return componentElementRepository.findByComponent(tenantId, componentId).stream()
                .map(componentMapper::toElementResponse)
                .toList();
    }
}
