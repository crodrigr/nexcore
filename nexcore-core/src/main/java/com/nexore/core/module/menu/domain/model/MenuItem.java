package com.nexore.core.module.menu.domain.model;

import lombok.Builder;
import lombok.Getter;

import java.util.List;
import java.util.UUID;

@Getter
@Builder
public class MenuItem {
    private final UUID id;
    private final String name;
    private final String title;
    private final String route;
    private final String icon;
    private final String iconType;
    private final String location;
    private final MenuItemType itemType;
    private final AccessLevel access;
    private final int orderIndex;
    private final List<MenuItem> children;
}
