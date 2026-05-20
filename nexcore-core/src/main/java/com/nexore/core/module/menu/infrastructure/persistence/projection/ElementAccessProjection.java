package com.nexore.core.module.menu.infrastructure.persistence.projection;

/**
 * Maps result of the element access query.
 * Columns: element_key, effective_access (int)
 */
public interface ElementAccessProjection {
    String getElementKey();
    Integer getEffectiveAccess();
}
