package com.nexore.core.module.tenant.application.dto.response;

import lombok.Builder;
import lombok.Data;

import java.time.OffsetDateTime;
import java.util.UUID;

@Data
@Builder
public class RoleSummary {
    private UUID id;
    private String name;
    private OffsetDateTime assignedAt;
    private OffsetDateTime expiresAt;
}
