package com.nexore.core.module.menu.application.dto.response;

import lombok.Builder;
import lombok.Data;

import java.util.UUID;

@Data
@Builder
public class ComponentSummaryResponse {
    private UUID id;
    private UUID tenantId;
    private String moduleKey;
    private String name;
    private String route;
    private String description;
    private boolean isSystem;
    private long elementCount;
    private String createdAt;
    private String updatedAt;
}
