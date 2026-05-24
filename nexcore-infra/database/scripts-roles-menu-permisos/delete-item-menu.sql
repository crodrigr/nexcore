DO $$
DECLARE
    -- =========================
    -- PARAMETROS (EDITAR)
    -- =========================
    v_tenant_id         UUID := '00000000-0000-0000-0000-000000000002';
    v_role_name         TEXT := 'TENANT_ADMIN';

    -- Menu item objetivo
    v_menu_name         TEXT := 'Monitoring';
    v_menu_location     TEXT := 'sidebar';       -- sidebar | profile | navbar
    v_parent_name       TEXT := NULL;            -- ejemplo: 'Admin' o NULL
    v_parent_location   TEXT := 'sidebar';       -- aplica si v_parent_name no es NULL

    -- Comportamiento
    v_delete_children           BOOLEAN := TRUE;   -- elimina hijos recursivamente
    v_delete_component_elements BOOLEAN := FALSE;  -- soft delete en component_elements asociados
    v_delete_orphan_components  BOOLEAN := FALSE;  -- soft delete en components sin menu_items activos

    -- =========================
    -- VARIABLES INTERNAS
    -- =========================
    v_role_id            UUID;
    v_parent_id          UUID;
    v_menu_item_id       UUID;

    v_menu_ids           UUID[];
    v_component_ids      UUID[];

    v_count_menu_items           INTEGER := 0;
    v_count_component_perms      INTEGER := 0;
    v_count_element_perms        INTEGER := 0;
    v_count_component_elements   INTEGER := 0;
    v_count_components           INTEGER := 0;
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

    -- 4) Buscar menu item objetivo
    SELECT mi.id INTO v_menu_item_id
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

    -- 5) Construir lista de menu_items (objetivo + hijos opcionales) y componentes asociados
    IF v_delete_children THEN
        WITH RECURSIVE subtree AS (
            SELECT mi.id, mi.component_id
            FROM nxc_menu.menu_items mi
            WHERE mi.id = v_menu_item_id
              AND mi.tenant_id = v_tenant_id
              AND mi.deleted_at IS NULL

            UNION ALL

            SELECT ch.id, ch.component_id
            FROM nxc_menu.menu_items ch
            JOIN subtree st ON st.id = ch.parent_id
            WHERE ch.tenant_id = v_tenant_id
              AND ch.deleted_at IS NULL
        )
        SELECT
            ARRAY_AGG(st.id),
            ARRAY_REMOVE(ARRAY_AGG(DISTINCT st.component_id), NULL)
        INTO v_menu_ids, v_component_ids
        FROM subtree st;
    ELSE
        SELECT
            ARRAY[mi.id],
            ARRAY_REMOVE(ARRAY[mi.component_id], NULL)
        INTO v_menu_ids, v_component_ids
        FROM nxc_menu.menu_items mi
        WHERE mi.id = v_menu_item_id;
    END IF;

    -- 6) Soft delete menu_items
    UPDATE nxc_menu.menu_items mi
       SET deleted_at = NOW(),
           updated_at = NOW()
     WHERE mi.tenant_id = v_tenant_id
       AND mi.id = ANY(v_menu_ids)
       AND mi.deleted_at IS NULL;

    GET DIAGNOSTICS v_count_menu_items = ROW_COUNT;

    -- 7) Eliminar permisos de componente para el role y componentes afectados
    IF v_component_ids IS NOT NULL AND CARDINALITY(v_component_ids) > 0 THEN
        DELETE FROM nxc_menu.component_permissions cp
         WHERE cp.tenant_id = v_tenant_id
           AND cp.role_id = v_role_id
           AND cp.component_id = ANY(v_component_ids);

        GET DIAGNOSTICS v_count_component_perms = ROW_COUNT;

        -- 8) Eliminar permisos de elementos del role para elementos de esos componentes
        DELETE FROM nxc_menu.element_permissions ep
        USING nxc_menu.component_elements ce
        WHERE ep.tenant_id = v_tenant_id
          AND ep.role_id = v_role_id
          AND ce.tenant_id = v_tenant_id
          AND ce.id = ep.element_id
          AND ce.component_id = ANY(v_component_ids);

        GET DIAGNOSTICS v_count_element_perms = ROW_COUNT;

        -- 9) Opcional: soft delete de elementos de componente
        IF v_delete_component_elements THEN
            UPDATE nxc_menu.component_elements ce
               SET deleted_at = NOW(),
                   updated_at = NOW()
             WHERE ce.tenant_id = v_tenant_id
               AND ce.component_id = ANY(v_component_ids)
               AND ce.deleted_at IS NULL;

            GET DIAGNOSTICS v_count_component_elements = ROW_COUNT;
        END IF;

        -- 10) Opcional: soft delete de componentes sin menu_items activos
        IF v_delete_orphan_components THEN
            UPDATE nxc_menu.components c
               SET deleted_at = NOW(),
                   updated_at = NOW()
             WHERE c.tenant_id = v_tenant_id
               AND c.id = ANY(v_component_ids)
               AND c.deleted_at IS NULL
               AND NOT EXISTS (
                   SELECT 1
                   FROM nxc_menu.menu_items mi
                   WHERE mi.tenant_id = v_tenant_id
                     AND mi.component_id = c.id
                     AND mi.deleted_at IS NULL
               );

            GET DIAGNOSTICS v_count_components = ROW_COUNT;
        END IF;
    END IF;

    RAISE NOTICE 'OK: menu_items eliminados(logico)=%', v_count_menu_items;
    RAISE NOTICE 'OK: component_permissions eliminados=%', v_count_component_perms;
    RAISE NOTICE 'OK: element_permissions eliminados=%', v_count_element_perms;
    RAISE NOTICE 'OK: component_elements eliminados(logico)=%', v_count_component_elements;
    RAISE NOTICE 'OK: components eliminados(logico)=%', v_count_components;
END $$;
