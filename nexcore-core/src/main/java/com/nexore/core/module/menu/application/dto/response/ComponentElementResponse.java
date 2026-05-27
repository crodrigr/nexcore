package com.nexore.core.module.menu.application.dto.response;

import lombok.Builder;
import lombok.Data;

import java.util.UUID;

@Data
@Builder
public class ComponentElementResponse {
    private UUID id;
    private UUID componentId;
    private String elementKey;
    private String label;
    private String elementType;
}
