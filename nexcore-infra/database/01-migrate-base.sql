-- =============================================================================
-- migreate-base.sql
-- Script de migración para crear un tenant demo con usuario y roles base
-- =============================================================================

DO $$
DECLARE
    v_tenant_id      UUID := '10000000-0000-0000-0000-000000000001';  -- UUID diferente al tenant 'system'
    v_admin_id       UUID := '10000000-0000-0000-0000-000000000002';
    v_role_admin_id  UUID;
    v_role_editor_id UUID;
    v_role_viewer_id UUID;
BEGIN

    -- 0. Limpiar datos previos del tenant demo
    -- Eliminar registros de login_attempts primero (no tiene ON DELETE CASCADE)
    DELETE FROM nxc_auth.login_attempts WHERE tenant_id = v_tenant_id OR tenant_id IN (
        SELECT id FROM nxc_tenant.tenants WHERE slug = 'demo'
    );
    RAISE NOTICE 'Login attempts del tenant demo eliminados (si existían).';
    
    -- Ahora sí eliminar el tenant (ON DELETE CASCADE limpia usuarios, roles, user_roles, etc.)
    DELETE FROM nxc_tenant.tenants WHERE id = v_tenant_id OR slug = 'demo';
    RAISE NOTICE 'Datos previos del tenant demo eliminados (si existían).';

    -- 1. Crear tenant demo con UUID fijo (coincide con Postman variable tenant_id)
    INSERT INTO nxc_tenant.tenants (
        id,
        slug, name, legal_name, tax_id, plan, mode, status,
        logo_url, primary_color, custom_domain,
        timezone, locale, date_format, currency,
        mfa_required, session_timeout_minutes, max_login_attempts,
        password_min_length, password_requires_upper, password_requires_special,
        password_expiry_days, max_users, audit_retention_days,
        trial_ends_at, subscription_ends_at,
        created_at, updated_at, version
    ) VALUES (
        v_tenant_id,
        'demo',
        'Tenant Demo',
        'Tenant Demo S.A.S.',
        '900123456',
        'STARTER',
        'SAAS_SHARED',
        'ACTIVE',
        NULL,
        '#1976D2',
        NULL,
        'America/Bogota',
        'es-CO',
        'DD/MM/YYYY',
        'COP',
        FALSE,
        480,
        5,
        8,
        FALSE,
        FALSE,
        NULL,
        100,
        90,
        NOW() + INTERVAL '15 days',
        NOW() + INTERVAL '1 year',
        NOW(),
        NOW(),
        0
    );

    RAISE NOTICE 'Tenant demo creado con id: %', v_tenant_id;

    -- 2. Crear usuario administrador demo con UUID fijo (coincide con Postman variable actor_id)
    -- NOTA: password_hash debe ser generado por la aplicación (bcrypt). El valor aquí
    --       es un placeholder. Reemplázalo con el hash real antes de ejecutar en producción.
    INSERT INTO nxc_tenant.users (
        id,
        tenant_id, username, email, password_hash,
        full_name, phone, status, is_tenant_admin,
        email_verified, email_verified_at,
        created_at, updated_at, version
    ) VALUES (
        v_admin_id,
        v_tenant_id,
        'admin.demo',
        'admin@demo.nexcore.io',
        '$2a$12$REPLACE_WITH_REAL_BCRYPT_HASH_OF_Admin123!',
        'Administrador Demo',
        '+573001234567',
        'ACTIVE',
        TRUE,
        TRUE,
        NOW(),
        NOW(),
        NOW(),
        0
    );

    RAISE NOTICE 'Usuario admin demo creado con id: %', v_admin_id;

    -- 3. Obtener IDs de los roles base creados automáticamente por el trigger del tenant
    SELECT id INTO v_role_admin_id  FROM nxc_tenant.roles WHERE tenant_id = v_tenant_id AND name = 'TENANT_ADMIN';
    SELECT id INTO v_role_editor_id FROM nxc_tenant.roles WHERE tenant_id = v_tenant_id AND name = 'EDITOR';
    SELECT id INTO v_role_viewer_id FROM nxc_tenant.roles WHERE tenant_id = v_tenant_id AND name = 'VIEWER';

    RAISE NOTICE 'Roles obtenidos — TENANT_ADMIN: %, EDITOR: %, VIEWER: %',
        v_role_admin_id, v_role_editor_id, v_role_viewer_id;

    -- 4. Asignar rol TENANT_ADMIN al usuario administrador demo
    INSERT INTO nxc_tenant.user_roles (
        tenant_id, user_id, role_id, assigned_at, assigned_by
    ) VALUES (
        v_tenant_id,
        v_admin_id,
        v_role_admin_id,
        NOW(),
        v_admin_id
    );

    RAISE NOTICE 'Rol TENANT_ADMIN asignado al usuario admin demo.';

END $$;

-- =============================================================================
-- Fin del script de migración demo
-- =============================================================================
