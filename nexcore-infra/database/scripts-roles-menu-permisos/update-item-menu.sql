DO $$
DECLARE
    -- =========================
    -- PARAMETROS (EDITAR)
    -- =========================
    v_tenant_id         UUID := '00000000-0000-0000-0000-000000000002';
    v_role_name         TEXT := 'TENANT_ADMIN';

    -- Selector del menu item objetivo
    v_menu_name         TEXT := 'Reports';
    v_menu_location     TEXT := 'sidebar';       -- valor actual para ubicar el registro
    v_parent_name       TEXT := NULL;            -- parent actual (ej: 'Admin') o NULL
    v_parent_location   TEXT := 'sidebar';

    -- Campos a actualizar
    v_new_title         TEXT := 'menu.reports';
    v_new_route         TEXT := '/reports';
    v_new_icon          TEXT := 'chart-bar';
    v_new_icon_type     TEXT := 'tabler';        -- tabler | material | custom
    v_new_location      TEXT := 'sidebar';       -- sidebar | profile | navbar
    v_new_item_type     nxc_menu.menu_item_type := 'ITEM'::nxc_menu.menu_item_type;
    v_new_order_index   INTEGER := 70;
    v_new_is_visible    BOOLEAN := TRUE;
    v_new_is_system     BOOLEAN := TRUE;
    v_new_default_access nxc_menu.access_level := 'EXECUTE'::nxc_menu.access_level;
    v_new_feature_flag_key TEXT := NULL;

    -- Si TRUE, sincroniza también component_permissions del role con v_new_default_access
    v_update_role_component_permission BOOLEAN := TRUE;

    -- =========================
    -- VARIABLES INTERNAS
    -- =========================
    v_role_id           UUID;
    v_parent_id         UUID;
    v_menu_item_id      UUID;
    v_component_id      UUID;
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

    -- 3) Resolver parent opcional (actual)
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

    -- 4) Buscar item objetivo por tenant + name + location + parent
    SELECT mi.id, mi.component_id
    INTO v_menu_item_id, v_component_id
    FROM nxc_menu.menu_items mi
    WHERE mi.tenant_id = v_tenant_id
      AND mi.name = v_menu_name
      AND mi.location = v_menu_location
      AND mi.parent_id IS NOT DISTINCT FROM v_parent_id
      AND mi.deleted_at IS NULL
    LIMIT 1;

    IF v_menu_item_id IS NULL THEN
        RAISE EXCEPTION 'No existe menu item % en location % para tenant %', v_menu_name, v_menu_location, v_tenant_id;
    END IF;

    -- 5) Update de campos solicitados
    UPDATE nxc_menu.menu_items mi
       SET title            = v_new_title,
           route            = v_new_route,
           icon             = v_new_icon,
           icon_type        = v_new_icon_type,
           location         = v_new_location,
           item_type        = v_new_item_type,
           order_index      = v_new_order_index,
           is_visible       = v_new_is_visible,
           is_system        = v_new_is_system,
           default_access   = v_new_default_access,
           feature_flag_key = v_new_feature_flag_key,
           updated_at       = NOW()
     WHERE mi.id = v_menu_item_id;

    -- 6) Opcional: sincronizar permiso del role para el componente del item
    IF v_update_role_component_permission
       AND v_component_id IS NOT NULL THEN
        INSERT INTO nxc_menu.component_permissions (
            tenant_id, role_id, component_id, access, created_by, created_at, updated_at
        )
        VALUES (
            v_tenant_id, v_role_id, v_component_id, v_new_default_access, NULL, NOW(), NOW()
        )
        ON CONFLICT (tenant_id, role_id, component_id)
        DO UPDATE
           SET access = EXCLUDED.access,
               updated_at = NOW();
    END IF;

    RAISE NOTICE 'OK: menu item % actualizado para tenant % (role %).',
        v_menu_name, v_tenant_id, v_role_name;
END $$;
