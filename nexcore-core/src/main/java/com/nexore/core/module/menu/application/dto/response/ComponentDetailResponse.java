package com.nexore.core.module.menu.application.dto.response;

import lombok.Builder;
import lombok.Data;

import java.util.List;
import java.util.UUID;

@Data
@Builder
public class ComponentDetailResponse {
    private UUID id;
    private UUID tenantId;
    private String moduleKey;
    private String name;
    private String route;
    private String description;
    private boolean isSystem;
    private List<ComponentElementResponse> elements;
    private String createdAt;
    private String updatedAt;
}
