package com.nexore.core.module.menu.infrastructure.persistence.projection;

import java.util.UUID;

/**
 * Maps rows from the menu items query.
 * Columns: id, parent_id, name, title, route, icon, icon_type, location, item_type, order_index, effective_access (int)
 */
public interface MenuItemProjection {
    UUID getId();
    UUID getParentId();
    String getName();
    String getTitle();
    String getRoute();
    String getIcon();
    String getIconType();
    String getLocation();
    String getItemType();
    Integer getOrderIndex();
    Integer getEffectiveAccess();
}
