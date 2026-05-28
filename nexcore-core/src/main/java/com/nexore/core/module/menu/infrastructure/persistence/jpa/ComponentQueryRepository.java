package com.nexore.core.module.menu.infrastructure.persistence.jpa;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.springframework.stereotype.Repository;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Native SQL queries for nxc_menu.components and nxc_menu.component_elements.
 * Components and elements are read-only in Phase 1 (registered via seed/script).
 */
@Repository
public class ComponentQueryRepository {

    @PersistenceContext
    private EntityManager em;

    public List<ComponentRow> findPagedByTenant(
            UUID tenantId, String search, Boolean isSystem, int page, int size) {
        StringBuilder sql = new StringBuilder("""
                SELECT c.id, c.tenant_id, c.module_key, c.name, c.route, c.description, c.is_system,
                       c.created_at, c.updated_at, c.deleted_at,
                       (SELECT COUNT(*) FROM nxc_menu.component_elements ce
                        WHERE ce.component_id = c.id AND ce.deleted_at IS NULL) AS element_count
                FROM nxc_menu.components c
                WHERE c.tenant_id = :tenantId
                  AND c.deleted_at IS NULL
                """);
        if (search != null && !search.isBlank()) {
            sql.append(" AND (LOWER(c.name) LIKE LOWER(CONCAT('%', :search, '%'))");
            sql.append("   OR LOWER(c.module_key) LIKE LOWER(CONCAT('%', :search, '%')))");
        }
        if (isSystem != null) {
            sql.append(" AND c.is_system = :isSystem");
        }
        sql.append(" ORDER BY c.name LIMIT :size OFFSET :offset");

        var query = em.createNativeQuery(sql.toString())
                .setParameter("tenantId", tenantId)
                .setParameter("size", size)
                .setParameter("offset", (long) page * size);
        if (search != null && !search.isBlank()) query.setParameter("search", search);
        if (isSystem != null) query.setParameter("isSystem", isSystem);

        @SuppressWarnings("unchecked")
        List<Object[]> rows = query.getResultList();
        return rows.stream().map(this::toComponentRow).toList();
    }

    public long countByTenant(UUID tenantId, String search, Boolean isSystem) {
        StringBuilder sql = new StringBuilder("""
                SELECT COUNT(*)
                FROM nxc_menu.components c
                WHERE c.tenant_id = :tenantId
                  AND c.deleted_at IS NULL
                """);
        if (search != null && !search.isBlank()) {
            sql.append(" AND (LOWER(c.name) LIKE LOWER(CONCAT('%', :search, '%'))");
            sql.append("   OR LOWER(c.module_key) LIKE LOWER(CONCAT('%', :search, '%')))");
        }
        if (isSystem != null) {
            sql.append(" AND c.is_system = :isSystem");
        }

        var query = em.createNativeQuery(sql.toString())
                .setParameter("tenantId", tenantId);
        if (search != null && !search.isBlank()) query.setParameter("search", search);
        if (isSystem != null) query.setParameter("isSystem", isSystem);

        Object result = query.getSingleResult();
        return result instanceof Number n ? n.longValue() : Long.parseLong(result.toString());
    }

    public Optional<ComponentRow> findByTenantAndId(UUID tenantId, UUID id) {
        @SuppressWarnings("unchecked")
        List<Object[]> rows = em.createNativeQuery("""
                SELECT c.id, c.tenant_id, c.module_key, c.name, c.route, c.description, c.is_system,
                       c.created_at, c.updated_at, c.deleted_at,
                       (SELECT COUNT(*) FROM nxc_menu.component_elements ce
                        WHERE ce.component_id = c.id AND ce.deleted_at IS NULL) AS element_count
                FROM nxc_menu.components c
                WHERE c.tenant_id = :tenantId
                  AND c.id = :id
                  AND c.deleted_at IS NULL
                """)
                .setParameter("tenantId", tenantId)
                .setParameter("id", id)
                .getResultList();
        return rows.isEmpty() ? Optional.empty() : Optional.of(toComponentRow(rows.get(0)));
    }

    public List<ElementRow> findByComponent(UUID tenantId, UUID componentId) {
        @SuppressWarnings("unchecked")
        List<Object[]> rows = em.createNativeQuery("""
                SELECT ce.id, ce.tenant_id, ce.component_id, ce.element_key,
                       ce.label, ce.element_type, ce.deleted_at
                FROM nxc_menu.component_elements ce
                WHERE ce.tenant_id = :tenantId
                  AND ce.component_id = :componentId
                  AND ce.deleted_at IS NULL
                ORDER BY ce.element_key
                """)
                .setParameter("tenantId", tenantId)
                .setParameter("componentId", componentId)
                .getResultList();
        return rows.stream().map(this::toElementRow).toList();
    }

    public Optional<ElementRow> findElementByTenantAndId(UUID tenantId, UUID elementId) {
        @SuppressWarnings("unchecked")
        List<Object[]> rows = em.createNativeQuery("""
                SELECT ce.id, ce.tenant_id, ce.component_id, ce.element_key,
                       ce.label, ce.element_type, ce.deleted_at
                FROM nxc_menu.component_elements ce
                JOIN nxc_menu.components c ON c.id = ce.component_id
                WHERE c.tenant_id = :tenantId
                  AND ce.id = :elementId
                  AND ce.deleted_at IS NULL
                """)
                .setParameter("tenantId", tenantId)
                .setParameter("elementId", elementId)
                .getResultList();
        return rows.isEmpty() ? Optional.empty() : Optional.of(toElementRow(rows.get(0)));
    }

    // -------------------------------------------------------------------------
    // Row records
    // -------------------------------------------------------------------------

    public record ComponentRow(
            UUID id, UUID tenantId, String moduleKey, String name, String route,
            String description, boolean isSystem, long elementCount,
            OffsetDateTime createdAt, OffsetDateTime updatedAt, OffsetDateTime deletedAt) {}

    public record ElementRow(
            UUID id, UUID tenantId, UUID componentId,
            String elementKey, String label, String elementType, OffsetDateTime deletedAt) {}

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    private ComponentRow toComponentRow(Object[] r) {
        return new ComponentRow(
                toUUID(r[0]), toUUID(r[1]), str(r[2]), str(r[3]), str(r[4]),
                str(r[5]), toBoolean(r[6]), toLong(r[10]),
                toOffsetDateTime(r[7]), toOffsetDateTime(r[8]), toOffsetDateTime(r[9]));
    }

    private ElementRow toElementRow(Object[] r) {
        return new ElementRow(
                toUUID(r[0]), toUUID(r[1]), toUUID(r[2]),
                str(r[3]), str(r[4]), str(r[5]), toOffsetDateTime(r[6]));
    }

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

    private static long toLong(Object val) {
        if (val == null) return 0L;
        if (val instanceof Number n) return n.longValue();
        return Long.parseLong(val.toString());
    }

    private static OffsetDateTime toOffsetDateTime(Object val) {
        if (val == null) return null;
        if (val instanceof OffsetDateTime odt) return odt;
        if (val instanceof java.sql.Timestamp ts) return ts.toInstant().atOffset(java.time.ZoneOffset.UTC);
        return null;
    }
}
