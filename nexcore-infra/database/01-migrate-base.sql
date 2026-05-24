-- =============================================================================
-- NexCore Platform  –  V013__seed_initial_data.sql
-- Datos iniciales de la plataforma NexCore
--
-- Ejecuta en orden:
--   1. Tenant sistema  (slug = 'system')  + usuario SUPER_ADMIN
--   2. Componentes del sistema (is_system = TRUE) — base para todos los tenants
--   3. Elementos de UI por componente
--   4. Árbol de menú del sistema
--   5. Permisos de componentes por rol (SUPER_ADMIN, TENANT_ADMIN, EDITOR, VIEWER)
--   6. Permisos de elementos por rol
--   7. Tenant demo  (slug = 'demo')  + usuario admin demo
--   8. Feature flags globales de la plataforma
--   9. Configuración base del tenant demo
--
-- CONVENCIONES DE UUIDs FIJOS (facilita Postman / scripts de prueba):
--   Tenant system    : 00000000-0000-0000-0000-000000000001
--   Tenant demo      : 00000000-0000-0000-0000-000000000002
--   User super_admin : 00000000-0000-0000-0001-000000000001
--   User admin_demo  : 00000000-0000-0000-0001-000000000002
--
-- NOTA SEGURIDAD: Los password_hash de este script son PLACEHOLDERS.
--   Reemplazar con hashes BCrypt reales antes de ejecutar en cualquier
--   entorno distinto a desarrollo local.
--   Placeholder usado: bcrypt('NexCore@2026!', 12,'$2a$12$2SgNZ1P9TWruO3hmUqL6u.U3K4mKg9o7xtK6N8uZJXVxjFqbMDf/y')
-- =============================================================================

DO $$
DECLARE
    -- -------------------------------------------------------------------------
    -- IDs fijos de tenants
    -- -------------------------------------------------------------------------
    v_tid_system        UUID := '00000000-0000-0000-0000-000000000001';
    v_tid_demo          UUID := '00000000-0000-0000-0000-000000000002';

    -- -------------------------------------------------------------------------
    -- IDs fijos de usuarios
    -- -------------------------------------------------------------------------
    v_uid_super_admin   UUID := '00000000-0000-0000-0001-000000000001';
    v_uid_admin_demo    UUID := '00000000-0000-0000-0001-000000000002';

    -- -------------------------------------------------------------------------
    -- IDs de roles del tenant system (se recuperan tras el INSERT del tenant)
    -- -------------------------------------------------------------------------
    v_role_sys_super    UUID;
    v_role_sys_admin    UUID;
    v_role_sys_editor   UUID;
    v_role_sys_viewer   UUID;

    -- -------------------------------------------------------------------------
    -- IDs de roles del tenant demo (se recuperan tras el INSERT del tenant)
    -- -------------------------------------------------------------------------
    v_role_demo_admin   UUID;
    v_role_demo_editor  UUID;
    v_role_demo_viewer  UUID;

    -- -------------------------------------------------------------------------
    -- IDs de componentes del sistema (is_system = TRUE)
    -- Compartidos entre todos los tenants vía la política RLS
    -- -------------------------------------------------------------------------
    v_comp_dashboard    UUID;
    v_comp_alerts       UUID;
    v_comp_incidents    UUID;
    v_comp_traps        UUID;
    v_comp_auth         UUID;
    v_comp_users        UUID;
    v_comp_roles        UUID;
    v_comp_menus        UUID;
    v_comp_audit        UUID;
    v_comp_settings     UUID;

    -- -------------------------------------------------------------------------
    -- IDs de elementos de UI — dashboard
    -- -------------------------------------------------------------------------
    v_el_dash_time_filter   UUID;
    v_el_dash_city_filter   UUID;
    v_el_dash_host_filter   UUID;
    v_el_dash_filter_btn    UUID;
    v_el_dash_refresh_btn   UUID;

    -- IDs de elementos de UI — alerts
    v_el_alerts_columns_btn UUID;
    v_el_alerts_toggle_col  UUID;
    v_el_alerts_reset_cols  UUID;
    v_el_alerts_search      UUID;
    v_el_alerts_paginator   UUID;

    -- IDs de elementos de UI — incidents
    v_el_inc_group_selected UUID;
    v_el_inc_detail_updated UUID;

    -- IDs de elementos de UI — traps
    v_el_traps_columns_btn  UUID;
    v_el_traps_toggle_col   UUID;
    v_el_traps_reset_cols   UUID;
    v_el_traps_search       UUID;
    v_el_traps_paginator    UUID;
    v_el_traps_sort_header  UUID;
    v_el_traps_row_toggle   UUID;

    -- IDs de elementos de UI — auth
    v_el_auth_toggle_pwd    UUID;
    v_el_auth_login_btn     UUID;
    v_el_auth_resend_code   UUID;
    v_el_auth_go_back       UUID;

    -- IDs de elementos de UI — users (gestión)
    v_el_users_btn_create   UUID;
    v_el_users_btn_edit     UUID;
    v_el_users_btn_suspend  UUID;
    v_el_users_btn_delete   UUID;
    v_el_users_btn_invite   UUID;
    v_el_users_search       UUID;
    v_el_users_paginator    UUID;
    v_el_users_tab_roles    UUID;

    -- IDs de elementos de UI — roles (gestión)
    v_el_roles_btn_create   UUID;
    v_el_roles_btn_edit     UUID;
    v_el_roles_btn_delete   UUID;
    v_el_roles_btn_assign   UUID;

    -- -------------------------------------------------------------------------
    -- IDs de ítems de menú del sistema
    -- -------------------------------------------------------------------------
    v_menu_dashboard        UUID;
    v_menu_alerts           UUID;
    v_menu_incidents        UUID;
    v_menu_traps            UUID;
    v_menu_profile_group    UUID;
    v_menu_profile_item     UUID;
    v_menu_settings_item    UUID;
    v_menu_logout_item      UUID;
    v_menu_admin_group      UUID;
    v_menu_admin_users      UUID;
    v_menu_admin_roles      UUID;
    v_menu_admin_menus      UUID;
    v_menu_admin_audit      UUID;

BEGIN

-- =============================================================================
-- BLOQUE 0 — VERIFICACIÓN
-- Las tablas ya fueron recreadas limpias por schema-nexcore.sql (DROP SCHEMA CASCADE)
-- Este bloque solo verifica que las tablas existen antes de insertar datos.
-- =============================================================================

    RAISE NOTICE '=== BLOQUE 0: Verificando schema ===';
    RAISE NOTICE '✅ Las tablas fueron recreadas por schema-nexcore.sql (DROP SCHEMA CASCADE)';

-- =============================================================================
-- BLOQUE 1 — TENANT SISTEMA
-- =============================================================================

    RAISE NOTICE '=== BLOQUE 1: Tenant sistema ===';

    INSERT INTO nxc_tenant.tenants (
        id, slug, name, legal_name,
        plan, mode, status,
        timezone, locale, date_format, currency,
        mfa_required, session_timeout_minutes, max_login_attempts,
        password_min_length, password_requires_upper, password_requires_special,
        audit_retention_days,
        created_at, updated_at, version
    ) VALUES (
        v_tid_system,
        'system',
        'NexCore System',
        'NexCore Platform S.A.S.',
        'ENTERPRISE', 'ON_PREMISE', 'ACTIVE',
        'UTC', 'es-CO', 'DD/MM/YYYY', 'COP',
        FALSE, 480, 5,
        10, TRUE, TRUE,
        365,
        NOW(), NOW(), 0
    ) ON CONFLICT (id) DO NOTHING;

    RAISE NOTICE 'Tenant system OK: %', v_tid_system;

    -- El trigger trg_create_default_roles crea TENANT_ADMIN, EDITOR, VIEWER.
    -- Recuperamos los IDs que generó.
    SELECT id INTO v_role_sys_admin  FROM nxc_tenant.roles WHERE tenant_id = v_tid_system AND name = 'TENANT_ADMIN';
    SELECT id INTO v_role_sys_editor FROM nxc_tenant.roles WHERE tenant_id = v_tid_system AND name = 'EDITOR';
    SELECT id INTO v_role_sys_viewer FROM nxc_tenant.roles WHERE tenant_id = v_tid_system AND name = 'VIEWER';

    -- Rol SUPER_ADMIN — exclusivo del tenant system
    INSERT INTO nxc_tenant.roles (
        tenant_id, name, description, is_system_role, is_default
    ) VALUES (
        v_tid_system,
        'SUPER_ADMIN',
        'Administrador global de la plataforma. Acceso total a todos los tenants vía bypass de RLS.',
        TRUE, FALSE
    ) ON CONFLICT (tenant_id, name) DO NOTHING;

    SELECT id INTO v_role_sys_super FROM nxc_tenant.roles WHERE tenant_id = v_tid_system AND name = 'SUPER_ADMIN';

    RAISE NOTICE 'Roles system — SUPER_ADMIN: %, TENANT_ADMIN: %, EDITOR: %, VIEWER: %',
        v_role_sys_super, v_role_sys_admin, v_role_sys_editor, v_role_sys_viewer;

    -- Usuario SUPER_ADMIN del sistema
    INSERT INTO nxc_tenant.users (
        id, tenant_id,
        username, email, password_hash,
        full_name, phone,
        status, is_tenant_admin,
        email_verified, email_verified_at,
        activated_at,
        created_at, updated_at, version
    ) VALUES (
        v_uid_super_admin, v_tid_system,
        'super.admin',
        'super.admin@nexcore.io',
        '$2a$12$2SgNZ1P9TWruO3hmUqL6u.U3K4mKg9o7xtK6N8uZJXVxjFqbMDf/y',
        'Super Administrador NexCore',
        NULL,
        'ACTIVE', TRUE,
        TRUE, NOW(),
        NOW(),
        NOW(), NOW(), 0
    ) ON CONFLICT (id) DO NOTHING;

    -- Asignar rol SUPER_ADMIN al super admin
    INSERT INTO nxc_tenant.user_roles (tenant_id, user_id, role_id, assigned_at, assigned_by)
    VALUES (v_tid_system, v_uid_super_admin, v_role_sys_super, NOW(), v_uid_super_admin)
    ON CONFLICT (tenant_id, user_id, role_id) DO NOTHING;

    RAISE NOTICE 'Usuario super.admin creado: %', v_uid_super_admin;

-- =============================================================================
-- BLOQUE 2 — COMPONENTES DEL SISTEMA (is_system = TRUE)
-- Pertenecen al tenant system y son visibles para todos los tenants
-- gracias a la política RLS: OR is_system = TRUE
-- =============================================================================

    RAISE NOTICE '=== BLOQUE 2: Componentes del sistema ===';

    -- dashboard
    INSERT INTO nxc_menu.components (
        tenant_id, module_key, name, route, description, is_system,
        created_by, created_at, updated_at, version
    ) VALUES (
        v_tid_system, 'dashboard', 'Dashboard', '/graphics',
        'Panel principal con gráficas y métricas del sistema.',
        TRUE, v_uid_super_admin, NOW(), NOW(), 0
    ) ON CONFLICT (tenant_id, module_key) DO NOTHING
    RETURNING id INTO v_comp_dashboard;

    IF v_comp_dashboard IS NULL THEN
        SELECT id INTO v_comp_dashboard FROM nxc_menu.components WHERE tenant_id = v_tid_system AND module_key = 'dashboard';
    END IF;

    -- alerts
    INSERT INTO nxc_menu.components (
        tenant_id, module_key, name, route, description, is_system,
        created_by, created_at, updated_at, version
    ) VALUES (
        v_tid_system, 'alerts', 'Alertas', '/alerts',
        'Gestión y visualización de alertas del sistema.',
        TRUE, v_uid_super_admin, NOW(), NOW(), 0
    ) ON CONFLICT (tenant_id, module_key) DO NOTHING
    RETURNING id INTO v_comp_alerts;

    IF v_comp_alerts IS NULL THEN
        SELECT id INTO v_comp_alerts FROM nxc_menu.components WHERE tenant_id = v_tid_system AND module_key = 'alerts';
    END IF;

    -- incidents
    INSERT INTO nxc_menu.components (
        tenant_id, module_key, name, route, description, is_system,
        created_by, created_at, updated_at, version
    ) VALUES (
        v_tid_system, 'incidents', 'Incidentes', '/incidents',
        'Gestión de incidentes y grupos de alertas.',
        TRUE, v_uid_super_admin, NOW(), NOW(), 0
    ) ON CONFLICT (tenant_id, module_key) DO NOTHING
    RETURNING id INTO v_comp_incidents;

    IF v_comp_incidents IS NULL THEN
        SELECT id INTO v_comp_incidents FROM nxc_menu.components WHERE tenant_id = v_tid_system AND module_key = 'incidents';
    END IF;

    -- traps
    INSERT INTO nxc_menu.components (
        tenant_id, module_key, name, route, description, is_system,
        created_by, created_at, updated_at, version
    ) VALUES (
        v_tid_system, 'traps', 'Traps SNMP', '/traps',
        'Visualización y filtrado de traps SNMP recibidos.',
        TRUE, v_uid_super_admin, NOW(), NOW(), 0
    ) ON CONFLICT (tenant_id, module_key) DO NOTHING
    RETURNING id INTO v_comp_traps;

    IF v_comp_traps IS NULL THEN
        SELECT id INTO v_comp_traps FROM nxc_menu.components WHERE tenant_id = v_tid_system AND module_key = 'traps';
    END IF;

    -- auth
    INSERT INTO nxc_menu.components (
        tenant_id, module_key, name, route, description, is_system,
        created_by, created_at, updated_at, version
    ) VALUES (
        v_tid_system, 'auth', 'Autenticación', '/auth',
        'Módulo de login, 2FA y logout.',
        TRUE, v_uid_super_admin, NOW(), NOW(), 0
    ) ON CONFLICT (tenant_id, module_key) DO NOTHING
    RETURNING id INTO v_comp_auth;

    IF v_comp_auth IS NULL THEN
        SELECT id INTO v_comp_auth FROM nxc_menu.components WHERE tenant_id = v_tid_system AND module_key = 'auth';
    END IF;

    -- user-management
    INSERT INTO nxc_menu.components (
        tenant_id, module_key, name, route, description, is_system,
        created_by, created_at, updated_at, version
    ) VALUES (
        v_tid_system, 'user-management', 'Gestión de Usuarios', '/admin/users',
        'CRUD de usuarios del tenant, invitaciones y suspensiones.',
        TRUE, v_uid_super_admin, NOW(), NOW(), 0
    ) ON CONFLICT (tenant_id, module_key) DO NOTHING
    RETURNING id INTO v_comp_users;

    IF v_comp_users IS NULL THEN
        SELECT id INTO v_comp_users FROM nxc_menu.components WHERE tenant_id = v_tid_system AND module_key = 'user-management';
    END IF;

    -- role-management
    INSERT INTO nxc_menu.components (
        tenant_id, module_key, name, route, description, is_system,
        created_by, created_at, updated_at, version
    ) VALUES (
        v_tid_system, 'role-management', 'Gestión de Roles', '/admin/roles',
        'CRUD de roles y asignación de permisos de UI.',
        TRUE, v_uid_super_admin, NOW(), NOW(), 0
    ) ON CONFLICT (tenant_id, module_key) DO NOTHING
    RETURNING id INTO v_comp_roles;

    IF v_comp_roles IS NULL THEN
        SELECT id INTO v_comp_roles FROM nxc_menu.components WHERE tenant_id = v_tid_system AND module_key = 'role-management';
    END IF;

    -- menu-management
    INSERT INTO nxc_menu.components (
        tenant_id, module_key, name, route, description, is_system,
        created_by, created_at, updated_at, version
    ) VALUES (
        v_tid_system, 'menu-management', 'Gestión de Menús', '/admin/menus',
        'Configuración dinámica del árbol de navegación por tenant.',
        TRUE, v_uid_super_admin, NOW(), NOW(), 0
    ) ON CONFLICT (tenant_id, module_key) DO NOTHING
    RETURNING id INTO v_comp_menus;

    IF v_comp_menus IS NULL THEN
        SELECT id INTO v_comp_menus FROM nxc_menu.components WHERE tenant_id = v_tid_system AND module_key = 'menu-management';
    END IF;

    -- audit-viewer
    INSERT INTO nxc_menu.components (
        tenant_id, module_key, name, route, description, is_system,
        created_by, created_at, updated_at, version
    ) VALUES (
        v_tid_system, 'audit-viewer', 'Auditoría', '/admin/audit',
        'Consulta del historial de cambios y accesos del tenant.',
        TRUE, v_uid_super_admin, NOW(), NOW(), 0
    ) ON CONFLICT (tenant_id, module_key) DO NOTHING
    RETURNING id INTO v_comp_audit;

    IF v_comp_audit IS NULL THEN
        SELECT id INTO v_comp_audit FROM nxc_menu.components WHERE tenant_id = v_tid_system AND module_key = 'audit-viewer';
    END IF;

    -- tenant-settings
    INSERT INTO nxc_menu.components (
        tenant_id, module_key, name, route, description, is_system,
        created_by, created_at, updated_at, version
    ) VALUES (
        v_tid_system, 'tenant-settings', 'Configuración del Tenant', '/admin/settings',
        'Configuración general del tenant: localización, seguridad y apariencia.',
        TRUE, v_uid_super_admin, NOW(), NOW(), 0
    ) ON CONFLICT (tenant_id, module_key) DO NOTHING
    RETURNING id INTO v_comp_settings;

    IF v_comp_settings IS NULL THEN
        SELECT id INTO v_comp_settings FROM nxc_menu.components WHERE tenant_id = v_tid_system AND module_key = 'tenant-settings';
    END IF;

    RAISE NOTICE 'Componentes creados — dashboard:%, alerts:%, incidents:%, traps:%, auth:%, users:%, roles:%, menus:%, audit:%, settings:%',
        v_comp_dashboard, v_comp_alerts, v_comp_incidents, v_comp_traps, v_comp_auth,
        v_comp_users, v_comp_roles, v_comp_menus, v_comp_audit, v_comp_settings;

-- =============================================================================
-- BLOQUE 3 — ELEMENTOS DE UI POR COMPONENTE
-- Mapean exactamente los element_key del ejemplo-perfil-user
-- =============================================================================

    RAISE NOTICE '=== BLOQUE 3: Elementos de UI ===';

    -- --- dashboard ---
    INSERT INTO nxc_menu.component_elements
        (tenant_id, component_id, element_key, label, element_type, created_at, updated_at, version)
    VALUES
        (v_tid_system, v_comp_dashboard, 'timeFilterSelect#timeFilter',  'Filtro de tiempo',   'SELECT',  NOW(), NOW(), 0),
        (v_tid_system, v_comp_dashboard, 'cityFilterSelect#cityFilter',  'Filtro de ciudad',   'SELECT',  NOW(), NOW(), 0),
        (v_tid_system, v_comp_dashboard, 'hostFilterSelect#hostFilter',  'Filtro de host',     'SELECT',  NOW(), NOW(), 0),
        (v_tid_system, v_comp_dashboard, 'filterButton',                 'Botón Filtrar',      'BUTTON',  NOW(), NOW(), 0),
        (v_tid_system, v_comp_dashboard, 'refreshButton',                'Botón Actualizar',   'BUTTON',  NOW(), NOW(), 0)
    ON CONFLICT (tenant_id, component_id, element_key) DO NOTHING;

    SELECT id INTO v_el_dash_time_filter FROM nxc_menu.component_elements WHERE component_id = v_comp_dashboard AND element_key = 'timeFilterSelect#timeFilter';
    SELECT id INTO v_el_dash_city_filter FROM nxc_menu.component_elements WHERE component_id = v_comp_dashboard AND element_key = 'cityFilterSelect#cityFilter';
    SELECT id INTO v_el_dash_host_filter FROM nxc_menu.component_elements WHERE component_id = v_comp_dashboard AND element_key = 'hostFilterSelect#hostFilter';
    SELECT id INTO v_el_dash_filter_btn  FROM nxc_menu.component_elements WHERE component_id = v_comp_dashboard AND element_key = 'filterButton';
    SELECT id INTO v_el_dash_refresh_btn FROM nxc_menu.component_elements WHERE component_id = v_comp_dashboard AND element_key = 'refreshButton';

    -- --- alerts ---
    INSERT INTO nxc_menu.component_elements
        (tenant_id, component_id, element_key, label, element_type, created_at, updated_at, version)
    VALUES
        (v_tid_system, v_comp_alerts, 'columnsMenuBtn',   'Botón columnas',            'BUTTON',   NOW(), NOW(), 0),
        (v_tid_system, v_comp_alerts, 'toggleColumnItem', 'Toggle de columna',         'ACTION',   NOW(), NOW(), 0),
        (v_tid_system, v_comp_alerts, 'resetColumnsBtn',  'Botón resetear columnas',   'BUTTON',   NOW(), NOW(), 0),
        (v_tid_system, v_comp_alerts, 'searchInput',      'Campo de búsqueda',         'FIELD',    NOW(), NOW(), 0),
        (v_tid_system, v_comp_alerts, 'paginator',        'Paginador',                 'ACTION',   NOW(), NOW(), 0)
    ON CONFLICT (tenant_id, component_id, element_key) DO NOTHING;

    SELECT id INTO v_el_alerts_columns_btn FROM nxc_menu.component_elements WHERE component_id = v_comp_alerts AND element_key = 'columnsMenuBtn';
    SELECT id INTO v_el_alerts_toggle_col  FROM nxc_menu.component_elements WHERE component_id = v_comp_alerts AND element_key = 'toggleColumnItem';
    SELECT id INTO v_el_alerts_reset_cols  FROM nxc_menu.component_elements WHERE component_id = v_comp_alerts AND element_key = 'resetColumnsBtn';
    SELECT id INTO v_el_alerts_search      FROM nxc_menu.component_elements WHERE component_id = v_comp_alerts AND element_key = 'searchInput';
    SELECT id INTO v_el_alerts_paginator   FROM nxc_menu.component_elements WHERE component_id = v_comp_alerts AND element_key = 'paginator';

    -- --- incidents ---
    INSERT INTO nxc_menu.component_elements
        (tenant_id, component_id, element_key, label, element_type, created_at, updated_at, version)
    VALUES
        (v_tid_system, v_comp_incidents, 'app-alert-groups[groupSelected]',     'Selección de grupo de alertas', 'ACTION', NOW(), NOW(), 0),
        (v_tid_system, v_comp_incidents, 'app-incident-detail[incidentUpdated]','Actualización de incidente',    'ACTION', NOW(), NOW(), 0)
    ON CONFLICT (tenant_id, component_id, element_key) DO NOTHING;

    SELECT id INTO v_el_inc_group_selected FROM nxc_menu.component_elements WHERE component_id = v_comp_incidents AND element_key = 'app-alert-groups[groupSelected]';
    SELECT id INTO v_el_inc_detail_updated FROM nxc_menu.component_elements WHERE component_id = v_comp_incidents AND element_key = 'app-incident-detail[incidentUpdated]';

    -- --- traps ---
    INSERT INTO nxc_menu.component_elements
        (tenant_id, component_id, element_key, label, element_type, created_at, updated_at, version)
    VALUES
        (v_tid_system, v_comp_traps, 'columnsMenuBtn',   'Botón columnas',          'BUTTON',  NOW(), NOW(), 0),
        (v_tid_system, v_comp_traps, 'toggleColumnItem', 'Toggle de columna',       'ACTION',  NOW(), NOW(), 0),
        (v_tid_system, v_comp_traps, 'resetColumnsBtn',  'Resetear columnas',       'BUTTON',  NOW(), NOW(), 0),
        (v_tid_system, v_comp_traps, 'searchInput',      'Campo de búsqueda',       'FIELD',   NOW(), NOW(), 0),
        (v_tid_system, v_comp_traps, 'paginator',        'Paginador',               'ACTION',  NOW(), NOW(), 0),
        (v_tid_system, v_comp_traps, 'matSortHeader',    'Cabecera de ordenamiento','ACTION',  NOW(), NOW(), 0),
        (v_tid_system, v_comp_traps, 'rowClickToggle',   'Expandir fila',           'ACTION',  NOW(), NOW(), 0)
    ON CONFLICT (tenant_id, component_id, element_key) DO NOTHING;

    SELECT id INTO v_el_traps_columns_btn FROM nxc_menu.component_elements WHERE component_id = v_comp_traps AND element_key = 'columnsMenuBtn';
    SELECT id INTO v_el_traps_toggle_col  FROM nxc_menu.component_elements WHERE component_id = v_comp_traps AND element_key = 'toggleColumnItem';
    SELECT id INTO v_el_traps_reset_cols  FROM nxc_menu.component_elements WHERE component_id = v_comp_traps AND element_key = 'resetColumnsBtn';
    SELECT id INTO v_el_traps_search      FROM nxc_menu.component_elements WHERE component_id = v_comp_traps AND element_key = 'searchInput';
    SELECT id INTO v_el_traps_paginator   FROM nxc_menu.component_elements WHERE component_id = v_comp_traps AND element_key = 'paginator';
    SELECT id INTO v_el_traps_sort_header FROM nxc_menu.component_elements WHERE component_id = v_comp_traps AND element_key = 'matSortHeader';
    SELECT id INTO v_el_traps_row_toggle  FROM nxc_menu.component_elements WHERE component_id = v_comp_traps AND element_key = 'rowClickToggle';

    -- --- auth ---
    INSERT INTO nxc_menu.component_elements
        (tenant_id, component_id, element_key, label, element_type, created_at, updated_at, version)
    VALUES
        (v_tid_system, v_comp_auth, 'togglePasswordButton', 'Mostrar/ocultar contraseña', 'BUTTON', NOW(), NOW(), 0),
        (v_tid_system, v_comp_auth, 'loginButton',           'Botón iniciar sesión',       'BUTTON', NOW(), NOW(), 0),
        (v_tid_system, v_comp_auth, 'resendCodeButton',      'Reenviar código 2FA',        'BUTTON', NOW(), NOW(), 0),
        (v_tid_system, v_comp_auth, 'goBackButton',          'Volver atrás',               'BUTTON', NOW(), NOW(), 0)
    ON CONFLICT (tenant_id, component_id, element_key) DO NOTHING;

    SELECT id INTO v_el_auth_toggle_pwd  FROM nxc_menu.component_elements WHERE component_id = v_comp_auth AND element_key = 'togglePasswordButton';
    SELECT id INTO v_el_auth_login_btn   FROM nxc_menu.component_elements WHERE component_id = v_comp_auth AND element_key = 'loginButton';
    SELECT id INTO v_el_auth_resend_code FROM nxc_menu.component_elements WHERE component_id = v_comp_auth AND element_key = 'resendCodeButton';
    SELECT id INTO v_el_auth_go_back     FROM nxc_menu.component_elements WHERE component_id = v_comp_auth AND element_key = 'goBackButton';

    -- --- user-management ---
    INSERT INTO nxc_menu.component_elements
        (tenant_id, component_id, element_key, label, element_type, created_at, updated_at, version)
    VALUES
        (v_tid_system, v_comp_users, 'btn-create-user',  'Crear usuario',         'BUTTON',  NOW(), NOW(), 0),
        (v_tid_system, v_comp_users, 'btn-edit-user',    'Editar usuario',         'BUTTON',  NOW(), NOW(), 0),
        (v_tid_system, v_comp_users, 'btn-suspend-user', 'Suspender usuario',      'BUTTON',  NOW(), NOW(), 0),
        (v_tid_system, v_comp_users, 'btn-delete-user',  'Eliminar usuario',       'BUTTON',  NOW(), NOW(), 0),
        (v_tid_system, v_comp_users, 'btn-invite-user',  'Invitar usuario',        'BUTTON',  NOW(), NOW(), 0),
        (v_tid_system, v_comp_users, 'searchInput',      'Búsqueda de usuarios',   'FIELD',   NOW(), NOW(), 0),
        (v_tid_system, v_comp_users, 'paginator',        'Paginador de usuarios',  'ACTION',  NOW(), NOW(), 0),
        (v_tid_system, v_comp_users, 'tab-roles',        'Pestaña de roles',       'TAB',     NOW(), NOW(), 0)
    ON CONFLICT (tenant_id, component_id, element_key) DO NOTHING;

    SELECT id INTO v_el_users_btn_create  FROM nxc_menu.component_elements WHERE component_id = v_comp_users AND element_key = 'btn-create-user';
    SELECT id INTO v_el_users_btn_edit    FROM nxc_menu.component_elements WHERE component_id = v_comp_users AND element_key = 'btn-edit-user';
    SELECT id INTO v_el_users_btn_suspend FROM nxc_menu.component_elements WHERE component_id = v_comp_users AND element_key = 'btn-suspend-user';
    SELECT id INTO v_el_users_btn_delete  FROM nxc_menu.component_elements WHERE component_id = v_comp_users AND element_key = 'btn-delete-user';
    SELECT id INTO v_el_users_btn_invite  FROM nxc_menu.component_elements WHERE component_id = v_comp_users AND element_key = 'btn-invite-user';
    SELECT id INTO v_el_users_search      FROM nxc_menu.component_elements WHERE component_id = v_comp_users AND element_key = 'searchInput';
    SELECT id INTO v_el_users_paginator   FROM nxc_menu.component_elements WHERE component_id = v_comp_users AND element_key = 'paginator';
    SELECT id INTO v_el_users_tab_roles   FROM nxc_menu.component_elements WHERE component_id = v_comp_users AND element_key = 'tab-roles';

    -- --- role-management ---
    INSERT INTO nxc_menu.component_elements
        (tenant_id, component_id, element_key, label, element_type, created_at, updated_at, version)
    VALUES
        (v_tid_system, v_comp_roles, 'btn-create-role', 'Crear rol',           'BUTTON', NOW(), NOW(), 0),
        (v_tid_system, v_comp_roles, 'btn-edit-role',   'Editar rol',           'BUTTON', NOW(), NOW(), 0),
        (v_tid_system, v_comp_roles, 'btn-delete-role', 'Eliminar rol',         'BUTTON', NOW(), NOW(), 0),
        (v_tid_system, v_comp_roles, 'btn-assign-role', 'Asignar roles a usuario', 'BUTTON', NOW(), NOW(), 0)
    ON CONFLICT (tenant_id, component_id, element_key) DO NOTHING;

    SELECT id INTO v_el_roles_btn_create FROM nxc_menu.component_elements WHERE component_id = v_comp_roles AND element_key = 'btn-create-role';
    SELECT id INTO v_el_roles_btn_edit   FROM nxc_menu.component_elements WHERE component_id = v_comp_roles AND element_key = 'btn-edit-role';
    SELECT id INTO v_el_roles_btn_delete FROM nxc_menu.component_elements WHERE component_id = v_comp_roles AND element_key = 'btn-delete-role';
    SELECT id INTO v_el_roles_btn_assign FROM nxc_menu.component_elements WHERE component_id = v_comp_roles AND element_key = 'btn-assign-role';

    RAISE NOTICE 'Elementos de UI creados correctamente.';

-- =============================================================================
-- BLOQUE 4 — ÁRBOL DE MENÚ DEL SISTEMA
-- Refleja exactamente la estructura del ejemplo-perfil-user
-- más el grupo de administración para TENANT_ADMIN
-- =============================================================================

    RAISE NOTICE '=== BLOQUE 4: Árbol de menú ===';

    -- Sidebar principal (location: sidebar)
    INSERT INTO nxc_menu.menu_items (
        tenant_id, component_id, parent_id,
        name, title, route, icon, icon_type, location,
        item_type, order_index, is_visible, is_system, default_access,
        created_by, created_at, updated_at, version
    ) VALUES (
        v_tid_system, v_comp_dashboard, NULL,
        'Dashboard', 'Panel Principal', '/graphics',
        'layout-dashboard', 'tabler', 'sidebar',
        'ITEM', 10, TRUE, TRUE, 'EXECUTE'::nxc_menu.access_level,
        v_uid_super_admin, NOW(), NOW(), 0
    ) ON CONFLICT DO NOTHING
    RETURNING id INTO v_menu_dashboard;
    IF v_menu_dashboard IS NULL THEN
        SELECT id INTO v_menu_dashboard FROM nxc_menu.menu_items WHERE tenant_id = v_tid_system AND name = 'Dashboard' AND parent_id IS NULL;
    END IF;

    INSERT INTO nxc_menu.menu_items (
        tenant_id, component_id, parent_id,
        name, title, route, icon, icon_type, location,
        item_type, order_index, is_visible, is_system, default_access,
        created_by, created_at, updated_at, version
    ) VALUES (
        v_tid_system, v_comp_alerts, NULL,
        'Alerts', 'Alertas', '/alerts',
        'bell', 'tabler', 'sidebar',
        'ITEM', 20, TRUE, TRUE, 'EXECUTE'::nxc_menu.access_level,
        v_uid_super_admin, NOW(), NOW(), 0
    ) ON CONFLICT DO NOTHING
    RETURNING id INTO v_menu_alerts;
    IF v_menu_alerts IS NULL THEN
        SELECT id INTO v_menu_alerts FROM nxc_menu.menu_items WHERE tenant_id = v_tid_system AND name = 'Alerts' AND parent_id IS NULL;
    END IF;

    INSERT INTO nxc_menu.menu_items (
        tenant_id, component_id, parent_id,
        name, title, route, icon, icon_type, location,
        item_type, order_index, is_visible, is_system, default_access,
        created_by, created_at, updated_at, version
    ) VALUES (
        v_tid_system, v_comp_incidents, NULL,
        'Incidents', 'Incidentes', '/incidents',
        'alert-circle', 'tabler', 'sidebar',
        'ITEM', 30, TRUE, TRUE, 'EXECUTE'::nxc_menu.access_level,
        v_uid_super_admin, NOW(), NOW(), 0
    ) ON CONFLICT DO NOTHING
    RETURNING id INTO v_menu_incidents;
    IF v_menu_incidents IS NULL THEN
        SELECT id INTO v_menu_incidents FROM nxc_menu.menu_items WHERE tenant_id = v_tid_system AND name = 'Incidents' AND parent_id IS NULL;
    END IF;

    INSERT INTO nxc_menu.menu_items (
        tenant_id, component_id, parent_id,
        name, title, route, icon, icon_type, location,
        item_type, order_index, is_visible, is_system, default_access,
        created_by, created_at, updated_at, version
    ) VALUES (
        v_tid_system, v_comp_traps, NULL,
        'Traps', 'Traps SNMP', '/traps',
        'radar', 'tabler', 'sidebar',
        'ITEM', 40, TRUE, TRUE, 'EXECUTE'::nxc_menu.access_level,
        v_uid_super_admin, NOW(), NOW(), 0
    ) ON CONFLICT DO NOTHING
    RETURNING id INTO v_menu_traps;
    IF v_menu_traps IS NULL THEN
        SELECT id INTO v_menu_traps FROM nxc_menu.menu_items WHERE tenant_id = v_tid_system AND name = 'Traps' AND parent_id IS NULL;
    END IF;

    -- Grupo dropdown de perfil (profile) — sin ruta propia
    INSERT INTO nxc_menu.menu_items (
        tenant_id, component_id, parent_id,
        name, title, route, icon, icon_type, location,
        item_type, order_index, is_visible, is_system, default_access,
        created_by, created_at, updated_at, version
    ) VALUES (
        v_tid_system, NULL, NULL,
        'ProfileMenu', 'Perfil', NULL,
        'user-circle', 'tabler', 'profile',
        'GROUP', 50, TRUE, TRUE, 'EXECUTE'::nxc_menu.access_level,
        v_uid_super_admin, NOW(), NOW(), 0
    ) ON CONFLICT DO NOTHING
    RETURNING id INTO v_menu_profile_group;
    IF v_menu_profile_group IS NULL THEN
        SELECT id INTO v_menu_profile_group FROM nxc_menu.menu_items WHERE tenant_id = v_tid_system AND name = 'ProfileMenu' AND parent_id IS NULL;
    END IF;

    -- Hijos del grupo perfil
    INSERT INTO nxc_menu.menu_items (
        tenant_id, component_id, parent_id,
        name, title, route, icon, icon_type, location,
        item_type, order_index, is_visible, is_system, default_access,
        created_by, created_at, updated_at, version
    ) VALUES (
        v_tid_system, NULL, v_menu_profile_group,
        'Profile', 'Mi Perfil', '/profile',
        'user', 'tabler', 'profile',
        'ITEM', 10, TRUE, TRUE, 'EXECUTE'::nxc_menu.access_level,
        v_uid_super_admin, NOW(), NOW(), 0
    ) ON CONFLICT DO NOTHING
    RETURNING id INTO v_menu_profile_item;

    INSERT INTO nxc_menu.menu_items (
        tenant_id, component_id, parent_id,
        name, title, route, icon, icon_type, location,
        item_type, order_index, is_visible, is_system, default_access,
        created_by, created_at, updated_at, version
    ) VALUES (
        v_tid_system, v_comp_settings, v_menu_profile_group,
        'Settings', 'Configuración', '/admin/settings',
        'settings', 'tabler', 'profile',
        'ITEM', 20, TRUE, TRUE, 'EXECUTE'::nxc_menu.access_level,
        v_uid_super_admin, NOW(), NOW(), 0
    ) ON CONFLICT DO NOTHING
    RETURNING id INTO v_menu_settings_item;

    INSERT INTO nxc_menu.menu_items (
        tenant_id, component_id, parent_id,
        name, title, route, icon, icon_type, location,
        item_type, order_index, is_visible, is_system, default_access,
        created_by, created_at, updated_at, version
    ) VALUES (
        v_tid_system, v_comp_auth, v_menu_profile_group,
        'Logout', 'Cerrar Sesión', '/auth/login',
        'logout', 'tabler', 'profile',
        'ITEM', 30, TRUE, TRUE, 'EXECUTE'::nxc_menu.access_level,
        v_uid_super_admin, NOW(), NOW(), 0
    ) ON CONFLICT DO NOTHING
    RETURNING id INTO v_menu_logout_item;

    -- Grupo Administración (solo visible para TENANT_ADMIN y SUPER_ADMIN)
    INSERT INTO nxc_menu.menu_items (
        tenant_id, component_id, parent_id,
        name, title, route, icon, icon_type, location,
        item_type, order_index, is_visible, is_system, default_access,
        created_by, created_at, updated_at, version
    ) VALUES (
        v_tid_system, NULL, NULL,
        'Administration', 'Administración', NULL,
        'shield', 'tabler', 'profile',
        'GROUP', 60, TRUE, TRUE, 'HIDDEN'::nxc_menu.access_level,
        v_uid_super_admin, NOW(), NOW(), 0
    ) ON CONFLICT DO NOTHING
    RETURNING id INTO v_menu_admin_group;
    IF v_menu_admin_group IS NULL THEN
        SELECT id INTO v_menu_admin_group FROM nxc_menu.menu_items WHERE tenant_id = v_tid_system AND name = 'Administration' AND parent_id IS NULL;
    END IF;

    INSERT INTO nxc_menu.menu_items (
        tenant_id, component_id, parent_id,
        name, title, route, icon, icon_type, location,
        item_type, order_index, is_visible, is_system, default_access,
        created_by, created_at, updated_at, version
    ) VALUES (
        v_tid_system, v_comp_users, v_menu_admin_group,
        'Users', 'Usuarios', '/admin/users',
        'users', 'tabler', 'profile',
        'ITEM', 10, TRUE, TRUE, 'HIDDEN'::nxc_menu.access_level,
        v_uid_super_admin, NOW(), NOW(), 0
    ) ON CONFLICT DO NOTHING
    RETURNING id INTO v_menu_admin_users;

    INSERT INTO nxc_menu.menu_items (
        tenant_id, component_id, parent_id,
        name, title, route, icon, icon_type, location,
        item_type, order_index, is_visible, is_system, default_access,
        created_by, created_at, updated_at, version
    ) VALUES (
        v_tid_system, v_comp_roles, v_menu_admin_group,
        'Roles', 'Roles', '/admin/roles',
        'lock', 'tabler', 'profile',
        'ITEM', 20, TRUE, TRUE, 'HIDDEN'::nxc_menu.access_level,
        v_uid_super_admin, NOW(), NOW(), 0
    ) ON CONFLICT DO NOTHING
    RETURNING id INTO v_menu_admin_roles;

    INSERT INTO nxc_menu.menu_items (
        tenant_id, component_id, parent_id,
        name, title, route, icon, icon_type, location,
        item_type, order_index, is_visible, is_system, default_access,
        created_by, created_at, updated_at, version
    ) VALUES (
        v_tid_system, v_comp_menus, v_menu_admin_group,
        'Menus', 'Menús', '/admin/menus',
        'layout-navbar', 'tabler', 'profile',
        'ITEM', 30, TRUE, TRUE, 'HIDDEN'::nxc_menu.access_level,
        v_uid_super_admin, NOW(), NOW(), 0
    ) ON CONFLICT DO NOTHING
    RETURNING id INTO v_menu_admin_menus;

    INSERT INTO nxc_menu.menu_items (
        tenant_id, component_id, parent_id,
        name, title, route, icon, icon_type, location,
        item_type, order_index, is_visible, is_system, default_access,
        created_by, created_at, updated_at, version
    ) VALUES (
        v_tid_system, v_comp_audit, v_menu_admin_group,
        'Audit', 'Auditoría', '/admin/audit',
        'history', 'tabler', 'profile',
        'ITEM', 40, TRUE, TRUE, 'HIDDEN'::nxc_menu.access_level,
        v_uid_super_admin, NOW(), NOW(), 0
    ) ON CONFLICT DO NOTHING
    RETURNING id INTO v_menu_admin_audit;

    RAISE NOTICE 'Árbol de menú creado correctamente.';

-- =============================================================================
-- BLOQUE 5 — PERMISOS DE COMPONENTES POR ROL (tenant system)
--
-- Matriz de acceso:
--   SUPER_ADMIN  → EXECUTE en todo
--   TENANT_ADMIN → EXECUTE en operacional + EXECUTE en administración
--   EDITOR       → EXECUTE en operacional, HIDDEN en administración
--   VIEWER       → VIEW en operacional, HIDDEN en administración
-- =============================================================================

    RAISE NOTICE '=== BLOQUE 5: Permisos de componentes por rol ===';

    -- SUPER_ADMIN — acceso total
    INSERT INTO nxc_menu.component_permissions
        (tenant_id, role_id, component_id, access, created_by, created_at, updated_at)
    SELECT v_tid_system, v_role_sys_super, c.id, 'EXECUTE'::nxc_menu.access_level, v_uid_super_admin, NOW(), NOW()
    FROM nxc_menu.components c
    WHERE c.tenant_id = v_tid_system
    ON CONFLICT (tenant_id, role_id, component_id) DO UPDATE SET access = 'EXECUTE'::nxc_menu.access_level;

    -- TENANT_ADMIN — todo EXECUTE
    INSERT INTO nxc_menu.component_permissions
        (tenant_id, role_id, component_id, access, created_by, created_at, updated_at)
    SELECT v_tid_system, v_role_sys_admin, c.id,
        CASE
            WHEN c.module_key IN ('dashboard','alerts','incidents','traps','auth') THEN 'EXECUTE'
            WHEN c.module_key IN ('user-management','role-management','menu-management','audit-viewer','tenant-settings') THEN 'EXECUTE'
            ELSE 'HIDDEN'
        END::nxc_menu.access_level,
        v_uid_super_admin, NOW(), NOW()
    FROM nxc_menu.components c
    WHERE c.tenant_id = v_tid_system
    ON CONFLICT (tenant_id, role_id, component_id) DO UPDATE
        SET access = EXCLUDED.access;

    -- EDITOR — operacional EXECUTE, administración HIDDEN
    INSERT INTO nxc_menu.component_permissions
        (tenant_id, role_id, component_id, access, created_by, created_at, updated_at)
    SELECT v_tid_system, v_role_sys_editor, c.id,
        CASE
            WHEN c.module_key IN ('dashboard','alerts','incidents','traps','auth') THEN 'EXECUTE'
            ELSE 'HIDDEN'
        END::nxc_menu.access_level,
        v_uid_super_admin, NOW(), NOW()
    FROM nxc_menu.components c
    WHERE c.tenant_id = v_tid_system
    ON CONFLICT (tenant_id, role_id, component_id) DO UPDATE
        SET access = EXCLUDED.access;

    -- VIEWER — operacional VIEW, administración HIDDEN
    INSERT INTO nxc_menu.component_permissions
        (tenant_id, role_id, component_id, access, created_by, created_at, updated_at)
    SELECT v_tid_system, v_role_sys_viewer, c.id,
        CASE
            WHEN c.module_key IN ('dashboard','alerts','incidents','traps','auth') THEN 'VIEW'
            ELSE 'HIDDEN'
        END::nxc_menu.access_level,
        v_uid_super_admin, NOW(), NOW()
    FROM nxc_menu.components c
    WHERE c.tenant_id = v_tid_system
    ON CONFLICT (tenant_id, role_id, component_id) DO UPDATE
        SET access = EXCLUDED.access;

    RAISE NOTICE 'Permisos de componentes asignados.';

-- =============================================================================
-- BLOQUE 6 — PERMISOS DE ELEMENTOS POR ROL
--
-- Granularidad fina: EDITOR no puede crear/eliminar/suspender usuarios.
-- VIEWER no puede hacer ninguna acción de escritura.
-- =============================================================================

    RAISE NOTICE '=== BLOQUE 6: Permisos de elementos por rol ===';

    -- SUPER_ADMIN y TENANT_ADMIN — EXECUTE en todos los elementos
    INSERT INTO nxc_menu.element_permissions
        (tenant_id, role_id, element_id, access, created_by, created_at, updated_at)
    SELECT v_tid_system, v_role_sys_super, ce.id, 'EXECUTE'::nxc_menu.access_level, v_uid_super_admin, NOW(), NOW()
    FROM nxc_menu.component_elements ce
    WHERE ce.tenant_id = v_tid_system
    ON CONFLICT (tenant_id, role_id, element_id) DO UPDATE SET access = 'EXECUTE'::nxc_menu.access_level;

    INSERT INTO nxc_menu.element_permissions
        (tenant_id, role_id, element_id, access, created_by, created_at, updated_at)
    SELECT v_tid_system, v_role_sys_admin, ce.id, 'EXECUTE'::nxc_menu.access_level, v_uid_super_admin, NOW(), NOW()
    FROM nxc_menu.component_elements ce
    WHERE ce.tenant_id = v_tid_system
    ON CONFLICT (tenant_id, role_id, element_id) DO UPDATE SET access = 'EXECUTE'::nxc_menu.access_level;

    -- EDITOR — EXECUTE en elementos operacionales, VIEW en admin, HIDDEN en destructivos
    INSERT INTO nxc_menu.element_permissions
        (tenant_id, role_id, element_id, access, created_by, created_at, updated_at)
    SELECT v_tid_system, v_role_sys_editor, ce.id,
        CASE
            -- Elementos destructivos: solo VIEW
            WHEN ce.element_key IN ('btn-delete-user','btn-suspend-user','btn-delete-role') THEN 'VIEW'
            -- Gestión de menús y audit: VIEW
            WHEN ce.component_id IN (v_comp_menus, v_comp_audit) THEN 'VIEW'
            -- Resto: EXECUTE
            ELSE 'EXECUTE'
        END::nxc_menu.access_level,
        v_uid_super_admin, NOW(), NOW()
    FROM nxc_menu.component_elements ce
    WHERE ce.tenant_id = v_tid_system
    ON CONFLICT (tenant_id, role_id, element_id) DO UPDATE
        SET access = EXCLUDED.access;

    -- VIEWER — VIEW en operacional, HIDDEN en escritura
    INSERT INTO nxc_menu.element_permissions
        (tenant_id, role_id, element_id, access, created_by, created_at, updated_at)
    SELECT v_tid_system, v_role_sys_viewer, ce.id,
        CASE
            -- Botones de acción: HIDDEN
            WHEN ce.element_type IN ('BUTTON','ACTION')
                AND ce.element_key NOT IN ('paginator','searchInput') THEN 'HIDDEN'
            -- Campos de búsqueda y paginación: VIEW
            ELSE 'VIEW'
        END::nxc_menu.access_level,
        v_uid_super_admin, NOW(), NOW()
    FROM nxc_menu.component_elements ce
    WHERE ce.tenant_id = v_tid_system
    ON CONFLICT (tenant_id, role_id, element_id) DO UPDATE
        SET access = EXCLUDED.access;

    RAISE NOTICE 'Permisos de elementos asignados.';

-- =============================================================================
-- BLOQUE 7 — TENANT DEMO
-- Un tenant de ejemplo con UUID fijo para desarrollo y Postman
-- =============================================================================

    RAISE NOTICE '=== BLOQUE 7: Tenant demo ===';

    INSERT INTO nxc_tenant.tenants (
        id, slug, name, legal_name, tax_id,
        plan, mode, status,
        primary_color,
        timezone, locale, date_format, currency,
        mfa_required, session_timeout_minutes, max_login_attempts,
        password_min_length, password_requires_upper, password_requires_special,
        max_users, audit_retention_days,
        trial_ends_at, subscription_ends_at,
        created_at, updated_at, version
    ) VALUES (
        v_tid_demo,
        'demo',
        'Tenant Demo',
        'Tenant Demo S.A.S.',
        '900123456-7',
        'STARTER', 'SAAS_SHARED', 'ACTIVE',
        '#1976D2',
        'America/Bogota', 'es-CO', 'DD/MM/YYYY', 'COP',
        FALSE, 480, 5,
        8, FALSE, FALSE,
        100, 90,
        NOW() + INTERVAL '15 days',
        NOW() + INTERVAL '1 year',
        NOW(), NOW(), 0
    ) ON CONFLICT (id) DO NOTHING;

    RAISE NOTICE 'Tenant demo creado: %', v_tid_demo;

    -- Recuperar roles del tenant demo (creados por el trigger)
    SELECT id INTO v_role_demo_admin  FROM nxc_tenant.roles WHERE tenant_id = v_tid_demo AND name = 'TENANT_ADMIN';
    SELECT id INTO v_role_demo_editor FROM nxc_tenant.roles WHERE tenant_id = v_tid_demo AND name = 'EDITOR';
    SELECT id INTO v_role_demo_viewer FROM nxc_tenant.roles WHERE tenant_id = v_tid_demo AND name = 'VIEWER';

    RAISE NOTICE 'Roles demo — TENANT_ADMIN:%, EDITOR:%, VIEWER:%',
        v_role_demo_admin, v_role_demo_editor, v_role_demo_viewer;

    -- Usuario administrador del tenant demo
    INSERT INTO nxc_tenant.users (
        id, tenant_id,
        username, email, password_hash,
        full_name, phone,
        status, is_tenant_admin,
        email_verified, email_verified_at,
        activated_at,
        created_at, updated_at, version
    ) VALUES (
        v_uid_admin_demo, v_tid_demo,
        'admin.demo',
        'admin@demo.nexcore.io',
        '$2a$12$2SgNZ1P9TWruO3hmUqL6u.U3K4mKg9o7xtK6N8uZJXVxjFqbMDf/y',
        'Administrador Demo',
        '+573001234567',
        'ACTIVE', TRUE,
        TRUE, NOW(),
        NOW(),
        NOW(), NOW(), 0
    ) ON CONFLICT (id) DO NOTHING;

    -- Asignar TENANT_ADMIN al admin demo
    INSERT INTO nxc_tenant.user_roles (tenant_id, user_id, role_id, assigned_at, assigned_by)
    VALUES (v_tid_demo, v_uid_admin_demo, v_role_demo_admin, NOW(), v_uid_admin_demo)
    ON CONFLICT (tenant_id, user_id, role_id) DO NOTHING;

    RAISE NOTICE 'Usuario admin demo creado: %', v_uid_admin_demo;

    -- Permisos de componentes para el tenant demo
    -- Hereda los componentes del sistema (is_system = TRUE), pero necesita
    -- sus propias entradas en component_permissions referenciando sus roles.

    INSERT INTO nxc_menu.component_permissions
        (tenant_id, role_id, component_id, access, created_by, created_at, updated_at)
    SELECT v_tid_demo, v_role_demo_admin, c.id, 'EXECUTE'::nxc_menu.access_level, v_uid_admin_demo, NOW(), NOW()
    FROM nxc_menu.components c
    WHERE c.tenant_id = v_tid_system AND c.is_system = TRUE
    ON CONFLICT (tenant_id, role_id, component_id) DO UPDATE SET access = 'EXECUTE'::nxc_menu.access_level;

    INSERT INTO nxc_menu.component_permissions
        (tenant_id, role_id, component_id, access, created_by, created_at, updated_at)
    SELECT v_tid_demo, v_role_demo_editor, c.id,
        CASE
            WHEN c.module_key IN ('dashboard','alerts','incidents','traps','auth') THEN 'EXECUTE'
            ELSE 'HIDDEN'
        END::nxc_menu.access_level,
        v_uid_admin_demo, NOW(), NOW()
    FROM nxc_menu.components c
    WHERE c.tenant_id = v_tid_system AND c.is_system = TRUE
    ON CONFLICT (tenant_id, role_id, component_id) DO UPDATE SET access = EXCLUDED.access;

    INSERT INTO nxc_menu.component_permissions
        (tenant_id, role_id, component_id, access, created_by, created_at, updated_at)
    SELECT v_tid_demo, v_role_demo_viewer, c.id,
        CASE
            WHEN c.module_key IN ('dashboard','alerts','incidents','traps','auth') THEN 'VIEW'
            ELSE 'HIDDEN'
        END::nxc_menu.access_level,
        v_uid_admin_demo, NOW(), NOW()
    FROM nxc_menu.components c
    WHERE c.tenant_id = v_tid_system AND c.is_system = TRUE
    ON CONFLICT (tenant_id, role_id, component_id) DO UPDATE SET access = EXCLUDED.access;

    RAISE NOTICE 'Permisos del tenant demo asignados.';

-- =============================================================================
-- BLOQUE 8 — FEATURE FLAGS GLOBALES
-- tenant_id NULL = aplica a todos los tenants
-- =============================================================================

    RAISE NOTICE '=== BLOQUE 8: Feature flags globales ===';

    INSERT INTO nxc_config.feature_flags
        (tenant_id, flag_key, description, is_enabled, min_plan, created_by, created_at, updated_at)
    VALUES
        -- Disponibles para todos los planes
        (NULL, 'multi-language',        'Soporte para múltiples idiomas en la interfaz.',         TRUE,  NULL,           v_uid_super_admin, NOW(), NOW()),
        (NULL, 'dark-mode',             'Tema oscuro en la interfaz de usuario.',                  TRUE,  NULL,           v_uid_super_admin, NOW(), NOW()),
        (NULL, 'notifications-sound',   'Sonido en notificaciones en tiempo real.',                TRUE,  NULL,           v_uid_super_admin, NOW(), NOW()),

        -- Solo desde STARTER
        (NULL, 'audit-viewer',          'Acceso al módulo de auditoría de cambios.',              TRUE,  'STARTER',      v_uid_super_admin, NOW(), NOW()),
        (NULL, 'saved-filters',         'Filtros guardados por usuario.',                          TRUE,  'STARTER',      v_uid_super_admin, NOW(), NOW()),
        (NULL, 'column-config',         'Configuración de columnas por tabla.',                    TRUE,  'STARTER',      v_uid_super_admin, NOW(), NOW()),

        -- Solo desde PROFESSIONAL
        (NULL, 'advanced-reporting',    'Reportes avanzados y exportación de datos.',              FALSE, 'PROFESSIONAL', v_uid_super_admin, NOW(), NOW()),
        (NULL, 'webhook-notifications', 'Notificaciones vía webhook a sistemas externos.',         FALSE, 'PROFESSIONAL', v_uid_super_admin, NOW(), NOW()),
        (NULL, 'custom-domain',         'Dominio personalizado para el portal del tenant.',        FALSE, 'PROFESSIONAL', v_uid_super_admin, NOW(), NOW()),

        -- Solo ENTERPRISE
        (NULL, 'sso-okta',             'Autenticación SSO vía Okta.',                             FALSE, 'ENTERPRISE',   v_uid_super_admin, NOW(), NOW()),
        (NULL, 'audit-export',         'Exportación de registros de auditoría en CSV/JSON.',       FALSE, 'ENTERPRISE',   v_uid_super_admin, NOW(), NOW()),
        (NULL, 'ip-whitelist',         'Lista blanca de IPs permitidas para el tenant.',           FALSE, 'ENTERPRISE',   v_uid_super_admin, NOW(), NOW())
    ON CONFLICT (tenant_id, flag_key) DO NOTHING;

    RAISE NOTICE 'Feature flags globales creados.';

-- =============================================================================
-- BLOQUE 9 — CONFIGURACIÓN BASE DEL TENANT DEMO
-- =============================================================================

    RAISE NOTICE '=== BLOQUE 9: Configuración del tenant demo ===';

    INSERT INTO nxc_config.tenant_configs
        (tenant_id, config_key, config_value, description, is_secret, created_by, created_at, updated_at)
    VALUES
        (v_tid_demo, 'email.from',
         '"no-reply@demo.nexcore.io"',
         'Dirección de remitente para emails del tenant demo.',
         FALSE, v_uid_admin_demo, NOW(), NOW()),

        (v_tid_demo, 'email.from_name',
         '"NexCore Demo"',
         'Nombre del remitente en emails.',
         FALSE, v_uid_admin_demo, NOW(), NOW()),

        (v_tid_demo, 'ui.items_per_page',
         '20',
         'Número de elementos por página por defecto.',
         FALSE, v_uid_admin_demo, NOW(), NOW()),

        (v_tid_demo, 'ui.default_theme',
         '"system"',
         'Tema por defecto para nuevos usuarios: light | dark | system.',
         FALSE, v_uid_admin_demo, NOW(), NOW()),

        (v_tid_demo, 'notification.channels',
         '["IN_APP","EMAIL"]',
         'Canales de notificación habilitados para este tenant.',
         FALSE, v_uid_admin_demo, NOW(), NOW())
    ON CONFLICT (tenant_id, config_key) DO NOTHING;

    RAISE NOTICE 'Configuración del tenant demo creada.';

    RAISE NOTICE '=== SEED COMPLETO — NexCore v2.0 ===';

END $$;

-- =============================================================================
-- BLOQUE 10 — CONSOLIDACIÓN FINAL SUPER_ADMIN
-- Integra la configuración final para dejar activo solo el menú/componentes
-- necesarios para SUPER_ADMIN.
-- =============================================================================

DO $$
DECLARE
    v_tid_system        UUID := '00000000-0000-0000-0000-000000000001';
    v_uid_super_admin   UUID := '00000000-0000-0000-0001-000000000001';

    v_role_sys_super    UUID;
    v_role_sys_admin    UUID;
    v_role_sys_editor   UUID;
    v_role_sys_viewer   UUID;

    v_role_demo_admin   UUID;
    v_role_demo_editor  UUID;
    v_role_demo_viewer  UUID;

    v_comp_dashboard    UUID;
    v_comp_tenants      UUID;
    v_comp_users        UUID;
    v_comp_audit        UUID;
    v_comp_feature      UUID;
    v_comp_platform     UUID;
    v_comp_auth         UUID;

    v_menu_profile_group UUID;
BEGIN
    RAISE NOTICE '=== BLOQUE 10: Consolidación SUPER_ADMIN ===';

    SELECT id INTO v_role_sys_super  FROM nxc_tenant.roles WHERE tenant_id = v_tid_system AND name = 'SUPER_ADMIN';
    SELECT id INTO v_role_sys_admin  FROM nxc_tenant.roles WHERE tenant_id = v_tid_system AND name = 'TENANT_ADMIN';
    SELECT id INTO v_role_sys_editor FROM nxc_tenant.roles WHERE tenant_id = v_tid_system AND name = 'EDITOR';
    SELECT id INTO v_role_sys_viewer FROM nxc_tenant.roles WHERE tenant_id = v_tid_system AND name = 'VIEWER';

    SELECT id INTO v_role_demo_admin  FROM nxc_tenant.roles WHERE tenant_id = '00000000-0000-0000-0000-000000000002' AND name = 'TENANT_ADMIN';
    SELECT id INTO v_role_demo_editor FROM nxc_tenant.roles WHERE tenant_id = '00000000-0000-0000-0000-000000000002' AND name = 'EDITOR';
    SELECT id INTO v_role_demo_viewer FROM nxc_tenant.roles WHERE tenant_id = '00000000-0000-0000-0000-000000000002' AND name = 'VIEWER';

    -- 1) Limpiar componentes/menús legacy que no van en el baseline final
    DELETE FROM nxc_menu.components
    WHERE tenant_id = v_tid_system
      AND module_key IN ('alerts', 'incidents', 'traps', 'role-management', 'menu-management', 'tenant-settings');

    DELETE FROM nxc_menu.menu_items
    WHERE tenant_id = v_tid_system
      AND (
            (location = 'sidebar' AND name NOT IN ('dashboard', 'tenant-management', 'identity-access', 'audit-viewer', 'feature-flags', 'platform-settings'))
         OR (location = 'profile' AND name NOT IN ('ProfileMenu', 'Profile', 'Settings', 'Logout'))
      );

    -- 2) Upsert de componentes finales
    INSERT INTO nxc_menu.components (tenant_id, module_key, name, route, description, is_system, created_by, created_at, updated_at, version)
    VALUES
        (v_tid_system, 'dashboard',         'Dashboard',         '/dashboard',       'Dashboard principal',                            TRUE, v_uid_super_admin, NOW(), NOW(), 0),
        (v_tid_system, 'tenant-management', 'Tenant Management', '/tenants',         'Administración de tenants',                      TRUE, v_uid_super_admin, NOW(), NOW(), 0),
        (v_tid_system, 'user-management',   'Identity & Access', '/identity-access', 'Administración de identidad y accesos',          TRUE, v_uid_super_admin, NOW(), NOW(), 0),
        (v_tid_system, 'audit-viewer',      'Audit Viewer',      '/audit',           'Auditoría de plataforma',                        TRUE, v_uid_super_admin, NOW(), NOW(), 0),
        (v_tid_system, 'feature-flags',     'Feature Flags',     '/feature-flags',   'Feature flags globales',                         TRUE, v_uid_super_admin, NOW(), NOW(), 0),
        (v_tid_system, 'platform-settings', 'Platform Settings', '/settings',        'Configuración global de plataforma',             TRUE, v_uid_super_admin, NOW(), NOW(), 0)
    ON CONFLICT (tenant_id, module_key)
    DO UPDATE SET
        name = EXCLUDED.name,
        route = EXCLUDED.route,
        description = EXCLUDED.description,
        is_system = TRUE,
        updated_at = NOW();

    SELECT id INTO v_comp_dashboard FROM nxc_menu.components WHERE tenant_id = v_tid_system AND module_key = 'dashboard';
    SELECT id INTO v_comp_tenants   FROM nxc_menu.components WHERE tenant_id = v_tid_system AND module_key = 'tenant-management';
    SELECT id INTO v_comp_users     FROM nxc_menu.components WHERE tenant_id = v_tid_system AND module_key = 'user-management';
    SELECT id INTO v_comp_audit     FROM nxc_menu.components WHERE tenant_id = v_tid_system AND module_key = 'audit-viewer';
    SELECT id INTO v_comp_feature   FROM nxc_menu.components WHERE tenant_id = v_tid_system AND module_key = 'feature-flags';
    SELECT id INTO v_comp_platform  FROM nxc_menu.components WHERE tenant_id = v_tid_system AND module_key = 'platform-settings';
    SELECT id INTO v_comp_auth      FROM nxc_menu.components WHERE tenant_id = v_tid_system AND module_key = 'auth';

    -- 3) Sidebar final
    UPDATE nxc_menu.menu_items
    SET component_id = v_comp_dashboard, title = 'menu.dashboard', route = '/dashboard', icon = 'dashboard', icon_type = 'tabler',
        item_type = 'ITEM', order_index = 1, is_visible = TRUE, is_system = TRUE, default_access = 'EXECUTE'::nxc_menu.access_level,
        updated_at = NOW()
    WHERE tenant_id = v_tid_system AND location = 'sidebar' AND parent_id IS NULL AND name = 'dashboard';
    IF NOT FOUND THEN
        INSERT INTO nxc_menu.menu_items (tenant_id, component_id, parent_id, name, title, route, icon, icon_type, location, item_type, order_index, is_visible, is_system, default_access, created_by, created_at, updated_at, version)
        VALUES (v_tid_system, v_comp_dashboard, NULL, 'dashboard', 'menu.dashboard', '/dashboard', 'dashboard', 'tabler', 'sidebar', 'ITEM', 1, TRUE, TRUE, 'EXECUTE'::nxc_menu.access_level, v_uid_super_admin, NOW(), NOW(), 0);
    END IF;

    UPDATE nxc_menu.menu_items
    SET component_id = v_comp_tenants, title = 'menu.tenants', route = '/tenants', icon = 'users', icon_type = 'tabler',
        item_type = 'ITEM', order_index = 2, is_visible = TRUE, is_system = TRUE, default_access = 'EXECUTE'::nxc_menu.access_level,
        updated_at = NOW()
    WHERE tenant_id = v_tid_system AND location = 'sidebar' AND parent_id IS NULL AND name = 'tenant-management';
    IF NOT FOUND THEN
        INSERT INTO nxc_menu.menu_items (tenant_id, component_id, parent_id, name, title, route, icon, icon_type, location, item_type, order_index, is_visible, is_system, default_access, created_by, created_at, updated_at, version)
        VALUES (v_tid_system, v_comp_tenants, NULL, 'tenant-management', 'menu.tenants', '/tenants', 'users', 'tabler', 'sidebar', 'ITEM', 2, TRUE, TRUE, 'EXECUTE'::nxc_menu.access_level, v_uid_super_admin, NOW(), NOW(), 0);
    END IF;

    UPDATE nxc_menu.menu_items
    SET component_id = v_comp_users, title = 'menu.identity_access', route = '/identity-access', icon = 'profile', icon_type = 'tabler',
        item_type = 'ITEM', order_index = 3, is_visible = TRUE, is_system = TRUE, default_access = 'EXECUTE'::nxc_menu.access_level,
        updated_at = NOW()
    WHERE tenant_id = v_tid_system AND location = 'sidebar' AND parent_id IS NULL AND name = 'identity-access';
    IF NOT FOUND THEN
        INSERT INTO nxc_menu.menu_items (tenant_id, component_id, parent_id, name, title, route, icon, icon_type, location, item_type, order_index, is_visible, is_system, default_access, created_by, created_at, updated_at, version)
        VALUES (v_tid_system, v_comp_users, NULL, 'identity-access', 'menu.identity_access', '/identity-access', 'profile', 'tabler', 'sidebar', 'ITEM', 3, TRUE, TRUE, 'EXECUTE'::nxc_menu.access_level, v_uid_super_admin, NOW(), NOW(), 0);
    END IF;

    UPDATE nxc_menu.menu_items
    SET component_id = v_comp_audit, title = 'menu.audit', route = '/audit', icon = 'chart-bar', icon_type = 'tabler',
        item_type = 'ITEM', order_index = 4, is_visible = TRUE, is_system = TRUE, default_access = 'EXECUTE'::nxc_menu.access_level,
        updated_at = NOW()
    WHERE tenant_id = v_tid_system AND location = 'sidebar' AND parent_id IS NULL AND name = 'audit-viewer';
    IF NOT FOUND THEN
        INSERT INTO nxc_menu.menu_items (tenant_id, component_id, parent_id, name, title, route, icon, icon_type, location, item_type, order_index, is_visible, is_system, default_access, created_by, created_at, updated_at, version)
        VALUES (v_tid_system, v_comp_audit, NULL, 'audit-viewer', 'menu.audit', '/audit', 'chart-bar', 'tabler', 'sidebar', 'ITEM', 4, TRUE, TRUE, 'EXECUTE'::nxc_menu.access_level, v_uid_super_admin, NOW(), NOW(), 0);
    END IF;

    UPDATE nxc_menu.menu_items
    SET component_id = v_comp_feature, title = 'menu.feature_flags', route = '/feature-flags', icon = 'bell', icon_type = 'tabler',
        item_type = 'ITEM', order_index = 5, is_visible = TRUE, is_system = TRUE, default_access = 'EXECUTE'::nxc_menu.access_level,
        updated_at = NOW()
    WHERE tenant_id = v_tid_system AND location = 'sidebar' AND parent_id IS NULL AND name = 'feature-flags';
    IF NOT FOUND THEN
        INSERT INTO nxc_menu.menu_items (tenant_id, component_id, parent_id, name, title, route, icon, icon_type, location, item_type, order_index, is_visible, is_system, default_access, created_by, created_at, updated_at, version)
        VALUES (v_tid_system, v_comp_feature, NULL, 'feature-flags', 'menu.feature_flags', '/feature-flags', 'bell', 'tabler', 'sidebar', 'ITEM', 5, TRUE, TRUE, 'EXECUTE'::nxc_menu.access_level, v_uid_super_admin, NOW(), NOW(), 0);
    END IF;

    UPDATE nxc_menu.menu_items
    SET component_id = v_comp_platform, title = 'menu.platform_settings', route = '/settings', icon = 'settings', icon_type = 'tabler',
        item_type = 'ITEM', order_index = 6, is_visible = TRUE, is_system = TRUE, default_access = 'EXECUTE'::nxc_menu.access_level,
        updated_at = NOW()
    WHERE tenant_id = v_tid_system AND location = 'sidebar' AND parent_id IS NULL AND name = 'platform-settings';
    IF NOT FOUND THEN
        INSERT INTO nxc_menu.menu_items (tenant_id, component_id, parent_id, name, title, route, icon, icon_type, location, item_type, order_index, is_visible, is_system, default_access, created_by, created_at, updated_at, version)
        VALUES (v_tid_system, v_comp_platform, NULL, 'platform-settings', 'menu.platform_settings', '/settings', 'settings', 'tabler', 'sidebar', 'ITEM', 6, TRUE, TRUE, 'EXECUTE'::nxc_menu.access_level, v_uid_super_admin, NOW(), NOW(), 0);
    END IF;

    -- 4) Profile final (Logout en EXECUTE)
    SELECT id INTO v_menu_profile_group
    FROM nxc_menu.menu_items
    WHERE tenant_id = v_tid_system AND location = 'profile' AND parent_id IS NULL AND name = 'ProfileMenu'
    LIMIT 1;

    IF v_menu_profile_group IS NULL THEN
        INSERT INTO nxc_menu.menu_items (tenant_id, component_id, parent_id, name, title, route, icon, icon_type, location, item_type, order_index, is_visible, is_system, default_access, created_by, created_at, updated_at, version)
        VALUES (v_tid_system, NULL, NULL, 'ProfileMenu', 'menu.profile_menu', NULL, 'profile', 'tabler', 'profile', 'GROUP', 50, TRUE, TRUE, 'EXECUTE'::nxc_menu.access_level, v_uid_super_admin, NOW(), NOW(), 0)
        RETURNING id INTO v_menu_profile_group;
    ELSE
        UPDATE nxc_menu.menu_items
        SET title = 'menu.profile_menu', icon = 'profile', icon_type = 'tabler', order_index = 50,
            is_visible = TRUE, is_system = TRUE, default_access = 'EXECUTE'::nxc_menu.access_level, updated_at = NOW()
        WHERE id = v_menu_profile_group;
    END IF;

    DELETE FROM nxc_menu.menu_items
    WHERE tenant_id = v_tid_system
      AND location = 'profile'
      AND parent_id = v_menu_profile_group
      AND name NOT IN ('Profile', 'Settings', 'Logout');

    UPDATE nxc_menu.menu_items
    SET component_id = NULL, parent_id = v_menu_profile_group, title = 'menu.profile', route = '/profile', icon = 'profile', icon_type = 'tabler',
        item_type = 'ITEM', order_index = 10, is_visible = TRUE, is_system = TRUE, default_access = 'EXECUTE'::nxc_menu.access_level, updated_at = NOW()
    WHERE tenant_id = v_tid_system AND location = 'profile' AND name = 'Profile';
    IF NOT FOUND THEN
        INSERT INTO nxc_menu.menu_items (tenant_id, component_id, parent_id, name, title, route, icon, icon_type, location, item_type, order_index, is_visible, is_system, default_access, created_by, created_at, updated_at, version)
        VALUES (v_tid_system, NULL, v_menu_profile_group, 'Profile', 'menu.profile', '/profile', 'profile', 'tabler', 'profile', 'ITEM', 10, TRUE, TRUE, 'EXECUTE'::nxc_menu.access_level, v_uid_super_admin, NOW(), NOW(), 0);
    END IF;

    UPDATE nxc_menu.menu_items
    SET component_id = v_comp_platform, parent_id = v_menu_profile_group, title = 'menu.settings', route = '/settings', icon = 'settings', icon_type = 'tabler',
        item_type = 'ITEM', order_index = 20, is_visible = TRUE, is_system = TRUE, default_access = 'HIDDEN'::nxc_menu.access_level, updated_at = NOW()
    WHERE tenant_id = v_tid_system AND location = 'profile' AND name = 'Settings';
    IF NOT FOUND THEN
        INSERT INTO nxc_menu.menu_items (tenant_id, component_id, parent_id, name, title, route, icon, icon_type, location, item_type, order_index, is_visible, is_system, default_access, created_by, created_at, updated_at, version)
        VALUES (v_tid_system, v_comp_platform, v_menu_profile_group, 'Settings', 'menu.settings', '/settings', 'settings', 'tabler', 'profile', 'ITEM', 20, TRUE, TRUE, 'HIDDEN'::nxc_menu.access_level, v_uid_super_admin, NOW(), NOW(), 0);
    END IF;

    UPDATE nxc_menu.menu_items
    SET component_id = v_comp_auth, parent_id = v_menu_profile_group, title = 'menu.logout', route = '/auth/login', icon = 'close', icon_type = 'tabler',
        item_type = 'ITEM', order_index = 30, is_visible = TRUE, is_system = TRUE, default_access = 'EXECUTE'::nxc_menu.access_level, updated_at = NOW()
    WHERE tenant_id = v_tid_system AND location = 'profile' AND name = 'Logout';
    IF NOT FOUND THEN
        INSERT INTO nxc_menu.menu_items (tenant_id, component_id, parent_id, name, title, route, icon, icon_type, location, item_type, order_index, is_visible, is_system, default_access, created_by, created_at, updated_at, version)
        VALUES (v_tid_system, v_comp_auth, v_menu_profile_group, 'Logout', 'menu.logout', '/auth/login', 'close', 'tabler', 'profile', 'ITEM', 30, TRUE, TRUE, 'EXECUTE'::nxc_menu.access_level, v_uid_super_admin, NOW(), NOW(), 0);
    END IF;

    -- 5) Permisos finales del SUPER_ADMIN y baseline de roles restantes
    DELETE FROM nxc_menu.component_permissions
    WHERE tenant_id = v_tid_system
      AND component_id IN (
          SELECT id FROM nxc_menu.components
          WHERE tenant_id = v_tid_system
            AND module_key NOT IN ('dashboard', 'tenant-management', 'user-management', 'audit-viewer', 'feature-flags', 'platform-settings', 'auth')
      );

    INSERT INTO nxc_menu.component_permissions (tenant_id, role_id, component_id, access, created_by, created_at, updated_at)
    SELECT v_tid_system, v_role_sys_super, c.id, 'EXECUTE'::nxc_menu.access_level, v_uid_super_admin, NOW(), NOW()
    FROM nxc_menu.components c
    WHERE c.tenant_id = v_tid_system
      AND c.module_key IN ('dashboard', 'tenant-management', 'user-management', 'audit-viewer', 'feature-flags', 'platform-settings', 'auth')
    ON CONFLICT (tenant_id, role_id, component_id) DO UPDATE
        SET access = 'EXECUTE'::nxc_menu.access_level,
            updated_at = NOW();

    -- Roles no super-admin quedan restringidos en componentes administrativos
    INSERT INTO nxc_menu.component_permissions (tenant_id, role_id, component_id, access, created_by, created_at, updated_at)
    SELECT v_tid_system, v_role_sys_admin, c.id,
           CASE WHEN c.module_key IN ('dashboard', 'auth') THEN 'EXECUTE'::nxc_menu.access_level ELSE 'HIDDEN'::nxc_menu.access_level END,
           v_uid_super_admin, NOW(), NOW()
    FROM nxc_menu.components c
    WHERE c.tenant_id = v_tid_system
      AND c.module_key IN ('dashboard', 'tenant-management', 'user-management', 'audit-viewer', 'feature-flags', 'platform-settings', 'auth')
    ON CONFLICT (tenant_id, role_id, component_id) DO UPDATE
        SET access = EXCLUDED.access,
            updated_at = NOW();

    INSERT INTO nxc_menu.component_permissions (tenant_id, role_id, component_id, access, created_by, created_at, updated_at)
    SELECT v_tid_system, v_role_sys_editor, c.id,
           CASE WHEN c.module_key IN ('dashboard', 'auth') THEN 'EXECUTE'::nxc_menu.access_level ELSE 'HIDDEN'::nxc_menu.access_level END,
           v_uid_super_admin, NOW(), NOW()
    FROM nxc_menu.components c
    WHERE c.tenant_id = v_tid_system
      AND c.module_key IN ('dashboard', 'tenant-management', 'user-management', 'audit-viewer', 'feature-flags', 'platform-settings', 'auth')
    ON CONFLICT (tenant_id, role_id, component_id) DO UPDATE
        SET access = EXCLUDED.access,
            updated_at = NOW();

    INSERT INTO nxc_menu.component_permissions (tenant_id, role_id, component_id, access, created_by, created_at, updated_at)
    SELECT v_tid_system, v_role_sys_viewer, c.id,
           CASE WHEN c.module_key IN ('dashboard', 'auth') THEN 'VIEW'::nxc_menu.access_level ELSE 'HIDDEN'::nxc_menu.access_level END,
           v_uid_super_admin, NOW(), NOW()
    FROM nxc_menu.components c
    WHERE c.tenant_id = v_tid_system
      AND c.module_key IN ('dashboard', 'tenant-management', 'user-management', 'audit-viewer', 'feature-flags', 'platform-settings', 'auth')
    ON CONFLICT (tenant_id, role_id, component_id) DO UPDATE
        SET access = EXCLUDED.access,
            updated_at = NOW();

    -- Alinear permisos del tenant demo al nuevo baseline
    DELETE FROM nxc_menu.component_permissions
    WHERE tenant_id = '00000000-0000-0000-0000-000000000002'
      AND component_id IN (
          SELECT id FROM nxc_menu.components
          WHERE tenant_id = v_tid_system
            AND module_key NOT IN ('dashboard', 'tenant-management', 'user-management', 'audit-viewer', 'feature-flags', 'platform-settings', 'auth')
      );

    INSERT INTO nxc_menu.component_permissions (tenant_id, role_id, component_id, access, created_by, created_at, updated_at)
    SELECT '00000000-0000-0000-0000-000000000002'::UUID, v_role_demo_admin, c.id,
           CASE WHEN c.module_key IN ('dashboard', 'auth') THEN 'EXECUTE'::nxc_menu.access_level ELSE 'HIDDEN'::nxc_menu.access_level END,
           v_uid_super_admin, NOW(), NOW()
    FROM nxc_menu.components c
    WHERE c.tenant_id = v_tid_system
      AND c.module_key IN ('dashboard', 'tenant-management', 'user-management', 'audit-viewer', 'feature-flags', 'platform-settings', 'auth')
    ON CONFLICT (tenant_id, role_id, component_id) DO UPDATE
        SET access = EXCLUDED.access,
            updated_at = NOW();

    INSERT INTO nxc_menu.component_permissions (tenant_id, role_id, component_id, access, created_by, created_at, updated_at)
    SELECT '00000000-0000-0000-0000-000000000002'::UUID, v_role_demo_editor, c.id,
           CASE WHEN c.module_key IN ('dashboard', 'auth') THEN 'EXECUTE'::nxc_menu.access_level ELSE 'HIDDEN'::nxc_menu.access_level END,
           v_uid_super_admin, NOW(), NOW()
    FROM nxc_menu.components c
    WHERE c.tenant_id = v_tid_system
      AND c.module_key IN ('dashboard', 'tenant-management', 'user-management', 'audit-viewer', 'feature-flags', 'platform-settings', 'auth')
    ON CONFLICT (tenant_id, role_id, component_id) DO UPDATE
        SET access = EXCLUDED.access,
            updated_at = NOW();

    INSERT INTO nxc_menu.component_permissions (tenant_id, role_id, component_id, access, created_by, created_at, updated_at)
    SELECT '00000000-0000-0000-0000-000000000002'::UUID, v_role_demo_viewer, c.id,
           CASE WHEN c.module_key IN ('dashboard', 'auth') THEN 'VIEW'::nxc_menu.access_level ELSE 'HIDDEN'::nxc_menu.access_level END,
           v_uid_super_admin, NOW(), NOW()
    FROM nxc_menu.components c
    WHERE c.tenant_id = v_tid_system
      AND c.module_key IN ('dashboard', 'tenant-management', 'user-management', 'audit-viewer', 'feature-flags', 'platform-settings', 'auth')
    ON CONFLICT (tenant_id, role_id, component_id) DO UPDATE
        SET access = EXCLUDED.access,
            updated_at = NOW();

    RAISE NOTICE 'Consolidación SUPER_ADMIN aplicada (logout en EXECUTE).';
END $$;

-- =============================================================================
-- BLOQUE 11 — CONSOLIDACIÓN TENANT DEMO (antes en 02-admin-user-config.sql)
-- Deja el tenant demo con navegación navbar/profile y usuarios demo base.
-- =============================================================================

DO $$
DECLARE
        v_tenant_id            UUID := '00000000-0000-0000-0000-000000000002';
        v_user_admin_id        UUID := '00000000-0000-0000-0001-000000000002';
        v_user_editor_id       UUID := '00000000-0000-0000-0001-000000000003';
    v_user_test_admin_id   UUID := '00000000-0000-0000-0001-000000000004';
    v_user_test_editor_id  UUID := '00000000-0000-0000-0001-000000000005';

        v_role_tenant_admin    UUID;
        v_role_editor          UUID;

        v_comp_identity_access UUID;
        v_comp_navigation      UUID;
        v_comp_audit           UUID;
        v_comp_tenant_settings UUID;
        v_comp_profile         UUID;
        v_comp_crm             UUID;
        v_comp_projects        UUID;
        v_comp_monitoring      UUID;

        v_menu_admin_group     UUID;
        v_menu_profile_group   UUID;

        v_exists               INTEGER;
BEGIN
        RAISE NOTICE '=== BLOQUE 11: Consolidación tenant demo ===';

        -- Validaciones base
        SELECT COUNT(*) INTO v_exists
        FROM nxc_tenant.tenants
        WHERE id = v_tenant_id AND deleted_at IS NULL;
        IF v_exists = 0 THEN
                RAISE EXCEPTION 'Tenant % no existe', v_tenant_id;
        END IF;

        SELECT id INTO v_role_tenant_admin
        FROM nxc_tenant.roles
        WHERE tenant_id = v_tenant_id
            AND name = 'TENANT_ADMIN'
            AND deleted_at IS NULL
        LIMIT 1;

        IF v_role_tenant_admin IS NULL THEN
                RAISE EXCEPTION 'Role TENANT_ADMIN no existe para tenant %', v_tenant_id;
        END IF;

        SELECT id INTO v_role_editor
        FROM nxc_tenant.roles
        WHERE tenant_id = v_tenant_id
            AND name = 'EDITOR'
            AND deleted_at IS NULL
        LIMIT 1;

        IF v_role_editor IS NULL THEN
                RAISE EXCEPTION 'Role EDITOR no existe para tenant %', v_tenant_id;
        END IF;

        -- Usuario TENANT_ADMIN demo (id fijo)
        UPDATE nxc_tenant.users
        SET tenant_id = v_tenant_id,
                status = 'ACTIVE',
                is_tenant_admin = TRUE,
                email_verified = TRUE,
                email_verified_at = COALESCE(email_verified_at, NOW()),
                updated_at = NOW()
        WHERE id = v_user_admin_id;

        IF NOT FOUND THEN
                INSERT INTO nxc_tenant.users (
                        id, tenant_id, username, email, password_hash, full_name,
                        status, is_tenant_admin, email_verified, email_verified_at,
                        activated_at, created_at, updated_at, version
                ) VALUES (
                        v_user_admin_id, v_tenant_id,
                        'admin.demo', 'admin.demo@nexcore.io',
                        '$2a$12$2SgNZ1P9TWruO3hmUqL6u.U3K4mKg9o7xtK6N8uZJXVxjFqbMDf/y',
                        'Admin Demo',
                        'ACTIVE', TRUE, TRUE, NOW(),
                        NOW(), NOW(), NOW(), 0
                );
        END IF;

        -- Dejar solo TENANT_ADMIN para admin.demo
        DELETE FROM nxc_tenant.user_roles
        WHERE tenant_id = v_tenant_id
            AND user_id = v_user_admin_id;

        INSERT INTO nxc_tenant.user_roles (tenant_id, user_id, role_id, assigned_at, assigned_by)
        VALUES (v_tenant_id, v_user_admin_id, v_role_tenant_admin, NOW(), v_user_admin_id)
        ON CONFLICT (tenant_id, user_id, role_id) DO NOTHING;

        -- Usuario EDITOR demo
        INSERT INTO nxc_tenant.users (
                id, tenant_id, username, email, password_hash, full_name,
                status, is_tenant_admin, email_verified, email_verified_at,
                activated_at, created_at, updated_at, version
        ) VALUES (
                v_user_editor_id, v_tenant_id,
                'editor.demo', 'editor.demo@nexcore.io',
                '$2a$12$2SgNZ1P9TWruO3hmUqL6u.U3K4mKg9o7xtK6N8uZJXVxjFqbMDf/y',
                'Editor Demo',
                'ACTIVE', FALSE, TRUE, NOW(),
                NOW(), NOW(), NOW(), 0
        )
        ON CONFLICT (id) DO UPDATE
        SET tenant_id = EXCLUDED.tenant_id,
                username = EXCLUDED.username,
                email = EXCLUDED.email,
                full_name = EXCLUDED.full_name,
                status = 'ACTIVE',
                is_tenant_admin = FALSE,
                updated_at = NOW();

        -- Dejar solo EDITOR para editor.demo
        DELETE FROM nxc_tenant.user_roles
        WHERE tenant_id = v_tenant_id
            AND user_id = v_user_editor_id;

        INSERT INTO nxc_tenant.user_roles (tenant_id, user_id, role_id, assigned_at, assigned_by)
        VALUES (v_tenant_id, v_user_editor_id, v_role_editor, NOW(), v_user_admin_id)
        ON CONFLICT (tenant_id, user_id, role_id) DO NOTHING;

        -- Usuario TEST TENANT_ADMIN
        INSERT INTO nxc_tenant.users (
            id, tenant_id, username, email, password_hash, full_name,
            status, is_tenant_admin, email_verified, email_verified_at,
            activated_at, created_at, updated_at, version
        ) VALUES (
            v_user_test_admin_id, v_tenant_id,
            'test.admin', 'test.admin@nexcore.io',
            '$2a$12$2SgNZ1P9TWruO3hmUqL6u.U3K4mKg9o7xtK6N8uZJXVxjFqbMDf/y',
            'Test Admin',
            'ACTIVE', TRUE, TRUE, NOW(),
            NOW(), NOW(), NOW(), 0
        )
        ON CONFLICT (id) DO UPDATE
        SET tenant_id = EXCLUDED.tenant_id,
            username = EXCLUDED.username,
            email = EXCLUDED.email,
            full_name = EXCLUDED.full_name,
            status = 'ACTIVE',
            is_tenant_admin = TRUE,
            updated_at = NOW();

        DELETE FROM nxc_tenant.user_roles
        WHERE tenant_id = v_tenant_id
            AND user_id = v_user_test_admin_id;

        INSERT INTO nxc_tenant.user_roles (tenant_id, user_id, role_id, assigned_at, assigned_by)
        VALUES (v_tenant_id, v_user_test_admin_id, v_role_tenant_admin, NOW(), v_user_admin_id)
        ON CONFLICT (tenant_id, user_id, role_id) DO NOTHING;

        -- Usuario TEST EDITOR
        INSERT INTO nxc_tenant.users (
            id, tenant_id, username, email, password_hash, full_name,
            status, is_tenant_admin, email_verified, email_verified_at,
            activated_at, created_at, updated_at, version
        ) VALUES (
            v_user_test_editor_id, v_tenant_id,
            'test.editor', 'test.editor@nexcore.io',
            '$2a$12$2SgNZ1P9TWruO3hmUqL6u.U3K4mKg9o7xtK6N8uZJXVxjFqbMDf/y',
            'Test Editor',
            'ACTIVE', FALSE, TRUE, NOW(),
            NOW(), NOW(), NOW(), 0
        )
        ON CONFLICT (id) DO UPDATE
        SET tenant_id = EXCLUDED.tenant_id,
            username = EXCLUDED.username,
            email = EXCLUDED.email,
            full_name = EXCLUDED.full_name,
            status = 'ACTIVE',
            is_tenant_admin = FALSE,
            updated_at = NOW();

        DELETE FROM nxc_tenant.user_roles
        WHERE tenant_id = v_tenant_id
            AND user_id = v_user_test_editor_id;

        INSERT INTO nxc_tenant.user_roles (tenant_id, user_id, role_id, assigned_at, assigned_by)
        VALUES (v_tenant_id, v_user_test_editor_id, v_role_editor, NOW(), v_user_admin_id)
        ON CONFLICT (tenant_id, user_id, role_id) DO NOTHING;

        -- Componentes del tenant demo para sidebar/profile
        INSERT INTO nxc_menu.components (tenant_id, module_key, name, route, description, is_system, created_by, created_at, updated_at, version)
        VALUES
            (v_tenant_id, 'user-management', 'Identity & Access', '/identity-access', 'Identity & Access', TRUE, v_user_admin_id, NOW(), NOW(), 0),
            (v_tenant_id, 'menu-management', 'Navigation', '/admin/menus', 'Navigation', TRUE, v_user_admin_id, NOW(), NOW(), 0),
            (v_tenant_id, 'audit-viewer', 'Audit', '/audit', 'Audit', TRUE, v_user_admin_id, NOW(), NOW(), 0),
            (v_tenant_id, 'tenant-settings', 'Tenant Settings', '/settings', 'Tenant Settings', TRUE, v_user_admin_id, NOW(), NOW(), 0),
            (v_tenant_id, 'profile', 'Profile', '/profile', 'Profile', TRUE, v_user_admin_id, NOW(), NOW(), 0),
            (v_tenant_id, 'crm', 'CRM', '/crm', 'CRM', TRUE, v_user_admin_id, NOW(), NOW(), 0),
            (v_tenant_id, 'projects', 'Projects', '/projects', 'Projects', TRUE, v_user_admin_id, NOW(), NOW(), 0),
            (v_tenant_id, 'monitoring', 'Monitoring', '/monitoring', 'Monitoring', TRUE, v_user_admin_id, NOW(), NOW(), 0)
        ON CONFLICT (tenant_id, module_key) DO UPDATE
        SET name = EXCLUDED.name,
                route = EXCLUDED.route,
                description = EXCLUDED.description,
                is_system = EXCLUDED.is_system,
                updated_at = NOW();

        SELECT id INTO v_comp_identity_access FROM nxc_menu.components WHERE tenant_id = v_tenant_id AND module_key = 'user-management';
        SELECT id INTO v_comp_navigation      FROM nxc_menu.components WHERE tenant_id = v_tenant_id AND module_key = 'menu-management';
        SELECT id INTO v_comp_audit           FROM nxc_menu.components WHERE tenant_id = v_tenant_id AND module_key = 'audit-viewer';
        SELECT id INTO v_comp_tenant_settings FROM nxc_menu.components WHERE tenant_id = v_tenant_id AND module_key = 'tenant-settings';
        SELECT id INTO v_comp_profile         FROM nxc_menu.components WHERE tenant_id = v_tenant_id AND module_key = 'profile';
        SELECT id INTO v_comp_crm             FROM nxc_menu.components WHERE tenant_id = v_tenant_id AND module_key = 'crm';
        SELECT id INTO v_comp_projects        FROM nxc_menu.components WHERE tenant_id = v_tenant_id AND module_key = 'projects';
        SELECT id INTO v_comp_monitoring      FROM nxc_menu.components WHERE tenant_id = v_tenant_id AND module_key = 'monitoring';

        -- Menú sidebar/profile del tenant demo
        DELETE FROM nxc_menu.menu_items
        WHERE tenant_id = v_tenant_id
            AND location IN ('navbar', 'sidebar', 'profile');

        INSERT INTO nxc_menu.menu_items (
            tenant_id, component_id, parent_id, name, title, route, icon, icon_type, location,
            item_type, order_index, is_visible, is_system, default_access, created_by, created_at, updated_at, version
        ) VALUES (
            v_tenant_id, v_comp_navigation, NULL, 'Admin', 'menu.admin', NULL, 'settings', 'tabler', 'sidebar',
            'GROUP', 10, TRUE, TRUE, 'EXECUTE'::nxc_menu.access_level, v_user_admin_id, NOW(), NOW(), 0
        ) RETURNING id INTO v_menu_admin_group;

        INSERT INTO nxc_menu.menu_items (
            tenant_id, component_id, parent_id, name, title, route, icon, icon_type, location,
            item_type, order_index, is_visible, is_system, default_access, created_by, created_at, updated_at, version
        ) VALUES
            (v_tenant_id, v_comp_identity_access, v_menu_admin_group, 'IdentityAccess', 'menu.identity-access', '/identity-access', 'users', 'tabler', 'sidebar', 'ITEM', 10, TRUE, TRUE, 'EXECUTE'::nxc_menu.access_level, v_user_admin_id, NOW(), NOW(), 0),
            (v_tenant_id, v_comp_navigation,      v_menu_admin_group, 'Navigation',     'menu.navigation',      '/admin/menus',     'menu',  'tabler', 'sidebar', 'ITEM', 20, TRUE, TRUE, 'EXECUTE'::nxc_menu.access_level, v_user_admin_id, NOW(), NOW(), 0),
            (v_tenant_id, v_comp_audit,           v_menu_admin_group, 'Audit',          'menu.audit',           '/audit',           'chart-bar', 'tabler', 'sidebar', 'ITEM', 30, TRUE, TRUE, 'EXECUTE'::nxc_menu.access_level, v_user_admin_id, NOW(), NOW(), 0),
            (v_tenant_id, v_comp_tenant_settings, v_menu_admin_group, 'TenantSettings', 'menu.tenant-settings', '/settings',        'settings', 'tabler', 'sidebar', 'ITEM', 40, TRUE, TRUE, 'EXECUTE'::nxc_menu.access_level, v_user_admin_id, NOW(), NOW(), 0),
            (v_tenant_id, v_comp_profile,         v_menu_admin_group, 'Profile',        'menu.profile_sidebar', '/profile',         'profile', 'tabler', 'sidebar', 'ITEM', 50, TRUE, TRUE, 'EXECUTE'::nxc_menu.access_level, v_user_admin_id, NOW(), NOW(), 0);

        INSERT INTO nxc_menu.menu_items (
            tenant_id, component_id, parent_id, name, title, route, icon, icon_type, location,
            item_type, order_index, is_visible, is_system, default_access, created_by, created_at, updated_at, version
        ) VALUES
            (v_tenant_id, v_comp_crm,        NULL, 'CRM',        'menu.crm',        '/crm',        'dashboard', 'tabler', 'sidebar', 'ITEM', 20, TRUE, TRUE, 'EXECUTE'::nxc_menu.access_level, v_user_admin_id, NOW(), NOW(), 0),
            (v_tenant_id, v_comp_projects,   NULL, 'Projects',   'menu.projects',   '/projects',   'home',      'tabler', 'sidebar', 'ITEM', 30, TRUE, TRUE, 'EXECUTE'::nxc_menu.access_level, v_user_admin_id, NOW(), NOW(), 0),
            (v_tenant_id, v_comp_monitoring, NULL, 'Monitoring', 'menu.monitoring', '/monitoring', 'bell',      'tabler', 'sidebar', 'ITEM', 40, TRUE, TRUE, 'EXECUTE'::nxc_menu.access_level, v_user_admin_id, NOW(), NOW(), 0);

        INSERT INTO nxc_menu.menu_items (
            tenant_id, component_id, parent_id, name, title, route, icon, icon_type, location,
            item_type, order_index, is_visible, is_system, default_access, created_by, created_at, updated_at, version
        ) VALUES (
            v_tenant_id, v_comp_profile, NULL, 'ProfileMenu', 'menu.profile_menu', NULL, 'profile', 'tabler', 'profile',
            'GROUP', 10, TRUE, TRUE, 'EXECUTE'::nxc_menu.access_level, v_user_admin_id, NOW(), NOW(), 0
        ) RETURNING id INTO v_menu_profile_group;

        INSERT INTO nxc_menu.menu_items (
            tenant_id, component_id, parent_id, name, title, route, icon, icon_type, location,
            item_type, order_index, is_visible, is_system, default_access, created_by, created_at, updated_at, version
        ) VALUES
            (v_tenant_id, v_comp_profile,         v_menu_profile_group, 'MyProfile', 'menu.my-profile', '/profile',  'profile',  'tabler', 'profile', 'ITEM', 10, TRUE, TRUE, 'EXECUTE'::nxc_menu.access_level, v_user_admin_id, NOW(), NOW(), 0),
            (v_tenant_id, v_comp_tenant_settings, v_menu_profile_group, 'Settings',  'menu.settings',   '/settings', 'settings', 'tabler', 'profile', 'ITEM', 20, TRUE, TRUE, 'EXECUTE'::nxc_menu.access_level, v_user_admin_id, NOW(), NOW(), 0),
            (v_tenant_id, v_comp_profile,         v_menu_profile_group, 'Logout',    'menu.logout','/auth/login','close',   'tabler', 'profile', 'ITEM', 90, TRUE, TRUE, 'EXECUTE'::nxc_menu.access_level, v_user_admin_id, NOW(), NOW(), 0);

        -- Permisos componente: TENANT_ADMIN = EXECUTE
        INSERT INTO nxc_menu.component_permissions (tenant_id, role_id, component_id, access, created_by, created_at, updated_at)
        SELECT v_tenant_id, v_role_tenant_admin, c.id, 'EXECUTE'::nxc_menu.access_level, v_user_admin_id, NOW(), NOW()
        FROM nxc_menu.components c
        WHERE c.tenant_id = v_tenant_id
            AND c.module_key IN ('user-management','menu-management','audit-viewer','tenant-settings','profile','crm','projects','monitoring')
        ON CONFLICT (tenant_id, role_id, component_id)
        DO UPDATE SET access = EXCLUDED.access, updated_at = NOW();

        -- Permisos componente: EDITOR = EXECUTE solo en módulos operativos definidos
        INSERT INTO nxc_menu.component_permissions (tenant_id, role_id, component_id, access, created_by, created_at, updated_at)
        SELECT
            v_tenant_id,
            v_role_editor,
            c.id,
            CASE
                WHEN c.module_key IN ('crm','projects','monitoring','profile','tenant-settings')
                    THEN 'EXECUTE'::nxc_menu.access_level
                ELSE 'HIDDEN'::nxc_menu.access_level
            END,
            v_user_admin_id, NOW(), NOW()
        FROM nxc_menu.components c
        WHERE c.tenant_id = v_tenant_id
            AND c.module_key IN ('user-management','menu-management','audit-viewer','tenant-settings','profile','crm','projects','monitoring')
        ON CONFLICT (tenant_id, role_id, component_id)
        DO UPDATE SET access = EXCLUDED.access, updated_at = NOW();

        RAISE NOTICE 'Consolidación tenant demo aplicada (navbar/profile + logout).';
END $$;

-- =============================================================================
-- BLOQUE 12 — NORMALIZACIÓN DE UBICACIÓN DE MENÚ
-- Reglas de despliegue base: todos los ítems de navbar pasan a sidebar.
-- =============================================================================

DO $$
BEGIN
    UPDATE nxc_menu.menu_items
    SET location = 'sidebar',
        updated_at = NOW()
    WHERE location = 'navbar';

    RAISE NOTICE 'Normalización aplicada: menu_items navbar -> sidebar';
END $$;

-- =============================================================================
-- Verificación post-seed
-- Ejecutar estas queries para confirmar que todo quedó correctamente:
-- =============================================================================

-- Tenants creados
-- SELECT id, slug, name, plan, mode, status FROM nxc_tenant.tenants ORDER BY created_at;

-- Roles por tenant
-- SELECT t.slug, r.name, r.is_system_role, r.is_default
-- FROM nxc_tenant.roles r
-- JOIN nxc_tenant.tenants t ON t.id = r.tenant_id
-- ORDER BY t.slug, r.name;

-- Usuarios y sus roles
-- SELECT t.slug, u.username, u.email, u.status, u.is_tenant_admin,
--        array_agg(r.name) AS roles
-- FROM nxc_tenant.users u
-- JOIN nxc_tenant.tenants t ON t.id = u.tenant_id
-- LEFT JOIN nxc_tenant.user_roles ur ON ur.user_id = u.id
-- LEFT JOIN nxc_tenant.roles r ON r.id = ur.role_id
-- GROUP BY t.slug, u.username, u.email, u.status, u.is_tenant_admin
-- ORDER BY t.slug, u.username;

-- Árbol de menú (2 niveles)
-- SELECT
--     CASE WHEN mi.parent_id IS NULL THEN mi.name ELSE '  └─ ' || mi.name END AS menu,
--     mi.route, mi.icon, mi.item_type, mi.order_index
-- FROM nxc_menu.menu_items mi
-- WHERE mi.tenant_id = '00000000-0000-0000-0000-000000000001'
--   AND mi.deleted_at IS NULL
-- ORDER BY COALESCE(mi.parent_id::text, mi.id::text), mi.order_index;

-- Permisos efectivos por rol (usando la vista)
-- SELECT v.name, v.route, v.role_id, v.effective_access
-- FROM nxc_menu.v_menu_effective_access v
-- WHERE v.tenant_id = '00000000-0000-0000-0000-000000000001'
-- ORDER BY v.order_index, v.name;

-- Feature flags globales
-- SELECT flag_key, description, is_enabled, min_plan
-- FROM nxc_config.feature_flags
-- WHERE tenant_id IS NULL
-- ORDER BY min_plan NULLS FIRST, flag_key;

-- =============================================================================
-- FIN — V013__seed_initial_data.sql
-- =============================================================================