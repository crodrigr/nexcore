DO $$
DECLARE
    -- =========================
    -- PARAMETROS (EDITAR)
    -- =========================
    v_tenant_id      UUID := '00000000-0000-0000-0000-000000000002';
    v_role_name      TEXT := 'TENANT_ADMIN';

    -- Menu item objetivo (registro en nxc_menu.menu_items)
    v_menu_name         TEXT := 'Monitoring';
    v_menu_location     TEXT := 'sidebar';       -- sidebar | profile | navbar
    v_parent_name       TEXT := NULL;            -- ejemplo: 'Admin' o NULL
    v_parent_location   TEXT := 'sidebar';       -- aplica si v_parent_name no es NULL

    -- Permiso final del role sobre el componente
    -- Valores permitidos: EXECUTE | VIEW | HIDDEN
    v_access         nxc_menu.access_level := 'EXECUTE'::nxc_menu.access_level;

    -- Si TRUE, también actualiza default_access del item de menú
    v_update_menu_default_access BOOLEAN := FALSE;

    -- =========================
    -- VARIABLES INTERNAS
    -- =========================
    v_role_id        UUID;
    v_parent_id      UUID;
    v_menu_item_id   UUID;
    v_component_id   UUID;
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

    -- 3) Resolver parent opcional
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

    -- 4) Buscar registro de menú objetivo
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

    IF v_component_id IS NULL THEN
        RAISE EXCEPTION 'El menu item % no tiene component_id asociado. No se puede asignar component_permissions.', v_menu_name;
    END IF;

    -- 5) Upsert permiso en component_permissions
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

    -- 6) Opcional: actualizar default_access del item de menú
    IF v_update_menu_default_access THEN
        UPDATE nxc_menu.menu_items
        SET default_access = v_access,
            updated_at = NOW()
        WHERE id = v_menu_item_id;
    END IF;

    RAISE NOTICE 'OK: role % en tenant % ahora tiene % sobre menu item % (%).',
        v_role_name, v_tenant_id, v_access, v_menu_name, v_menu_location;
END $$;
