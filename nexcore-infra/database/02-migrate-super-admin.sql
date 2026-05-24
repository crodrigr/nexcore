DO $$
DECLARE
    v_tenant_system UUID := '00000000-0000-0000-0000-000000000001';
BEGIN
  -- SIDEBAR (top level): usar solo iconos soportados por el switch actual
  UPDATE nxc_menu.menu_items
  SET icon = CASE name
      WHEN 'dashboard'          THEN 'layout-dashboard'
      WHEN 'tenant-management'  THEN 'bell'
      WHEN 'identity-access'    THEN 'alert-circle'
      WHEN 'audit-viewer'       THEN 'radar'
      WHEN 'feature-flags'      THEN 'bell'
      WHEN 'platform-settings'  THEN 'alert-circle'
      ELSE icon
  END,
  icon_type = 'tabler',
  updated_at = NOW()
  WHERE tenant_id = v_tenant_system
    AND location = 'sidebar'
    AND parent_id IS NULL
    AND name IN (
      'dashboard',
      'tenant-management',
      'identity-access',
      'audit-viewer',
      'feature-flags',
      'platform-settings'
    );

  -- SIDEBAR legados (ya compatibles)
  UPDATE nxc_menu.menu_items
  SET icon = CASE name
      WHEN 'Alerts'    THEN 'bell'
      WHEN 'Incidents' THEN 'bell'
      WHEN 'Traps'     THEN 'radar'
      ELSE icon
  END,
  icon_type = 'tabler',
  updated_at = NOW()
  WHERE tenant_id = v_tenant_system
    AND location = 'sidebar'
    AND name IN ('Alerts','Incidents','Traps');

  -- PROFILE menu items (compatibles en navbar/profile switch)
  UPDATE nxc_menu.menu_items
  SET icon = CASE name
      WHEN 'Profile'       THEN 'user'
      WHEN 'Settings'      THEN 'settings'
      WHEN 'Logout'        THEN 'logout'
      WHEN 'Menus'         THEN 'layout-navbar'
      WHEN 'ProfileMenu'   THEN 'user'
      WHEN 'Administration'THEN 'lock'
      ELSE icon
  END,
  icon_type = 'tabler',
  updated_at = NOW()
  WHERE tenant_id = v_tenant_system
    AND location = 'profile'
    AND name IN ('Profile','Settings','Logout','Menus','ProfileMenu','Administration');

  RAISE NOTICE 'Iconos normalizados a los casos soportados por el frontend actual';
END $$;


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Eliminar este bloque de código, era para debuggear el tema de los iconos en el sidebar y profile menu. Ya se normalizaron los iconos a los casos soportados por el switch actual del frontend, así que no debería haber más problemas con iconos faltantes o incorrectos.
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



-- =============================================================================
-- NEXCORE - REMOVE SUPER_ADMIN INITIAL SETUP
-- =============================================================================
-- REMOVE:
-- - USER ROLE
-- - COMPONENT PERMISSIONS
-- - MENU ITEMS
-- - COMPONENTS
-- - ROLE SUPER_ADMIN
-- =============================================================================

DO $$
DECLARE

    v_tenant_system UUID := '00000000-0000-0000-0000-000000000001';
    v_super_admin_user UUID := '00000000-0000-0000-0001-000000000001';

    v_role_super_admin UUID;

BEGIN

-- =============================================================================
-- GET ROLE ID
-- =============================================================================

SELECT id
INTO v_role_super_admin
FROM nxc_tenant.roles
WHERE tenant_id = v_tenant_system
AND name = 'SUPER_ADMIN';

-- =============================================================================
-- DELETE USER ROLE
-- =============================================================================

DELETE FROM nxc_tenant.user_roles
WHERE tenant_id = v_tenant_system
AND user_id = v_super_admin_user
AND role_id = v_role_super_admin;

-- =============================================================================
-- DELETE COMPONENT PERMISSIONS
-- =============================================================================

DELETE FROM nxc_menu.component_permissions
WHERE tenant_id = v_tenant_system
AND role_id = v_role_super_admin;

-- =============================================================================
-- DELETE ELEMENT PERMISSIONS
-- =============================================================================

DELETE FROM nxc_menu.element_permissions
WHERE tenant_id = v_tenant_system
AND role_id = v_role_super_admin;

-- =============================================================================
-- DELETE MENU ITEMS
-- =============================================================================

DELETE FROM nxc_menu.menu_items
WHERE tenant_id = v_tenant_system
AND component_id IN (

    SELECT id
    FROM nxc_menu.components
    WHERE tenant_id = v_tenant_system
    AND module_key IN (
        'dashboard',
        'tenant-management',
        'user-management',
        'role-management',
        'audit-viewer',
        'feature-flags',
        'platform-settings'
    )
);

-- =============================================================================
-- DELETE COMPONENT ELEMENTS
-- =============================================================================

DELETE FROM nxc_menu.component_elements
WHERE tenant_id = v_tenant_system
AND component_id IN (

    SELECT id
    FROM nxc_menu.components
    WHERE tenant_id = v_tenant_system
    AND module_key IN (
        'dashboard',
        'tenant-management',
        'user-management',
        'role-management',
        'audit-viewer',
        'feature-flags',
        'platform-settings'
    )
);

-- =============================================================================
-- DELETE COMPONENTS
-- =============================================================================

DELETE FROM nxc_menu.components
WHERE tenant_id = v_tenant_system
AND module_key IN (
    'dashboard',
    'tenant-management',
    'user-management',
    'role-management',
    'audit-viewer',
    'feature-flags',
    'platform-settings'
);

-- =============================================================================
-- DELETE ROLE
-- =============================================================================

DELETE FROM nxc_tenant.roles
WHERE tenant_id = v_tenant_system
AND name = 'SUPER_ADMIN';

RAISE NOTICE 'SUPER_ADMIN INITIAL SETUP REMOVED';

END $$;

