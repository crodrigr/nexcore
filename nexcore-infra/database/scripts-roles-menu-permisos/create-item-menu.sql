DO $$
DECLARE
    -- =========================
    -- PARAMETROS (EDITAR)
    -- =========================
    v_tenant_id         UUID := '00000000-0000-0000-0000-000000000002'; -- tenant objetivo
    v_role_name         TEXT := 'TENANT_ADMIN';                           -- role objetivo

    -- Componente (se crea/actualiza si no existe)
    v_module_key        TEXT := 'reports';
    v_component_name    TEXT := 'Reports';
    v_component_route   TEXT := '/reports';
    v_component_desc    TEXT := 'Modulo de reportes';

    -- Menu item
    v_menu_name         TEXT := 'Reports';
    v_menu_title_key    TEXT := 'menu.reports';
    v_menu_route        TEXT := '/reports';
    v_menu_icon         TEXT := 'chart-bar';
    v_menu_icon_type    TEXT := 'tabler';
    v_menu_location     TEXT := 'sidebar'; -- sidebar | profile | navbar
    v_menu_item_type    TEXT := 'ITEM';    -- ITEM | GROUP | DIVIDER
    v_menu_order        INTEGER := 70;

    -- Parent opcional (si va dentro de un grupo)
    v_parent_name       TEXT := NULL;      -- ej: 'Admin' o NULL
    v_parent_location   TEXT := 'sidebar';

    -- Permiso del role sobre el componente
    v_access            nxc_menu.access_level := 'EXECUTE'::nxc_menu.access_level;

    -- =========================
    -- VARIABLES INTERNAS
    -- =========================
    v_role_id           UUID;
    v_component_id      UUID;
    v_parent_id         UUID;
BEGIN
    -- 1) Validar tenant
    IF NOT EXISTS (
        SELECT 1
        FROM nxc_tenant.tenants t
        WHERE t.id = v_tenant_id
          AND t.deleted_at IS NULL
    ) THEN
        RAISE EXCEPTION 'Tenant % no existe', v_tenant_id;
    END IF;

    -- 2) Obtener role del tenant
    SELECT r.id INTO v_role_id
    FROM nxc_tenant.roles r
    WHERE r.tenant_id = v_tenant_id
      AND r.name = v_role_name
      AND r.deleted_at IS NULL
    LIMIT 1;

    IF v_role_id IS NULL THEN
        RAISE EXCEPTION 'Role % no existe para tenant %', v_role_name, v_tenant_id;
    END IF;

    -- 3) Upsert componente
    INSERT INTO nxc_menu.components (
        tenant_id, module_key, name, route, description, is_system,
        created_by, created_at, updated_at, version
    )
    VALUES (
        v_tenant_id, v_module_key, v_component_name, v_component_route, v_component_desc, TRUE,
        NULL, NOW(), NOW(), 0
    )
    ON CONFLICT (tenant_id, module_key)
    DO UPDATE
       SET name = EXCLUDED.name,
           route = EXCLUDED.route,
           description = EXCLUDED.description,
           updated_at = NOW();

    SELECT c.id INTO v_component_id
    FROM nxc_menu.components c
    WHERE c.tenant_id = v_tenant_id
      AND c.module_key = v_module_key;

    -- 4) Resolver parent opcional
    v_parent_id := NULL;
    IF v_parent_name IS NOT NULL THEN
        SELECT mi.id INTO v_parent_id
        FROM nxc_menu.menu_items mi
        WHERE mi.tenant_id = v_tenant_id
          AND mi.name = v_parent_name
          AND mi.location = v_parent_location
          AND mi.parent_id IS NULL
          AND mi.deleted_at IS NULL
        LIMIT 1;

        IF v_parent_id IS NULL THEN
            RAISE EXCEPTION 'Parent menu % no encontrado en location %', v_parent_name, v_parent_location;
        END IF;
    END IF;

    -- 5) Upsert menu item (por tenant + name + location + parent)
    UPDATE nxc_menu.menu_items mi
       SET component_id    = v_component_id,
           title           = v_menu_title_key,
           route           = v_menu_route,
           icon            = v_menu_icon,
           icon_type       = v_menu_icon_type,
           item_type       = v_menu_item_type,
           order_index     = v_menu_order,
           is_visible      = TRUE,
           is_system       = TRUE,
           default_access  = v_access,
           updated_at      = NOW()
     WHERE mi.tenant_id = v_tenant_id
       AND mi.name = v_menu_name
       AND mi.location = v_menu_location
       AND mi.parent_id IS NOT DISTINCT FROM v_parent_id;

    IF NOT FOUND THEN
        INSERT INTO nxc_menu.menu_items (
            tenant_id, component_id, parent_id,
            name, title, route, icon, icon_type, location,
            item_type, order_index, is_visible, is_system, default_access,
            created_by, created_at, updated_at, version
        )
        VALUES (
            v_tenant_id, v_component_id, v_parent_id,
            v_menu_name, v_menu_title_key, v_menu_route, v_menu_icon, v_menu_icon_type, v_menu_location,
            v_menu_item_type, v_menu_order, TRUE, TRUE, v_access,
            NULL, NOW(), NOW(), 0
        );
    END IF;

    -- 6) Permiso del role sobre componente
    INSERT INTO nxc_menu.component_permissions (
        tenant_id, role_id, component_id, access, created_by, created_at, updated_at
    )
    VALUES (
        v_tenant_id, v_role_id, v_component_id, v_access, NULL, NOW(), NOW()
    )
    ON CONFLICT (tenant_id, role_id, component_id)
    DO UPDATE
       SET access = EXCLUDED.access,
           updated_at = NOW();

    RAISE NOTICE 'OK: menu % agregado/actualizado para role % en tenant %',
        v_menu_name, v_role_name, v_tenant_id;
END $$;