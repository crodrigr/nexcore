package com.nexore.core.module.menu.application.dto.response;

import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class ComponentPermissionResponse {

    private final String component;
    private final String route;
    private final String access;
    private final List<ElementPermissionResponse> elements;
}
