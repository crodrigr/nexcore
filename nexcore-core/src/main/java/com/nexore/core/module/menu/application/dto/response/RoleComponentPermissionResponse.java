package com.nexore.core.module.menu.application.dto.response;

import lombok.Builder;
import lombok.Data;

import java.util.List;
import java.util.UUID;

@Data
@Builder
public class RoleComponentPermissionResponse {
    private UUID componentId;
    private String moduleKey;
    private String name;
    private String route;
    private String access;
    private List<RoleElementPermissionResponse> elements;
}
