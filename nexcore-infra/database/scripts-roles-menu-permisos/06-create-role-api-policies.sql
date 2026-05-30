-- =============================================================================
-- NexCore Platform — role_api_policies DDL
-- Script: 06-create-role-api-policies.sql
--
-- PROPÓSITO:
--   Crear la tabla nxc_tenant.role_api_policies que almacena las políticas
--   de acceso a la API REST por nombre de rol.
--
-- SCHEMA: nxc_tenant  (no nxc_menu)
--   nxc_tenant agrupa todo lo relacionado con identidad y autorización:
--   tenants, users, roles, user_roles → y ahora role_api_policies.
--   nxc_menu es para navegación y visibilidad de UI (component_permissions,
--   menu_items, etc.), que es una capa distinta.
--
-- =============================================================================
-- DECISIONES DE DISEÑO
-- =============================================================================
--
-- 1. POR QUÉ role_name (TEXT) y no role_id (UUID)
-- ─────────────────────────────────────────────────
--   Los roles TENANT_ADMIN, EDITOR y VIEWER se crean automáticamente por
--   trigger en cada INSERT de tenant. Cada tenant tiene su propio UUID para
--   el mismo rol semántico:
--
--     Tenant A → TENANT_ADMIN UUID: aaa-111
--     Tenant B → TENANT_ADMIN UUID: bbb-222
--
--   Usar role_id requeriría una fila por tenant. Usar role_name cubre todos
--   los tenants con una sola política. Es coherente con nxc_tenant.roles.name
--   como clave de negocio.
--
-- 2. POR QUÉ SIN tenant_id (políticas globales)
-- ──────────────────────────────────────────────
--   Las políticas de API definen el contrato de seguridad de la PLATAFORMA,
--   no de cada tenant. Que un TENANT_ADMIN pueda llamar a PATCH /api/*/users/*
--   es igual en todos los tenants — la diferenciación de datos entre tenants
--   ocurre en otras capas:
--
--     · RLS en PostgreSQL       → filtra por tenant_id en cada tabla
--     · Business logic          → X-Tenant-Id limita qué datos ve cada tenant
--     · component_permissions   → personaliza visibilidad de UI por tenant
--
--   Si un tenant necesita restricciones especiales de API, se resuelve con
--   tenant_feature_flags, no con políticas de API por tenant.
--
-- 3. DIFERENCIA CON component_permissions (dos capas distintas)
-- ──────────────────────────────────────────────────────────────
--   ┌──────────────────────┬──────────────────────────────────────────────┐
--   │ component_permissions│ role_api_policies                            │
--   ├──────────────────────┼──────────────────────────────────────────────┤
--   │ Controla VISIBILIDAD │ Controla AUTORIZACIÓN en la API              │
--   │ en la UI             │                                              │
--   │ Usa role_id UUID     │ Usa role_name TEXT                           │
--   │ (específico/tenant)  │ (global para todos los tenants)              │
--   │ TENANT_ADMIN gestiona│ Solo SUPER_ADMIN puede modificar             │
--   │ por tenant           │ (vía scripts; RLS is_system_admin())         │
--   └──────────────────────┴──────────────────────────────────────────────┘
--
--   La UI puede ser más restrictiva que la API (ocultar un botón no implica
--   que la API lo bloquee). La seguridad real vive en la API.
--
-- 4. CAMPO module (organizativo, no afecta evaluación)
-- ──────────────────────────────────────────────────────
--   Agrupa políticas por dominio de negocio para facilitar consultas de
--   administración y auditoría de seguridad:
--     auth | profile | tenants | users | roles | components | permissions | general
--
--   El interceptor NO filtra por module. Es solo para la UI de admin y reportes.
--
-- 5. CACHÉ EN REDIS
-- ─────────────────
--   El interceptor carga las políticas UNA VEZ por combinación de roles
--   y las guarda en Redis (compartido entre instancias). TTL recomendado: 5 min.
--
--   Cache key: "service::role1,role2"  (roles ordenados alfabéticamente)
--     "core::EDITOR,TENANT_ADMIN"
--     "core::SUPER_ADMIN"
--     "auth::TENANT_ADMIN"
--
--   La BD solo se consulta en el primer request de cada combinación y al
--   expirar el TTL. No hay query a BD en cada petición HTTP.
--
-- =============================================================================
--
-- PREREQUISITO: schema-nexcore.sql debe haber sido ejecutado primero.
--   El schema nxc_tenant debe existir con sus funciones RLS.
--
-- EJECUCIÓN MANUAL:
--   1. Conectarse a la BD con psql o DBeaver.
--   2. Asegurarse de estar en la BD correcta (nexcore_db).
--   3. Ejecutar este script completo (F5 en DBeaver o \i en psql).
--   4. Luego ejecutar 07-seed-role-api-policies.sql para cargar las políticas.
--   5. Verificar con: SELECT * FROM nxc_tenant.role_api_policies LIMIT 5;
-- =============================================================================

-- ---------------------------------------------------------------------------
-- TABLA: role_api_policies
-- Almacena una regla por fila: "el rol X puede/no puede llamar al
-- método HTTP M sobre el path P del servicio S".
--
-- SEMÁNTICA:
--   · Si el usuario tiene al menos un rol que coincide con una política ALLOW
--     y ningún rol que coincide con una política DENY de mayor prioridad → ALLOW.
--   · Si no hay ninguna política que aplique → DENY implícito (fail-closed).
--   · Las políticas con effect='DENY' y mayor priority ganan sobre los ALLOW.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS nxc_tenant.role_api_policies (

    id            UUID          PRIMARY KEY DEFAULT gen_random_uuid(),

    -- -------------------------------------------------------------------------
    -- role_name: nombre del rol al que aplica esta política.
    --
    -- Valores válidos:
    --   SUPER_ADMIN   → solo el admin de la plataforma (tenant system)
    --   TENANT_ADMIN  → admin de cualquier tenant
    --   EDITOR        → editor de cualquier tenant
    --   VIEWER        → viewer de cualquier tenant
    --   *             → cualquier usuario autenticado (sin importar su rol)
    --
    -- IMPORTANTE: usa nombre (TEXT), no UUID, porque los roles TENANT_ADMIN,
    -- EDITOR, VIEWER existen con diferentes UUIDs en cada tenant. Usar el nombre
    -- permite definir la política una sola vez para todos los tenants.
    -- Coherente con nxc_tenant.roles.name que ya es la clave de negocio del rol.
    -- -------------------------------------------------------------------------
    role_name     VARCHAR(100)  NOT NULL,

    -- -------------------------------------------------------------------------
    -- http_method: verbo HTTP al que aplica esta política.
    --
    -- Valores: GET | POST | PUT | PATCH | DELETE | * (cualquier verbo)
    --
    -- Si http_method = '*' la política aplica sin importar el verbo.
    -- Se recomienda ser explícito (no usar * en prod) para evitar sobre-permisos.
    -- -------------------------------------------------------------------------
    http_method   VARCHAR(10)   NOT NULL DEFAULT '*',

    -- -------------------------------------------------------------------------
    -- path_pattern: patrón del path de la URL.
    --
    -- Usa sintaxis compatible con Spring PathPatternParser.
    -- El segmento de versión (v1, v2…) se escribe siempre como * para que
    -- la política cubra cualquier versión presente y futura de la API:
    --
    --   /api/*/users           → /api/v1/users, /api/v2/users, etc.
    --   /api/*/users/*         → un segmento variable (/{id})
    --   /api/*/users/**        → cualquier subruta (/{id}/roles, etc.)
    --   /api/*/users/*/suspend → variable en el medio + sufijo exacto
    --   /api/**                → cualquier path bajo /api/ (DENY globales)
    --
    -- Evaluación: el interceptor ordena las políticas por especificidad
    -- (más larga gana) antes de evaluar. Si hay empate, priority desempata.
    -- -------------------------------------------------------------------------
    path_pattern  VARCHAR(500)  NOT NULL,

    -- -------------------------------------------------------------------------
    -- effect: resultado de la política cuando hay match.
    --
    --   ALLOW → acceso permitido
    --   DENY  → acceso denegado (tiene precedencia sobre ALLOW)
    --
    -- Regla de oro: "deny explícito gana sobre allow explícito".
    -- -------------------------------------------------------------------------
    effect        VARCHAR(5)    NOT NULL DEFAULT 'ALLOW'
                  CHECK (effect IN ('ALLOW', 'DENY')),

    -- -------------------------------------------------------------------------
    -- service: a qué microservicio aplica esta política.
    --
    --   core  → nexcore-core (puerto 8080)
    --   auth  → nexcore-auth-service (puerto 8081)
    --
    -- El interceptor lee su propio nombre de servicio desde application.yml
    -- y solo carga las políticas donde service = su nombre.
    -- -------------------------------------------------------------------------
    service       VARCHAR(20)   NOT NULL DEFAULT 'core'
                  CHECK (service IN ('core', 'auth')),

    -- -------------------------------------------------------------------------
    -- module: módulo de negocio al que pertenece la política.
    --
    -- Permite agrupar y filtrar políticas por dominio:
    --   auth        → endpoints de autenticación (nexcore-auth-service)
    --   profile     → perfil del usuario (/me/profile)
    --   tenants     → gestión de tenants
    --   users       → gestión de usuarios e invitaciones
    --   roles       → gestión de roles
    --   components  → componentes de UI (/menu/components)
    --   permissions → matriz de permisos por rol (/menu/permissions)
    --   general     → políticas transversales / fallback
    --
    -- No afecta la evaluación de la política (solo es organizativo).
    -- Útil para la UI de administración y para reportes de seguridad.
    -- -------------------------------------------------------------------------
    module        VARCHAR(50)   NOT NULL DEFAULT 'general',

    -- -------------------------------------------------------------------------
    -- priority: orden de evaluación cuando múltiples reglas coinciden.
    --
    -- Rango recomendado: 1–999 (mayor número = mayor prioridad).
    --   100 → políticas de ALLOW generales
    --   500 → políticas de DENY específicas (anulan ALLOW)
    --   900 → políticas de emergencia / bloqueo total
    -- -------------------------------------------------------------------------
    priority      INTEGER       NOT NULL DEFAULT 100,

    -- -------------------------------------------------------------------------
    -- description: documentación del por qué existe esta política.
    --
    -- Obligatorio en revisiones de seguridad. Debe explicar el motivo
    -- de negocio, no solo "ALLOW para EDITOR".
    -- -------------------------------------------------------------------------
    description   VARCHAR(500),

    -- Auditoría
    created_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    created_by    UUID          REFERENCES nxc_tenant.users(id),

    -- Un rol no puede tener dos políticas iguales para el mismo método+path+servicio
    UNIQUE (role_name, http_method, path_pattern, service)
);

-- ---------------------------------------------------------------------------
-- Índices de consulta
--
-- El interceptor consulta frecuentemente:
--   SELECT * FROM nxc_tenant.role_api_policies
--   WHERE service = 'core'
--     AND role_name IN ('TENANT_ADMIN', 'EDITOR')
--   ORDER BY priority DESC
--
-- El índice compuesto (service, role_name) cubre este patrón.
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS ix_role_api_policies_service_role
    ON nxc_tenant.role_api_policies (service, role_name);

-- Índice adicional para consultas de solo path (diagnóstico / admin UI)
CREATE INDEX IF NOT EXISTS ix_role_api_policies_path
    ON nxc_tenant.role_api_policies (path_pattern);

-- Índice para filtrar por módulo (admin UI y reportes de seguridad)
CREATE INDEX IF NOT EXISTS ix_role_api_policies_module
    ON nxc_tenant.role_api_policies (module);

-- ---------------------------------------------------------------------------
-- Row-Level Security (RLS)
--
-- A diferencia de las otras tablas de nxc_tenant, role_api_policies NO tiene
-- tenant_id (las políticas son globales por nombre de rol).
-- La política es:
--   · SELECT: cualquier conexión puede leer (el interceptor las necesita).
--   · INSERT/UPDATE/DELETE: solo el sistema (is_system_admin).
-- ---------------------------------------------------------------------------
ALTER TABLE nxc_tenant.role_api_policies ENABLE ROW LEVEL SECURITY;

-- Lectura libre: el interceptor lee estas políticas en cada request
DROP POLICY IF EXISTS rls_api_policies_read ON nxc_tenant.role_api_policies;
CREATE POLICY rls_api_policies_read ON nxc_tenant.role_api_policies
    FOR SELECT
    USING (TRUE);

-- Escritura solo para el administrador de la plataforma
-- Las modificaciones se hacen via scripts SQL controlados, no via API pública.
DROP POLICY IF EXISTS rls_api_policies_write ON nxc_tenant.role_api_policies;
CREATE POLICY rls_api_policies_write ON nxc_tenant.role_api_policies
    FOR ALL
    USING (nxc_tenant.is_system_admin());

-- ---------------------------------------------------------------------------
-- Trigger: actualizar updated_at automáticamente
--
-- Reutiliza la función fn_set_updated_at() definida en nxc_tenant.
-- ---------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_updated_at ON nxc_tenant.role_api_policies;
CREATE TRIGGER trg_updated_at
    BEFORE UPDATE ON nxc_tenant.role_api_policies
    FOR EACH ROW EXECUTE FUNCTION nxc_tenant.fn_set_updated_at();

-- ---------------------------------------------------------------------------
-- Comentarios de tabla y columnas
-- ---------------------------------------------------------------------------
COMMENT ON TABLE nxc_tenant.role_api_policies IS
    'Políticas de autorización HTTP por nombre de rol. '
    'Vive en nxc_tenant porque es autorización (igual que roles/user_roles), '
    'no visibilidad de UI (que va en nxc_menu). '
    'Aplica globalmente para todos los tenants que tengan un rol con ese nombre. '
    'Evaluación fail-closed: sin política → DENY implícito.';

COMMENT ON COLUMN nxc_tenant.role_api_policies.role_name IS
    'Nombre del rol (coincide con nxc_tenant.roles.name). '
    'Usar * para cualquier usuario autenticado. '
    'No usa UUID porque roles como TENANT_ADMIN tienen distintos UUIDs por tenant.';

COMMENT ON COLUMN nxc_tenant.role_api_policies.http_method IS
    'Verbo HTTP: GET | POST | PUT | PATCH | DELETE | * (cualquier verbo).';

COMMENT ON COLUMN nxc_tenant.role_api_policies.path_pattern IS
    'Patrón del path compatible con Spring PathPatternParser. '
    'El segmento de versión se escribe como * (/api/*/users) para cubrir v1, v2, etc.';

COMMENT ON COLUMN nxc_tenant.role_api_policies.effect IS
    'ALLOW = acceso permitido. DENY = acceso denegado. '
    'DENY con mayor priority tiene precedencia sobre ALLOW.';

COMMENT ON COLUMN nxc_tenant.role_api_policies.service IS
    'Microservicio al que aplica: core (8080) o auth (8081).';

COMMENT ON COLUMN nxc_tenant.role_api_policies.module IS
    'Módulo de negocio: auth | profile | tenants | users | roles | components | permissions | general. '
    'Puramente organizativo; no afecta la evaluación de la política.';

COMMENT ON COLUMN nxc_tenant.role_api_policies.priority IS
    'Prioridad de evaluación. Mayor número = se evalúa primero. '
    'Usar 100 para ALLOW generales, 500 para DENY específicos.';

-- ---------------------------------------------------------------------------
-- Verificación post-creación
-- Descomentar para confirmar que la tabla se creó correctamente.
-- ---------------------------------------------------------------------------
-- SELECT
--     table_schema,
--     table_name,
--     (SELECT COUNT(*) FROM nxc_tenant.role_api_policies) AS row_count
-- FROM information_schema.tables
-- WHERE table_schema = 'nxc_tenant'
--   AND table_name = 'role_api_policies';

-- =============================================================================
-- FIN — 06-create-role-api-policies.sql
-- =============================================================================
