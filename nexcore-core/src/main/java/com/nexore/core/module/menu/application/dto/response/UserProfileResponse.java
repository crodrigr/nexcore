package com.nexore.core.module.menu.application.dto.response;

import lombok.Builder;
import lombok.Getter;

import java.util.List;

@Getter
@Builder
public class UserProfileResponse {

    private final UserInfoResponse user;
    private final List<ComponentPermissionResponse> permissions;
    private final List<MenuItemResponse> menus;
    private final String token;
}
