package com.nexore.core.module.menu.application.dto.response;

import lombok.Builder;
import lombok.Data;

import java.util.UUID;

@Data
@Builder
public class ComponentPermissionResultResponse {
    private UUID componentId;
    private String moduleKey;
    private String access;
    private String updatedAt;
}
