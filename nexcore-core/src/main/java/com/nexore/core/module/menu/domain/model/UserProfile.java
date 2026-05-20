package com.nexore.core.module.menu.domain.model;

import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class UserProfile {
    private final UserInfo user;
    private final List<ComponentPermission> permissions;
    private final List<MenuItem> menus;
    private final String token;
}
