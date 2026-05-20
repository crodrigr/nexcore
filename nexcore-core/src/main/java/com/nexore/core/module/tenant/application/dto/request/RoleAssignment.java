package com.nexore.core.module.tenant.application.dto.request;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.time.OffsetDateTime;
import java.util.UUID;

@Data
public class RoleAssignment {

    @NotNull
    private UUID roleId;

    private OffsetDateTime expiresAt;
}
