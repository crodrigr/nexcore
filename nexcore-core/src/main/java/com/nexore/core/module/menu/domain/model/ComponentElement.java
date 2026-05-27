package com.nexore.core.module.menu.domain.model;

import lombok.Builder;
import lombok.Getter;

import java.time.OffsetDateTime;
import java.util.UUID;

@Getter
@Builder
public class ComponentElement {
    private final UUID id;
    private final UUID tenantId;
    private final UUID componentId;
    private final String elementKey;
    private final String label;
    private final String elementType;
    private final OffsetDateTime deletedAt;
}
