-- =============================================================================
-- NexCore Platform  –  PostgreSQL Schema  v2.0
-- Modelo B: el usuario pertenece al tenant (identidad local)
-- Un usuario existe dentro de exactamente un tenant.
-- El SUPER_ADMIN del sistema es un usuario del tenant especial 'system'.
--
-- Schemas: nxc_tenant | nxc_menu | nxc_preference | nxc_config | nxc_auth
-- =============================================================================
-- CONVENCIONES
--   · PKs: UUID con gen_random_uuid()
--   · Toda tabla de negocio lleva: tenant_id, created_at, updated_at,
--     created_by, updated_by, deleted_at (soft delete), version (optimistic lock)
--   · Email/username únicos POR TENANT, no globalmente
--   · Row-Level Security (RLS) activo en todas las tablas de negocio
--   · La auditoría de cambios va a MongoDB vía Kafka (no en este schema)
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 0. Extensiones
-- ---------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "pgcrypto";   -- gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS "pg_trgm";    -- índices GIN para búsqueda ILIKE

-- ---------------------------------------------------------------------------
-- 1. Schemas
-- ---------------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS nxc_tenant;
CREATE SCHEMA IF NOT EXISTS nxc_auth;
CREATE SCHEMA IF NOT EXISTS nxc_menu;
CREATE SCHEMA IF NOT EXISTS nxc_preference;
CREATE SCHEMA IF NOT EXISTS nxc_config;

-- =============================================================================
-- 2. TIPOS ENUM
-- =============================================================================
DO $$ BEGIN

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'tenant_status') THEN
        CREATE TYPE nxc_tenant.tenant_status AS ENUM (
            'TRIAL',        -- período de prueba
            'ACTIVE',       -- cuenta activa y pagada
            'SUSPENDED',    -- suspendida por impago u otra razón
            'CANCELLED'     -- cancelada definitivamente
        );
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'tenant_plan') THEN
        CREATE TYPE nxc_tenant.tenant_plan AS ENUM (
            'FREE',
            'STARTER',
            'PROFESSIONAL',
            'ENTERPRISE'
        );
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'tenant_mode') THEN
        CREATE TYPE nxc_tenant.tenant_mode AS ENUM (
            'SAAS_SHARED',      -- infraestructura compartida (SaaS estándar)
            'SAAS_DEDICATED',   -- infraestructura dedicada dentro de la plataforma
            'ON_PREMISE'        -- instancia única para un solo cliente
        );
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_status') THEN
        CREATE TYPE nxc_tenant.user_status AS ENUM (
            'PENDING_ACTIVATION',   -- invitado, aún no activó su cuenta
            'ACTIVE',               -- activo y puede ingresar
            'SUSPENDED',            -- suspendido por el admin del tenant
            'BLOCKED',              -- bloqueado por intentos fallidos de login
            'DELETED'               -- eliminado con soft delete
        );
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'access_level') THEN
        CREATE TYPE nxc_menu.access_level AS ENUM (
            'HIDDEN',       -- no visible en la interfaz
            'VIEW',         -- visible pero deshabilitado (solo lectura)
            'EXECUTE'       -- visible y habilitado (puede operar)
        );
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'menu_item_type') THEN
        CREATE TYPE nxc_menu.menu_item_type AS ENUM (
            'GROUP',            -- agrupador sin ruta propia
            'ITEM',             -- ítem navegable con ruta
            'DIVIDER',          -- separador visual
            'EXTERNAL_LINK'     -- enlace externo (abre nueva pestaña)
        );
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'menu_location') THEN
        CREATE TYPE nxc_menu.menu_location AS ENUM (
            'navbar',           -- barra de navegación principal
            'sidebar',          -- panel lateral
            'header-dropdown',  -- menú desplegable del header (perfil, ajustes, logout)
            'footer',           -- pie de página
            'internal'          -- uso interno, no visible en la navegación principal
        );
    END IF;

END $$;

-- =============================================================================
-- SCHEMA: nxc_tenant
-- Tenants, usuarios (por tenant), roles y permisos
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 3. tenants
--    Raíz del modelo. Cada empresa cliente es un tenant.
--    El tenant especial slug='system' es para el SUPER_ADMIN de la plataforma.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS nxc_tenant.tenants (
    id                      UUID                        PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Identificación
    slug                    VARCHAR(100)                NOT NULL,   -- 'acme-corp' (URL-safe, inmutable)
    name                    VARCHAR(200)                NOT NULL,   -- "Acme Corporation"
    legal_name              VARCHAR(300),                           -- razón social
    tax_id                  VARCHAR(50),                            -- NIT / RUT / RFC

    -- Plan y modo de despliegue
    plan                    nxc_tenant.tenant_plan      NOT NULL DEFAULT 'FREE',
    mode                    nxc_tenant.tenant_mode      NOT NULL DEFAULT 'SAAS_SHARED',
    status                  nxc_tenant.tenant_status    NOT NULL DEFAULT 'TRIAL',

    -- Identidad visual
    logo_url                VARCHAR(500),
    primary_color           VARCHAR(7),                             -- #RRGGBB
    custom_domain           VARCHAR(255),                           -- portal.acme.com (subdominio propio)

    -- Localización del tenant (los usuarios pueden sobreescribir esto en sus preferencias)
    timezone                VARCHAR(50)                 NOT NULL DEFAULT 'UTC',
    locale                  VARCHAR(10)                 NOT NULL DEFAULT 'es-CO',
    date_format             VARCHAR(30)                 NOT NULL DEFAULT 'DD/MM/YYYY',
    currency                VARCHAR(3)                  NOT NULL DEFAULT 'COP',

    -- Políticas de seguridad configurables por tenant
    mfa_required            BOOLEAN                     NOT NULL DEFAULT FALSE,
    session_timeout_minutes INTEGER                     NOT NULL DEFAULT 480,
    max_login_attempts      INTEGER                     NOT NULL DEFAULT 5,
    password_min_length     INTEGER                     NOT NULL DEFAULT 8,
    password_requires_upper BOOLEAN                     NOT NULL DEFAULT FALSE,
    password_requires_special BOOLEAN                   NOT NULL DEFAULT FALSE,
    password_expiry_days    INTEGER,                               -- NULL = nunca expira

    -- Límites del plan
    max_users               INTEGER,                               -- NULL = sin límite
    audit_retention_days    INTEGER                     NOT NULL DEFAULT 90,

    -- Suscripción / licencia
    trial_ends_at           TIMESTAMPTZ,
    subscription_ends_at    TIMESTAMPTZ,

    -- Auditoría de la tabla
    created_at              TIMESTAMPTZ                 NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ                 NOT NULL DEFAULT NOW(),
    deleted_at              TIMESTAMPTZ,
    version                 INTEGER                     NOT NULL DEFAULT 0
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_tenants_slug
    ON nxc_tenant.tenants (slug)
    WHERE deleted_at IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_tenants_custom_domain
    ON nxc_tenant.tenants (custom_domain)
    WHERE custom_domain IS NOT NULL AND deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS ix_tenants_status
    ON nxc_tenant.tenants (status)
    WHERE deleted_at IS NULL;

COMMENT ON TABLE  nxc_tenant.tenants IS
    'Empresa cliente que contrata el sistema. Raíz del aislamiento multi-tenant.';
COMMENT ON COLUMN nxc_tenant.tenants.slug IS
    'Identificador URL-safe e inmutable. Se usa en subdominios (acme.nexcore.io) y en el JWT.';
COMMENT ON COLUMN nxc_tenant.tenants.mode IS
    'SAAS_SHARED: infraestructura compartida. ON_PREMISE: instancia única para un solo cliente.';
COMMENT ON COLUMN nxc_tenant.tenants.custom_domain IS
    'Si el cliente configura su propio dominio (portal.acme.com), se almacena aquí para el routing del gateway.';

-- ---------------------------------------------------------------------------
-- 4. users
--    MODELO B: el usuario pertenece a exactamente un tenant.
--    Email y username son únicos DENTRO del tenant, no globalmente.
--    El SUPER_ADMIN de la plataforma es un usuario del tenant 'system'.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS nxc_tenant.users (
    id                  UUID                        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id           UUID                        NOT NULL
                            REFERENCES nxc_tenant.tenants(id) ON DELETE CASCADE,

    -- Credenciales
    username            VARCHAR(100)                NOT NULL,
    email               VARCHAR(200)                NOT NULL,
    password_hash       VARCHAR(255)                NOT NULL,

    -- Perfil
    full_name           VARCHAR(200),
    phone               VARCHAR(30),
    photo_url           VARCHAR(500),
    observaciones       VARCHAR(3000),

    -- Estado dentro de su tenant
    status              nxc_tenant.user_status      NOT NULL DEFAULT 'PENDING_ACTIVATION',
    is_tenant_admin     BOOLEAN                     NOT NULL DEFAULT FALSE,
                            -- TRUE: puede gestionar usuarios y roles del tenant.
                            -- Distinto del SUPER_ADMIN de la plataforma.

    -- Verificación de email
    email_verified      BOOLEAN                     NOT NULL DEFAULT FALSE,
    email_verified_at   TIMESTAMPTZ,

    -- Autenticación de dos factores (TOTP)
    totp_secret         VARCHAR(255),               -- secret cifrado en la app (no en texto plano en DB)
    totp_enabled        BOOLEAN                     NOT NULL DEFAULT FALSE,
    totp_backup_codes   JSONB,                      -- array de códigos de recuperación (hashed)

    -- Temporal 2FA (código de email / SMS antes de activar TOTP)
    temporal_code       VARCHAR(50),                -- código 2FA de uso único
    temporal_code_expires_at TIMESTAMPTZ,           -- expiración del código

    -- Invitación
    invited_by          UUID                        REFERENCES nxc_tenant.users(id),
    invited_at          TIMESTAMPTZ,
    activated_at        TIMESTAMPTZ,                -- momento en que aceptó la invitación

    -- Último acceso
    last_login_at       TIMESTAMPTZ,
    last_login_ip       VARCHAR(45),

    -- Auditoría de la fila
    created_at          TIMESTAMPTZ                 NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ                 NOT NULL DEFAULT NOW(),
    created_by          UUID                        REFERENCES nxc_tenant.users(id),
    updated_by          UUID                        REFERENCES nxc_tenant.users(id),
    deleted_at          TIMESTAMPTZ,
    version             INTEGER                     NOT NULL DEFAULT 0,

    -- Unicidad DENTRO del tenant (no globalmente)
    UNIQUE (tenant_id, email),
    UNIQUE (tenant_id, username)
);

CREATE INDEX IF NOT EXISTS ix_users_tenant_status
    ON nxc_tenant.users (tenant_id, status)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS ix_users_email_trgm
    ON nxc_tenant.users USING GIN (email gin_trgm_ops);

CREATE INDEX IF NOT EXISTS ix_users_full_name_trgm
    ON nxc_tenant.users USING GIN (full_name gin_trgm_ops);

COMMENT ON TABLE  nxc_tenant.users IS
    'Usuario que pertenece a exactamente un tenant. Email y username son únicos por tenant, no globalmente.';
COMMENT ON COLUMN nxc_tenant.users.is_tenant_admin IS
    'Si TRUE, puede gestionar usuarios y roles de su propio tenant. No tiene acceso a otros tenants.';
COMMENT ON COLUMN nxc_tenant.users.totp_secret IS
    'El secret TOTP debe cifrarse a nivel de aplicación antes de persistir. Nunca se almacena en texto plano.';

-- ---------------------------------------------------------------------------
-- 5. roles
--    Roles definidos dentro de un tenant.
--    Los roles base (TENANT_ADMIN, EDITOR, VIEWER) se crean automáticamente
--    via trigger cuando se inserta un nuevo tenant.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS nxc_tenant.roles (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID        NOT NULL
                        REFERENCES nxc_tenant.tenants(id) ON DELETE CASCADE,

    name            VARCHAR(100)    NOT NULL,
    description     VARCHAR(500),
    is_system_role  BOOLEAN         NOT NULL DEFAULT FALSE,
                        -- TRUE: rol base no eliminable (TENANT_ADMIN, EDITOR, VIEWER)
    is_default      BOOLEAN         NOT NULL DEFAULT FALSE,
                        -- TRUE: se asigna automáticamente a nuevos usuarios del tenant

    -- Auditoría
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    created_by      UUID            REFERENCES nxc_tenant.users(id),
    updated_by      UUID            REFERENCES nxc_tenant.users(id),
    deleted_at      TIMESTAMPTZ,
    version         INTEGER         NOT NULL DEFAULT 0,

    UNIQUE (tenant_id, name)
);

CREATE INDEX IF NOT EXISTS ix_roles_tenant
    ON nxc_tenant.roles (tenant_id)
    WHERE deleted_at IS NULL;

COMMENT ON COLUMN nxc_tenant.roles.is_system_role IS
    'Los roles sistema (TENANT_ADMIN, EDITOR, VIEWER) no pueden eliminarse. Se crean con el tenant.';
COMMENT ON COLUMN nxc_tenant.roles.is_default IS
    'Si TRUE, se asigna automáticamente cuando se crea un usuario en este tenant.';

-- ---------------------------------------------------------------------------
-- 6. user_roles  –  asignación de roles a usuarios (dentro del mismo tenant)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS nxc_tenant.user_roles (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID        NOT NULL REFERENCES nxc_tenant.tenants(id) ON DELETE CASCADE,
    user_id         UUID        NOT NULL REFERENCES nxc_tenant.users(id)   ON DELETE CASCADE,
    role_id         UUID        NOT NULL REFERENCES nxc_tenant.roles(id)   ON DELETE CASCADE,

    assigned_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    assigned_by     UUID        REFERENCES nxc_tenant.users(id),
    expires_at      TIMESTAMPTZ,    -- NULL = permanente. Soporta roles temporales.

    UNIQUE (tenant_id, user_id, role_id)
);

CREATE INDEX IF NOT EXISTS ix_user_roles_user
    ON nxc_tenant.user_roles (tenant_id, user_id);

CREATE INDEX IF NOT EXISTS ix_user_roles_role
    ON nxc_tenant.user_roles (tenant_id, role_id);

COMMENT ON COLUMN nxc_tenant.user_roles.expires_at IS
    'Soporte para roles temporales. NULL = permanente. Un job nocturno revoca los expirados.';

-- ---------------------------------------------------------------------------
-- 7. user_invitations  –  tokens de invitación para nuevos usuarios
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS nxc_tenant.user_invitations (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID        NOT NULL REFERENCES nxc_tenant.tenants(id) ON DELETE CASCADE,

    email           VARCHAR(200)    NOT NULL,
    token_hash      VARCHAR(255)    NOT NULL UNIQUE,    -- hash del token enviado por email
    role_ids        UUID[]          NOT NULL DEFAULT '{}',

    invited_by      UUID        NOT NULL REFERENCES nxc_tenant.users(id),
    invited_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at      TIMESTAMPTZ NOT NULL,

    -- Estado de la invitación
    accepted_at     TIMESTAMPTZ,                        -- NULL = pendiente
    user_id         UUID        REFERENCES nxc_tenant.users(id), -- poblado al aceptar
    is_revoked      BOOLEAN     NOT NULL DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS ix_invitations_token
    ON nxc_tenant.user_invitations (token_hash);

CREATE INDEX IF NOT EXISTS ix_invitations_tenant_email
    ON nxc_tenant.user_invitations (tenant_id, email)
    WHERE accepted_at IS NULL AND is_revoked = FALSE;

-- =============================================================================
-- SCHEMA: nxc_auth
-- Sesiones, refresh tokens, intentos de login, reset de contraseña
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 8. sessions  –  sesiones activas por usuario
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS nxc_auth.sessions (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID        NOT NULL REFERENCES nxc_tenant.tenants(id) ON DELETE CASCADE,
    user_id         UUID        NOT NULL REFERENCES nxc_tenant.users(id)   ON DELETE CASCADE,

    device_id       UUID        NOT NULL DEFAULT gen_random_uuid(),
    device_name     VARCHAR(200),       -- "Chrome en macOS 14"
    ip_address      VARCHAR(45),
    user_agent      TEXT,

    is_active       BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_active_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at      TIMESTAMPTZ NOT NULL,
    revoked_at      TIMESTAMPTZ,
    revoked_reason  VARCHAR(50)         -- 'LOGOUT' | 'ADMIN' | 'SECURITY' | 'EXPIRED'
);

CREATE INDEX IF NOT EXISTS ix_sessions_user_active
    ON nxc_auth.sessions (tenant_id, user_id, is_active)
    WHERE is_active = TRUE;

-- ---------------------------------------------------------------------------
-- 9. refresh_tokens  –  tokens de refresco con rotación automática
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS nxc_auth.refresh_tokens (
    id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id              UUID        NOT NULL
                                REFERENCES nxc_auth.sessions(id) ON DELETE CASCADE,
    tenant_id               UUID        NOT NULL REFERENCES nxc_tenant.tenants(id) ON DELETE CASCADE,
    user_id                 UUID        NOT NULL REFERENCES nxc_tenant.users(id)   ON DELETE CASCADE,

    token_hash              VARCHAR(255)    NOT NULL UNIQUE,    -- SHA-256 del token real
    previous_token_hash     VARCHAR(255),                       -- para detectar reuso (token theft)

    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at              TIMESTAMPTZ NOT NULL,
    used_at                 TIMESTAMPTZ,       -- NULL = aún no fue usado para rotar
    is_revoked              BOOLEAN     NOT NULL DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS ix_refresh_tokens_hash
    ON nxc_auth.refresh_tokens (token_hash)
    WHERE is_revoked = FALSE AND used_at IS NULL;

COMMENT ON COLUMN nxc_auth.refresh_tokens.previous_token_hash IS
    'Si se detecta reuso del token anterior (ya rotado), se revoca toda la sesión: posible robo de token.';

-- ---------------------------------------------------------------------------
-- 10. login_attempts  –  trazabilidad y protección brute force
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS nxc_auth.login_attempts (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID        REFERENCES nxc_tenant.tenants(id),  -- NULL si el tenant no existe
    user_id         UUID        REFERENCES nxc_tenant.users(id),     -- NULL si el usuario no existe
    username_tried  VARCHAR(200)    NOT NULL,
    ip_address      VARCHAR(45)     NOT NULL,
    success         BOOLEAN         NOT NULL,
    failure_reason  VARCHAR(100),
                        -- 'WRONG_PASSWORD' | 'USER_BLOCKED' | 'USER_SUSPENDED'
                        -- | 'TENANT_INACTIVE' | 'MFA_FAILED' | 'ACCOUNT_LOCKED'
    attempted_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS ix_login_attempts_user_fails
    ON nxc_auth.login_attempts (user_id, attempted_at DESC)
    WHERE success = FALSE AND user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS ix_login_attempts_ip_fails
    ON nxc_auth.login_attempts (ip_address, attempted_at DESC)
    WHERE success = FALSE;

-- ---------------------------------------------------------------------------
-- 11. password_reset_tokens
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS nxc_auth.password_reset_tokens (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID        NOT NULL REFERENCES nxc_tenant.tenants(id) ON DELETE CASCADE,
    user_id         UUID        NOT NULL REFERENCES nxc_tenant.users(id)   ON DELETE CASCADE,

    token_hash      VARCHAR(255)    NOT NULL UNIQUE,
    expires_at      TIMESTAMPTZ     NOT NULL,
    used_at         TIMESTAMPTZ,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    ip_address      VARCHAR(45)
);

CREATE INDEX IF NOT EXISTS ix_password_reset_token_hash
    ON nxc_auth.password_reset_tokens (token_hash)
    WHERE used_at IS NULL;

-- =============================================================================
-- SCHEMA: nxc_menu
-- Componentes de la app, árbol de menú, permisos de UI por rol,
-- overrides por usuario
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 12. components  –  módulos / páginas de la aplicación
--     is_system=TRUE → componente global (visible para todos los tenants).
--     is_system=FALSE → componente privado registrado por ese tenant.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS nxc_menu.components (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID        NOT NULL REFERENCES nxc_tenant.tenants(id) ON DELETE CASCADE,

    module_key      VARCHAR(150)    NOT NULL,   -- clave técnica: 'user-management', 'audit-viewer'
    name            VARCHAR(150)    NOT NULL,   -- nombre legible: "Gestión de usuarios"
    route           VARCHAR(255),               -- ruta Angular: /users
    description     VARCHAR(500),
    is_system       BOOLEAN         NOT NULL DEFAULT FALSE,
                        -- TRUE: componente del sistema, no editable por el tenant

    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    created_by      UUID            REFERENCES nxc_tenant.users(id),
    updated_by      UUID            REFERENCES nxc_tenant.users(id),
    deleted_at      TIMESTAMPTZ,
    version         INTEGER         NOT NULL DEFAULT 0,

    UNIQUE (tenant_id, module_key)
);

CREATE INDEX IF NOT EXISTS ix_components_tenant
    ON nxc_menu.components (tenant_id)
    WHERE deleted_at IS NULL;

-- ---------------------------------------------------------------------------
-- 13. component_elements  –  elementos de UI controlables individualmente
--     Botones, tabs, secciones, campos. Se controla su visibilidad/habilitación
--     por rol y por usuario.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS nxc_menu.component_elements (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID        NOT NULL REFERENCES nxc_tenant.tenants(id)  ON DELETE CASCADE,
    component_id    UUID        NOT NULL REFERENCES nxc_menu.components(id) ON DELETE CASCADE,

    element_key     VARCHAR(150)    NOT NULL,   -- 'btn-create-user', 'tab-roles', 'field-email'
    label           VARCHAR(200),               -- descripción legible para el administrador
    element_type    VARCHAR(50),                -- 'BUTTON' | 'TAB' | 'FIELD' | 'SECTION' | 'ACTION'

    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ,
    version         INTEGER         NOT NULL DEFAULT 0,

    UNIQUE (tenant_id, component_id, element_key)
);

CREATE INDEX IF NOT EXISTS ix_component_elements_component
    ON nxc_menu.component_elements (component_id)
    WHERE deleted_at IS NULL;

-- ---------------------------------------------------------------------------
-- 14. menu_items  –  árbol de navegación por tenant
--     parent_id NULL = ítem raíz.
--     order_index controla el orden dentro del mismo nivel.
--     feature_flag_key: el ítem solo aparece si el flag está activo para el tenant.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS nxc_menu.menu_items (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID        NOT NULL REFERENCES nxc_tenant.tenants(id)  ON DELETE CASCADE,
    parent_id       UUID        REFERENCES nxc_menu.menu_items(id)          ON DELETE SET NULL,
    component_id    UUID        REFERENCES nxc_menu.components(id)          ON DELETE SET NULL,

    -- Presentación
    name            VARCHAR(150)    NOT NULL,
    title           VARCHAR(255),
    route           VARCHAR(255),
    icon            VARCHAR(150),
    icon_type       VARCHAR(50)     NOT NULL DEFAULT 'tabler', -- 'tabler' | 'material' | 'custom'
    location        nxc_menu.menu_location  NOT NULL DEFAULT 'navbar',
    item_type       nxc_menu.menu_item_type NOT NULL DEFAULT 'ITEM',
    order_index     INTEGER         NOT NULL DEFAULT 0,
    is_visible      BOOLEAN         NOT NULL DEFAULT TRUE,
    is_system       BOOLEAN         NOT NULL DEFAULT FALSE,    -- no eliminable por el tenant

    -- Acceso por defecto si no hay permiso explícito para el rol
    default_access  nxc_menu.access_level NOT NULL DEFAULT 'VIEW',

    -- Feature flag opcional
    feature_flag_key VARCHAR(150),

    -- Auditoría
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    created_by      UUID            REFERENCES nxc_tenant.users(id),
    updated_by      UUID            REFERENCES nxc_tenant.users(id),
    deleted_at      TIMESTAMPTZ,
    version         INTEGER         NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS ix_menu_items_tenant_parent
    ON nxc_menu.menu_items (tenant_id, parent_id, order_index)
    WHERE deleted_at IS NULL;

COMMENT ON COLUMN nxc_menu.menu_items.feature_flag_key IS
    'Si se especifica, el ítem solo se muestra cuando el feature flag está activo para el tenant.';

-- ---------------------------------------------------------------------------
-- 15. component_permissions  –  permiso de ROL sobre un componente completo
--     Si un rol tiene EXECUTE sobre un componente, puede usar todos sus
--     elementos (a menos que element_permissions lo restrinja).
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS nxc_menu.component_permissions (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID        NOT NULL REFERENCES nxc_tenant.tenants(id)  ON DELETE CASCADE,
    role_id         UUID        NOT NULL REFERENCES nxc_tenant.roles(id)    ON DELETE CASCADE,
    component_id    UUID        NOT NULL REFERENCES nxc_menu.components(id) ON DELETE CASCADE,

    access          nxc_menu.access_level NOT NULL DEFAULT 'HIDDEN',

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by      UUID        REFERENCES nxc_tenant.users(id),
    updated_by      UUID        REFERENCES nxc_tenant.users(id),

    UNIQUE (tenant_id, role_id, component_id)
);

CREATE INDEX IF NOT EXISTS ix_component_perms_role
    ON nxc_menu.component_permissions (tenant_id, role_id);

-- ---------------------------------------------------------------------------
-- 16. element_permissions  –  permiso de ROL sobre un elemento específico
--     Permite granularidad fina: rol EDITOR puede ver el botón eliminar
--     pero no ejecutarlo.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS nxc_menu.element_permissions (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID        NOT NULL REFERENCES nxc_tenant.tenants(id)           ON DELETE CASCADE,
    role_id         UUID        NOT NULL REFERENCES nxc_tenant.roles(id)             ON DELETE CASCADE,
    element_id      UUID        NOT NULL REFERENCES nxc_menu.component_elements(id)  ON DELETE CASCADE,

    access          nxc_menu.access_level NOT NULL DEFAULT 'HIDDEN',

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by      UUID        REFERENCES nxc_tenant.users(id),
    updated_by      UUID        REFERENCES nxc_tenant.users(id),

    UNIQUE (tenant_id, role_id, element_id)
);

CREATE INDEX IF NOT EXISTS ix_element_perms_role
    ON nxc_menu.element_permissions (tenant_id, role_id);

-- ---------------------------------------------------------------------------
-- 17. user_element_overrides  –  override por USUARIO sobre un elemento
--     Anula el permiso del rol. Útil para casos excepcionales.
--     expires_at permite overrides temporales.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS nxc_menu.user_element_overrides (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID        NOT NULL REFERENCES nxc_tenant.tenants(id)           ON DELETE CASCADE,
    user_id         UUID        NOT NULL REFERENCES nxc_tenant.users(id)             ON DELETE CASCADE,
    element_id      UUID        NOT NULL REFERENCES nxc_menu.component_elements(id)  ON DELETE CASCADE,

    access          nxc_menu.access_level NOT NULL,
    reason          VARCHAR(500),       -- justificación obligatoria del override
    expires_at      TIMESTAMPTZ,        -- NULL = permanente

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by      UUID        REFERENCES nxc_tenant.users(id),
    updated_by      UUID        REFERENCES nxc_tenant.users(id),

    UNIQUE (tenant_id, user_id, element_id)
);

-- ---------------------------------------------------------------------------
-- 18. tenant_menu_config  –  personalización del menú por tenant
--     Permite a cada tenant ocultar, renombrar o reordenar ítems del
--     menú del sistema sin modificar los registros base.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS nxc_menu.tenant_menu_config (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID        NOT NULL REFERENCES nxc_tenant.tenants(id)  ON DELETE CASCADE,
    menu_item_id    UUID        NOT NULL REFERENCES nxc_menu.menu_items(id) ON DELETE CASCADE,

    is_hidden       BOOLEAN     NOT NULL DEFAULT FALSE,
    custom_label    VARCHAR(150),
    custom_icon     VARCHAR(150),
    order_override  INTEGER,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE (tenant_id, menu_item_id)
);

-- =============================================================================
-- SCHEMA: nxc_preference
-- Preferencias de UI del usuario: tema, columnas de tablas, filtros guardados
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 19. user_preferences  –  configuración general de UX por usuario
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS nxc_preference.user_preferences (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID        NOT NULL REFERENCES nxc_tenant.tenants(id) ON DELETE CASCADE,
    user_id         UUID        NOT NULL REFERENCES nxc_tenant.users(id)   ON DELETE CASCADE,

    theme           VARCHAR(10)     NOT NULL DEFAULT 'system',
                        -- 'light' | 'dark' | 'system' (sigue el OS)
    language        VARCHAR(10)     NOT NULL DEFAULT 'es',
    timezone        VARCHAR(50),    -- override personal del timezone del tenant
    date_format     VARCHAR(30),    -- override personal del formato de fecha del tenant
    density         VARCHAR(15)     NOT NULL DEFAULT 'normal',
                        -- 'compact' | 'normal' | 'comfortable'
    sidebar_collapsed       BOOLEAN NOT NULL DEFAULT FALSE,
    notifications_sound     BOOLEAN NOT NULL DEFAULT TRUE,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE (tenant_id, user_id)
);

-- ---------------------------------------------------------------------------
-- 20. table_column_configs  –  configuración de columnas por tabla/vista
--     Persiste el orden, visibilidad y ancho de columnas que el usuario
--     configura en cada tabla de la interfaz.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS nxc_preference.table_column_configs (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID        NOT NULL REFERENCES nxc_tenant.tenants(id) ON DELETE CASCADE,
    user_id         UUID        NOT NULL REFERENCES nxc_tenant.users(id)   ON DELETE CASCADE,

    table_key       VARCHAR(150)    NOT NULL,   -- 'users-list' | 'roles-grid' | 'audit-list'
    -- Ejemplo: [{"key":"email","visible":true,"order":1,"width":200,"frozen":false}]
    columns_config  JSONB           NOT NULL DEFAULT '[]',
    sort_by         VARCHAR(100),
    sort_direction  VARCHAR(4)      NOT NULL DEFAULT 'ASC',  -- 'ASC' | 'DESC'
    page_size       INTEGER         NOT NULL DEFAULT 20,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE (tenant_id, user_id, table_key)
);

-- ---------------------------------------------------------------------------
-- 21. saved_filters  –  filtros guardados por el usuario
--     El usuario puede guardar combinaciones de filtros con nombre
--     y aplicarlas con un clic. Puede marcarlas como default o compartirlas.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS nxc_preference.saved_filters (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID        NOT NULL REFERENCES nxc_tenant.tenants(id) ON DELETE CASCADE,
    user_id         UUID        NOT NULL REFERENCES nxc_tenant.users(id)   ON DELETE CASCADE,

    module_key      VARCHAR(150)    NOT NULL,   -- módulo al que aplica: 'users' | 'audit'
    filter_name     VARCHAR(150)    NOT NULL,   -- nombre dado por el usuario: "Usuarios activos hoy"
    -- Ejemplo: [{"field":"status","operator":"eq","value":"ACTIVE"},{"field":"createdAt","operator":"gte","value":"2026-01-01"}]
    filter_config   JSONB           NOT NULL DEFAULT '{}',
    is_default      BOOLEAN         NOT NULL DEFAULT FALSE,
                        -- TRUE: se aplica automáticamente al abrir el módulo
    is_shared       BOOLEAN         NOT NULL DEFAULT FALSE,
                        -- TRUE: visible para todos los usuarios del tenant

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS ix_saved_filters_user_module
    ON nxc_preference.saved_filters (tenant_id, user_id, module_key);

CREATE INDEX IF NOT EXISTS ix_saved_filters_shared
    ON nxc_preference.saved_filters (tenant_id, module_key)
    WHERE is_shared = TRUE;

-- =============================================================================
-- SCHEMA: nxc_config
-- Feature flags y configuración dinámica por tenant
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 22. feature_flags
--     tenant_id NULL = flag global del sistema (aplica a todos los tenants).
--     tenant_id específico = override para ese tenant en particular.
--     min_plan: restricción por tier (solo disponible a partir de ese plan).
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS nxc_config.feature_flags (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID        REFERENCES nxc_tenant.tenants(id) ON DELETE CASCADE,
                        -- NULL = flag global del sistema

    flag_key        VARCHAR(150)    NOT NULL,
    description     VARCHAR(500),
    is_enabled      BOOLEAN         NOT NULL DEFAULT FALSE,
    min_plan        nxc_tenant.tenant_plan,
                        -- NULL = sin restricción de plan

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by      UUID        REFERENCES nxc_tenant.users(id),

    UNIQUE (tenant_id, flag_key)
);

CREATE INDEX IF NOT EXISTS ix_feature_flags_global
    ON nxc_config.feature_flags (flag_key)
    WHERE tenant_id IS NULL;

-- ---------------------------------------------------------------------------
-- 23. tenant_configs  –  pares clave-valor de configuración por tenant
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS nxc_config.tenant_configs (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID        NOT NULL REFERENCES nxc_tenant.tenants(id) ON DELETE CASCADE,

    config_key      VARCHAR(150)    NOT NULL,
    config_value    JSONB           NOT NULL,
    description     VARCHAR(500),
    is_secret       BOOLEAN         NOT NULL DEFAULT FALSE,
                        -- TRUE: no exponer en APIs públicas ni en logs

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by      UUID        REFERENCES nxc_tenant.users(id),
    updated_by      UUID        REFERENCES nxc_tenant.users(id),

    UNIQUE (tenant_id, config_key)
);

-- =============================================================================
-- 3. ROW-LEVEL SECURITY (RLS)
-- El tenant_id se pasa como variable de sesión antes de cada query:
--   SET app.tenant_id  = '<uuid>';
--   SET app.is_system_admin = 'true';   -- solo para el tenant 'system'
-- El JpaConfig de Spring lo inyecta en un Hibernate interceptor.
-- =============================================================================

ALTER TABLE nxc_tenant.tenants              ENABLE ROW LEVEL SECURITY;
ALTER TABLE nxc_tenant.users                ENABLE ROW LEVEL SECURITY;
ALTER TABLE nxc_tenant.roles                ENABLE ROW LEVEL SECURITY;
ALTER TABLE nxc_tenant.user_roles           ENABLE ROW LEVEL SECURITY;
ALTER TABLE nxc_tenant.user_invitations     ENABLE ROW LEVEL SECURITY;
ALTER TABLE nxc_auth.sessions               ENABLE ROW LEVEL SECURITY;
ALTER TABLE nxc_auth.refresh_tokens         ENABLE ROW LEVEL SECURITY;
ALTER TABLE nxc_auth.login_attempts         ENABLE ROW LEVEL SECURITY;
ALTER TABLE nxc_auth.password_reset_tokens  ENABLE ROW LEVEL SECURITY;
ALTER TABLE nxc_menu.components             ENABLE ROW LEVEL SECURITY;
ALTER TABLE nxc_menu.component_elements     ENABLE ROW LEVEL SECURITY;
ALTER TABLE nxc_menu.menu_items             ENABLE ROW LEVEL SECURITY;
ALTER TABLE nxc_menu.component_permissions  ENABLE ROW LEVEL SECURITY;
ALTER TABLE nxc_menu.element_permissions    ENABLE ROW LEVEL SECURITY;
ALTER TABLE nxc_menu.user_element_overrides ENABLE ROW LEVEL SECURITY;
ALTER TABLE nxc_menu.tenant_menu_config     ENABLE ROW LEVEL SECURITY;
ALTER TABLE nxc_preference.user_preferences     ENABLE ROW LEVEL SECURITY;
ALTER TABLE nxc_preference.table_column_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE nxc_preference.saved_filters        ENABLE ROW LEVEL SECURITY;
ALTER TABLE nxc_config.feature_flags        ENABLE ROW LEVEL SECURITY;
ALTER TABLE nxc_config.tenant_configs       ENABLE ROW LEVEL SECURITY;

-- Helpers RLS
CREATE OR REPLACE FUNCTION nxc_tenant.current_tenant_id()
RETURNS UUID LANGUAGE SQL STABLE AS $$
    SELECT NULLIF(current_setting('app.tenant_id', TRUE), '')::UUID;
$$;

CREATE OR REPLACE FUNCTION nxc_tenant.is_system_admin()
RETURNS BOOLEAN LANGUAGE SQL STABLE AS $$
    SELECT COALESCE(current_setting('app.is_system_admin', TRUE), 'false')::BOOLEAN;
$$;

-- Macro para la política estándar: accede solo a su propio tenant o bypass si system admin
CREATE OR REPLACE FUNCTION nxc_tenant.rls_tenant_check(row_tenant_id UUID)
RETURNS BOOLEAN LANGUAGE SQL STABLE AS $$
    SELECT nxc_tenant.is_system_admin()
        OR row_tenant_id = nxc_tenant.current_tenant_id();
$$;

-- Políticas RLS por tabla
-- DROP POLICY IF EXISTS evita el error si ya existen (idempotente en re-ejecuciones)
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN
        SELECT policyname, tablename, schemaname
        FROM pg_policies
        WHERE policyname = 'rls_tenant'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS rls_tenant ON %I.%I',
                       pol.schemaname, pol.tablename);
    END LOOP;
END;
$$;

CREATE POLICY rls_tenant ON nxc_tenant.tenants
    USING (nxc_tenant.is_system_admin() OR id = nxc_tenant.current_tenant_id());

CREATE POLICY rls_tenant ON nxc_tenant.users
    USING (nxc_tenant.rls_tenant_check(tenant_id));

CREATE POLICY rls_tenant ON nxc_tenant.roles
    USING (nxc_tenant.rls_tenant_check(tenant_id));

CREATE POLICY rls_tenant ON nxc_tenant.user_roles
    USING (nxc_tenant.rls_tenant_check(tenant_id));

CREATE POLICY rls_tenant ON nxc_tenant.user_invitations
    USING (nxc_tenant.rls_tenant_check(tenant_id));

CREATE POLICY rls_tenant ON nxc_auth.sessions
    USING (nxc_tenant.rls_tenant_check(tenant_id));

CREATE POLICY rls_tenant ON nxc_auth.refresh_tokens
    USING (nxc_tenant.rls_tenant_check(tenant_id));

CREATE POLICY rls_tenant ON nxc_auth.login_attempts
    USING (nxc_tenant.is_system_admin()
        OR tenant_id IS NULL
        OR tenant_id = nxc_tenant.current_tenant_id());

CREATE POLICY rls_tenant ON nxc_auth.password_reset_tokens
    USING (nxc_tenant.rls_tenant_check(tenant_id));

CREATE POLICY rls_tenant ON nxc_menu.components
    USING (nxc_tenant.is_system_admin()
        OR tenant_id = nxc_tenant.current_tenant_id()
        OR is_system = TRUE);

CREATE POLICY rls_tenant ON nxc_menu.component_elements
    USING (nxc_tenant.rls_tenant_check(tenant_id));

CREATE POLICY rls_tenant ON nxc_menu.menu_items
    USING (nxc_tenant.rls_tenant_check(tenant_id));

CREATE POLICY rls_tenant ON nxc_menu.component_permissions
    USING (nxc_tenant.rls_tenant_check(tenant_id));

CREATE POLICY rls_tenant ON nxc_menu.element_permissions
    USING (nxc_tenant.rls_tenant_check(tenant_id));

CREATE POLICY rls_tenant ON nxc_menu.user_element_overrides
    USING (nxc_tenant.rls_tenant_check(tenant_id));

CREATE POLICY rls_tenant ON nxc_menu.tenant_menu_config
    USING (nxc_tenant.rls_tenant_check(tenant_id));

CREATE POLICY rls_tenant ON nxc_preference.user_preferences
    USING (nxc_tenant.rls_tenant_check(tenant_id));

CREATE POLICY rls_tenant ON nxc_preference.table_column_configs
    USING (nxc_tenant.rls_tenant_check(tenant_id));

CREATE POLICY rls_tenant ON nxc_preference.saved_filters
    USING (nxc_tenant.rls_tenant_check(tenant_id));

CREATE POLICY rls_tenant ON nxc_config.feature_flags
    USING (nxc_tenant.is_system_admin()
        OR tenant_id IS NULL
        OR tenant_id = nxc_tenant.current_tenant_id());

CREATE POLICY rls_tenant ON nxc_config.tenant_configs
    USING (nxc_tenant.rls_tenant_check(tenant_id));

-- =============================================================================
-- 4. TRIGGERS
-- =============================================================================

-- ---------------------------------------------------------------------------
-- updated_at automático
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION nxc_tenant.fn_set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

DO $$
DECLARE
    tbl TEXT;
    tbls TEXT[] := ARRAY[
        'nxc_tenant.tenants',
        'nxc_tenant.users',
        'nxc_tenant.roles',
        'nxc_tenant.user_roles',
        'nxc_menu.components',
        'nxc_menu.component_elements',
        'nxc_menu.menu_items',
        'nxc_menu.component_permissions',
        'nxc_menu.element_permissions',
        'nxc_menu.user_element_overrides',
        'nxc_menu.tenant_menu_config',
        'nxc_preference.user_preferences',
        'nxc_preference.table_column_configs',
        'nxc_preference.saved_filters',
        'nxc_config.feature_flags',
        'nxc_config.tenant_configs'
    ];
BEGIN
    FOREACH tbl IN ARRAY tbls LOOP
        EXECUTE format(
            'DROP TRIGGER IF EXISTS trg_updated_at ON %s;
             CREATE TRIGGER trg_updated_at
             BEFORE UPDATE ON %s
             FOR EACH ROW EXECUTE FUNCTION nxc_tenant.fn_set_updated_at();',
            tbl, tbl
        );
    END LOOP;
END;
$$;

-- ---------------------------------------------------------------------------
-- Trigger: validar que user_id y role_id pertenecen al mismo tenant
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION nxc_tenant.fn_validate_user_role_tenant()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM nxc_tenant.users
        WHERE id = NEW.user_id AND tenant_id = NEW.tenant_id AND deleted_at IS NULL
    ) THEN
        RAISE EXCEPTION 'El usuario % no pertenece al tenant %', NEW.user_id, NEW.tenant_id;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM nxc_tenant.roles
        WHERE id = NEW.role_id AND tenant_id = NEW.tenant_id AND deleted_at IS NULL
    ) THEN
        RAISE EXCEPTION 'El rol % no pertenece al tenant %', NEW.role_id, NEW.tenant_id;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_user_role_tenant ON nxc_tenant.user_roles;
CREATE TRIGGER trg_validate_user_role_tenant
BEFORE INSERT OR UPDATE ON nxc_tenant.user_roles
FOR EACH ROW EXECUTE FUNCTION nxc_tenant.fn_validate_user_role_tenant();

-- ---------------------------------------------------------------------------
-- Trigger: crear roles base al insertar un nuevo tenant
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION nxc_tenant.fn_create_default_roles()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO nxc_tenant.roles
        (tenant_id, name, description, is_system_role, is_default)
    VALUES
        (NEW.id, 'TENANT_ADMIN', 'Administrador del tenant. Gestiona usuarios y roles.', TRUE,  FALSE),
        (NEW.id, 'EDITOR',       'Puede crear y editar registros.',                       TRUE,  FALSE),
        (NEW.id, 'VIEWER',       'Acceso de solo lectura.',                               TRUE,  TRUE)
    ON CONFLICT (tenant_id, name) DO NOTHING;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_create_default_roles ON nxc_tenant.tenants;
CREATE TRIGGER trg_create_default_roles
AFTER INSERT ON nxc_tenant.tenants
FOR EACH ROW EXECUTE FUNCTION nxc_tenant.fn_create_default_roles();

-- ---------------------------------------------------------------------------
-- Trigger: asignar rol default al crear un usuario
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION nxc_tenant.fn_assign_default_role()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    v_default_role_id UUID;
BEGIN
    SELECT id INTO v_default_role_id
    FROM nxc_tenant.roles
    WHERE tenant_id = NEW.tenant_id
      AND is_default = TRUE
      AND deleted_at IS NULL
    LIMIT 1;

    IF v_default_role_id IS NOT NULL THEN
        INSERT INTO nxc_tenant.user_roles (tenant_id, user_id, role_id, assigned_by)
        VALUES (NEW.tenant_id, NEW.id, v_default_role_id, NEW.created_by)
        ON CONFLICT (tenant_id, user_id, role_id) DO NOTHING;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_assign_default_role ON nxc_tenant.users;
CREATE TRIGGER trg_assign_default_role
AFTER INSERT ON nxc_tenant.users
FOR EACH ROW EXECUTE FUNCTION nxc_tenant.fn_assign_default_role();

-- =============================================================================
-- 5. VISTAS DE UTILIDAD
-- =============================================================================

-- Vista usada por el servicio de auth al hacer login.
-- Devuelve todo lo necesario para construir el JWT en una sola query.
CREATE OR REPLACE VIEW nxc_tenant.v_user_login_profile AS
SELECT
    u.id                    AS user_id,
    u.tenant_id,
    u.username,
    u.email,
    u.password_hash,
    u.full_name,
    u.photo_url,
    u.status,
    u.is_tenant_admin,
    u.totp_enabled,
    u.email_verified,
    u.last_login_at,
    t.slug                  AS tenant_slug,
    t.name                  AS tenant_name,
    t.plan                  AS tenant_plan,
    t.mode                  AS tenant_mode,
    t.status                AS tenant_status,
    t.logo_url              AS tenant_logo,
    t.timezone              AS tenant_timezone,
    t.locale                AS tenant_locale,
    t.mfa_required,
    t.max_login_attempts,
    t.session_timeout_minutes,
    -- Roles del usuario en este tenant
    ARRAY(
        SELECT r.name
        FROM nxc_tenant.user_roles ur
        JOIN nxc_tenant.roles r ON r.id = ur.role_id
        WHERE ur.user_id = u.id
          AND ur.tenant_id = u.tenant_id
          AND (ur.expires_at IS NULL OR ur.expires_at > NOW())
    )                       AS role_names,
    ARRAY(
        SELECT ur.role_id::TEXT
        FROM nxc_tenant.user_roles ur
        WHERE ur.user_id = u.id
          AND ur.tenant_id = u.tenant_id
          AND (ur.expires_at IS NULL OR ur.expires_at > NOW())
    )                       AS role_ids
FROM nxc_tenant.users   u
JOIN nxc_tenant.tenants t ON t.id = u.tenant_id
WHERE u.deleted_at IS NULL
  AND t.deleted_at IS NULL;

COMMENT ON VIEW nxc_tenant.v_user_login_profile IS
    'Usada por AuthService.login(). Devuelve todo lo necesario para construir el JWT en una sola query.';

-- Vista del árbol de menú con acceso efectivo por rol
CREATE OR REPLACE VIEW nxc_menu.v_menu_effective_access AS
SELECT
    mi.id               AS menu_item_id,
    mi.tenant_id,
    mi.parent_id,
    mi.name,
    mi.title,
    mi.route,
    mi.icon,
    mi.icon_type,
    mi.location,
    mi.item_type,
    mi.order_index,
    mi.is_visible,
    mi.feature_flag_key,
    mi.default_access,
    cp.role_id,
    COALESCE(cp.access, mi.default_access) AS effective_access
FROM nxc_menu.menu_items mi
LEFT JOIN nxc_menu.components c
    ON c.id = mi.component_id AND c.deleted_at IS NULL
LEFT JOIN nxc_menu.component_permissions cp
    ON cp.component_id = c.id AND cp.tenant_id = mi.tenant_id
WHERE mi.deleted_at IS NULL
  AND mi.is_visible = TRUE;

COMMENT ON VIEW nxc_menu.v_menu_effective_access IS
    'Árbol plano de menú con acceso efectivo por rol. MenuService la usa para construir el árbol filtrado.';

-- =============================================================================
-- 6. DATOS SEMILLA
-- =============================================================================

-- Tenant sistema (administra la plataforma completa)
-- ON CONFLICT usa el índice parcial uq_tenants_slug (WHERE deleted_at IS NULL)
INSERT INTO nxc_tenant.tenants (
    id, slug, name, plan, mode, status, timezone, locale
) VALUES (
    '00000000-0000-0000-0000-000000000001',
    'system',
    'NexCore System',
    'ENTERPRISE',
    'ON_PREMISE',
    'ACTIVE',
    'UTC',
    'es-CO'
) ON CONFLICT (slug) WHERE deleted_at IS NULL DO NOTHING;

-- Los roles base del tenant system se crean automáticamente
-- por el trigger trg_create_default_roles.
-- Adicionalmente se crea el rol SUPER_ADMIN solo para el tenant system:
INSERT INTO nxc_tenant.roles (
    tenant_id, name, description, is_system_role, is_default
) VALUES (
    '00000000-0000-0000-0000-000000000001',
    'SUPER_ADMIN',
    'Administrador global de la plataforma. Acceso total a todos los tenants via bypass de RLS.',
    TRUE,
    FALSE
) ON CONFLICT (tenant_id, name) DO NOTHING;

-- =============================================================================
-- FIN DEL SCHEMA NexCore v2.0  –  Modelo B (usuario pertenece al tenant)
-- =============================================================================
