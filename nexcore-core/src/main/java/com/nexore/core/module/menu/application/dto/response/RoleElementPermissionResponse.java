package com.nexore.core.module.menu.application.dto.response;

import lombok.Builder;
import lombok.Data;

import java.util.UUID;

@Data
@Builder
public class RoleElementPermissionResponse {
    private UUID elementId;
    private String elementKey;
    private String label;
    private String elementType;
    private String access;
    private boolean inherited;
}
