-- =============================================================================
-- Script 04: Elimina los usuarios e invitaciones de prueba del tenant demo
-- Tenant demo : 00000000-0000-0000-0000-000000000002
--
-- Elimina ÚNICAMENTE los registros generados por 03-seed-users-invitations.sql:
--   · Usuarios con username LIKE 'demo.user.%'
--   · Invitaciones con email   LIKE 'invite.user.%@external.com'
--   · Sus asignaciones de roles asociadas (en cascada vía FK o explícitamente)
--
-- Los usuarios semilla (admin.demo, super.admin, test.admin, test.editor) y
-- las demás invitaciones NO se ven afectados.
-- =============================================================================

SET app.is_system_admin = 'true';

-- Verificación previa
SELECT
    'usuarios de prueba' AS tipo,
    COUNT(*)             AS registros_a_eliminar
FROM nxc_tenant.users
WHERE tenant_id = '00000000-0000-0000-0000-000000000002'
  AND username LIKE 'demo.user.%'

UNION ALL

SELECT
    'invitaciones de prueba',
    COUNT(*)
FROM nxc_tenant.user_invitations
WHERE tenant_id = '00000000-0000-0000-0000-000000000002'
  AND email LIKE 'invite.user.%@external.com';

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Roles asignados a los usuarios de prueba
--    (la FK ON DELETE CASCADE ya lo hace, pero explicitamos para claridad)
-- ─────────────────────────────────────────────────────────────────────────────
DELETE FROM nxc_tenant.user_roles ur
USING nxc_tenant.users u
WHERE u.id = ur.user_id
  AND u.tenant_id = '00000000-0000-0000-0000-000000000002'
  AND u.username LIKE 'demo.user.%';

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Usuarios de prueba
-- ─────────────────────────────────────────────────────────────────────────────
DELETE FROM nxc_tenant.users
WHERE tenant_id = '00000000-0000-0000-0000-000000000002'
  AND username LIKE 'demo.user.%';

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Invitaciones de prueba
-- ─────────────────────────────────────────────────────────────────────────────
DELETE FROM nxc_tenant.user_invitations
WHERE tenant_id = '00000000-0000-0000-0000-000000000002'
  AND email LIKE 'invite.user.%@external.com';

COMMIT;

-- Verificación final
SELECT
    'usuarios restantes (seed)'   AS tipo,
    COUNT(*)                      AS total
FROM nxc_tenant.users
WHERE tenant_id = '00000000-0000-0000-0000-000000000002'
  AND deleted_at IS NULL

UNION ALL

SELECT
    'invitaciones restantes',
    COUNT(*)
FROM nxc_tenant.user_invitations
WHERE tenant_id = '00000000-0000-0000-0000-000000000002';
