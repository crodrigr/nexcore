-- =============================================================================
-- NexCore Platform  –  V013__seed_initial_data.sql
-- Datos iniciales de la plataforma NexCore
--
-- Estructura generada desde JSON de configuración de menús:
--   Tenant system  (00…0001): SUPER_ADMIN → Tenants + ProfileMenu
--   Tenant demo    (00…0002): TENANT_ADMIN/EDITOR/VIEWER → Dashboard + Admin + CRM + Monitoring + ProfileMenu
--
-- UUIDs fijos:
--   Tenant system    : 00000000-0000-0000-0000-000000000001
--   Tenant demo      : 00000000-0000-0000-0000-000000000002
--   User super_admin : 00000000-0000-0000-0001-000000000001
--   User admin_demo  : 00000000-0000-0000-0001-000000000002
--
-- NOTA SEGURIDAD: Los password_hash son PLACEHOLDERS de desarrollo.
--   Reemplazar con hashes BCrypt reales antes de usar en otro entorno.
-- =============================================================================

-- =============================================================================
-- BLOQUE 1 — TENANT SISTEMA + SUPER_ADMIN
-- =============================================================================
DO $$
DECLARE
    v_tid_system      UUID := '00000000-0000-0000-0000-000000000001';
    v_uid_super_admin UUID := '00000000-0000-0000-0001-000000000001';
    v_role_sys_super  UUID;
BEGIN
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
        v_tid_system, 'system', 'NexCore System', 'NexCore Platform S.A.S.',
        'ENTERPRISE', 'ON_PREMISE', 'ACTIVE',
        'UTC', 'es-CO', 'DD/MM/YYYY', 'COP',
        FALSE, 480, 5,
        10, TRUE, TRUE, 365,
        NOW(), NOW(), 0
    ) ON CONFLICT (id) DO NOTHING;

    DELETE FROM nxc_tenant.roles
    WHERE tenant_id = v_tid_system AND name IN ('TENANT_ADMIN', 'EDITOR', 'VIEWER');

    INSERT INTO nxc_tenant.roles (tenant_id, name, description, is_system_role, is_default)
    VALUES (v_tid_system, 'SUPER_ADMIN',
            'Administrador global de la plataforma. Acceso total a todos los tenants vía bypass de RLS.',
            TRUE, FALSE)
    ON CONFLICT (tenant_id, name) DO NOTHING;

    SELECT id INTO v_role_sys_super
    FROM nxc_tenant.roles WHERE tenant_id = v_tid_system AND name = 'SUPER_ADMIN';

    INSERT INTO nxc_tenant.users (
        id, tenant_id, username, email, password_hash,
        full_name, status, is_tenant_admin,
        email_verified, email_verified_at, activated_at,
        created_at, updated_at, version
    ) VALUES (
        v_uid_super_admin, v_tid_system,
        'super.admin', 'super.admin@nexcore.io',
        '$2a$12$2SgNZ1P9TWruO3hmUqL6u.U3K4mKg9o7xtK6N8uZJXVxjFqbMDf/y',
        'Super Administrador NexCore', 'ACTIVE', TRUE,
        TRUE, NOW(), NOW(),
        NOW(), NOW(), 0
    ) ON CONFLICT (id) DO NOTHING;

    INSERT INTO nxc_tenant.user_roles (tenant_id, user_id, role_id, assigned_at, assigned_by)
    VALUES (v_tid_system, v_uid_super_admin, v_role_sys_super, NOW(), v_uid_super_admin)
    ON CONFLICT (tenant_id, user_id, role_id) DO NOTHING;

    RAISE NOTICE 'Tenant system OK: %', v_tid_system;
END $$;

-- =============================================================================
-- BLOQUE 2 — TENANT DEMO + USUARIOS
-- =============================================================================
DO $$
DECLARE
    v_tid_demo          UUID := '00000000-0000-0000-0000-000000000002';
    v_uid_admin_demo    UUID := '00000000-0000-0000-0001-000000000002';
    v_uid_editor_demo   UUID := '00000000-0000-0000-0001-000000000003';
    v_uid_test_admin    UUID := '00000000-0000-0000-0001-000000000004';
    v_uid_test_editor   UUID := '00000000-0000-0000-0001-000000000005';
    v_role_tenant_admin UUID;
    v_role_editor       UUID;
BEGIN
    RAISE NOTICE '=== BLOQUE 2: Tenant demo ===';

    INSERT INTO nxc_tenant.tenants (
        id, slug, name, legal_name, tax_id,
        plan, mode, status, primary_color,
        timezone, locale, date_format, currency,
        mfa_required, session_timeout_minutes, max_login_attempts,
        password_min_length, password_requires_upper, password_requires_special,
        max_users, audit_retention_days,
        trial_ends_at, subscription_ends_at,
        created_at, updated_at, version
    ) VALUES (
        v_tid_demo, 'demo', 'Tenant Demo', 'Tenant Demo S.A.S.', '900123456-7',
        'STARTER', 'SAAS_SHARED', 'ACTIVE', '#1976D2',
        'America/Bogota', 'es-CO', 'DD/MM/YYYY', 'COP',
        FALSE, 480, 5, 8, FALSE, FALSE,
        100, 90,
        NOW() + INTERVAL '15 days', NOW() + INTERVAL '1 year',
        NOW(), NOW(), 0
    ) ON CONFLICT (id) DO NOTHING;

    SELECT id INTO v_role_tenant_admin
    FROM nxc_tenant.roles WHERE tenant_id = v_tid_demo AND name = 'TENANT_ADMIN';
    SELECT id INTO v_role_editor
    FROM nxc_tenant.roles WHERE tenant_id = v_tid_demo AND name = 'EDITOR';

    -- admin.demo (TENANT_ADMIN)
    INSERT INTO nxc_tenant.users (
        id, tenant_id, username, email, password_hash, full_name,
        status, is_tenant_admin, email_verified, email_verified_at,
        activated_at, created_at, updated_at, version
    ) VALUES (
        v_uid_admin_demo, v_tid_demo,
        'admin.demo', 'admin.demo@nexcore.io',
        '$2a$12$2SgNZ1P9TWruO3hmUqL6u.U3K4mKg9o7xtK6N8uZJXVxjFqbMDf/y',
        'Admin Demo', 'ACTIVE', TRUE, TRUE, NOW(),
        NOW(), NOW(), NOW(), 0
    ) ON CONFLICT (id) DO UPDATE SET status = 'ACTIVE', updated_at = NOW();

    DELETE FROM nxc_tenant.user_roles WHERE tenant_id = v_tid_demo AND user_id = v_uid_admin_demo;
    INSERT INTO nxc_tenant.user_roles (tenant_id, user_id, role_id, assigned_at, assigned_by)
    VALUES (v_tid_demo, v_uid_admin_demo, v_role_tenant_admin, NOW(), v_uid_admin_demo)
    ON CONFLICT (tenant_id, user_id, role_id) DO NOTHING;

    -- editor.demo (EDITOR)
    INSERT INTO nxc_tenant.users (
        id, tenant_id, username, email, password_hash, full_name,
        status, is_tenant_admin, email_verified, email_verified_at,
        activated_at, created_at, updated_at, version
    ) VALUES (
        v_uid_editor_demo, v_tid_demo,
        'editor.demo', 'editor.demo@nexcore.io',
        '$2a$12$2SgNZ1P9TWruO3hmUqL6u.U3K4mKg9o7xtK6N8uZJXVxjFqbMDf/y',
        'Editor Demo', 'ACTIVE', FALSE, TRUE, NOW(),
        NOW(), NOW(), NOW(), 0
    ) ON CONFLICT (id) DO UPDATE SET status = 'ACTIVE', updated_at = NOW();

    DELETE FROM nxc_tenant.user_roles WHERE tenant_id = v_tid_demo AND user_id = v_uid_editor_demo;
    INSERT INTO nxc_tenant.user_roles (tenant_id, user_id, role_id, assigned_at, assigned_by)
    VALUES (v_tid_demo, v_uid_editor_demo, v_role_editor, NOW(), v_uid_admin_demo)
    ON CONFLICT (tenant_id, user_id, role_id) DO NOTHING;

    -- test.admin (TENANT_ADMIN)
    INSERT INTO nxc_tenant.users (
        id, tenant_id, username, email, password_hash, full_name,
        status, is_tenant_admin, email_verified, email_verified_at,
        activated_at, created_at, updated_at, version
    ) VALUES (
        v_uid_test_admin, v_tid_demo,
        'test.admin', 'test.admin@nexcore.io',
        '$2a$12$2SgNZ1P9TWruO3hmUqL6u.U3K4mKg9o7xtK6N8uZJXVxjFqbMDf/y',
        'Test Admin', 'ACTIVE', TRUE, TRUE, NOW(),
        NOW(), NOW(), NOW(), 0
    ) ON CONFLICT (id) DO UPDATE SET status = 'ACTIVE', updated_at = NOW();

    DELETE FROM nxc_tenant.user_roles WHERE tenant_id = v_tid_demo AND user_id = v_uid_test_admin;
    INSERT INTO nxc_tenant.user_roles (tenant_id, user_id, role_id, assigned_at, assigned_by)
    VALUES (v_tid_demo, v_uid_test_admin, v_role_tenant_admin, NOW(), v_uid_admin_demo)
    ON CONFLICT (tenant_id, user_id, role_id) DO NOTHING;

    -- test.editor (EDITOR)
    INSERT INTO nxc_tenant.users (
        id, tenant_id, username, email, password_hash, full_name,
        status, is_tenant_admin, email_verified, email_verified_at,
        activated_at, created_at, updated_at, version
    ) VALUES (
        v_uid_test_editor, v_tid_demo,
        'test.editor', 'test.editor@nexcore.io',
        '$2a$12$2SgNZ1P9TWruO3hmUqL6u.U3K4mKg9o7xtK6N8uZJXVxjFqbMDf/y',
        'Test Editor', 'ACTIVE', FALSE, TRUE, NOW(),
        NOW(), NOW(), NOW(), 0
    ) ON CONFLICT (id) DO UPDATE SET status = 'ACTIVE', updated_at = NOW();

    DELETE FROM nxc_tenant.user_roles WHERE tenant_id = v_tid_demo AND user_id = v_uid_test_editor;
    INSERT INTO nxc_tenant.user_roles (tenant_id, user_id, role_id, assigned_at, assigned_by)
    VALUES (v_tid_demo, v_uid_test_editor, v_role_editor, NOW(), v_uid_admin_demo)
    ON CONFLICT (tenant_id, user_id, role_id) DO NOTHING;

    RAISE NOTICE 'Tenant demo OK: %', v_tid_demo;
END $$;

-- =============================================================================
-- BLOQUE 3 — FEATURE FLAGS GLOBALES
-- =============================================================================
DO $$
DECLARE
    v_uid_super_admin UUID := '00000000-0000-0000-0001-000000000001';
BEGIN
    RAISE NOTICE '=== BLOQUE 3: Feature flags globales ===';

    INSERT INTO nxc_config.feature_flags
        (tenant_id, flag_key, description, is_enabled, min_plan, created_by, created_at, updated_at)
    VALUES
        (NULL, 'multi-language',        'Soporte para múltiples idiomas en la interfaz.',        TRUE,  NULL,           v_uid_super_admin, NOW(), NOW()),
        (NULL, 'dark-mode',             'Tema oscuro en la interfaz de usuario.',                 TRUE,  NULL,           v_uid_super_admin, NOW(), NOW()),
        (NULL, 'notifications-sound',   'Sonido en notificaciones en tiempo real.',               TRUE,  NULL,           v_uid_super_admin, NOW(), NOW()),
        (NULL, 'audit-viewer',          'Acceso al módulo de auditoría de cambios.',             TRUE,  'STARTER',      v_uid_super_admin, NOW(), NOW()),
        (NULL, 'saved-filters',         'Filtros guardados por usuario.',                         TRUE,  'STARTER',      v_uid_super_admin, NOW(), NOW()),
        (NULL, 'column-config',         'Configuración de columnas por tabla.',                   TRUE,  'STARTER',      v_uid_super_admin, NOW(), NOW()),
        (NULL, 'advanced-reporting',    'Reportes avanzados y exportación de datos.',             FALSE, 'PROFESSIONAL', v_uid_super_admin, NOW(), NOW()),
        (NULL, 'webhook-notifications', 'Notificaciones vía webhook a sistemas externos.',        FALSE, 'PROFESSIONAL', v_uid_super_admin, NOW(), NOW()),
        (NULL, 'custom-domain',         'Dominio personalizado para el portal del tenant.',       FALSE, 'PROFESSIONAL', v_uid_super_admin, NOW(), NOW()),
        (NULL, 'sso-okta',             'Autenticación SSO vía Okta.',                            FALSE, 'ENTERPRISE',   v_uid_super_admin, NOW(), NOW()),
        (NULL, 'audit-export',         'Exportación de registros de auditoría en CSV/JSON.',      FALSE, 'ENTERPRISE',   v_uid_super_admin, NOW(), NOW()),
        (NULL, 'ip-whitelist',         'Lista blanca de IPs permitidas para el tenant.',          FALSE, 'ENTERPRISE',   v_uid_super_admin, NOW(), NOW())
    ON CONFLICT (tenant_id, flag_key) DO NOTHING;

    RAISE NOTICE 'Feature flags OK';
END $$;

-- =============================================================================
-- BLOQUE 4 — CONFIGURACIÓN BASE DEL TENANT DEMO
-- =============================================================================
DO $$
DECLARE
    v_tid_demo       UUID := '00000000-0000-0000-0000-000000000002';
    v_uid_admin_demo UUID := '00000000-0000-0000-0001-000000000002';
BEGIN
    RAISE NOTICE '=== BLOQUE 4: Configuración tenant demo ===';

    INSERT INTO nxc_config.tenant_configs
        (tenant_id, config_key, config_value, description, is_secret, created_by, created_at, updated_at)
    VALUES
        (v_tid_demo, 'email.from',            '"no-reply@demo.nexcore.io"', 'Dirección remitente para emails.',         FALSE, v_uid_admin_demo, NOW(), NOW()),
        (v_tid_demo, 'email.from_name',       '"NexCore Demo"',             'Nombre del remitente en emails.',          FALSE, v_uid_admin_demo, NOW(), NOW()),
        (v_tid_demo, 'ui.items_per_page',     '20',                         'Número de elementos por página.',          FALSE, v_uid_admin_demo, NOW(), NOW()),
        (v_tid_demo, 'ui.default_theme',      '"system"',                   'Tema por defecto: light | dark | system.', FALSE, v_uid_admin_demo, NOW(), NOW()),
        (v_tid_demo, 'notification.channels', '["IN_APP","EMAIL"]',          'Canales de notificación habilitados.',    FALSE, v_uid_admin_demo, NOW(), NOW())
    ON CONFLICT (tenant_id, config_key) DO NOTHING;

    RAISE NOTICE 'Configuración demo OK';
END $$;

-- =============================================================================
-- BLOQUE 5 — COMPONENTES, ELEMENTOS, MENÚS Y PERMISOS
--
-- ÚNICA FUENTE DE VERDAD: estructura definida por JSON de configuración.
-- Se elimina todo lo existente para ambos tenants antes de recrear.
--
-- Tenant system  (00…0001):
--   Componentes : tenant-management, profile-menu
--   Elementos   : profile-menu → profile, settings, logout
--   Sidebar     : Tenants (ITEM)
--   Profile     : ProfileMenu (GROUP) → Profile, Settings, Logout
--   Permisos    : SUPER_ADMIN → EXECUTE en todo
--
-- Tenant demo    (00…0002):
--   Componentes : dashboard, crm, monitoring, profile-menu, admin-panel
--   Elementos   : profile-menu → profile, settings, logout
--                 admin-panel  → user, permissions
--   Sidebar     : Dashboard (ITEM), Admin (GROUP → User / Permisos), CRM (ITEM), Monitoring (ITEM)
--   Profile     : ProfileMenu (GROUP) → Profile, Settings, Logout
--   Permisos    : TENANT_ADMIN = EXECUTE todo
--                 EDITOR       = EXECUTE Dashboard/CRM/Monitoring/ProfileMenu  |  HIDDEN Admin
--                 VIEWER       = VIEW   Dashboard/CRM/Monitoring  |  EXECUTE ProfileMenu  |  HIDDEN Admin
-- =============================================================================
DO $$
DECLARE
    v_tid_system UUID := '00000000-0000-0000-0000-000000000001';
    v_tid_demo   UUID := '00000000-0000-0000-0000-000000000002';
    v_uid_super  UUID := '00000000-0000-0000-0001-000000000001';
    v_uid_admin  UUID := '00000000-0000-0000-0001-000000000002';

    -- Roles
    v_role_super_admin  UUID;
    v_role_tenant_admin UUID;
    v_role_editor       UUID;
    v_role_viewer       UUID;

    -- Componentes tenant system
    v_sys_comp_tenants      UUID;
    v_sys_comp_profile_menu UUID;

    -- Componentes tenant demo
    v_demo_comp_dashboard    UUID;
    v_demo_comp_crm          UUID;
    v_demo_comp_monitoring   UUID;
    v_demo_comp_profile_menu UUID;
    v_demo_comp_admin        UUID;

    -- Elementos tenant system (profile-menu)
    v_sys_el_profile  UUID;
    v_sys_el_settings UUID;
    v_sys_el_logout   UUID;

    -- Elementos tenant demo (profile-menu)
    v_demo_el_profile  UUID;
    v_demo_el_settings UUID;
    v_demo_el_logout   UUID;

    -- Elementos tenant demo (admin-panel)
    v_demo_el_user     UUID;
    v_demo_el_permisos UUID;

    -- Grupos de menú
    v_sys_menu_profile_group  UUID;
    v_demo_menu_admin_group   UUID;
    v_demo_menu_profile_group UUID;

BEGIN
    RAISE NOTICE '=== BLOQUE 5: Componentes, Elementos, Menús y Permisos ===';

    SELECT id INTO v_role_super_admin  FROM nxc_tenant.roles WHERE tenant_id = v_tid_system AND name = 'SUPER_ADMIN';
    SELECT id INTO v_role_tenant_admin FROM nxc_tenant.roles WHERE tenant_id = v_tid_demo   AND name = 'TENANT_ADMIN';
    SELECT id INTO v_role_editor       FROM nxc_tenant.roles WHERE tenant_id = v_tid_demo   AND name = 'EDITOR';
    SELECT id INTO v_role_viewer       FROM nxc_tenant.roles WHERE tenant_id = v_tid_demo   AND name = 'VIEWER';

    -- =========================================================================
    -- LIMPIEZA: eliminar todo lo existente para ambos tenants
    -- =========================================================================
    RAISE NOTICE 'Limpiando datos previos...';

    -- tenant system
    DELETE FROM nxc_menu.user_element_overrides WHERE tenant_id = v_tid_system;
    DELETE FROM nxc_menu.element_permissions     WHERE tenant_id = v_tid_system;
    DELETE FROM nxc_menu.component_permissions   WHERE tenant_id = v_tid_system;
    DELETE FROM nxc_menu.menu_items WHERE tenant_id = v_tid_system AND parent_id IS NOT NULL;
    DELETE FROM nxc_menu.menu_items WHERE tenant_id = v_tid_system;
    DELETE FROM nxc_menu.component_elements      WHERE tenant_id = v_tid_system;
    DELETE FROM nxc_menu.components              WHERE tenant_id = v_tid_system;

    -- tenant demo
    DELETE FROM nxc_menu.user_element_overrides WHERE tenant_id = v_tid_demo;
    DELETE FROM nxc_menu.element_permissions     WHERE tenant_id = v_tid_demo;
    DELETE FROM nxc_menu.component_permissions   WHERE tenant_id = v_tid_demo;
    DELETE FROM nxc_menu.menu_items WHERE tenant_id = v_tid_demo AND parent_id IS NOT NULL;
    DELETE FROM nxc_menu.menu_items WHERE tenant_id = v_tid_demo;
    DELETE FROM nxc_menu.component_elements      WHERE tenant_id = v_tid_demo;
    DELETE FROM nxc_menu.components              WHERE tenant_id = v_tid_demo;

    -- =========================================================================
    -- TENANT SYSTEM — Componentes
    -- =========================================================================
    RAISE NOTICE 'Creando componentes tenant system...';

    INSERT INTO nxc_menu.components (tenant_id, module_key, name, route, description, is_system, created_by, created_at, updated_at, version)
    VALUES (v_tid_system, 'tenant-management', 'Tenant Management', '/tenants', 'Administración de tenants', TRUE, v_uid_super, NOW(), NOW(), 0)
    RETURNING id INTO v_sys_comp_tenants;

    INSERT INTO nxc_menu.components (tenant_id, module_key, name, route, description, is_system, created_by, created_at, updated_at, version)
    VALUES (v_tid_system, 'profile-menu', 'Profile Menu', NULL, 'Menú desplegable del perfil de usuario', TRUE, v_uid_super, NOW(), NOW(), 0)
    RETURNING id INTO v_sys_comp_profile_menu;

    -- =========================================================================
    -- TENANT SYSTEM — Elementos (profile-menu)
    -- =========================================================================
    INSERT INTO nxc_menu.component_elements (tenant_id, component_id, element_key, label, element_type, created_at, updated_at, version)
    VALUES
        (v_tid_system, v_sys_comp_profile_menu, 'profile',  'Mi Perfil',     'ITEM', NOW(), NOW(), 0),
        (v_tid_system, v_sys_comp_profile_menu, 'settings', 'Configuración', 'ITEM', NOW(), NOW(), 0),
        (v_tid_system, v_sys_comp_profile_menu, 'logout',   'Cerrar Sesión', 'ITEM', NOW(), NOW(), 0);

    SELECT id INTO v_sys_el_profile  FROM nxc_menu.component_elements WHERE component_id = v_sys_comp_profile_menu AND element_key = 'profile';
    SELECT id INTO v_sys_el_settings FROM nxc_menu.component_elements WHERE component_id = v_sys_comp_profile_menu AND element_key = 'settings';
    SELECT id INTO v_sys_el_logout   FROM nxc_menu.component_elements WHERE component_id = v_sys_comp_profile_menu AND element_key = 'logout';

    -- =========================================================================
    -- TENANT SYSTEM — Menu Items
    -- =========================================================================
    RAISE NOTICE 'Creando menu items tenant system...';

    -- sidebar: Tenants (ITEM)
    INSERT INTO nxc_menu.menu_items (
        tenant_id, component_id, parent_id, name, title, route,
        icon, icon_type, location, item_type, order_index,
        is_visible, is_system, default_access, created_by, created_at, updated_at, version
    ) VALUES (
        v_tid_system, v_sys_comp_tenants, NULL, 'Tenants', 'Tenants', '/tenants',
        'building', 'tabler', 'sidebar', 'ITEM', 10,
        TRUE, TRUE, 'EXECUTE'::nxc_menu.access_level, v_uid_super, NOW(), NOW(), 0
    );

    -- profile: ProfileMenu (GROUP)
    INSERT INTO nxc_menu.menu_items (
        tenant_id, component_id, parent_id, name, title, route,
        icon, icon_type, location, item_type, order_index,
        is_visible, is_system, default_access, created_by, created_at, updated_at, version
    ) VALUES (
        v_tid_system, v_sys_comp_profile_menu, NULL, 'ProfileMenu', 'Profile Menu', NULL,
        'user-circle', 'tabler', 'profile', 'GROUP', 10,
        TRUE, TRUE, 'EXECUTE'::nxc_menu.access_level, v_uid_super, NOW(), NOW(), 0
    ) RETURNING id INTO v_sys_menu_profile_group;

    -- profile: Profile, Settings, Logout (hijos de ProfileMenu)
    INSERT INTO nxc_menu.menu_items (
        tenant_id, component_id, parent_id, name, title, route,
        icon, icon_type, location, item_type, order_index,
        is_visible, is_system, default_access, created_by, created_at, updated_at, version
    ) VALUES
        (v_tid_system, v_sys_comp_profile_menu, v_sys_menu_profile_group,
         'Profile',  'Profile',  '/profile',    'user',     'tabler', 'profile', 'ITEM', 10, TRUE, TRUE, 'EXECUTE'::nxc_menu.access_level, v_uid_super, NOW(), NOW(), 0),
        (v_tid_system, v_sys_comp_profile_menu, v_sys_menu_profile_group,
         'Settings', 'Settings', '/settings',   'settings', 'tabler', 'profile', 'ITEM', 20, TRUE, TRUE, 'EXECUTE'::nxc_menu.access_level, v_uid_super, NOW(), NOW(), 0),
        (v_tid_system, v_sys_comp_profile_menu, v_sys_menu_profile_group,
         'Logout',   'Logout',   '/auth/login', 'logout',   'tabler', 'profile', 'ITEM', 30, TRUE, TRUE, 'EXECUTE'::nxc_menu.access_level, v_uid_super, NOW(), NOW(), 0);

    -- =========================================================================
    -- TENANT SYSTEM — Permisos (SUPER_ADMIN: EXECUTE en todo)
    -- =========================================================================
    INSERT INTO nxc_menu.component_permissions (tenant_id, role_id, component_id, access, created_by, created_at, updated_at)
    VALUES
        (v_tid_system, v_role_super_admin, v_sys_comp_tenants,      'EXECUTE'::nxc_menu.access_level, v_uid_super, NOW(), NOW()),
        (v_tid_system, v_role_super_admin, v_sys_comp_profile_menu, 'EXECUTE'::nxc_menu.access_level, v_uid_super, NOW(), NOW());

    INSERT INTO nxc_menu.element_permissions (tenant_id, role_id, element_id, access, created_by, created_at, updated_at)
    VALUES
        (v_tid_system, v_role_super_admin, v_sys_el_profile,  'EXECUTE'::nxc_menu.access_level, v_uid_super, NOW(), NOW()),
        (v_tid_system, v_role_super_admin, v_sys_el_settings, 'EXECUTE'::nxc_menu.access_level, v_uid_super, NOW(), NOW()),
        (v_tid_system, v_role_super_admin, v_sys_el_logout,   'EXECUTE'::nxc_menu.access_level, v_uid_super, NOW(), NOW());

    RAISE NOTICE 'Tenant system OK';

    -- =========================================================================
    -- TENANT DEMO — Componentes
    -- =========================================================================
    RAISE NOTICE 'Creando componentes tenant demo...';

    INSERT INTO nxc_menu.components (tenant_id, module_key, name, route, description, is_system, created_by, created_at, updated_at, version)
    VALUES (v_tid_demo, 'dashboard', 'Dashboard', '/dashboard', 'Dashboard principal', TRUE, v_uid_admin, NOW(), NOW(), 0)
    RETURNING id INTO v_demo_comp_dashboard;

    INSERT INTO nxc_menu.components (tenant_id, module_key, name, route, description, is_system, created_by, created_at, updated_at, version)
    VALUES (v_tid_demo, 'crm', 'CRM', '/crm', 'Gestión de clientes', TRUE, v_uid_admin, NOW(), NOW(), 0)
    RETURNING id INTO v_demo_comp_crm;

    INSERT INTO nxc_menu.components (tenant_id, module_key, name, route, description, is_system, created_by, created_at, updated_at, version)
    VALUES (v_tid_demo, 'monitoring', 'Monitoring', '/monitoring', 'Monitoreo del sistema', TRUE, v_uid_admin, NOW(), NOW(), 0)
    RETURNING id INTO v_demo_comp_monitoring;

    INSERT INTO nxc_menu.components (tenant_id, module_key, name, route, description, is_system, created_by, created_at, updated_at, version)
    VALUES (v_tid_demo, 'profile-menu', 'Profile Menu', NULL, 'Menú desplegable del perfil de usuario', TRUE, v_uid_admin, NOW(), NOW(), 0)
    RETURNING id INTO v_demo_comp_profile_menu;

    INSERT INTO nxc_menu.components (tenant_id, module_key, name, route, description, is_system, created_by, created_at, updated_at, version)
    VALUES (v_tid_demo, 'admin-panel', 'Administración', NULL, 'Panel de administración del tenant', TRUE, v_uid_admin, NOW(), NOW(), 0)
    RETURNING id INTO v_demo_comp_admin;

    -- =========================================================================
    -- TENANT DEMO — Elementos
    -- =========================================================================

    -- profile-menu: Profile, Settings, Logout
    INSERT INTO nxc_menu.component_elements (tenant_id, component_id, element_key, label, element_type, created_at, updated_at, version)
    VALUES
        (v_tid_demo, v_demo_comp_profile_menu, 'profile',  'Mi Perfil',     'ITEM', NOW(), NOW(), 0),
        (v_tid_demo, v_demo_comp_profile_menu, 'settings', 'Configuración', 'ITEM', NOW(), NOW(), 0),
        (v_tid_demo, v_demo_comp_profile_menu, 'logout',   'Cerrar Sesión', 'ITEM', NOW(), NOW(), 0);

    SELECT id INTO v_demo_el_profile  FROM nxc_menu.component_elements WHERE component_id = v_demo_comp_profile_menu AND element_key = 'profile';
    SELECT id INTO v_demo_el_settings FROM nxc_menu.component_elements WHERE component_id = v_demo_comp_profile_menu AND element_key = 'settings';
    SELECT id INTO v_demo_el_logout   FROM nxc_menu.component_elements WHERE component_id = v_demo_comp_profile_menu AND element_key = 'logout';

    -- admin-panel: User, Permisos
    INSERT INTO nxc_menu.component_elements (tenant_id, component_id, element_key, label, element_type, created_at, updated_at, version)
    VALUES
        (v_tid_demo, v_demo_comp_admin, 'user',        'Usuarios', 'ITEM', NOW(), NOW(), 0),
        (v_tid_demo, v_demo_comp_admin, 'permissions', 'Permisos', 'ITEM', NOW(), NOW(), 0);

    SELECT id INTO v_demo_el_user     FROM nxc_menu.component_elements WHERE component_id = v_demo_comp_admin AND element_key = 'user';
    SELECT id INTO v_demo_el_permisos FROM nxc_menu.component_elements WHERE component_id = v_demo_comp_admin AND element_key = 'permissions';

    -- =========================================================================
    -- TENANT DEMO — Menu Items
    -- =========================================================================
    RAISE NOTICE 'Creando menu items tenant demo...';

    -- sidebar: Dashboard (ITEM, order 10)
    INSERT INTO nxc_menu.menu_items (
        tenant_id, component_id, parent_id, name, title, route,
        icon, icon_type, location, item_type, order_index,
        is_visible, is_system, default_access, created_by, created_at, updated_at, version
    ) VALUES (
        v_tid_demo, v_demo_comp_dashboard, NULL, 'Dashboard', 'Dashboard', '/dashboard',
        'dashboard', 'tabler', 'sidebar', 'ITEM', 10,
        TRUE, TRUE, 'EXECUTE'::nxc_menu.access_level, v_uid_admin, NOW(), NOW(), 0
    );

    -- sidebar: Admin (GROUP, order 20)
    INSERT INTO nxc_menu.menu_items (
        tenant_id, component_id, parent_id, name, title, route,
        icon, icon_type, location, item_type, order_index,
        is_visible, is_system, default_access, created_by, created_at, updated_at, version
    ) VALUES (
        v_tid_demo, v_demo_comp_admin, NULL, 'Admin', 'Administración', NULL,
        'shield', 'tabler', 'sidebar', 'GROUP', 20,
        TRUE, TRUE, 'HIDDEN'::nxc_menu.access_level, v_uid_admin, NOW(), NOW(), 0
    ) RETURNING id INTO v_demo_menu_admin_group;

    -- sidebar: User, Permisos (hijos de Admin)
    INSERT INTO nxc_menu.menu_items (
        tenant_id, component_id, parent_id, name, title, route,
        icon, icon_type, location, item_type, order_index,
        is_visible, is_system, default_access, created_by, created_at, updated_at, version
    ) VALUES
        (v_tid_demo, v_demo_comp_admin, v_demo_menu_admin_group,
         'User',     'Usuarios', '/users',       'users', 'tabler', 'sidebar', 'ITEM', 10, TRUE, TRUE, 'HIDDEN'::nxc_menu.access_level, v_uid_admin, NOW(), NOW(), 0),
        (v_tid_demo, v_demo_comp_admin, v_demo_menu_admin_group,
         'Permisos', 'Permisos', '/permissions', 'lock',  'tabler', 'sidebar', 'ITEM', 20, TRUE, TRUE, 'HIDDEN'::nxc_menu.access_level, v_uid_admin, NOW(), NOW(), 0);

    -- sidebar: CRM (ITEM, order 30)
    INSERT INTO nxc_menu.menu_items (
        tenant_id, component_id, parent_id, name, title, route,
        icon, icon_type, location, item_type, order_index,
        is_visible, is_system, default_access, created_by, created_at, updated_at, version
    ) VALUES (
        v_tid_demo, v_demo_comp_crm, NULL, 'CRM', 'CRM', '/crm',
        'users', 'tabler', 'sidebar', 'ITEM', 30,
        TRUE, TRUE, 'EXECUTE'::nxc_menu.access_level, v_uid_admin, NOW(), NOW(), 0
    );

    -- sidebar: Monitoring (ITEM, order 40)
    INSERT INTO nxc_menu.menu_items (
        tenant_id, component_id, parent_id, name, title, route,
        icon, icon_type, location, item_type, order_index,
        is_visible, is_system, default_access, created_by, created_at, updated_at, version
    ) VALUES (
        v_tid_demo, v_demo_comp_monitoring, NULL, 'Monitoring', 'Monitoring', '/monitoring',
        'bell', 'tabler', 'sidebar', 'ITEM', 40,
        TRUE, TRUE, 'EXECUTE'::nxc_menu.access_level, v_uid_admin, NOW(), NOW(), 0
    );

    -- profile: ProfileMenu (GROUP)
    INSERT INTO nxc_menu.menu_items (
        tenant_id, component_id, parent_id, name, title, route,
        icon, icon_type, location, item_type, order_index,
        is_visible, is_system, default_access, created_by, created_at, updated_at, version
    ) VALUES (
        v_tid_demo, v_demo_comp_profile_menu, NULL, 'ProfileMenu', 'Profile Menu', NULL,
        'user-circle', 'tabler', 'profile', 'GROUP', 10,
        TRUE, TRUE, 'EXECUTE'::nxc_menu.access_level, v_uid_admin, NOW(), NOW(), 0
    ) RETURNING id INTO v_demo_menu_profile_group;

    -- profile: Profile, Settings, Logout (hijos de ProfileMenu)
    INSERT INTO nxc_menu.menu_items (
        tenant_id, component_id, parent_id, name, title, route,
        icon, icon_type, location, item_type, order_index,
        is_visible, is_system, default_access, created_by, created_at, updated_at, version
    ) VALUES
        (v_tid_demo, v_demo_comp_profile_menu, v_demo_menu_profile_group,
         'Profile',  'Profile',  '/profile',    'user',     'tabler', 'profile', 'ITEM', 10, TRUE, TRUE, 'EXECUTE'::nxc_menu.access_level, v_uid_admin, NOW(), NOW(), 0),
        (v_tid_demo, v_demo_comp_profile_menu, v_demo_menu_profile_group,
         'Settings', 'Settings', '/settings',   'settings', 'tabler', 'profile', 'ITEM', 20, TRUE, TRUE, 'EXECUTE'::nxc_menu.access_level, v_uid_admin, NOW(), NOW(), 0),
        (v_tid_demo, v_demo_comp_profile_menu, v_demo_menu_profile_group,
         'Logout',   'Logout',   '/auth/login', 'logout',   'tabler', 'profile', 'ITEM', 30, TRUE, TRUE, 'EXECUTE'::nxc_menu.access_level, v_uid_admin, NOW(), NOW(), 0);

    -- =========================================================================
    -- TENANT DEMO — Permisos de componentes
    -- =========================================================================
    RAISE NOTICE 'Creando permisos tenant demo...';

    -- TENANT_ADMIN: EXECUTE en todo
    INSERT INTO nxc_menu.component_permissions (tenant_id, role_id, component_id, access, created_by, created_at, updated_at)
    VALUES
        (v_tid_demo, v_role_tenant_admin, v_demo_comp_dashboard,    'EXECUTE'::nxc_menu.access_level, v_uid_admin, NOW(), NOW()),
        (v_tid_demo, v_role_tenant_admin, v_demo_comp_crm,          'EXECUTE'::nxc_menu.access_level, v_uid_admin, NOW(), NOW()),
        (v_tid_demo, v_role_tenant_admin, v_demo_comp_monitoring,   'EXECUTE'::nxc_menu.access_level, v_uid_admin, NOW(), NOW()),
        (v_tid_demo, v_role_tenant_admin, v_demo_comp_profile_menu, 'EXECUTE'::nxc_menu.access_level, v_uid_admin, NOW(), NOW()),
        (v_tid_demo, v_role_tenant_admin, v_demo_comp_admin,        'EXECUTE'::nxc_menu.access_level, v_uid_admin, NOW(), NOW());

    -- EDITOR: EXECUTE en Dashboard/CRM/Monitoring/ProfileMenu; HIDDEN en Admin
    INSERT INTO nxc_menu.component_permissions (tenant_id, role_id, component_id, access, created_by, created_at, updated_at)
    VALUES
        (v_tid_demo, v_role_editor, v_demo_comp_dashboard,    'EXECUTE'::nxc_menu.access_level, v_uid_admin, NOW(), NOW()),
        (v_tid_demo, v_role_editor, v_demo_comp_crm,          'EXECUTE'::nxc_menu.access_level, v_uid_admin, NOW(), NOW()),
        (v_tid_demo, v_role_editor, v_demo_comp_monitoring,   'EXECUTE'::nxc_menu.access_level, v_uid_admin, NOW(), NOW()),
        (v_tid_demo, v_role_editor, v_demo_comp_profile_menu, 'EXECUTE'::nxc_menu.access_level, v_uid_admin, NOW(), NOW()),
        (v_tid_demo, v_role_editor, v_demo_comp_admin,        'HIDDEN'::nxc_menu.access_level,  v_uid_admin, NOW(), NOW());

    -- VIEWER: VIEW en Dashboard/CRM/Monitoring; EXECUTE en ProfileMenu; HIDDEN en Admin
    INSERT INTO nxc_menu.component_permissions (tenant_id, role_id, component_id, access, created_by, created_at, updated_at)
    VALUES
        (v_tid_demo, v_role_viewer, v_demo_comp_dashboard,    'VIEW'::nxc_menu.access_level,    v_uid_admin, NOW(), NOW()),
        (v_tid_demo, v_role_viewer, v_demo_comp_crm,          'VIEW'::nxc_menu.access_level,    v_uid_admin, NOW(), NOW()),
        (v_tid_demo, v_role_viewer, v_demo_comp_monitoring,   'VIEW'::nxc_menu.access_level,    v_uid_admin, NOW(), NOW()),
        (v_tid_demo, v_role_viewer, v_demo_comp_profile_menu, 'EXECUTE'::nxc_menu.access_level, v_uid_admin, NOW(), NOW()),
        (v_tid_demo, v_role_viewer, v_demo_comp_admin,        'HIDDEN'::nxc_menu.access_level,  v_uid_admin, NOW(), NOW());

    -- =========================================================================
    -- TENANT DEMO — Permisos de elementos
    -- =========================================================================

    -- TENANT_ADMIN: EXECUTE en todos los elementos
    INSERT INTO nxc_menu.element_permissions (tenant_id, role_id, element_id, access, created_by, created_at, updated_at)
    VALUES
        (v_tid_demo, v_role_tenant_admin, v_demo_el_profile,  'EXECUTE'::nxc_menu.access_level, v_uid_admin, NOW(), NOW()),
        (v_tid_demo, v_role_tenant_admin, v_demo_el_settings, 'EXECUTE'::nxc_menu.access_level, v_uid_admin, NOW(), NOW()),
        (v_tid_demo, v_role_tenant_admin, v_demo_el_logout,   'EXECUTE'::nxc_menu.access_level, v_uid_admin, NOW(), NOW()),
        (v_tid_demo, v_role_tenant_admin, v_demo_el_user,     'EXECUTE'::nxc_menu.access_level, v_uid_admin, NOW(), NOW()),
        (v_tid_demo, v_role_tenant_admin, v_demo_el_permisos, 'EXECUTE'::nxc_menu.access_level, v_uid_admin, NOW(), NOW());

    -- EDITOR: EXECUTE en profile/logout; HIDDEN en settings y admin elements
    INSERT INTO nxc_menu.element_permissions (tenant_id, role_id, element_id, access, created_by, created_at, updated_at)
    VALUES
        (v_tid_demo, v_role_editor, v_demo_el_profile,  'EXECUTE'::nxc_menu.access_level, v_uid_admin, NOW(), NOW()),
        (v_tid_demo, v_role_editor, v_demo_el_settings, 'HIDDEN'::nxc_menu.access_level,  v_uid_admin, NOW(), NOW()),
        (v_tid_demo, v_role_editor, v_demo_el_logout,   'EXECUTE'::nxc_menu.access_level, v_uid_admin, NOW(), NOW()),
        (v_tid_demo, v_role_editor, v_demo_el_user,     'HIDDEN'::nxc_menu.access_level,  v_uid_admin, NOW(), NOW()),
        (v_tid_demo, v_role_editor, v_demo_el_permisos, 'HIDDEN'::nxc_menu.access_level,  v_uid_admin, NOW(), NOW());

    -- VIEWER: EXECUTE en profile elements; HIDDEN en admin elements
    INSERT INTO nxc_menu.element_permissions (tenant_id, role_id, element_id, access, created_by, created_at, updated_at)
    VALUES
        (v_tid_demo, v_role_viewer, v_demo_el_profile,  'EXECUTE'::nxc_menu.access_level, v_uid_admin, NOW(), NOW()),
        (v_tid_demo, v_role_viewer, v_demo_el_settings, 'EXECUTE'::nxc_menu.access_level, v_uid_admin, NOW(), NOW()),
        (v_tid_demo, v_role_viewer, v_demo_el_logout,   'EXECUTE'::nxc_menu.access_level, v_uid_admin, NOW(), NOW()),
        (v_tid_demo, v_role_viewer, v_demo_el_user,     'HIDDEN'::nxc_menu.access_level,  v_uid_admin, NOW(), NOW()),
        (v_tid_demo, v_role_viewer, v_demo_el_permisos, 'HIDDEN'::nxc_menu.access_level,  v_uid_admin, NOW(), NOW());

    RAISE NOTICE 'Tenant demo OK';
    RAISE NOTICE '=== SEED COMPLETADO — NexCore v2.0 ===';
END $$;

-- =============================================================================
-- Verificación post-seed
-- =============================================================================

-- Tenants
-- SELECT id, slug, name, plan, mode, status FROM nxc_tenant.tenants ORDER BY created_at;

-- Roles por tenant
-- SELECT t.slug, r.name, r.is_system_role FROM nxc_tenant.roles r
-- JOIN nxc_tenant.tenants t ON t.id = r.tenant_id ORDER BY t.slug, r.name;

-- Usuarios y sus roles
-- SELECT t.slug, u.username, u.email, u.status, array_agg(r.name) AS roles
-- FROM nxc_tenant.users u
-- JOIN nxc_tenant.tenants t ON t.id = u.tenant_id
-- LEFT JOIN nxc_tenant.user_roles ur ON ur.user_id = u.id AND ur.tenant_id = u.tenant_id
-- LEFT JOIN nxc_tenant.roles r ON r.id = ur.role_id
-- GROUP BY t.slug, u.username, u.email, u.status ORDER BY t.slug, u.username;

-- Componentes por tenant
-- SELECT t.slug, c.module_key, c.name, c.route,
--        (SELECT COUNT(*) FROM nxc_menu.component_elements ce WHERE ce.component_id = c.id) AS elements
-- FROM nxc_menu.components c JOIN nxc_tenant.tenants t ON t.id = c.tenant_id
-- ORDER BY t.slug, c.module_key;

-- Árbol de menú
-- SELECT t.slug,
--     CASE WHEN mi.parent_id IS NULL THEN mi.name ELSE '  └─ ' || mi.name END AS menu,
--     mi.location, mi.route, mi.item_type, mi.order_index
-- FROM nxc_menu.menu_items mi
-- JOIN nxc_tenant.tenants t ON t.id = mi.tenant_id
-- WHERE mi.deleted_at IS NULL
-- ORDER BY t.slug, mi.location, COALESCE(mi.parent_id::text, mi.id::text), mi.order_index;

-- Permisos por tenant y rol
-- SELECT t.slug, r.name AS role, c.module_key, cp.access
-- FROM nxc_menu.component_permissions cp
-- JOIN nxc_tenant.tenants t ON t.id = cp.tenant_id
-- JOIN nxc_tenant.roles r ON r.id = cp.role_id
-- JOIN nxc_menu.components c ON c.id = cp.component_id
-- ORDER BY t.slug, r.name, c.module_key;

-- =============================================================================
-- BLOQUE 6 — POLÍTICAS DE ACCESO A LA API (role_api_policies)
--
-- Carga las políticas para todos los endpoints actuales de:
--   nexcore-core (service='core', puerto 8080)
--   nexcore-auth-service (service='auth', puerto 8081)
--
-- CONVENCIÓN DE PRIORIDADES:
--   100 → ALLOW general (rol puede acceder)
--   500 → DENY específico (bloqueo explícito que anula ALLOW de nivel 100)
--
-- CONVENCIÓN DE PATRONES DE PATH:
--   /api/*/recurso         → cubre /api/v1/recurso, /api/v2/recurso, etc.
--   /api/*/recurso/*       → un segmento variable (/{id})
--   /api/*/recurso/**      → cualquier subruta (/{id}/accion, etc.)
--   /api/**                → cualquier path bajo /api/ (para DENY globales)
-- =============================================================================
DO $$
DECLARE
    v_super_admin    UUID := '00000000-0000-0000-0001-000000000001'; -- super.admin
BEGIN
    RAISE NOTICE '=== BLOQUE 6: role_api_policies ===';

    -- Limpiar políticas existentes para recarga idempotente
    DELETE FROM nxc_tenant.role_api_policies;

-- -------------------------------------------------------------------------
-- SECCIÓN 1: NEXCORE-AUTH-SERVICE (puerto 8081)
-- Endpoints que requieren JWT válido (los públicos son excluidos por el interceptor).
-- -------------------------------------------------------------------------
    INSERT INTO nxc_tenant.role_api_policies
        (role_name, http_method, path_pattern, effect, service, module, priority, description, created_by)
    VALUES
    ('*', 'POST',   '/auth/refresh',   'ALLOW', 'auth', 'auth', 100,
     'Refrescar access token con refresh token válido. Aplica a cualquier usuario autenticado.',
     v_super_admin),
    ('*', 'DELETE', '/auth/logout',    'ALLOW', 'auth', 'auth', 100,
     'Cerrar la sesión actual del usuario autenticado.',
     v_super_admin),
    ('*', 'DELETE', '/auth/logout-all','ALLOW', 'auth', 'auth', 100,
     'Cerrar todas las sesiones activas del usuario autenticado.',
     v_super_admin),
    ('*', 'PUT',    '/auth/password',  'ALLOW', 'auth', 'auth', 100,
     'Cambiar contraseña. El usuario debe estar autenticado y proporcionar la contraseña actual.',
     v_super_admin);

-- -------------------------------------------------------------------------
-- SECCIÓN 2: NEXCORE-CORE — Endpoint público sin auth
-- -------------------------------------------------------------------------
    INSERT INTO nxc_tenant.role_api_policies
        (role_name, http_method, path_pattern, effect, service, module, priority, description, created_by)
    VALUES
    ('*', 'POST', '/api/*/users/invitations/accept', 'ALLOW', 'core', 'users', 100,
     'Aceptar invitación. Endpoint público: el invitado no tiene JWT aún, usa token del email.',
     v_super_admin);

-- -------------------------------------------------------------------------
-- SECCIÓN 3: PERFIL DE USUARIO — GET /api/*/me/profile
-- -------------------------------------------------------------------------
    INSERT INTO nxc_tenant.role_api_policies
        (role_name, http_method, path_pattern, effect, service, module, priority, description, created_by)
    VALUES
    ('*', 'GET', '/api/*/me/profile', 'ALLOW', 'core', 'profile', 100,
     'Obtener perfil completo del usuario autenticado (menus, permisos por componente).',
     v_super_admin);

-- -------------------------------------------------------------------------
-- SECCIÓN 4: TENANTS — /api/*/tenants
-- -------------------------------------------------------------------------
    INSERT INTO nxc_tenant.role_api_policies
        (role_name, http_method, path_pattern, effect, service, module, priority, description, created_by)
    VALUES
    ('SUPER_ADMIN',  'GET',   '/api/*/tenants',          'ALLOW', 'core', 'tenants', 100,
     'Listar todos los tenants de la plataforma. Operación exclusiva de SUPER_ADMIN.',          v_super_admin),
    ('SUPER_ADMIN',  'POST',  '/api/*/tenants',          'ALLOW', 'core', 'tenants', 100,
     'Crear un nuevo tenant en la plataforma. Operación exclusiva de SUPER_ADMIN.',             v_super_admin),
    ('SUPER_ADMIN',  'GET',   '/api/*/tenants/*',        'ALLOW', 'core', 'tenants', 100,
     'Ver detalle de cualquier tenant. SUPER_ADMIN tiene acceso total.',                        v_super_admin),
    ('TENANT_ADMIN', 'GET',   '/api/*/tenants/*',        'ALLOW', 'core', 'tenants', 100,
     'Ver detalle del propio tenant. La capa de negocio valida que solo sea el suyo.',          v_super_admin),
    ('SUPER_ADMIN',  'PATCH', '/api/*/tenants/*',        'ALLOW', 'core', 'tenants', 100,
     'Editar cualquier tenant, incluyendo cambio de plan/modo. Solo SUPER_ADMIN.',              v_super_admin),
    ('TENANT_ADMIN', 'PATCH', '/api/*/tenants/*',        'ALLOW', 'core', 'tenants', 100,
     'Editar el propio tenant. Sin acceso a cambiar plan/modo (validado en negocio).',          v_super_admin),
    ('SUPER_ADMIN',  'POST',  '/api/*/tenants/*/suspend','ALLOW', 'core', 'tenants', 100,
     'Suspender un tenant. Operación exclusiva de SUPER_ADMIN.',                                v_super_admin),
    ('SUPER_ADMIN',  'POST',  '/api/*/tenants/*/activate','ALLOW','core', 'tenants', 100,
     'Reactivar un tenant suspendido. Operación exclusiva de SUPER_ADMIN.',                     v_super_admin);

-- -------------------------------------------------------------------------
-- SECCIÓN 5: USUARIOS — /api/*/users
-- -------------------------------------------------------------------------
    INSERT INTO nxc_tenant.role_api_policies
        (role_name, http_method, path_pattern, effect, service, module, priority, description, created_by)
    VALUES
    ('*',           'GET',    '/api/*/users/me',                  'ALLOW', 'core', 'users', 100,
     'Ver los datos propios del usuario autenticado (UserResponse básico).',                    v_super_admin),
    ('SUPER_ADMIN',  'GET',   '/api/*/users',                     'ALLOW', 'core', 'users', 100,
     'Listar usuarios de cualquier tenant (según X-Tenant-Id).',                               v_super_admin),
    ('TENANT_ADMIN', 'GET',   '/api/*/users',                     'ALLOW', 'core', 'users', 100,
     'Listar usuarios del propio tenant con filtros y paginación.',                            v_super_admin),
    ('SUPER_ADMIN',  'POST',  '/api/*/users',                     'ALLOW', 'core', 'users', 100,
     'Crear usuario directamente en cualquier tenant. Uso de SUPER_ADMIN.',                    v_super_admin),
    ('TENANT_ADMIN', 'POST',  '/api/*/users',                     'ALLOW', 'core', 'users', 100,
     'Crear usuario directamente en el propio tenant.',                                        v_super_admin),
    ('SUPER_ADMIN',  'GET',   '/api/*/users/*',                   'ALLOW', 'core', 'users', 100,
     'Ver detalle de cualquier usuario en cualquier tenant.',                                  v_super_admin),
    ('TENANT_ADMIN', 'GET',   '/api/*/users/*',                   'ALLOW', 'core', 'users', 100,
     'Ver detalle de usuarios del propio tenant.',                                             v_super_admin),
    ('EDITOR',       'GET',   '/api/*/users/*',                   'ALLOW', 'core', 'users', 100,
     'Ver detalle de usuarios del propio tenant. Solo lectura.',                               v_super_admin),
    ('SUPER_ADMIN',  'PATCH', '/api/*/users/*',                   'ALLOW', 'core', 'users', 100,
     'Editar cualquier usuario en cualquier tenant.',                                          v_super_admin),
    ('TENANT_ADMIN', 'PATCH', '/api/*/users/*',                   'ALLOW', 'core', 'users', 100,
     'Editar usuarios del propio tenant.',                                                     v_super_admin),
    ('EDITOR',       'PATCH', '/api/*/users/*',                   'ALLOW', 'core', 'users', 100,
     'Editar solo el propio perfil. La capa de negocio valida que id = actor.',                v_super_admin),
    ('SUPER_ADMIN',  'POST',  '/api/*/users/*/suspend',           'ALLOW', 'core', 'users', 100,
     'Suspender cualquier usuario en cualquier tenant.',                                       v_super_admin),
    ('TENANT_ADMIN', 'POST',  '/api/*/users/*/suspend',           'ALLOW', 'core', 'users', 100,
     'Suspender usuarios del propio tenant.',                                                  v_super_admin),
    ('SUPER_ADMIN',  'POST',  '/api/*/users/*/activate',          'ALLOW', 'core', 'users', 100,
     'Reactivar cualquier usuario en cualquier tenant.',                                       v_super_admin),
    ('TENANT_ADMIN', 'POST',  '/api/*/users/*/activate',          'ALLOW', 'core', 'users', 100,
     'Reactivar usuarios del propio tenant.',                                                  v_super_admin),
    ('SUPER_ADMIN',  'DELETE','/api/*/users/*',                   'ALLOW', 'core', 'users', 100,
     'Eliminar (soft-delete) cualquier usuario en cualquier tenant.',                          v_super_admin),
    ('TENANT_ADMIN', 'DELETE','/api/*/users/*',                   'ALLOW', 'core', 'users', 100,
     'Eliminar (soft-delete) usuarios del propio tenant.',                                     v_super_admin),
    ('SUPER_ADMIN',  'PUT',   '/api/*/users/*/roles',             'ALLOW', 'core', 'users', 100,
     'Reasignar roles de cualquier usuario en cualquier tenant.',                              v_super_admin),
    ('TENANT_ADMIN', 'PUT',   '/api/*/users/*/roles',             'ALLOW', 'core', 'users', 100,
     'Reasignar roles de usuarios del propio tenant.',                                        v_super_admin),
    ('SUPER_ADMIN',  'POST',  '/api/*/users/invite',              'ALLOW', 'core', 'users', 100,
     'Enviar invitación de usuario en cualquier tenant.',                                      v_super_admin),
    ('TENANT_ADMIN', 'POST',  '/api/*/users/invite',              'ALLOW', 'core', 'users', 100,
     'Enviar invitación de usuario en el propio tenant.',                                      v_super_admin),
    ('SUPER_ADMIN',  'GET',   '/api/*/users/invitations',         'ALLOW', 'core', 'users', 100,
     'Listar invitaciones de cualquier tenant.',                                               v_super_admin),
    ('TENANT_ADMIN', 'GET',   '/api/*/users/invitations',         'ALLOW', 'core', 'users', 100,
     'Listar invitaciones del propio tenant.',                                                 v_super_admin),
    ('SUPER_ADMIN',  'POST',  '/api/*/users/invitations/*/revoke','ALLOW', 'core', 'users', 100,
     'Revocar invitación en cualquier tenant.',                                                v_super_admin),
    ('TENANT_ADMIN', 'POST',  '/api/*/users/invitations/*/revoke','ALLOW', 'core', 'users', 100,
     'Revocar invitación en el propio tenant.',                                                v_super_admin),
    ('SUPER_ADMIN',  'POST',  '/api/*/users/invitations/*/resend','ALLOW', 'core', 'users', 100,
     'Reenviar invitación en cualquier tenant.',                                               v_super_admin),
    ('TENANT_ADMIN', 'POST',  '/api/*/users/invitations/*/resend','ALLOW', 'core', 'users', 100,
     'Reenviar invitación en el propio tenant.',                                               v_super_admin);

-- -------------------------------------------------------------------------
-- SECCIÓN 6: ROLES — /api/*/roles
-- -------------------------------------------------------------------------
    INSERT INTO nxc_tenant.role_api_policies
        (role_name, http_method, path_pattern, effect, service, module, priority, description, created_by)
    VALUES
    ('SUPER_ADMIN',  'GET',    '/api/*/roles',  'ALLOW', 'core', 'roles', 100,
     'Listar roles de cualquier tenant.',                                  v_super_admin),
    ('TENANT_ADMIN', 'GET',    '/api/*/roles',  'ALLOW', 'core', 'roles', 100,
     'Listar roles del propio tenant.',                                    v_super_admin),
    ('EDITOR',       'GET',    '/api/*/roles',  'ALLOW', 'core', 'roles', 100,
     'Leer lista de roles del tenant (solo lectura).',                     v_super_admin),
    ('VIEWER',       'GET',    '/api/*/roles',  'ALLOW', 'core', 'roles', 100,
     'Leer lista de roles del tenant (solo lectura).',                     v_super_admin),
    ('SUPER_ADMIN',  'POST',   '/api/*/roles',  'ALLOW', 'core', 'roles', 100,
     'Crear rol personalizado en cualquier tenant.',                       v_super_admin),
    ('TENANT_ADMIN', 'POST',   '/api/*/roles',  'ALLOW', 'core', 'roles', 100,
     'Crear rol personalizado en el propio tenant.',                       v_super_admin),
    ('SUPER_ADMIN',  'GET',    '/api/*/roles/*','ALLOW', 'core', 'roles', 100,
     'Ver detalle de cualquier rol en cualquier tenant.',                  v_super_admin),
    ('TENANT_ADMIN', 'GET',    '/api/*/roles/*','ALLOW', 'core', 'roles', 100,
     'Ver detalle de roles del propio tenant.',                            v_super_admin),
    ('EDITOR',       'GET',    '/api/*/roles/*','ALLOW', 'core', 'roles', 100,
     'Ver detalle de roles del tenant (solo lectura).',                    v_super_admin),
    ('VIEWER',       'GET',    '/api/*/roles/*','ALLOW', 'core', 'roles', 100,
     'Ver detalle de roles del tenant (solo lectura).',                    v_super_admin),
    ('SUPER_ADMIN',  'PATCH',  '/api/*/roles/*','ALLOW', 'core', 'roles', 100,
     'Editar roles personalizados en cualquier tenant.',                   v_super_admin),
    ('TENANT_ADMIN', 'PATCH',  '/api/*/roles/*','ALLOW', 'core', 'roles', 100,
     'Editar roles personalizados del propio tenant.',                     v_super_admin),
    ('SUPER_ADMIN',  'DELETE', '/api/*/roles/*','ALLOW', 'core', 'roles', 100,
     'Eliminar rol personalizado en cualquier tenant.',                    v_super_admin),
    ('TENANT_ADMIN', 'DELETE', '/api/*/roles/*','ALLOW', 'core', 'roles', 100,
     'Eliminar rol personalizado del propio tenant.',                      v_super_admin);

-- -------------------------------------------------------------------------
-- SECCIÓN 7: COMPONENTES UI — /api/*/menu/components
-- -------------------------------------------------------------------------
    INSERT INTO nxc_tenant.role_api_policies
        (role_name, http_method, path_pattern, effect, service, module, priority, description, created_by)
    VALUES
    ('SUPER_ADMIN',  'GET', '/api/*/menu/components',          'ALLOW', 'core', 'components', 100,
     'Listar componentes de UI de cualquier tenant.',                      v_super_admin),
    ('TENANT_ADMIN', 'GET', '/api/*/menu/components',          'ALLOW', 'core', 'components', 100,
     'Listar componentes de UI del propio tenant.',                        v_super_admin),
    ('SUPER_ADMIN',  'GET', '/api/*/menu/components/*',        'ALLOW', 'core', 'components', 100,
     'Ver detalle de cualquier componente de UI.',                         v_super_admin),
    ('TENANT_ADMIN', 'GET', '/api/*/menu/components/*',        'ALLOW', 'core', 'components', 100,
     'Ver detalle de un componente de UI del propio tenant.',              v_super_admin),
    ('SUPER_ADMIN',  'GET', '/api/*/menu/components/*/elements','ALLOW','core', 'components', 100,
     'Listar elementos de UI de cualquier componente.',                    v_super_admin),
    ('TENANT_ADMIN', 'GET', '/api/*/menu/components/*/elements','ALLOW','core', 'components', 100,
     'Listar elementos de UI de componentes del propio tenant.',           v_super_admin);

-- -------------------------------------------------------------------------
-- SECCIÓN 8: PERMISOS POR ROL — /api/*/menu/permissions
-- -------------------------------------------------------------------------
    INSERT INTO nxc_tenant.role_api_policies
        (role_name, http_method, path_pattern, effect, service, module, priority, description, created_by)
    VALUES
    ('SUPER_ADMIN',  'GET', '/api/*/menu/permissions/roles/*',                   'ALLOW', 'core', 'permissions', 100,
     'Ver matriz de permisos de cualquier rol.',                                               v_super_admin),
    ('TENANT_ADMIN', 'GET', '/api/*/menu/permissions/roles/*',                   'ALLOW', 'core', 'permissions', 100,
     'Ver matriz de permisos de roles del propio tenant.',                                     v_super_admin),
    ('SUPER_ADMIN',  'PUT', '/api/*/menu/permissions/roles/*/components/*',      'ALLOW', 'core', 'permissions', 100,
     'Asignar permiso de cualquier rol sobre cualquier componente.',                           v_super_admin),
    ('TENANT_ADMIN', 'PUT', '/api/*/menu/permissions/roles/*/components/*',      'ALLOW', 'core', 'permissions', 100,
     'Asignar permiso de roles del propio tenant sobre componentes.',                         v_super_admin),
    ('SUPER_ADMIN',  'PUT', '/api/*/menu/permissions/roles/*/components/batch',  'ALLOW', 'core', 'permissions', 100,
     'Asignar permisos en batch sobre múltiples componentes (máx 100).',                      v_super_admin),
    ('TENANT_ADMIN', 'PUT', '/api/*/menu/permissions/roles/*/components/batch',  'ALLOW', 'core', 'permissions', 100,
     'Asignar permisos en batch sobre componentes del propio tenant.',                        v_super_admin),
    ('SUPER_ADMIN',  'PUT', '/api/*/menu/permissions/roles/*/elements/*',        'ALLOW', 'core', 'permissions', 100,
     'Asignar permiso granular de un rol sobre un elemento de UI.',                           v_super_admin),
    ('TENANT_ADMIN', 'PUT', '/api/*/menu/permissions/roles/*/elements/*',        'ALLOW', 'core', 'permissions', 100,
     'Asignar permiso granular de roles del propio tenant sobre elementos.',                  v_super_admin);

-- -------------------------------------------------------------------------
-- SECCIÓN 9: DENY EXPLÍCITOS — bloqueos de alta prioridad
-- -------------------------------------------------------------------------
    INSERT INTO nxc_tenant.role_api_policies
        (role_name, http_method, path_pattern, effect, service, module, priority, description, created_by)
    VALUES
    -- EDITOR: no puede suspender/activar/eliminar usuarios
    ('EDITOR', 'POST',   '/api/*/users/*/suspend',  'DENY', 'core', 'users', 500,
     'DENY explícito: EDITOR no puede suspender usuarios bajo ninguna circunstancia.',  v_super_admin),
    ('EDITOR', 'POST',   '/api/*/users/*/activate', 'DENY', 'core', 'users', 500,
     'DENY explícito: EDITOR no puede reactivar usuarios.',                             v_super_admin),
    ('EDITOR', 'DELETE', '/api/*/users/*',           'DENY', 'core', 'users', 500,
     'DENY explícito: EDITOR no puede eliminar usuarios.',                              v_super_admin),
    -- VIEWER: bloqueo general de escritura (POST/PUT/PATCH/DELETE)
    ('VIEWER', 'POST',   '/api/**', 'DENY', 'core', 'general', 500,
     'DENY general: VIEWER no puede ejecutar ningún POST en nexcore-core.',             v_super_admin),
    ('VIEWER', 'PUT',    '/api/**', 'DENY', 'core', 'general', 500,
     'DENY general: VIEWER no puede ejecutar ningún PUT en nexcore-core.',              v_super_admin),
    ('VIEWER', 'PATCH',  '/api/**', 'DENY', 'core', 'general', 500,
     'DENY general: VIEWER no puede ejecutar ningún PATCH en nexcore-core.',            v_super_admin),
    ('VIEWER', 'DELETE', '/api/**', 'DENY', 'core', 'general', 500,
     'DENY general: VIEWER no puede ejecutar ningún DELETE en nexcore-core.',           v_super_admin);

    RAISE NOTICE 'role_api_policies OK. Registros: %',
        (SELECT COUNT(*) FROM nxc_tenant.role_api_policies);
END $$;

-- =============================================================================
-- FIN — V013__seed_initial_data.sql
-- =============================================================================
