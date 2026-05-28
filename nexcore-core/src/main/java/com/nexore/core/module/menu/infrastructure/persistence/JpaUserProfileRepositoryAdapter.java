package com.nexore.core.module.menu.infrastructure.persistence;

import com.nexore.core.module.menu.domain.model.*;
import com.nexore.core.module.menu.domain.repository.UserProfileRepository;
import com.nexore.core.module.menu.infrastructure.persistence.jpa.UserProfileQueryRepository;
import com.nexore.core.module.menu.infrastructure.persistence.jpa.UserProfileQueryRepository.*;
import com.nexore.core.module.menu.infrastructure.persistence.mapper.UserProfilePersistenceMapper;
import com.nexore.core.module.tenant.application.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.*;
import java.util.stream.Collectors;

@Repository
@RequiredArgsConstructor
public class JpaUserProfileRepositoryAdapter implements UserProfileRepository {

    private final UserProfileQueryRepository queryRepository;
    private final UserProfilePersistenceMapper mapper;

    @Override
    public Optional<UserProfile> loadProfile(UUID userId, UUID tenantId) {
        // Step 1 — load user + role info
        Optional<UserLoginProfileRow> profileOpt = queryRepository.findUserLoginProfile(userId, tenantId);
        if (profileOpt.isEmpty()) return Optional.empty();
        UserLoginProfileRow profileRow = profileOpt.get();

        // Validate tenant status
        if (!"ACTIVE".equals(profileRow.tenantStatus())) {
            throw BusinessException.menuTenantNotActive();
        }
        // Validate user status
        if ("SUSPENDED".equals(profileRow.status()) || "BLOCKED".equals(profileRow.status())) {
            throw BusinessException.menuUserSuspended();
        }
        if (!"ACTIVE".equals(profileRow.status())) {
            return Optional.empty();
        }

        UserInfo userInfo = mapper.toUserInfo(profileRow);

        // Parse role IDs
        List<UUID> roleIds = profileRow.roleIds() == null
                ? List.of()
                : Arrays.stream(profileRow.roleIds()).map(UUID::fromString).toList();

        // Step 2 — permissions (components + elements)
        List<ComponentPermission> permissions = buildPermissions(tenantId, userId, roleIds);

        // Step 3 — menu tree
        List<MenuItem> menus = buildMenuTree(tenantId, roleIds);

        return Optional.of(UserProfile.builder()
                .user(userInfo)
                .permissions(permissions)
                .menus(menus)
                .token(null)  // JWT pendiente (module-auth)
                .build());
    }

    private List<ComponentPermission> buildPermissions(UUID tenantId, UUID userId, List<UUID> roleIds) {
        List<ComponentAccessRow> componentRows = queryRepository.findComponentAccess(tenantId, roleIds);
        List<ComponentPermission> result = new ArrayList<>();

        for (ComponentAccessRow compRow : componentRows) {
            List<ElementPermission> elements = queryRepository
                    .findElementAccess(compRow.componentId(), tenantId, userId, roleIds)
                    .stream()
                    .map(mapper::toElementPermission)
                    .toList();

            result.add(mapper.toComponentPermission(compRow, elements));
        }

        return result;
    }

    private List<MenuItem> buildMenuTree(UUID tenantId, List<UUID> roleIds) {
        List<MenuItemRow> flatList = queryRepository.findMenuItems(tenantId, roleIds);

        // Group children by parent_id
        Map<UUID, List<MenuItemRow>> byParent = flatList.stream()
                .filter(r -> r.parentId() != null)
                .collect(Collectors.groupingBy(MenuItemRow::parentId));

        // Build recursively for root items (parent_id IS NULL)
        return flatList.stream()
                .filter(r -> r.parentId() == null)
                .sorted(Comparator.comparingInt(MenuItemRow::orderIndex))
                .map(r -> buildMenuItemRecursive(r, byParent))
                .toList();
    }

    private MenuItem buildMenuItemRecursive(MenuItemRow row, Map<UUID, List<MenuItemRow>> byParent) {
        List<MenuItem> children = byParent.getOrDefault(row.id(), List.of())
                .stream()
                .sorted(Comparator.comparingInt(MenuItemRow::orderIndex))
                .map(child -> buildMenuItemRecursive(child, byParent))
                .toList();

        return mapper.toMenuItem(row, children);
    }
}
