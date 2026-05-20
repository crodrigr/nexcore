package com.nexore.core.module.menu.domain.model;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class ElementPermission {
    private final String elementKey;
    private final AccessLevel access;
}
