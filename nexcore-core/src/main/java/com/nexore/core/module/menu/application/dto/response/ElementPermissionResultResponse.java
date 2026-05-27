package com.nexore.core.module.menu.application.dto.response;

import lombok.Builder;
import lombok.Data;

import java.util.UUID;

@Data
@Builder
public class ElementPermissionResultResponse {
    private UUID elementId;
    private String elementKey;
    private String access;
    private boolean inherited;
    private String updatedAt;
}
