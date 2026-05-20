package com.nexore.core.module.menu.application.mapper;

import com.nexore.core.module.menu.application.dto.response.*;
import com.nexore.core.module.menu.domain.model.*;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class UserProfileMapper {

    public UserProfileResponse toResponse(UserProfile profile) {
        return UserProfileResponse.builder()
                .user(toUserInfoResponse(profile.getUser()))
                .permissions(profile.getPermissions().stream().map(this::toComponentPermissionResponse).toList())
                .menus(profile.getMenus().stream().map(this::toMenuItemResponse).toList())
                .token(profile.getToken())
                .build();
    }

    private UserInfoResponse toUserInfoResponse(UserInfo user) {
        return UserInfoResponse.builder()
                .iduser(user.getId().toString())
                .username(user.getUsername())
                .name(user.getName())
                .email(user.getEmail())
                .phone(user.getPhone())
                .photo(user.getPhoto())
                .roles(user.getRoles())
                .build();
    }

    private ComponentPermissionResponse toComponentPermissionResponse(ComponentPermission cp) {
        return ComponentPermissionResponse.builder()
                .component(cp.getComponent())
                .route(cp.getRoute())
                .access(cp.getAccess().toJson())
                .elements(cp.getElements().stream().map(this::toElementPermissionResponse).toList())
                .build();
    }

    private ElementPermissionResponse toElementPermissionResponse(ElementPermission ep) {
        return ElementPermissionResponse.builder()
                .elementKey(ep.getElementKey())
                .access(ep.getAccess().toJson())
                .build();
    }

    private MenuItemResponse toMenuItemResponse(MenuItem item) {
        return MenuItemResponse.builder()
                .id(item.getId().toString())
                .name(item.getName())
                .title(item.getTitle())
                .route(item.getRoute())
                .icon(item.getIcon())
                .iconType(item.getIconType())
                .location(item.getLocation())
                .itemType(item.getItemType().name())
                .access(item.getAccess().toJson())
                .orderIndex(item.getOrderIndex())
                .children(item.getChildren().stream().map(this::toMenuItemResponse).toList())
                .build();
    }
}
