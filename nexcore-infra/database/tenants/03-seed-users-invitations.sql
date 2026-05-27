-- =============================================================================
-- Script 03: Seed 100 usuarios de prueba + 100 invitaciones
-- Tenant demo : 00000000-0000-0000-0000-000000000002
-- Actor       : admin.demo  (00000000-0000-0000-0001-000000000002)
-- Contraseña  : NexCore@2026!
--
-- Distribución de estados de usuarios:
--   ACTIVE              → i % 10 ∈ {5,6,7,8,9}  (50 usuarios)
--   PENDING_ACTIVATION  → i % 10 ∈ {3,4}         (20 usuarios)
--   SUSPENDED           → i % 10 ∈ {1,2}         (20 usuarios)
--   BLOCKED             → i % 10 = 0             (10 usuarios)
--
-- Distribución de roles:
--   VIEWER       → usuarios impares (no multiplo de 25)
--   EDITOR       → usuarios pares  (no multiplo de 25)
--   TENANT_ADMIN → i % 25 = 0  (4 usuarios: 25, 50, 75, 100)
--
-- Distribución de invitaciones:
--   PENDING  → i % 10 ∈ {5,6,7,8,9}  (50 invitaciones)
--   ACCEPTED → i % 10 ∈ {2,3,4}      (30 invitaciones)
--   REVOKED  → i % 10 ∈ {0,1}        (20 invitaciones)
-- =============================================================================

SET app.is_system_admin = 'true';

DO $$
DECLARE
    v_tenant_id   UUID    := '00000000-0000-0000-0000-000000000002';
    v_actor_id    UUID    := '00000000-0000-0000-0001-000000000002';
    v_pwd_hash    TEXT    := '$2a$12$2SgNZ1P9TWruO3hmUqL6u.U3K4mKg9o7xtK6N8uZJXVxjFqbMDf/y';

    v_role_viewer UUID;
    v_role_editor UUID;
    v_role_admin  UUID;

    v_first_names TEXT[] := ARRAY[
        'Ana','Carlos','María','Juan','Laura',
        'Pedro','Sofía','Luis','Carmen','Diego',
        'Isabella','Andrés','Valentina','Miguel','Paula',
        'Sebastián','Gabriela','Felipe','Daniela','Jorge'
    ];
    v_last_names  TEXT[] := ARRAY[
        'García','López','Rodríguez','Martínez','Hernández',
        'González','Díaz','Torres','Flores','Ramírez',
        'Gómez','Moreno','Vargas','Jiménez','Castro',
        'Romero','Mendoza','Ruiz','Suárez','Silva'
    ];

    i             INTEGER;
    v_user_id     UUID;
    v_status      nxc_tenant.user_status;
    v_full_name   TEXT;
    v_role_id     UUID;
    v_days_ago    INTERVAL;
    v_is_admin    BOOLEAN;
    v_email_ok    BOOLEAN;
    v_cnt_users   INTEGER := 0;
    v_cnt_invs    INTEGER := 0;

BEGIN
    -- Verificar que el tenant demo existe
    IF NOT EXISTS (
        SELECT 1 FROM nxc_tenant.tenants
        WHERE id = v_tenant_id AND deleted_at IS NULL
    ) THEN
        RAISE EXCEPTION 'Tenant demo (%) no existe. Ejecute primero schema-nexcore.sql.', v_tenant_id;
    END IF;

    -- Obtener roles del tenant demo
    SELECT id INTO v_role_viewer FROM nxc_tenant.roles
        WHERE tenant_id = v_tenant_id AND name = 'VIEWER'       AND deleted_at IS NULL;
    SELECT id INTO v_role_editor FROM nxc_tenant.roles
        WHERE tenant_id = v_tenant_id AND name = 'EDITOR'       AND deleted_at IS NULL;
    SELECT id INTO v_role_admin  FROM nxc_tenant.roles
        WHERE tenant_id = v_tenant_id AND name = 'TENANT_ADMIN' AND deleted_at IS NULL;

    IF v_role_viewer IS NULL OR v_role_editor IS NULL THEN
        RAISE EXCEPTION 'Roles VIEWER / EDITOR no encontrados para el tenant demo.';
    END IF;

    -- =========================================================================
    -- SECCIÓN 1 — Usuarios
    -- =========================================================================
    FOR i IN 1..100 LOOP
        v_user_id   := gen_random_uuid();
        v_days_ago  := (i || ' days')::INTERVAL;
        v_full_name := v_first_names[((i - 1) % 20) + 1]
                       || ' '
                       || v_last_names[((i + 9 - 1) % 20) + 1];

        -- Estado
        v_status := CASE
            WHEN i % 10 = 0              THEN 'BLOCKED'::nxc_tenant.user_status
            WHEN i % 10 IN (1, 2)        THEN 'SUSPENDED'::nxc_tenant.user_status
            WHEN i % 10 IN (3, 4)        THEN 'PENDING_ACTIVATION'::nxc_tenant.user_status
            ELSE                              'ACTIVE'::nxc_tenant.user_status
        END;

        v_is_admin  := (i % 25 = 0) AND (v_role_admin IS NOT NULL);
        v_email_ok  := v_status != 'PENDING_ACTIVATION'::nxc_tenant.user_status;

        -- Rol asignado
        v_role_id := CASE
            WHEN v_is_admin             THEN v_role_admin
            WHEN i % 2 = 0              THEN v_role_editor
            ELSE                             v_role_viewer
        END;

        INSERT INTO nxc_tenant.users (
            id, tenant_id,
            username, email, password_hash, full_name, phone,
            status, active, suspended, is_tenant_admin,
            email_verified, email_verified_at,
            invited_by, invited_at, activated_at,
            last_login_at,
            created_by, updated_by, created_at, updated_at, version
        ) VALUES (
            v_user_id, v_tenant_id,
            format('demo.user.%s', lpad(i::text, 3, '0')),
            format('demo.user.%s@demo.nexcore.io', lpad(i::text, 3, '0')),
            v_pwd_hash,
            v_full_name,
            '+57 3' || lpad(((100000000 + i * 9973) % 1000000000)::text, 9, '0'),
            v_status,
            v_status != 'BLOCKED'::nxc_tenant.user_status,
            v_status = 'SUSPENDED'::nxc_tenant.user_status,
            v_is_admin,
            v_email_ok,
            CASE WHEN v_email_ok THEN NOW() - v_days_ago ELSE NULL END,
            v_actor_id,
            NOW() - v_days_ago - INTERVAL '1 hour',
            CASE WHEN v_email_ok THEN NOW() - v_days_ago ELSE NULL END,
            CASE WHEN v_status = 'ACTIVE'::nxc_tenant.user_status
                 THEN NOW() - ((i % 7) || ' hours')::INTERVAL
                 ELSE NULL END,
            v_actor_id, v_actor_id,
            NOW() - v_days_ago,
            NOW() - v_days_ago,
            0
        )
        ON CONFLICT (tenant_id, username) DO NOTHING;

        -- Asignar rol (solo si el INSERT tuvo efecto)
        IF FOUND THEN
            INSERT INTO nxc_tenant.user_roles (
                tenant_id, user_id, role_id, assigned_by, assigned_at
            ) VALUES (
                v_tenant_id, v_user_id, v_role_id, v_actor_id, NOW() - v_days_ago
            )
            ON CONFLICT (tenant_id, user_id, role_id) DO NOTHING;

            v_cnt_users := v_cnt_users + 1;
        END IF;
    END LOOP;

    RAISE NOTICE '>> Usuarios insertados: %', v_cnt_users;

    -- =========================================================================
    -- SECCIÓN 2 — Invitaciones
    -- =========================================================================
    FOR i IN 1..100 LOOP
        v_role_id := CASE WHEN i % 2 = 0 THEN v_role_editor ELSE v_role_viewer END;

        INSERT INTO nxc_tenant.user_invitations (
            id, tenant_id, email, token_hash, role_ids,
            invited_by, invited_at, expires_at,
            accepted_at, is_revoked
        ) VALUES (
            gen_random_uuid(),
            v_tenant_id,
            format('invite.user.%s@external.com', lpad(i::text, 3, '0')),
            encode(digest(gen_random_uuid()::text || i::text || clock_timestamp()::text, 'sha256'), 'hex'),
            ARRAY[v_role_id],
            v_actor_id,
            NOW() - ((i + 10) || ' hours')::INTERVAL,
            CASE
                WHEN i % 5 = 0 THEN NOW() - '1 hour'::INTERVAL    -- expiradas (20 total)
                ELSE                NOW() + '72 hours'::INTERVAL   -- vigentes
            END,
            CASE
                WHEN i % 10 IN (2, 3, 4) THEN NOW() - (i || ' hours')::INTERVAL
                ELSE NULL
            END,
            i % 10 IN (0, 1)
        )
        ON CONFLICT (token_hash) DO NOTHING;

        IF FOUND THEN
            v_cnt_invs := v_cnt_invs + 1;
        END IF;
    END LOOP;

    RAISE NOTICE '>> Invitaciones insertadas: %', v_cnt_invs;
    RAISE NOTICE '>> Seed completado para tenant demo (%)', v_tenant_id;
END $$;

COMMIT;

-- =============================================================================
-- Verificación
-- =============================================================================
SELECT
    status,
    COUNT(*) AS total
FROM nxc_tenant.users
WHERE tenant_id = '00000000-0000-0000-0000-000000000002'
  AND username LIKE 'demo.user.%'
  AND deleted_at IS NULL
GROUP BY status
ORDER BY status;

SELECT
    CASE
        WHEN is_revoked = TRUE             THEN 'REVOKED'
        WHEN accepted_at IS NOT NULL       THEN 'ACCEPTED'
        ELSE                                    'PENDING'
    END AS inv_status,
    COUNT(*) AS total
FROM nxc_tenant.user_invitations
WHERE tenant_id = '00000000-0000-0000-0000-000000000002'
  AND email LIKE 'invite.user.%@external.com'
GROUP BY inv_status
ORDER BY inv_status;
