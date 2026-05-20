package com.nexore.core.module.menu.domain.model;

import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class ComponentPermission {
    private final String component;
    private final String route;
    private final AccessLevel access;
    private final List<ElementPermission> elements;
}
