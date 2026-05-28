package com.nexore.core.module.menu.infrastructure.persistence.jpa;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.springframework.stereotype.Repository;

import java.util.*;

/**
 * Executes native SQL queries against nxc_menu / nxc_tenant views and tables.
 * Uses EntityManager directly because the module has no JPA entities.
 */
@Repository
public class UserProfileQueryRepository {

    @PersistenceContext
    private EntityManager em;

    /**
     * Loads user identity and role metadata from nxc_tenant.v_user_login_profile.
     */
    public Optional<UserLoginProfileRow> findUserLoginProfile(UUID userId, UUID tenantId) {
        String sql = """
                SELECT
                    v.user_id,
                    v.tenant_id,
                    v.username,
                    v.email,
                    v.full_name,
                    v.photo_url,
                    v.status,
                    v.tenant_status,
                    v.role_names,
                    v.role_ids
                FROM nxc_tenant.v_user_login_profile v
                WHERE v.user_id = :userId
                  AND v.tenant_id = :tenantId
                """;

        @SuppressWarnings("unchecked")
        List<Object[]> rows = em.createNativeQuery(sql)
                .setParameter("userId", userId)
                .setParameter("tenantId", tenantId)
                .getResultList();

        if (rows.isEmpty()) return Optional.empty();
        Object[] r = rows.get(0);
        return Optional.of(new UserLoginProfileRow(
                toUUID(r[0]),
                toUUID(r[1]),
                str(r[2]),
                str(r[3]),
                str(r[4]),
                str(r[5]),
                str(r[6]),
                str(r[7]),
                toStringArray(r[8]),
                toStringArray(r[9])
        ));
    }

    /**
     * Loads effective component access for the given roles in the tenant.
     * Returns ALL components (including HIDDEN).
     */
    public List<ComponentAccessRow> findComponentAccess(UUID tenantId, List<UUID> roleIds) {
        if (roleIds.isEmpty()) return List.of();

        String sql = """
                SELECT
                    c.id,
                    c.module_key,
                    c.route,
                    CASE MAX(cp.access)
                        WHEN 'EXECUTE' THEN 2
                        WHEN 'VIEW'    THEN 1
                        ELSE 0
                    END AS effective_access
                FROM nxc_menu.component_permissions cp
                JOIN nxc_menu.components c ON c.id = cp.component_id AND c.deleted_at IS NULL
                WHERE cp.tenant_id = :tenantId
                  AND cp.role_id::text = ANY(:roleIds)
                GROUP BY c.id, c.module_key, c.route
                ORDER BY c.module_key
                """;

        @SuppressWarnings("unchecked")
        List<Object[]> rows = em.createNativeQuery(sql)
                .setParameter("tenantId", tenantId)
                .setParameter("roleIds", roleIds.stream().map(UUID::toString).toArray(String[]::new))
                .getResultList();

        return rows.stream()
                .map(r -> new ComponentAccessRow(toUUID(r[0]), str(r[1]), str(r[2]), toInt(r[3])))
                .toList();
    }

    /**
     * Loads effective element access for a component, for the given roles in the tenant.
     * Applies user override when present and not expired.
     * Returns ALL elements (including HIDDEN).
     */
    public List<ElementAccessRow> findElementAccess(UUID componentId, UUID tenantId, UUID userId, List<UUID> roleIds) {
        if (roleIds.isEmpty()) return List.of();

        String sql = """
                SELECT
                    ce.element_key,
                    COALESCE(
                        MAX(CASE ueo.access WHEN 'EXECUTE' THEN 2 WHEN 'VIEW' THEN 1 WHEN 'HIDDEN' THEN 0 ELSE NULL END),
                        MAX(CASE ep.access  WHEN 'EXECUTE' THEN 2 WHEN 'VIEW' THEN 1 WHEN 'HIDDEN' THEN 0 ELSE NULL END)
                    ) AS effective_access
                FROM nxc_menu.component_elements ce
                JOIN nxc_menu.element_permissions ep ON ep.element_id = ce.id
                LEFT JOIN nxc_menu.user_element_overrides ueo
                    ON ueo.element_id = ce.id
                    AND ueo.user_id = :userId
                    AND (ueo.expires_at IS NULL OR ueo.expires_at > NOW())
                WHERE ce.component_id = :componentId
                  AND ce.deleted_at IS NULL
                  AND ep.tenant_id = :tenantId
                  AND ep.role_id::text = ANY(:roleIds)
                GROUP BY ce.element_key
                ORDER BY ce.element_key
                """;

        @SuppressWarnings("unchecked")
        List<Object[]> rows = em.createNativeQuery(sql)
                .setParameter("componentId", componentId)
                .setParameter("tenantId", tenantId)
                .setParameter("userId", userId)
                .setParameter("roleIds", roleIds.stream().map(UUID::toString).toArray(String[]::new))
                .getResultList();

        return rows.stream()
                .map(r -> new ElementAccessRow(str(r[0]), toInt(r[1])))
                .toList();
    }

    /**
     * Loads the flat list of menu items with effective access for the given roles.
     * Includes ALL items (including HIDDEN). Tree assembly is done in the adapter.
     */
    public List<MenuItemRow> findMenuItems(UUID tenantId, List<UUID> roleIds) {
        if (roleIds.isEmpty()) return List.of();

        String sql = """
                SELECT
                    mi.id,
                    mi.parent_id,
                    mi.name,
                    mi.title,
                    mi.route,
                    mi.icon,
                    mi.icon_type,
                    mi.location,
                    mi.item_type,
                    mi.order_index,
                    MAX(CASE COALESCE(ep_el.access, cp.access, mi.default_access)
                            WHEN 'EXECUTE' THEN 2
                            WHEN 'VIEW'    THEN 1
                            ELSE 0
                        END) AS effective_access
                FROM nxc_menu.menu_items mi
                LEFT JOIN nxc_menu.component_permissions cp
                    ON cp.component_id = mi.component_id
                    AND cp.tenant_id = :tenantId
                    AND cp.role_id::text = ANY(:roleIds)
                LEFT JOIN nxc_menu.component_elements ce
                    ON ce.component_id = mi.component_id
                    AND ce.element_key = LOWER(mi.name)
                    AND ce.deleted_at IS NULL
                LEFT JOIN nxc_menu.element_permissions ep_el
                    ON ep_el.element_id = ce.id
                    AND ep_el.tenant_id = :tenantId
                    AND ep_el.role_id = cp.role_id
                WHERE mi.tenant_id = :tenantId
                  AND mi.deleted_at IS NULL
                  AND mi.is_visible = TRUE
                GROUP BY mi.id, mi.parent_id, mi.name, mi.title, mi.route,
                         mi.icon, mi.icon_type, mi.location, mi.item_type,
                         mi.order_index, mi.default_access
                ORDER BY mi.order_index
                """;

        @SuppressWarnings("unchecked")
        List<Object[]> rows = em.createNativeQuery(sql)
                .setParameter("tenantId", tenantId)
                .setParameter("roleIds", roleIds.stream().map(UUID::toString).toArray(String[]::new))
                .getResultList();

        return rows.stream()
                .map(r -> new MenuItemRow(
                        toUUID(r[0]),
                        toUUID(r[1]),
                        str(r[2]),
                        str(r[3]),
                        str(r[4]),
                        str(r[5]),
                        str(r[6]),
                        str(r[7]),
                        str(r[8]),
                        toInt(r[9]),
                        toInt(r[10])
                ))
                .toList();
    }

    /**
     * Looks up the component_id for a given module_key in the tenant.
     */
    public Optional<UUID> findComponentId(String moduleKey, UUID tenantId) {
        String sql = """
                SELECT c.id
                FROM nxc_menu.components c
                WHERE c.module_key = :moduleKey
                  AND (c.tenant_id = :tenantId OR c.is_system = TRUE)
                  AND c.deleted_at IS NULL
                LIMIT 1
                """;

        @SuppressWarnings("unchecked")
        List<Object> rows = em.createNativeQuery(sql)
                .setParameter("moduleKey", moduleKey)
                .setParameter("tenantId", tenantId)
                .getResultList();

        if (rows.isEmpty()) return Optional.empty();
        return Optional.of(toUUID(rows.get(0)));
    }

    // -------------------------------------------------------------------------
    // Inner row records (replaces projection interfaces for native SQL)
    // -------------------------------------------------------------------------

    public record UserLoginProfileRow(
            UUID userId, UUID tenantId, String username, String email,
            String fullName, String photoUrl, String status, String tenantStatus,
            String[] roleNames, String[] roleIds) {}

    public record ComponentAccessRow(UUID componentId, String moduleKey, String route, int effectiveAccess) {}

    public record ElementAccessRow(String elementKey, int effectiveAccess) {}

    public record MenuItemRow(
            UUID id, UUID parentId, String name, String title, String route,
            String icon, String iconType, String location, String itemType,
            int orderIndex, int effectiveAccess) {}

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    private static UUID toUUID(Object val) {
        if (val == null) return null;
        if (val instanceof UUID u) return u;
        return UUID.fromString(val.toString());
    }

    private static String str(Object val) {
        return val == null ? null : val.toString();
    }

    private static int toInt(Object val) {
        if (val == null) return 0;
        if (val instanceof Number n) return n.intValue();
        return Integer.parseInt(val.toString());
    }

    @SuppressWarnings("unchecked")
    private static String[] toStringArray(Object val) {
        if (val == null) return new String[0];
        if (val instanceof String[] arr) return arr;
        // PostgreSQL JDBC returns arrays as java.sql.Array
        if (val instanceof java.sql.Array sqlArr) {
            try {
                Object arr = sqlArr.getArray();
                if (arr instanceof String[] strArr) return strArr;
                if (arr instanceof Object[] objArr) {
                    return Arrays.stream(objArr).map(Object::toString).toArray(String[]::new);
                }
            } catch (java.sql.SQLException e) {
                return new String[0];
            }
        }
        return new String[0];
    }
}
