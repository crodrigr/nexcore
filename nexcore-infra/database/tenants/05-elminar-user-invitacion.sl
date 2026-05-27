	delete from nxc_tenant.user_invitations ui; 


-- Nullifica invitaciones del usuario
UPDATE nxc_tenant.user_invitations 
SET accepted_at = NULL, user_id = NULL
WHERE tenant_id = '00000000-0000-0000-0000-000000000002' 
  AND user_id IN (
    SELECT id FROM nxc_tenant.users 
    WHERE tenant_id = '00000000-0000-0000-0000-000000000002'
      AND username = 'camilo.rm'
  );

-- Elimina roles del usuario
DELETE FROM nxc_tenant.user_roles 
WHERE tenant_id = '00000000-0000-0000-0000-000000000002'
  AND user_id IN (
    SELECT id FROM nxc_tenant.users 
    WHERE tenant_id = '00000000-0000-0000-0000-000000000002'
      AND username = 'camilo.rm'
  );

-- Elimina intentos de login del usuario
DELETE FROM nxc_auth.login_attempts 
WHERE user_id IN (
    SELECT id FROM nxc_tenant.users 
    WHERE tenant_id = '00000000-0000-0000-0000-000000000002'
      AND username = 'camilo.rm'
  );

-- Elimina el usuario
DELETE FROM nxc_tenant.users 
WHERE tenant_id = '00000000-0000-0000-0000-000000000002'
  AND username = 'camilo.rm';

-- Limpia roles huérfanos (opcional)
DELETE FROM nxc_tenant.user_roles 
WHERE tenant_id = '00000000-0000-0000-0000-000000000002'
  AND user_id NOT IN (
    SELECT id FROM nxc_tenant.users 
    WHERE tenant_id = '00000000-0000-0000-0000-000000000002'
  );