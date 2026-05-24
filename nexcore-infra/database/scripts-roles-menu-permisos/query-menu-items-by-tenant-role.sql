-- Consulta de menu_items por tenant + role
-- Edita los valores en el CTE params.

WITH params AS (
    SELECT
        '00000000-0000-0000-0000-000000000002'::UUID AS tenant_id,
        'TENANT_ADMIN'::TEXT AS role_name
),
role_ctx AS (
    SELECT
        r.id AS role_id,
        r.name AS role_name,
        r.tenant_id
    FROM nxc_tenant.roles r
    JOIN params p ON p.tenant_id = r.tenant_id
    WHERE r.name = p.role_name
      AND r.deleted_at IS NULL
    LIMIT 1
),
menu_base AS (
    SELECT
        mi.id,
        mi.parent_id,
        mi.tenant_id,
        mi.component_id,
        mi.name,
        mi.title,
        mi.route,
        mi.icon,
        mi.icon_type,
        mi.location,
        mi.item_type,
        mi.order_index,
        mi.default_access,
        mi.is_visible,
        mi.is_system
    FROM nxc_menu.menu_items mi
    JOIN params p ON p.tenant_id = mi.tenant_id
    WHERE mi.deleted_at IS NULL
),
menu_with_role AS (
    SELECT
        mb.*,
        cp.access AS role_component_access,
        COALESCE(cp.access, mb.default_access) AS effective_access
    FROM menu_base mb
    CROSS JOIN role_ctx rc
    LEFT JOIN nxc_menu.component_permissions cp
        ON cp.tenant_id = mb.tenant_id
       AND cp.role_id = rc.role_id
       AND cp.component_id = mb.component_id
),
menu_tree AS (
    SELECT
        mwr.*,
        p.name AS parent_name
    FROM menu_with_role mwr
    LEFT JOIN nxc_menu.menu_items p
        ON p.id = mwr.parent_id
)
SELECT
    mt.tenant_id,
    (SELECT role_name FROM role_ctx) AS role_name,
    mt.location,
    mt.item_type,
    mt.parent_name,
    mt.name,
    mt.title,
    mt.route,
    mt.icon,
    mt.icon_type,
    mt.default_access,
    mt.role_component_access,
    mt.effective_access,
    mt.order_index,
    mt.is_visible,
    mt.is_system
FROM menu_tree mt
ORDER BY
    mt.location,
    COALESCE(mt.parent_name, mt.name),
    mt.parent_id NULLS FIRST,
    mt.order_index,
    mt.name;
