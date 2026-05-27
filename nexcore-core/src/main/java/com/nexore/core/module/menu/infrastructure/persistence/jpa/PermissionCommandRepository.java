package com.nexore.core.module.menu.infrastructure.persistence.jpa;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.springframework.stereotype.Repository;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Native SQL upsert operations for nxc_menu.component_permissions and nxc_menu.element_permissions.
 * All methods require an active transaction (provided by the calling service).
 */
@Repository
public class PermissionCommandRepository {

    @PersistenceContext
    private EntityManager em;

    public void upsertComponentPermission(
            UUID tenantId, UUID roleId, UUID componentId, String access, UUID createdBy, UUID updatedBy) {
        em.createNativeQuery("""
                INSERT INTO nxc_menu.component_permissions
                    (id, tenant_id, role_id, component_id, access, created_at, updated_at, created_by, updated_by)
                VALUES
                    (gen_random_uuid(), :tenantId, :roleId, :componentId,
                     CAST(:access AS nxc_menu.access_level), NOW(), NOW(), :createdBy, :updatedBy)
                ON CONFLICT (tenant_id, role_id, component_id) DO UPDATE SET
                    access     = CAST(EXCLUDED.access AS nxc_menu.access_level),
                    updated_at = NOW(),
                    updated_by = EXCLUDED.updated_by
                """)
                .setParameter("tenantId", tenantId)
                .setParameter("roleId", roleId)
                .setParameter("componentId", componentId)
                .setParameter("access", access)
                .setParameter("createdBy", createdBy)
                .setParameter("updatedBy", updatedBy)
                .executeUpdate();
    }

    public Optional<CompPermResultRow> findComponentPermission(UUID tenantId, UUID roleId, UUID componentId) {
        @SuppressWarnings("unchecked")
        List<Object[]> rows = em.createNativeQuery("""
                SELECT cp.id, cp.component_id, c.module_key, cp.access, cp.updated_at, cp.created_at,
                       cp.created_by, cp.updated_by
                FROM nxc_menu.component_permissions cp
                JOIN nxc_menu.components c ON c.id = cp.component_id
                WHERE cp.tenant_id = :tenantId
                  AND cp.role_id   = :roleId
                  AND cp.component_id = :componentId
                """)
                .setParameter("tenantId", tenantId)
                .setParameter("roleId", roleId)
                .setParameter("componentId", componentId)
                .getResultList();
        if (rows.isEmpty()) return Optional.empty();
        Object[] r = rows.get(0);
        return Optional.of(new CompPermResultRow(
                toUUID(r[0]), toUUID(r[1]), str(r[2]), str(r[3]),
                toOffsetDateTime(r[4]), toOffsetDateTime(r[5]), toUUID(r[6]), toUUID(r[7])));
    }

    public void upsertElementPermission(
            UUID tenantId, UUID roleId, UUID elementId, String access, UUID createdBy, UUID updatedBy) {
        em.createNativeQuery("""
                INSERT INTO nxc_menu.element_permissions
                    (id, tenant_id, role_id, element_id, access, created_at, updated_at, created_by, updated_by)
                VALUES
                    (gen_random_uuid(), :tenantId, :roleId, :elementId,
                     CAST(:access AS nxc_menu.access_level), NOW(), NOW(), :createdBy, :updatedBy)
                ON CONFLICT (tenant_id, role_id, element_id) DO UPDATE SET
                    access     = CAST(EXCLUDED.access AS nxc_menu.access_level),
                    updated_at = NOW(),
                    updated_by = EXCLUDED.updated_by
                """)
                .setParameter("tenantId", tenantId)
                .setParameter("roleId", roleId)
                .setParameter("elementId", elementId)
                .setParameter("access", access)
                .setParameter("createdBy", createdBy)
                .setParameter("updatedBy", updatedBy)
                .executeUpdate();
    }

    public Optional<ElemPermResultRow> findElementPermission(UUID tenantId, UUID roleId, UUID elementId) {
        @SuppressWarnings("unchecked")
        List<Object[]> rows = em.createNativeQuery("""
                SELECT ep.id, ep.element_id, ce.element_key, ep.access, ep.updated_at, ep.created_at,
                       ep.created_by, ep.updated_by
                FROM nxc_menu.element_permissions ep
                JOIN nxc_menu.component_elements ce ON ce.id = ep.element_id
                WHERE ep.tenant_id  = :tenantId
                  AND ep.role_id    = :roleId
                  AND ep.element_id = :elementId
                """)
                .setParameter("tenantId", tenantId)
                .setParameter("roleId", roleId)
                .setParameter("elementId", elementId)
                .getResultList();
        if (rows.isEmpty()) return Optional.empty();
        Object[] r = rows.get(0);
        return Optional.of(new ElemPermResultRow(
                toUUID(r[0]), toUUID(r[1]), str(r[2]), str(r[3]),
                toOffsetDateTime(r[4]), toOffsetDateTime(r[5]), toUUID(r[6]), toUUID(r[7])));
    }

    // -------------------------------------------------------------------------
    // Row records
    // -------------------------------------------------------------------------

    public record CompPermResultRow(
            UUID id, UUID componentId, String moduleKey, String access,
            OffsetDateTime updatedAt, OffsetDateTime createdAt, UUID createdBy, UUID updatedBy) {}

    public record ElemPermResultRow(
            UUID id, UUID elementId, String elementKey, String access,
            OffsetDateTime updatedAt, OffsetDateTime createdAt, UUID createdBy, UUID updatedBy) {}

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

    private static OffsetDateTime toOffsetDateTime(Object val) {
        if (val == null) return null;
        if (val instanceof OffsetDateTime odt) return odt;
        if (val instanceof java.sql.Timestamp ts) return ts.toInstant().atOffset(java.time.ZoneOffset.UTC);
        return null;
    }
}
