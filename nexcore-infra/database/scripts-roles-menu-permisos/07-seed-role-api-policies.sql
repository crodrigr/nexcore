-- =============================================================================
-- NexCore Platform — Seed inicial de role_api_policies
-- Script: 07-seed-role-api-policies.sql
--
-- PROPÓSITO:
--   Cargar las políticas de acceso para todos los endpoints actuales de
--   nexcore-core (8080) y nexcore-auth-service (8081).
--
-- PREREQUISITO: 06-create-role-api-policies.sql debe haberse ejecutado.
--
-- EJECUCIÓN MANUAL:
--   1. Ejecutar primero el script 06- (DDL de la tabla).
--   2. Ejecutar este script completo.
--   3. Verificar con las queries al final del script.
--
-- =============================================================================
-- DISEÑO: por qué las políticas son GLOBALES (sin tenant_id)
-- =============================================================================
--
--   Las políticas de API son un contrato de la PLATAFORMA, no de cada tenant.
--   Todos los TENANT_ADMIN de todos los tenants pueden llamar a los mismos
--   endpoints — la separación de datos entre tenants la hacen otras capas:
--     · RLS en PostgreSQL (filtra por tenant_id)
--     · Business logic (X-Tenant-Id en headers)
--     · component_permissions (visibilidad de UI, sí es por tenant)
--
--   Ver 06-create-role-api-policies.sql para la explicación completa de las
--   decisiones de diseño (role_name vs role_id, caché Redis, dos capas, etc.).
--
-- =============================================================================
-- CONVENCIÓN DE PRIORIDADES
-- =============================================================================
--   100 → ALLOW general (rol puede acceder)
--   500 → DENY específico (bloqueo explícito que anula un ALLOW de nivel 100)
--
-- =============================================================================
-- CONVENCIÓN DE PATRONES DE PATH
-- =============================================================================
--   El segmento de versión (v1, v2…) se escribe siempre como *
--   /api/*/recurso          → cubre /api/v1/recurso, /api/v2/recurso, etc.
--   /api/*/recurso/*        → un segmento variable (/{id})
--   /api/*/recurso/**       → cualquier subruta (/{id}/accion, etc.)
--   /api/*/recurso/*/accion → variable en el medio + sufijo exacto
--   /api/**                 → cualquier path bajo /api/ (para DENY globales)
--
-- =============================================================================
-- MÓDULOS (campo module — organizativo, no afecta evaluación del interceptor)
-- =============================================================================
--   auth        → endpoints de autenticación (nexcore-auth-service)
--   profile     → perfil del usuario (/me/profile)
--   tenants     → gestión de tenants
--   users       → gestión de usuarios e invitaciones
--   roles       → gestión de roles
--   components  → componentes de UI (/menu/components)
--   permissions → matriz de permisos por rol (/menu/permissions)
--   general     → políticas transversales / fallback (DENY globales de VIEWER)
--
-- =============================================================================
-- SECCIONES
-- =============================================================================
--   1. Auth service  — endpoints autenticados de nexcore-auth-service
--   2. Público       — POST /api/*/users/invitations/accept (sin JWT)
--   3. Perfil        — GET /api/*/me/profile
--   4. Tenants       — CRUD de tenants (mayormente SUPER_ADMIN)
--   5. Usuarios      — CRUD de usuarios e invitaciones
--   6. Roles         — CRUD de roles
--   7. Componentes   — Consulta de componentes de UI
--   8. Permisos      — Matriz de permisos por rol
--   9. DENY          — Bloqueos explícitos de alta prioridad
-- =============================================================================

DO $$
DECLARE
    v_super_admin    UUID := '00000000-0000-0000-0001-000000000001'; -- super.admin
BEGIN
    RAISE NOTICE '=== SEED: role_api_policies ===';

    -- Limpiar políticas existentes para recarga idempotente
    DELETE FROM nxc_tenant.role_api_policies;

-- =============================================================================
-- SECCIÓN 1: NEXCORE-AUTH-SERVICE (puerto 8081)
--
-- La mayoría de endpoints de auth son PÚBLICOS (no requieren JWT):
--   · POST /auth/login           → recibe tenantId + username + password
--   · POST /auth/verify-otp      → recibe challengeToken + código OTP
--   · POST /auth/password/reset/request  → pide reset con email
--   · POST /auth/password/reset/confirm  → confirma reset con token del email
--
-- Estos NO necesitan política (el interceptor los excluye del filtro).
--
-- Los que SÍ requieren autenticación (JWT válido):
--   · DELETE /auth/logout
--   · DELETE /auth/logout-all
--   · PUT /auth/password  (cambiar contraseña con contraseña actual)
--   · POST /auth/refresh  (usa X-Refresh-Token, no JWT pero sí sesión activa)
-- =============================================================================

-- Nota: para auth-service, la política '*' significa "cualquier usuario
-- con una sesión válida". El interceptor del auth-service verifica el JWT
-- antes de consultar estas políticas.

    INSERT INTO nxc_tenant.role_api_policies
        (role_name, http_method, path_pattern, effect, service, module, priority, description, created_by)
    VALUES

    -- -----------------------------------------------------------------
    -- POST /auth/refresh
    -- Cualquier usuario autenticado puede refrescar su token.
    -- El interceptor verifica que el refresh token sea válido.
    -- -----------------------------------------------------------------
    ('*', 'POST', '/auth/refresh', 'ALLOW', 'auth', 'auth', 100,
     'Refrescar access token con refresh token válido. Aplica a cualquier usuario autenticado.',
     v_super_admin),

    -- -----------------------------------------------------------------
    -- DELETE /auth/logout
    -- El usuario solo puede cerrar su propia sesión (validado por sessionId en el JWT).
    -- -----------------------------------------------------------------
    ('*', 'DELETE', '/auth/logout', 'ALLOW', 'auth', 'auth', 100,
     'Cerrar la sesión actual del usuario autenticado.',
     v_super_admin),

    -- -----------------------------------------------------------------
    -- DELETE /auth/logout-all
    -- Cierra todas las sesiones del usuario (excepto la actual).
    -- -----------------------------------------------------------------
    ('*', 'DELETE', '/auth/logout-all', 'ALLOW', 'auth', 'auth', 100,
     'Cerrar todas las sesiones activas del usuario autenticado.',
     v_super_admin),

    -- -----------------------------------------------------------------
    -- PUT /auth/password
    -- Cambiar contraseña proporcionando la contraseña actual.
    -- Requiere JWT válido (usuario debe estar logueado).
    -- -----------------------------------------------------------------
    ('*', 'PUT', '/auth/password', 'ALLOW', 'auth', 'auth', 100,
     'Cambiar contraseña. El usuario debe estar autenticado y proporcionar la contraseña actual.',
     v_super_admin);

-- =============================================================================
-- SECCIÓN 2: NEXCORE-CORE (puerto 8080) — Endpoints públicos sin auth
--
-- Solo uno es completamente público (sin JWT requerido):
--   · POST /api/v1/users/invitations/accept → el usuario recién invitado
--     no tiene cuenta aún, acepta con un token del email.
-- =============================================================================

    INSERT INTO nxc_tenant.role_api_policies
        (role_name, http_method, path_pattern, effect, service, module, priority, description, created_by)
    VALUES

    -- -----------------------------------------------------------------
    -- POST /api/vN/users/invitations/accept  (PÚBLICO)
    -- El invitado usa el token del email, no tiene JWT todavía.
    -- El rol '*' con prioridad 100 cubre este caso.
    -- El interceptor debe excluir este endpoint del check de JWT.
    -- -----------------------------------------------------------------
    ('*', 'POST', '/api/*/users/invitations/accept', 'ALLOW', 'core', 'users', 100,
     'Aceptar invitación. Endpoint público: el invitado no tiene JWT aún, usa token del email.',
     v_super_admin);

-- =============================================================================
-- SECCIÓN 3: NEXCORE-CORE — Perfil de usuario (GET /api/*/me/profile)
--
-- Cualquier usuario autenticado puede obtener su propio perfil.
-- Este endpoint es el que construye el objeto profile con menus + permissions
-- que el frontend guarda en localStorage.
-- =============================================================================

    INSERT INTO nxc_tenant.role_api_policies
        (role_name, http_method, path_pattern, effect, service, module, priority, description, created_by)
    VALUES

    -- -----------------------------------------------------------------
    -- GET /api/vN/me/profile
    -- Lee el usuario por X-Actor-Id + X-Tenant-Id y devuelve
    -- su perfil completo con menus[] y permissions[].
    -- -----------------------------------------------------------------
    ('*', 'GET', '/api/*/me/profile', 'ALLOW', 'core', 'profile', 100,
     'Obtener perfil completo del usuario autenticado (menus, permisos por componente).',
     v_super_admin);

-- =============================================================================
-- SECCIÓN 4: TENANTS  /api/*/tenants  (cubre v1, v2, …)
--
-- Solo el SUPER_ADMIN puede gestionar tenants.
-- El TENANT_ADMIN puede leer y editar SU OWN tenant (validado en la lógica de negocio,
-- no aquí; aquí solo decimos que puede llamar al endpoint).
-- =============================================================================

    INSERT INTO nxc_tenant.role_api_policies
        (role_name, http_method, path_pattern, effect, service, module, priority, description, created_by)
    VALUES

    -- -----------------------------------------------------------------
    -- GET /api/vN/tenants
    -- Lista paginada de todos los tenants. Solo SUPER_ADMIN.
    -- Un TENANT_ADMIN no puede ver la lista de otros tenants.
    -- -----------------------------------------------------------------
    ('SUPER_ADMIN', 'GET', '/api/*/tenants', 'ALLOW', 'core', 'tenants', 100,
     'Listar todos los tenants de la plataforma. Operación exclusiva de SUPER_ADMIN.',
     v_super_admin),

    -- -----------------------------------------------------------------
    -- POST /api/vN/tenants
    -- Crear un nuevo tenant. Solo SUPER_ADMIN.
    -- -----------------------------------------------------------------
    ('SUPER_ADMIN', 'POST', '/api/*/tenants', 'ALLOW', 'core', 'tenants', 100,
     'Crear un nuevo tenant en la plataforma. Operación exclusiva de SUPER_ADMIN.',
     v_super_admin),

    -- -----------------------------------------------------------------
    -- GET /api/vN/tenants/{id}
    -- Ver detalle de un tenant. SUPER_ADMIN ve cualquier tenant.
    -- TENANT_ADMIN puede ver solo el suyo (validado en la capa de negocio).
    -- -----------------------------------------------------------------
    ('SUPER_ADMIN',   'GET', '/api/*/tenants/*', 'ALLOW', 'core', 'tenants', 100,
     'Ver detalle de cualquier tenant. SUPER_ADMIN tiene acceso total.',
     v_super_admin),
    ('TENANT_ADMIN',  'GET', '/api/*/tenants/*', 'ALLOW', 'core', 'tenants', 100,
     'Ver detalle del propio tenant. La capa de negocio valida que solo sea el suyo.',
     v_super_admin),

    -- -----------------------------------------------------------------
    -- PATCH /api/vN/tenants/{id}
    -- Editar datos del tenant. SUPER_ADMIN edita cualquiera (puede cambiar plan).
    -- TENANT_ADMIN edita solo el suyo (sin cambiar plan/modo).
    -- -----------------------------------------------------------------
    ('SUPER_ADMIN',  'PATCH', '/api/*/tenants/*', 'ALLOW', 'core', 'tenants', 100,
     'Editar cualquier tenant, incluyendo cambio de plan/modo. Solo SUPER_ADMIN.',
     v_super_admin),
    ('TENANT_ADMIN', 'PATCH', '/api/*/tenants/*', 'ALLOW', 'core', 'tenants', 100,
     'Editar el propio tenant. Sin acceso a cambiar plan/modo (validado en negocio).',
     v_super_admin),

    -- -----------------------------------------------------------------
    -- POST /api/vN/tenants/{id}/suspend
    -- Suspender un tenant. Solo SUPER_ADMIN.
    -- -----------------------------------------------------------------
    ('SUPER_ADMIN', 'POST', '/api/*/tenants/*/suspend', 'ALLOW', 'core', 'tenants', 100,
     'Suspender un tenant. Operación exclusiva de SUPER_ADMIN.',
     v_super_admin),

    -- -----------------------------------------------------------------
    -- POST /api/vN/tenants/{id}/activate
    -- Reactivar un tenant suspendido. Solo SUPER_ADMIN.
    -- -----------------------------------------------------------------
    ('SUPER_ADMIN', 'POST', '/api/*/tenants/*/activate', 'ALLOW', 'core', 'tenants', 100,
     'Reactivar un tenant suspendido. Operación exclusiva de SUPER_ADMIN.',
     v_super_admin);

-- =============================================================================
-- SECCIÓN 5: USUARIOS  /api/*/users  (cubre v1, v2, …)
--
-- SUPER_ADMIN: acceso total (gestiona usuarios de cualquier tenant)
-- TENANT_ADMIN: gestión completa de usuarios de su propio tenant
-- EDITOR: acceso reducido (lectura de usuarios, puede editar el propio perfil)
-- VIEWER: solo lectura de usuarios del tenant
-- * (cualquier autenticado): solo GET /api/*/users/me (propio perfil)
-- =============================================================================

    INSERT INTO nxc_tenant.role_api_policies
        (role_name, http_method, path_pattern, effect, service, module, priority, description, created_by)
    VALUES

    -- -----------------------------------------------------------------
    -- GET /api/vN/users/me
    -- El usuario puede ver sus propios datos básicos (no el perfil de UI completo).
    -- Diferente de /me/profile: este retorna UserResponse del módulo users.
    -- -----------------------------------------------------------------
    ('*', 'GET', '/api/*/users/me', 'ALLOW', 'core', 'users', 100,
     'Ver los datos propios del usuario autenticado (UserResponse básico).',
     v_super_admin),

    -- -----------------------------------------------------------------
    -- GET /api/vN/users
    -- Listar usuarios del tenant (paginado, con filtros).
    -- SUPER_ADMIN: lista usuarios de cualquier tenant (según X-Tenant-Id).
    -- TENANT_ADMIN: lista usuarios de su tenant.
    -- EDITOR/VIEWER: NO pueden listar usuarios (solo el admin gestiona usuarios).
    -- -----------------------------------------------------------------
    ('SUPER_ADMIN',  'GET', '/api/*/users', 'ALLOW', 'core', 'users', 100,
     'Listar usuarios de cualquier tenant (según X-Tenant-Id).',
     v_super_admin),
    ('TENANT_ADMIN', 'GET', '/api/*/users', 'ALLOW', 'core', 'users', 100,
     'Listar usuarios del propio tenant con filtros y paginación.',
     v_super_admin),

    -- -----------------------------------------------------------------
    -- POST /api/vN/users
    -- Crear usuario directamente (sin invitación). Admin-only.
    -- -----------------------------------------------------------------
    ('SUPER_ADMIN',  'POST', '/api/*/users', 'ALLOW', 'core', 'users', 100,
     'Crear usuario directamente en cualquier tenant. Uso de SUPER_ADMIN.',
     v_super_admin),
    ('TENANT_ADMIN', 'POST', '/api/*/users', 'ALLOW', 'core', 'users', 100,
     'Crear usuario directamente en el propio tenant.',
     v_super_admin),

    -- -----------------------------------------------------------------
    -- GET /api/vN/users/{id}
    -- Ver detalle de un usuario específico.
    -- -----------------------------------------------------------------
    ('SUPER_ADMIN',  'GET', '/api/*/users/*', 'ALLOW', 'core', 'users', 100,
     'Ver detalle de cualquier usuario en cualquier tenant.',
     v_super_admin),
    ('TENANT_ADMIN', 'GET', '/api/*/users/*', 'ALLOW', 'core', 'users', 100,
     'Ver detalle de usuarios del propio tenant.',
     v_super_admin),
    ('EDITOR',       'GET', '/api/*/users/*', 'ALLOW', 'core', 'users', 100,
     'Ver detalle de usuarios del propio tenant. Solo lectura.',
     v_super_admin),

    -- -----------------------------------------------------------------
    -- PATCH /api/vN/users/{id}
    -- Editar datos del usuario. Admin puede editar cualquier usuario.
    -- EDITOR puede editar solo su propio perfil (validado en negocio por X-Actor-Id).
    -- -----------------------------------------------------------------
    ('SUPER_ADMIN',  'PATCH', '/api/*/users/*', 'ALLOW', 'core', 'users', 100,
     'Editar cualquier usuario en cualquier tenant.',
     v_super_admin),
    ('TENANT_ADMIN', 'PATCH', '/api/*/users/*', 'ALLOW', 'core', 'users', 100,
     'Editar usuarios del propio tenant.',
     v_super_admin),
    ('EDITOR',       'PATCH', '/api/*/users/*', 'ALLOW', 'core', 'users', 100,
     'Editar solo el propio perfil. La capa de negocio valida que id = actor.',
     v_super_admin),

    -- -----------------------------------------------------------------
    -- POST /api/vN/users/{id}/suspend
    -- Suspender un usuario. Solo administradores.
    -- -----------------------------------------------------------------
    ('SUPER_ADMIN',  'POST', '/api/*/users/*/suspend', 'ALLOW', 'core', 'users', 100,
     'Suspender cualquier usuario en cualquier tenant.',
     v_super_admin),
    ('TENANT_ADMIN', 'POST', '/api/*/users/*/suspend', 'ALLOW', 'core', 'users', 100,
     'Suspender usuarios del propio tenant.',
     v_super_admin),

    -- -----------------------------------------------------------------
    -- POST /api/vN/users/{id}/activate
    -- Reactivar un usuario suspendido. Solo administradores.
    -- -----------------------------------------------------------------
    ('SUPER_ADMIN',  'POST', '/api/*/users/*/activate', 'ALLOW', 'core', 'users', 100,
     'Reactivar cualquier usuario en cualquier tenant.',
     v_super_admin),
    ('TENANT_ADMIN', 'POST', '/api/*/users/*/activate', 'ALLOW', 'core', 'users', 100,
     'Reactivar usuarios del propio tenant.',
     v_super_admin),

    -- -----------------------------------------------------------------
    -- DELETE /api/vN/users/{id}
    -- Soft-delete de usuario. Solo administradores.
    -- -----------------------------------------------------------------
    ('SUPER_ADMIN',  'DELETE', '/api/*/users/*', 'ALLOW', 'core', 'users', 100,
     'Eliminar (soft-delete) cualquier usuario en cualquier tenant.',
     v_super_admin),
    ('TENANT_ADMIN', 'DELETE', '/api/*/users/*', 'ALLOW', 'core', 'users', 100,
     'Eliminar (soft-delete) usuarios del propio tenant.',
     v_super_admin),

    -- -----------------------------------------------------------------
    -- PUT /api/vN/users/{id}/roles
    -- Reemplazar roles de un usuario. Solo administradores.
    -- -----------------------------------------------------------------
    ('SUPER_ADMIN',  'PUT', '/api/*/users/*/roles', 'ALLOW', 'core', 'users', 100,
     'Reasignar roles de cualquier usuario en cualquier tenant.',
     v_super_admin),
    ('TENANT_ADMIN', 'PUT', '/api/*/users/*/roles', 'ALLOW', 'core', 'users', 100,
     'Reasignar roles de usuarios del propio tenant.',
     v_super_admin),

    -- -----------------------------------------------------------------
    -- POST /api/vN/users/invite
    -- Enviar invitación por email. Solo administradores.
    -- -----------------------------------------------------------------
    ('SUPER_ADMIN',  'POST', '/api/*/users/invite', 'ALLOW', 'core', 'users', 100,
     'Enviar invitación de usuario en cualquier tenant.',
     v_super_admin),
    ('TENANT_ADMIN', 'POST', '/api/*/users/invite', 'ALLOW', 'core', 'users', 100,
     'Enviar invitación de usuario en el propio tenant.',
     v_super_admin),

    -- -----------------------------------------------------------------
    -- GET /api/vN/users/invitations
    -- Listar invitaciones del tenant. Solo administradores.
    -- -----------------------------------------------------------------
    ('SUPER_ADMIN',  'GET', '/api/*/users/invitations', 'ALLOW', 'core', 'users', 100,
     'Listar invitaciones de cualquier tenant.',
     v_super_admin),
    ('TENANT_ADMIN', 'GET', '/api/*/users/invitations', 'ALLOW', 'core', 'users', 100,
     'Listar invitaciones del propio tenant.',
     v_super_admin),

    -- -----------------------------------------------------------------
    -- POST /api/vN/users/invitations/{id}/revoke
    -- Revocar una invitación pendiente. Solo administradores.
    -- -----------------------------------------------------------------
    ('SUPER_ADMIN',  'POST', '/api/*/users/invitations/*/revoke', 'ALLOW', 'core', 'users', 100,
     'Revocar invitación en cualquier tenant.',
     v_super_admin),
    ('TENANT_ADMIN', 'POST', '/api/*/users/invitations/*/revoke', 'ALLOW', 'core', 'users', 100,
     'Revocar invitación en el propio tenant.',
     v_super_admin),

    -- -----------------------------------------------------------------
    -- POST /api/vN/users/invitations/{id}/resend
    -- Reenviar una invitación. Solo administradores.
    -- -----------------------------------------------------------------
    ('SUPER_ADMIN',  'POST', '/api/*/users/invitations/*/resend', 'ALLOW', 'core', 'users', 100,
     'Reenviar invitación en cualquier tenant.',
     v_super_admin),
    ('TENANT_ADMIN', 'POST', '/api/*/users/invitations/*/resend', 'ALLOW', 'core', 'users', 100,
     'Reenviar invitación en el propio tenant.',
     v_super_admin);

-- =============================================================================
-- SECCIÓN 6: ROLES  /api/*/roles  (cubre v1, v2, …)
--
-- SUPER_ADMIN y TENANT_ADMIN gestionan roles.
-- EDITOR y VIEWER pueden leer la lista (para asignaciones de UI).
-- =============================================================================

    INSERT INTO nxc_tenant.role_api_policies
        (role_name, http_method, path_pattern, effect, service, module, priority, description, created_by)
    VALUES

    -- -----------------------------------------------------------------
    -- GET /api/vN/roles
    -- Listar roles del tenant. EDITOR y VIEWER necesitan esto para
    -- ver qué roles existen (aunque no puedan asignarlos).
    -- -----------------------------------------------------------------
    ('SUPER_ADMIN',  'GET', '/api/*/roles', 'ALLOW', 'core', 'roles', 100,
     'Listar roles de cualquier tenant.', v_super_admin),
    ('TENANT_ADMIN', 'GET', '/api/*/roles', 'ALLOW', 'core', 'roles', 100,
     'Listar roles del propio tenant.', v_super_admin),
    ('EDITOR',       'GET', '/api/*/roles', 'ALLOW', 'core', 'roles', 100,
     'Leer lista de roles del tenant (solo lectura).', v_super_admin),
    ('VIEWER',       'GET', '/api/*/roles', 'ALLOW', 'core', 'roles', 100,
     'Leer lista de roles del tenant (solo lectura).', v_super_admin),

    -- -----------------------------------------------------------------
    -- POST /api/vN/roles
    -- Crear rol personalizado. Solo administradores.
    -- -----------------------------------------------------------------
    ('SUPER_ADMIN',  'POST', '/api/*/roles', 'ALLOW', 'core', 'roles', 100,
     'Crear rol personalizado en cualquier tenant.', v_super_admin),
    ('TENANT_ADMIN', 'POST', '/api/*/roles', 'ALLOW', 'core', 'roles', 100,
     'Crear rol personalizado en el propio tenant.', v_super_admin),

    -- -----------------------------------------------------------------
    -- GET /api/vN/roles/{id}
    -- Ver detalle de un rol específico.
    -- -----------------------------------------------------------------
    ('SUPER_ADMIN',  'GET', '/api/*/roles/*', 'ALLOW', 'core', 'roles', 100,
     'Ver detalle de cualquier rol en cualquier tenant.', v_super_admin),
    ('TENANT_ADMIN', 'GET', '/api/*/roles/*', 'ALLOW', 'core', 'roles', 100,
     'Ver detalle de roles del propio tenant.', v_super_admin),
    ('EDITOR',       'GET', '/api/*/roles/*', 'ALLOW', 'core', 'roles', 100,
     'Ver detalle de roles del tenant (solo lectura).', v_super_admin),
    ('VIEWER',       'GET', '/api/*/roles/*', 'ALLOW', 'core', 'roles', 100,
     'Ver detalle de roles del tenant (solo lectura).', v_super_admin),

    -- -----------------------------------------------------------------
    -- PATCH /api/vN/roles/{id}
    -- Editar nombre/descripción del rol. Solo administradores.
    -- Los roles de sistema (TENANT_ADMIN, EDITOR, VIEWER) no son editables
    -- (validado en la capa de negocio, no aquí).
    -- -----------------------------------------------------------------
    ('SUPER_ADMIN',  'PATCH', '/api/*/roles/*', 'ALLOW', 'core', 'roles', 100,
     'Editar roles personalizados en cualquier tenant.', v_super_admin),
    ('TENANT_ADMIN', 'PATCH', '/api/*/roles/*', 'ALLOW', 'core', 'roles', 100,
     'Editar roles personalizados del propio tenant.', v_super_admin),

    -- -----------------------------------------------------------------
    -- DELETE /api/vN/roles/{id}
    -- Eliminar rol. Falla si tiene usuarios asignados o es de sistema.
    -- -----------------------------------------------------------------
    ('SUPER_ADMIN',  'DELETE', '/api/*/roles/*', 'ALLOW', 'core', 'roles', 100,
     'Eliminar rol personalizado en cualquier tenant.', v_super_admin),
    ('TENANT_ADMIN', 'DELETE', '/api/*/roles/*', 'ALLOW', 'core', 'roles', 100,
     'Eliminar rol personalizado del propio tenant.', v_super_admin);

-- =============================================================================
-- SECCIÓN 7: COMPONENTES UI  /api/*/menu/components  (cubre v1, v2, …)
--
-- Endpoints de solo lectura (los componentes se registran por seed/script).
-- TENANT_ADMIN los necesita para administrar los permisos por rol.
-- =============================================================================

    INSERT INTO nxc_tenant.role_api_policies
        (role_name, http_method, path_pattern, effect, service, module, priority, description, created_by)
    VALUES

    -- -----------------------------------------------------------------
    -- GET /api/vN/menu/components
    -- Lista paginada de componentes del tenant. Solo admins.
    -- -----------------------------------------------------------------
    ('SUPER_ADMIN',  'GET', '/api/*/menu/components', 'ALLOW', 'core', 'components', 100,
     'Listar componentes de UI de cualquier tenant.', v_super_admin),
    ('TENANT_ADMIN', 'GET', '/api/*/menu/components', 'ALLOW', 'core', 'components', 100,
     'Listar componentes de UI del propio tenant.', v_super_admin),

    -- -----------------------------------------------------------------
    -- GET /api/vN/menu/components/{componentId}
    -- Detalle del componente con sus elementos.
    -- -----------------------------------------------------------------
    ('SUPER_ADMIN',  'GET', '/api/*/menu/components/*', 'ALLOW', 'core', 'components', 100,
     'Ver detalle de cualquier componente de UI.', v_super_admin),
    ('TENANT_ADMIN', 'GET', '/api/*/menu/components/*', 'ALLOW', 'core', 'components', 100,
     'Ver detalle de un componente de UI del propio tenant.', v_super_admin),

    -- -----------------------------------------------------------------
    -- GET /api/vN/menu/components/{componentId}/elements
    -- Lista de elementos de UI del componente (botones, tabs, etc.).
    -- -----------------------------------------------------------------
    ('SUPER_ADMIN',  'GET', '/api/*/menu/components/*/elements', 'ALLOW', 'core', 'components', 100,
     'Listar elementos de UI de cualquier componente.', v_super_admin),
    ('TENANT_ADMIN', 'GET', '/api/*/menu/components/*/elements', 'ALLOW', 'core', 'components', 100,
     'Listar elementos de UI de componentes del propio tenant.', v_super_admin);

-- =============================================================================
-- SECCIÓN 8: PERMISOS POR ROL  /api/*/menu/permissions  (cubre v1, v2, …)
--
-- Gestión de la matriz de permisos (componente_permissions, element_permissions).
-- Solo administradores (SUPER_ADMIN y TENANT_ADMIN).
-- =============================================================================

    INSERT INTO nxc_tenant.role_api_policies
        (role_name, http_method, path_pattern, effect, service, module, priority, description, created_by)
    VALUES

    -- -----------------------------------------------------------------
    -- GET /api/vN/menu/permissions/roles/{roleId}
    -- Obtener la matriz completa de permisos de un rol.
    -- Alimenta la pantalla de configuración de permisos en el frontend.
    -- -----------------------------------------------------------------
    ('SUPER_ADMIN',  'GET', '/api/*/menu/permissions/roles/*', 'ALLOW', 'core', 'permissions', 100,
     'Ver matriz de permisos de cualquier rol.', v_super_admin),
    ('TENANT_ADMIN', 'GET', '/api/*/menu/permissions/roles/*', 'ALLOW', 'core', 'permissions', 100,
     'Ver matriz de permisos de roles del propio tenant.', v_super_admin),

    -- -----------------------------------------------------------------
    -- PUT /api/vN/menu/permissions/roles/{roleId}/components/{componentId}
    -- Upsert del permiso de un rol sobre un componente.
    -- -----------------------------------------------------------------
    ('SUPER_ADMIN',  'PUT', '/api/*/menu/permissions/roles/*/components/*', 'ALLOW', 'core', 'permissions', 100,
     'Asignar permiso de cualquier rol sobre cualquier componente.', v_super_admin),
    ('TENANT_ADMIN', 'PUT', '/api/*/menu/permissions/roles/*/components/*', 'ALLOW', 'core', 'permissions', 100,
     'Asignar permiso de roles del propio tenant sobre componentes.', v_super_admin),

    -- -----------------------------------------------------------------
    -- PUT /api/vN/menu/permissions/roles/{roleId}/components/batch
    -- Upsert batch de permisos (múltiples componentes en una transacción).
    -- -----------------------------------------------------------------
    ('SUPER_ADMIN',  'PUT', '/api/*/menu/permissions/roles/*/components/batch', 'ALLOW', 'core', 'permissions', 100,
     'Asignar permisos en batch sobre múltiples componentes (máx 100).', v_super_admin),
    ('TENANT_ADMIN', 'PUT', '/api/*/menu/permissions/roles/*/components/batch', 'ALLOW', 'core', 'permissions', 100,
     'Asignar permisos en batch sobre componentes del propio tenant.', v_super_admin),

    -- -----------------------------------------------------------------
    -- PUT /api/vN/menu/permissions/roles/{roleId}/elements/{elementId}
    -- Upsert granular del permiso de un rol sobre un elemento de UI.
    -- -----------------------------------------------------------------
    ('SUPER_ADMIN',  'PUT', '/api/*/menu/permissions/roles/*/elements/*', 'ALLOW', 'core', 'permissions', 100,
     'Asignar permiso granular de un rol sobre un elemento de UI.', v_super_admin),
    ('TENANT_ADMIN', 'PUT', '/api/*/menu/permissions/roles/*/elements/*', 'ALLOW', 'core', 'permissions', 100,
     'Asignar permiso granular de roles del propio tenant sobre elementos.', v_super_admin);

-- =============================================================================
-- SECCIÓN 9: DENY EXPLÍCITOS
--
-- Políticas de denegación de alta prioridad que anulan los ALLOW anteriores.
-- Ejemplos de uso: bloquear operaciones destructivas para ciertos roles,
-- incluso si tienen un ALLOW general.
-- =============================================================================

    INSERT INTO nxc_tenant.role_api_policies
        (role_name, http_method, path_pattern, effect, service, module, priority, description, created_by)
    VALUES

    -- -----------------------------------------------------------------
    -- DENY: el EDITOR no puede suspender/activar/eliminar usuarios
    -- aunque tenga ALLOW en /api/*/users/*/... general.
    -- Nota: en este seed, EDITOR no tiene esos ALLOW, pero los DENY
    -- se agregan como salvaguarda explícita.
    -- -----------------------------------------------------------------
    ('EDITOR', 'POST',   '/api/*/users/*/suspend',  'DENY', 'core', 'users', 500,
     'DENY explícito: EDITOR no puede suspender usuarios bajo ninguna circunstancia.',
     v_super_admin),
    ('EDITOR', 'POST',   '/api/*/users/*/activate', 'DENY', 'core', 'users', 500,
     'DENY explícito: EDITOR no puede reactivar usuarios.',
     v_super_admin),
    ('EDITOR', 'DELETE', '/api/*/users/*',           'DENY', 'core', 'users', 500,
     'DENY explícito: EDITOR no puede eliminar usuarios.',
     v_super_admin),

    -- -----------------------------------------------------------------
    -- DENY: el VIEWER no puede modificar nada
    -- Bloqueo general para cualquier operación de escritura del VIEWER.
    -- El patrón /api/** cubre CUALQUIER versión (/api/v1/, /api/v2/, etc.)
    -- porque ** abarca múltiples segmentos incluyendo el de versión.
    -- -----------------------------------------------------------------
    ('VIEWER', 'POST',   '/api/**', 'DENY', 'core', 'general', 500,
     'DENY general: VIEWER no puede ejecutar ningún POST en nexcore-core (cualquier versión).',
     v_super_admin),
    ('VIEWER', 'PUT',    '/api/**', 'DENY', 'core', 'general', 500,
     'DENY general: VIEWER no puede ejecutar ningún PUT en nexcore-core (cualquier versión).',
     v_super_admin),
    ('VIEWER', 'PATCH',  '/api/**', 'DENY', 'core', 'general', 500,
     'DENY general: VIEWER no puede ejecutar ningún PATCH en nexcore-core (cualquier versión).',
     v_super_admin),
    ('VIEWER', 'DELETE', '/api/**', 'DENY', 'core', 'general', 500,
     'DENY general: VIEWER no puede ejecutar ningún DELETE en nexcore-core (cualquier versión).',
     v_super_admin);

    RAISE NOTICE 'Seed completado.';
    RAISE NOTICE '  Registros insertados: %',
        (SELECT COUNT(*) FROM nxc_tenant.role_api_policies);

END $$;

-- =============================================================================
-- VERIFICACIÓN POST-SEED
-- Ejecutar estas queries por separado después del seed para validar los datos.
-- =============================================================================

-- Total de políticas por módulo, rol y efecto
-- SELECT module, role_name, effect, service, COUNT(*) AS total
-- FROM nxc_tenant.role_api_policies
-- GROUP BY module, role_name, effect, service
-- ORDER BY module, role_name, service, effect;

-- Todas las políticas del TENANT_ADMIN en core
-- SELECT module, http_method, path_pattern, effect, priority, description
-- FROM nxc_tenant.role_api_policies
-- WHERE role_name = 'TENANT_ADMIN' AND service = 'core'
-- ORDER BY module, priority DESC, path_pattern;

-- Políticas DENY (las más críticas de revisar)
-- SELECT module, role_name, http_method, path_pattern, priority, description
-- FROM nxc_tenant.role_api_policies
-- WHERE effect = 'DENY'
-- ORDER BY module, priority DESC;

-- Todas las políticas de un módulo específico
-- SELECT role_name, http_method, path_pattern, effect, priority
-- FROM nxc_tenant.role_api_policies
-- WHERE module = 'users' AND service = 'core'
-- ORDER BY path_pattern, role_name;

-- Simulación: ¿puede EDITOR hacer POST /api/v1/users/abc123/suspend?
-- SELECT module, role_name, http_method, path_pattern, effect, priority
-- FROM nxc_tenant.role_api_policies
-- WHERE role_name IN ('EDITOR', '*')
--   AND service = 'core'
--   AND http_method IN ('POST', '*')
-- ORDER BY priority DESC;

-- =============================================================================
-- FIN — 07-seed-role-api-policies.sql
-- =============================================================================
