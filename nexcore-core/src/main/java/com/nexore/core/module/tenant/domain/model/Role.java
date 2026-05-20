package com.nexore.core.module.tenant.domain.model;

import lombok.*;

import java.time.OffsetDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Role {

    private UUID id;
    private UUID tenantId;
    private String name;
    private String description;
    private boolean isSystemRole;
    private boolean isDefault;
    private OffsetDateTime createdAt;
    private OffsetDateTime updatedAt;
    private UUID createdBy;
    private UUID updatedBy;
    private OffsetDateTime deletedAt;
    private int version;
}
