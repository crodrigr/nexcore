package com.nexore.core.module.menu.infrastructure.persistence.projection;

/**
 * Maps result of the component access query.
 * Columns: module_key, route, effective_access (int)
 */
public interface ComponentAccessProjection {
    String getModuleKey();
    String getRoute();
    Integer getEffectiveAccess();
}
