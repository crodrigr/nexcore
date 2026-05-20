package com.nexore.core.module.menu.infrastructure.persistence.mapper;

import com.nexore.core.module.menu.domain.model.*;
import com.nexore.core.module.menu.infrastructure.persistence.jpa.UserProfileQueryRepository.*;
import org.springframework.stereotype.Component;

import java.util.*;

@Component
public class UserProfilePersistenceMapper {

    public UserInfo toUserInfo(UserLoginProfileRow row) {
        return UserInfo.builder()
                .id(row.userId())
                .username(row.username())
                .name(row.fullName())
                .email(row.email())
                .photo(row.photoUrl())
                .roles(row.roleNames() == null ? List.of() : Arrays.asList(row.roleNames()))
                .build();
    }

    public ComponentPermission toComponentPermission(ComponentAccessRow row, List<ElementPermission> elements) {
        return ComponentPermission.builder()
                .component(row.moduleKey())
                .route(row.route())
                .access(AccessLevel.fromInt(row.effectiveAccess()))
                .elements(elements)
                .build();
    }

    public ElementPermission toElementPermission(ElementAccessRow row) {
        return ElementPermission.builder()
                .elementKey(row.elementKey())
                .access(AccessLevel.fromInt(row.effectiveAccess()))
                .build();
    }

    public MenuItem toMenuItem(MenuItemRow row, List<MenuItem> children) {
        return MenuItem.builder()
                .id(row.id())
                .name(row.name())
                .title(row.title())
                .route(row.route())
                .icon(row.icon())
                .iconType(row.iconType())
                .location(row.location())
                .itemType(MenuItemType.valueOf(row.itemType()))
                .access(AccessLevel.fromInt(row.effectiveAccess()))
                .orderIndex(row.orderIndex())
                .children(children)
                .build();
    }
}
