package com.nexore.core.module.menu.domain.model;

import lombok.Builder;
import lombok.Getter;

import java.time.OffsetDateTime;
import java.util.UUID;

@Getter
@Builder
public class Component {
    private final UUID id;
    private final UUID tenantId;
    private final String moduleKey;
    private final String name;
    private final String route;
    private final String description;
    private final boolean isSystem;
    private final long elementCount;
    private final OffsetDateTime createdAt;
    private final OffsetDateTime updatedAt;
    private final OffsetDateTime deletedAt;
}
