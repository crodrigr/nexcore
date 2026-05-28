DO $$
DECLARE
    -- =========================
    -- PARAMETROS (EDITAR)
    -- =========================
    v_tenant_id      UUID := '00000000-0000-0000-0000-000000000002';
    v_component_id   UUID := '00000000-0000-0000-0000-000000000000';

    -- =========================
    -- VARIABLES INTERNAS
    -- =========================
    v_component_name         VARCHAR;
    v_element_ids            UUID[];
    v_menu_preview           TEXT;

    v_count_menu_items       INTEGER := 0;
    v_count_comp_perms       INTEGER := 0;
    v_count_elem_perms       INTEGER := 0;
    v_count_user_overrides   INTEGER := 0;
    v_count_elements         INTEGER := 0;
BEGIN
    -- ── 1. Validar tenant ───────────────────────────────────────────────────
    IF NOT EXISTS (
        SELECT 1 FROM nxc_tenant.tenants t
         WHERE t.id = v_tenant_id AND t.deleted_at IS NULL
    ) THEN
        RAISE EXCEPTION 'Tenant % no existe o está eliminado', v_tenant_id;
    END IF;

    -- ── 2. Validar componente ───────────────────────────────────────────────
    SELECT c.name INTO v_component_name
    FROM nxc_menu.components c
    WHERE c.id        = v_component_id
      AND c.tenant_id = v_tenant_id
      AND c.deleted_at IS NULL;

    IF v_component_name IS NULL THEN
        RAISE EXCEPTION 'Componente % no existe para tenant %', v_component_id, v_tenant_id;
    END IF;

    RAISE NOTICE '>>> Iniciando limpieza del componente: "%" (%)', v_component_name, v_component_id;

    -- ── 3. Recolectar IDs de elements del componente ────────────────────────
    SELECT ARRAY_AGG(ce.id) INTO v_element_ids
    FROM nxc_menu.component_elements ce
    WHERE ce.component_id = v_component_id
      AND ce.tenant_id    = v_tenant_id;

    RAISE NOTICE '    Elements encontrados: %', COALESCE(CARDINALITY(v_element_ids), 0);

    -- ── 4. Preview: menu_items asociados ────────────────────────────────────
    FOR v_menu_preview IN
        SELECT '      - "' || mi.name || '" [' || mi.location || '] id=' || mi.id::TEXT
        FROM nxc_menu.menu_items mi
        WHERE mi.component_id = v_component_id
          AND mi.tenant_id    = v_tenant_id
          AND mi.deleted_at   IS NULL
    LOOP
        RAISE NOTICE '    Menu item: %', v_menu_preview;
    END LOOP;

    -- ── 5. Eliminar user_element_overrides ──────────────────────────────────
    IF v_element_ids IS NOT NULL AND CARDINALITY(v_element_ids) > 0 THEN
        DELETE FROM nxc_menu.user_element_overrides ueo
         WHERE ueo.tenant_id  = v_tenant_id
           AND ueo.element_id = ANY(v_element_ids);
        GET DIAGNOSTICS v_count_user_overrides = ROW_COUNT;
    END IF;

    -- ── 6. Eliminar element_permissions ─────────────────────────────────────
    IF v_element_ids IS NOT NULL AND CARDINALITY(v_element_ids) > 0 THEN
        DELETE FROM nxc_menu.element_permissions ep
         WHERE ep.tenant_id  = v_tenant_id
           AND ep.element_id = ANY(v_element_ids);
        GET DIAGNOSTICS v_count_elem_perms = ROW_COUNT;
    END IF;

    -- ── 7. Eliminar component_permissions ───────────────────────────────────
    DELETE FROM nxc_menu.component_permissions cp
     WHERE cp.tenant_id    = v_tenant_id
       AND cp.component_id = v_component_id;
    GET DIAGNOSTICS v_count_comp_perms = ROW_COUNT;

    -- ── 8. Soft delete menu_items que apuntan a este componente ─────────────
    UPDATE nxc_menu.menu_items mi
       SET deleted_at = NOW(),
           updated_at = NOW()
     WHERE mi.tenant_id    = v_tenant_id
       AND mi.component_id = v_component_id
       AND mi.deleted_at   IS NULL;
    GET DIAGNOSTICS v_count_menu_items = ROW_COUNT;

    -- ── 9. Soft delete component_elements ───────────────────────────────────
    UPDATE nxc_menu.component_elements ce
       SET deleted_at = NOW(),
           updated_at = NOW()
     WHERE ce.tenant_id    = v_tenant_id
       AND ce.component_id = v_component_id
       AND ce.deleted_at   IS NULL;
    GET DIAGNOSTICS v_count_elements = ROW_COUNT;

    -- ── 10. Soft delete del componente ──────────────────────────────────────
    UPDATE nxc_menu.components c
       SET deleted_at = NOW(),
           updated_at = NOW()
     WHERE c.id        = v_component_id
       AND c.tenant_id = v_tenant_id
       AND c.deleted_at IS NULL;

    -- ── Resumen ─────────────────────────────────────────────────────────────
    RAISE NOTICE '';
    RAISE NOTICE '=== RESUMEN ===================================================';
    RAISE NOTICE 'user_element_overrides eliminados      : %', v_count_user_overrides;
    RAISE NOTICE 'element_permissions eliminados         : %', v_count_elem_perms;
    RAISE NOTICE 'component_permissions eliminados       : %', v_count_comp_perms;
    RAISE NOTICE 'menu_items eliminados (logico)         : %', v_count_menu_items;
    RAISE NOTICE 'component_elements eliminados (logico) : %', v_count_elements;
    RAISE NOTICE 'componente eliminado (logico)          : 1';
    RAISE NOTICE '===============================================================';
END $$;
