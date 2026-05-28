package com.nexore.core.module.menu.infrastructure.persistence.jpa;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

/**
 * The 3 native SQL queries needed to assemble the role permission matrix (UC-PRM-003).
 * Max 3 queries per invocation as required by CA-PRM-009.
 */
@Repository
public class PermissionQueryRepository {

    @PersistenceContext
    private EntityManager em;

    /** Query 1: all active components visible to the tenant (own + system). */
    public List<ComponentRow> findComponents(UUID tenantId) {
        @SuppressWarnings("unchecked")
        List<Object[]> rows = em.createNativeQuery("""
                SELECT c.id, c.module_key, c.name, c.route, c.description, c.is_system
                FROM nxc_menu.components c
                WHERE c.tenant_id = :tenantId
                  AND c.deleted_at IS NULL
                ORDER BY c.name
                """)
                .setParameter("tenantId", tenantId)
                .getResultList();
        return rows.stream()
                .map(r -> new ComponentRow(toUUID(r[0]), str(r[1]), str(r[2]), str(r[3]), str(r[4]), toBoolean(r[5])))
                .toList();
    }

    /** Query 2: role's explicit component permissions. */
    public List<CompPermRow> findComponentPermissions(UUID tenantId, UUID roleId) {
        @SuppressWarnings("unchecked")
        List<Object[]> rows = em.createNativeQuery("""
                SELECT cp.component_id, cp.access
                FROM nxc_menu.component_permissions cp
                WHERE cp.tenant_id = :tenantId
                  AND cp.role_id = :roleId
                """)
                .setParameter("tenantId", tenantId)
                .setParameter("roleId", roleId)
                .getResultList();
        return rows.stream()
                .map(r -> new CompPermRow(toUUID(r[0]), str(r[1])))
                .toList();
    }

    /** Query 3: all active elements of the tenant with optional explicit element permissions for the role. */
    public List<ElemPermRow> findElementsWithPermissions(UUID tenantId, UUID roleId) {
        @SuppressWarnings("unchecked")
        List<Object[]> rows = em.createNativeQuery("""
                SELECT ce.id, ce.component_id, ce.element_key, ce.label, ce.element_type,
                       ep.access AS explicit_access
                FROM nxc_menu.component_elements ce
                LEFT JOIN nxc_menu.element_permissions ep
                    ON ep.element_id = ce.id
                    AND ep.tenant_id = :tenantId
                    AND ep.role_id = :roleId
                WHERE ce.tenant_id = :tenantId
                  AND ce.deleted_at IS NULL
                ORDER BY ce.component_id, ce.element_key
                """)
                .setParameter("tenantId", tenantId)
                .setParameter("roleId", roleId)
                .getResultList();
        return rows.stream()
                .map(r -> new ElemPermRow(toUUID(r[0]), toUUID(r[1]), str(r[2]), str(r[3]), str(r[4]), str(r[5])))
                .toList();
    }

    // -------------------------------------------------------------------------
    // Row records
    // -------------------------------------------------------------------------

    public record ComponentRow(UUID id, String moduleKey, String name, String route, String description, boolean isSystem) {}

    public record CompPermRow(UUID componentId, String access) {}

    /** explicitAccess is null when no ElementPermission exists for the role. */
    public record ElemPermRow(UUID id, UUID componentId, String elementKey, String label, String elementType, String explicitAccess) {}

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

    private static boolean toBoolean(Object val) {
        if (val == null) return false;
        if (val instanceof Boolean b) return b;
        return Boolean.parseBoolean(val.toString());
    }
}
