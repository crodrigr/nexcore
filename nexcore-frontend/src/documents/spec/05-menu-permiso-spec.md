# Especificación: Sistema de Menús y Permisos por Roles — NexCore

Última actualización: 2026-05-23

Propósito: definir la arquitectura completa del sistema de menús dinámicos y control de permisos granular por roles en NexCore. Incluye modelo de datos, contratos API, flujos de trabajo, implementación frontend (Guards, Services, Directivas) y testing.

---

## 1. Resumen Ejecutivo

### 1.1. Objetivo

Implementar un sistema de control de acceso basado en roles (RBAC - Role-Based Access Control) que permita:

1. **Menús dinámicos**: Mostrar/ocultar opciones de navegación según roles del usuario
2. **Permisos granulares**: Controlar acceso a componentes y elementos específicos (botones, inputs, secciones)
3. **Configuración centralizada**: Toda la lógica de permisos se define en base de datos, sin hard-coding en frontend
4. **Validación multi-capa**: Guards para rutas, servicios para lógica, directivas para UI

### 1.2. Decisiones Arquitectónicas

- **Backend**: PostgreSQL como fuente de verdad para menús y permisos
- **API**: Endpoint único `/api/profile` retorna perfil completo (user, menus, permissions)
- **Frontend**: Sistema reactivo con Observables y async pipe
- **Seguridad**: Validación en múltiples capas (Guard → Service → Component → Template)

### 1.3. Componentes Principales

| Componente | Responsabilidad |
|------------|-----------------|
| **Base de Datos** | 6 tablas para componentes, elementos, menús, roles y permisos |
| **ProfileService** | Almacena y expone menus$ y permissions$ como Observables |
| **PermissionService** | Valida permisos de componentes y elementos |
| **permissionGuard** | Protege rutas según permisos del usuario |
| **Componentes UI** | Consumen permisos reactivamente con *ngIf + async pipe |

---

## 2. Alcance

### 2.1. Incluye

✅ Modelo de datos completo en PostgreSQL  
✅ Vista SQL `v_user_menu_access` para menús por usuario  
✅ Vista SQL `v_user_permissions` para permisos por usuario  
✅ Endpoint `GET /api/profile` que retorna perfil completo  
✅ ProfileService para gestionar estado del perfil  
✅ PermissionService con métodos `canView$()`, `canExecute$()`  
✅ permissionGuard para proteger rutas  
✅ Componentes UI que consumen permisos reactivamente  
✅ Soporte para menús multinivel (grupos con hijos)  
✅ Soporte para múltiples ubicaciones (navbar, profile, sidebar, footer)  
✅ 3 niveles de acceso: EXECUTE, VIEW, HIDDEN  
✅ Control por tenant (multi-tenancy)  
✅ Tests unitarios para Guards y Services  

### 2.2. No Incluye

❌ Interfaz gráfica para administrar permisos (se gestionan vía SQL)  
❌ Permisos a nivel de campo de formulario (se controla elemento completo)  
❌ Auditoría de intentos de acceso denegado  
❌ Cache de permisos en servidor (se recalcula en cada login)  

---

## 3. Modelo de Datos

### 3.1. Esquema General

El sistema utiliza 7 tablas principales distribuidas en 2 esquemas PostgreSQL:

```
nxc_menu.*                              nxc_tenant.*
├─ components                           └─ roles
├─ component_elements
├─ menu_items
├─ component_permissions
├─ element_permissions
├─ user_element_overrides
└─ tenant_menu_config
```

**Nota importante**: Todas las tablas de menús y permisos están en el esquema `nxc_menu`, no existe el esquema `nxc_config` para estos propósitos.

### 3.2. Tabla: nxc_menu.components

**Propósito**: Define los componentes (módulos/páginas) de la aplicación.

```sql
CREATE TABLE nxc_menu.components (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID        NOT NULL REFERENCES nxc_tenant.tenants(id) ON DELETE CASCADE,
    module_key      VARCHAR(150)    NOT NULL,   -- 'user-management', 'audit-viewer', 'dashboard'
    name            VARCHAR(150)    NOT NULL,   -- 'Gestión de usuarios', 'Alertas'
    route           VARCHAR(255),               -- '/users', '/alerts'
    description     VARCHAR(500),
    is_system       BOOLEAN         NOT NULL DEFAULT FALSE,  -- TRUE: componente del sistema
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    created_by      UUID            REFERENCES nxc_tenant.users(id),
    updated_by      UUID            REFERENCES nxc_tenant.users(id),
    deleted_at      TIMESTAMPTZ,
    version         INTEGER         NOT NULL DEFAULT 0,
    UNIQUE (tenant_id, module_key)
);

-- Índices
CREATE INDEX ix_components_tenant
    ON nxc_menu.components (tenant_id)
    WHERE deleted_at IS NULL;
```

**Ejemplos de datos:**

| id | tenant_id | module_key | name | route | is_system |
|----|-----------|------------|------|-------|----------|
| uuid-1 | system | dashboard | Dashboard | /graphics | TRUE |
| uuid-2 | system | alerts | Alertas | /alerts | TRUE |
| uuid-3 | system | user-management | Gestión de Usuarios | /admin/users | TRUE |

**Campos clave:**
- `module_key`: Identificador técnico único del componente (usado en código)
- `is_system`: Si es TRUE, el componente pertenece al sistema y está disponible para todos los tenants

### 3.3. Tabla: nxc_menu.component_elements

**Propósito**: Define elementos específicos dentro de cada componente (botones, inputs, secciones).

```sql
CREATE TABLE nxc_menu.component_elements (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID        NOT NULL REFERENCES nxc_tenant.tenants(id) ON DELETE CASCADE,
    component_id    UUID        NOT NULL REFERENCES nxc_menu.components(id) ON DELETE CASCADE,
    element_key     VARCHAR(150)    NOT NULL,   -- 'btn-create-user', 'tab-roles', 'searchInput'
    label           VARCHAR(200),               -- Descripción legible para administrador
    element_type    VARCHAR(50),                -- 'BUTTON', 'TAB', 'FIELD', 'SECTION', 'ACTION'
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ,
    version         INTEGER         NOT NULL DEFAULT 0,
    UNIQUE (tenant_id, component_id, element_key)
);

-- Índices
CREATE INDEX ix_component_elements_component
    ON nxc_menu.component_elements (component_id)
    WHERE deleted_at IS NULL;
```

**Ejemplos de datos:**

| id | tenant_id | component_id | element_key | label | element_type |
|----|-----------|--------------|-------------|-------|-------------|
| uuid-10 | system | uuid-3 | btn-create-user | Botón Crear Usuario | BUTTON |
| uuid-11 | system | uuid-3 | btn-edit-user | Botón Editar Usuario | BUTTON |
| uuid-12 | system | uuid-3 | btn-delete-user | Botón Eliminar Usuario | BUTTON |
| uuid-13 | system | uuid-3 | searchInput | Input de Búsqueda | FIELD |
| uuid-14 | system | uuid-3 | paginator | Paginador | SECTION |
| uuid-15 | system | uuid-3 | tab-roles | Pestaña de Roles | TAB |

**Convención de nombres:**

- Botones: `btn-[acción]-[contexto]` → `btn-create-user`, `btn-export-pdf`
- Inputs: `[tipo]Input` → `searchInput`, `emailInput`
- Selectores: `[nombre]Select` → `cityFilterSelect`, `roleSelect`
- Secciones: `section-[nombre]` → `section-stats`, `section-charts`
- Pestañas: `tab-[nombre]` → `tab-roles`, `tab-permissions`

### 3.4. Tabla: nxc_menu.menu_items

**Propósito**: Define los ítems de menú de la aplicación.

```sql
CREATE TABLE nxc_menu.menu_items (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID        NOT NULL REFERENCES nxc_tenant.tenants(id) ON DELETE CASCADE,
    parent_id       UUID        REFERENCES nxc_menu.menu_items(id) ON DELETE SET NULL,
    component_id    UUID        REFERENCES nxc_menu.components(id) ON DELETE SET NULL,
    name            VARCHAR(150)    NOT NULL,
    title           VARCHAR(255),
    route           VARCHAR(255),
    icon            VARCHAR(150),
    icon_type       VARCHAR(50)     NOT NULL DEFAULT 'tabler',  -- 'tabler', 'material', 'custom'
    location        VARCHAR(50)     NOT NULL DEFAULT 'navbar',  -- 'navbar', 'profile', 'sidebar', 'footer'
    item_type       nxc_menu.menu_item_type NOT NULL DEFAULT 'ITEM',
    order_index     INTEGER         NOT NULL DEFAULT 0,
    is_visible      BOOLEAN         NOT NULL DEFAULT TRUE,
    is_system       BOOLEAN         NOT NULL DEFAULT FALSE,     -- No eliminable por el tenant
    default_access  nxc_menu.access_level NOT NULL DEFAULT 'VIEW',
    feature_flag_key VARCHAR(150),                              -- Feature flag opcional
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    created_by      UUID            REFERENCES nxc_tenant.users(id),
    updated_by      UUID            REFERENCES nxc_tenant.users(id),
    deleted_at      TIMESTAMPTZ,
    version         INTEGER         NOT NULL DEFAULT 0,
    UNIQUE(tenant_id, name)
);

-- Índices
CREATE INDEX ix_menu_items_tenant_parent
    ON nxc_menu.menu_items (tenant_id, parent_id, order_index)
    WHERE deleted_at IS NULL;
```

**Valores del ENUM `menu_item_type`:**

| Tipo | Descripción | route | parent_id |
|------|-------------|-------|-----------|
| **ITEM** | Enlace directo a una ruta | Requerido | Opcional |
| **GROUP** | Grupo que contiene submenús | NULL | Opcional |
| **DIVIDER** | Separador visual | NULL | Requerido |
| **EXTERNAL_LINK** | Enlace externo (nueva pestaña) | Requerido (URL completa) | Opcional |

**Valores de `location`:**

| Location | Descripción | Uso |
|----------|-------------|-----|
| **navbar** | Barra de navegación principal | Menús principales (Dashboard, Alertas, etc.) |
| **profile** | Dropdown del avatar/perfil | Perfil, Configuración, Logout, Administración |
| **sidebar** | Barra lateral (si existe) | Navegación secundaria |
| **footer** | Pie de página | Enlaces legales, ayuda |

**Campos especiales:**

- `component_id`: Enlaza el menú con un componente para validación de permisos
- `default_access`: Nivel de acceso por defecto si no hay permiso explícito del rol
- `feature_flag_key`: Si se especifica, el ítem solo se muestra cuando el feature flag está activo
- `is_system`: TRUE para menús del sistema, no eliminables por el tenant
- `is_visible`: Permite ocultar menús sin eliminarlos

**Ejemplos de datos:**

| id | name | title | route | location | item_type | component_id | default_access | parent_id | order_index |
|----|------|-------|-------|----------|-----------|--------------|----------------|-----------|-------------|
| uuid-20 | Dashboard | Panel Principal | /graphics | navbar | ITEM | v_comp_dashboard | EXECUTE | NULL | 10 |
| uuid-21 | Alerts | Alertas | /alerts | navbar | ITEM | v_comp_alerts | EXECUTE | NULL | 20 |
| uuid-22 | ProfileMenu | Perfil | NULL | profile | GROUP | NULL | EXECUTE | NULL | 50 |
| uuid-23 | Profile | Mi Perfil | /profile | profile | ITEM | NULL | EXECUTE | uuid-22 | 10 |
| uuid-24 | Logout | Cerrar Sesión | /auth/login | profile | ITEM | v_comp_auth | EXECUTE | uuid-22 | 30 |
| uuid-25 | Administration | Administración | NULL | profile | GROUP | NULL | HIDDEN | NULL | 60 |

**Nota importante sobre permisos de menú:**

El sistema NexCore no tiene una tabla separada para asignar menús a roles. En su lugar, los permisos de menú se derivan de:

1. **Campo `default_access`** en `menu_items`: Define el nivel de acceso por defecto
2. **Campo `component_id`** en `menu_items`: Enlaza el menú con un componente
3. **Tabla `component_permissions`**: Los permisos del componente enlazado determinan el acceso al menú

La vista `v_menu_effective_access` consolida esta lógica automáticamente.

### 3.5. Tabla: nxc_menu.component_permissions

### 3.5. Tabla: nxc_menu.component_permissions

**Propósito**: Define el nivel de acceso de un rol a un componente completo.

```sql
CREATE TABLE nxc_menu.component_permissions (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID        NOT NULL REFERENCES nxc_tenant.tenants(id) ON DELETE CASCADE,
    role_id         UUID        NOT NULL REFERENCES nxc_tenant.roles(id) ON DELETE CASCADE,
    component_id    UUID        NOT NULL REFERENCES nxc_menu.components(id) ON DELETE CASCADE,
    access          nxc_menu.access_level NOT NULL DEFAULT 'HIDDEN',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by      UUID        REFERENCES nxc_tenant.users(id),
    updated_by      UUID        REFERENCES nxc_tenant.users(id),
    UNIQUE (tenant_id, role_id, component_id)
);

-- Índices
CREATE INDEX ix_component_perms_role
    ON nxc_menu.component_permissions (tenant_id, role_id);
```

**Interpretación del campo `access`:**

| Nivel | Guard permite acceso | Usuario puede |
|-------|---------------------|---------------|
| **EXECUTE** | ✅ Sí | Ver y ejecutar todas las acciones por defecto |
| **VIEW** | ✅ Sí | Ver el componente pero con acciones limitadas |
| **HIDDEN** | ❌ No | Es redirigido al dashboard |

### 3.6. Tabla: nxc_menu.element_permissions

### 3.6. Tabla: nxc_menu.element_permissions

**Propósito**: Define el nivel de acceso de un rol a elementos específicos dentro de un componente.

```sql
CREATE TABLE nxc_menu.element_permissions (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID        NOT NULL REFERENCES nxc_tenant.tenants(id) ON DELETE CASCADE,
    role_id         UUID        NOT NULL REFERENCES nxc_tenant.roles(id) ON DELETE CASCADE,
    element_id      UUID        NOT NULL REFERENCES nxc_menu.component_elements(id) ON DELETE CASCADE,
    access          nxc_menu.access_level NOT NULL DEFAULT 'HIDDEN',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by      UUID        REFERENCES nxc_tenant.users(id),
    updated_by      UUID        REFERENCES nxc_tenant.users(id),
    UNIQUE (tenant_id, role_id, element_id)
);

-- Índices
CREATE INDEX ix_element_perms_role
    ON nxc_menu.element_permissions (tenant_id, role_id);
```

**Interpretación del campo `access` en elementos:**

| Nivel | Comportamiento en UI | Ejemplo |
|-------|----------------------|---------|
| **EXECUTE** | Elemento visible e interactivo | Botón visible y clickeable |
| **VIEW** | Elemento visible pero deshabilitado | Botón gris, input readonly |
| **HIDDEN** | Elemento no se muestra | Display: none |

### 3.7. Tablas Adicionales

**nxc_menu.user_element_overrides**: Permite overrides temporales o permanentes de permisos de elementos a nivel de usuario individual.

**nxc_menu.tenant_menu_config**: Permite a cada tenant personalizar menús del sistema (ocultar, renombrar, reordenar) sin modificar los registros base.

### 3.8. Vista: v_menu_effective_access

### 3.8. Vista: v_menu_effective_access

**Propósito**: Consolida el árbol de menús con el acceso efectivo por rol, considerando los permisos del componente enlazado.

```sql
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
```

**Lógica de acceso efectivo:**

1. Si el menú tiene `component_id` enlazado:
   - Se busca el permiso del rol en `component_permissions`
   - Si existe permiso, se usa `cp.access`
   - Si no existe permiso, se usa `mi.default_access`

2. Si el menú NO tiene `component_id`:
   - Se usa `mi.default_access` directamente

3. El backend usa esta vista para construir el árbol de menús filtrado por rol del usuario

**Nota**: No hay una vista separada `v_user_permissions`. Los permisos se consultan directamente de las tablas `component_permissions` y `element_permissions` filtrando por los roles del usuario.

---

## 4. Contratos API

### 4.1. GET /api/profile

**Propósito**: Retorna el perfil completo del usuario autenticado, incluyendo menús y permisos.

**Headers:**
```
Authorization: Bearer <access-token>
Content-Type: application/json
```

**Response 200 OK:**

```json
{
  "user": {
    "iduser": "00000000-0000-0000-0001-000000000001",
    "username": "super.admin",
    "name": "Super Administrador NexCore",
    "email": "super.admin@nexcore.io",
    "phone": null,
    "photo": null,
    "roles": ["SUPER_ADMIN", "VIEWER"]
  },
  "menus": [
    {
      "id": "4337a18f-c20d-422e-a828-db3fb3d45a7c",
      "name": "Dashboard",
      "title": "Panel Principal",
      "icon": "layout-dashboard",
      "icon_type": "tabler",
      "route": "/graphics",
      "location": "navbar",
      "item_type": "ITEM",
      "access": "execute",
      "order_index": 10,
      "children": []
    },
    {
      "id": "37bbc70f-6d2d-463a-8714-ded61c4d0596",
      "name": "ProfileMenu",
      "title": "Perfil",
      "icon": "user-circle",
      "icon_type": "tabler",
      "route": null,
      "location": "profile",
      "item_type": "GROUP",
      "access": "execute",
      "order_index": 50,
      "children": [
        {
          "id": "d0fca44e-9948-4d0c-895b-24d5050f967f",
          "name": "Profile",
          "title": "Mi Perfil",
          "icon": "user",
          "icon_type": "tabler",
          "route": "/profile",
          "location": "profile",
          "item_type": "ITEM",
          "access": "execute",
          "order_index": 10,
          "children": []
        }
      ]
    }
  ],
  "permissions": [
    {
      "component": "dashboard",
      "route": "/graphics",
      "access": "execute",
      "elements": [
        {
          "element_key": "filterButton",
          "access": "hidden"
        },
        {
          "element_key": "refreshButton",
          "access": "hidden"
        }
      ]
    },
    {
      "component": "user-management",
      "route": "/admin/users",
      "access": "execute",
      "elements": [
        {
          "element_key": "btn-create-user",
          "access": "execute"
        },
        {
          "element_key": "btn-edit-user",
          "access": "execute"
        },
        {
          "element_key": "btn-delete-user",
          "access": "hidden"
        }
      ]
    }
  ],
  "token": null
}
```

**Estructura de `menus[]`:**

| Campo | Tipo | Descripción | Obligatorio |
|-------|------|-------------|-------------|
| `id` | UUID | Identificador único del menú | Sí |
| `name` | string | Identificador técnico (ej: "Dashboard") | Sí |
| `title` | string | Texto visible en UI (ej: "Panel Principal") | Sí |
| `icon` | string | Nombre del ícono | No |
| `icon_type` | string | Librería de íconos (tabler, material) | No |
| `route` | string\|null | Ruta de navegación (null para grupos) | Condicional |
| `location` | string | Ubicación: navbar, profile, sidebar, footer | Sí |
| `item_type` | string | Tipo: ITEM, GROUP, DIVIDER, EXTERNAL_LINK | Sí |
| `access` | string | Nivel de acceso: execute, view, hidden | Sí |
| `order_index` | number | Orden de visualización | Sí |
| `children` | array | Submenús (solo para GROUP) | Sí |

**Estructura de `permissions[]`:**

| Campo | Tipo | Descripción | Obligatorio |
|-------|------|-------------|-------------|
| `component` | string | Identificador del componente | Sí |
| `route` | string | Ruta asociada al componente | Sí |
| `access` | string | Nivel de acceso al componente: execute, view, hidden | Sí |
| `elements` | array | Lista de elementos con permisos específicos | Sí |

**Estructura de `elements[]`:**

| Campo | Tipo | Descripción | Obligatorio |
|-------|------|-------------|-------------|
| `element_key` | string | Identificador del elemento | Sí |
| `access` | string | Nivel de acceso: execute, view, hidden | Sí |

**Response 401 Unauthorized:**

```json
{
  "error": "Unauthorized",
  "message": "Invalid or expired token",
  "timestamp": "2026-05-23T10:30:00Z"
}
```

**Response 403 Forbidden:**

```json
{
  "error": "Forbidden",
  "message": "User account is suspended",
  "timestamp": "2026-05-23T10:30:00Z"
}
```

---

## 5. Flujos de Trabajo

### 5.1. Flujo Principal: Login y Carga de Perfil

```
┌─────────────┐
│   Usuario   │
└──────┬──────┘
       │ 1. Ingresa credenciales
       ↓
┌─────────────────────────┐
│  LoginComponent         │
│  authService.login()    │
└──────┬──────────────────┘
       │ 2. POST /auth/login
       │ 3. POST /auth/verify-otp
       ↓
┌─────────────────────────┐
│  Auth Service (Backend) │
│  Valida credenciales    │
│  Genera tokens          │
└──────┬──────────────────┘
       │ 4. Response con token
       ↓
┌─────────────────────────┐
│  AuthService (Frontend) │
│  Guarda token           │
│  Llama loadProfile()    │
└──────┬──────────────────┘
       │ 5. GET /api/profile
       ↓
┌─────────────────────────┐
│  Profile API (Backend)  │
│  Consulta vistas SQL    │
│  - v_user_menu_access   │
│  - v_user_permissions   │
└──────┬──────────────────┘
       │ 6. Response JSON
       │    { user, menus, permissions }
       ↓
┌─────────────────────────┐
│  ProfileService         │
│  setProfile(data)       │
│  menus$ ← data.menus    │
│  permissions$ ← data... │
└──────┬──────────────────┘
       │ 7. Navega a dashboard
       ↓
┌─────────────────────────┐
│  App Component          │
│  Router renderiza       │
└──────┬──────────────────┘
       │ 8. Navbar consume menus$
       ↓
┌─────────────────────────┐
│  NavbarComponent        │
│  Filtra location:navbar │
│  Muestra menús          │
└─────────────────────────┘
```

### 5.2. Flujo: Navegación con Protección de Rutas

```
┌─────────────┐
│   Usuario   │
│ Click "Alertas" │
└──────┬──────┘
       │ 1. Router navega a /alerts
       ↓
┌─────────────────────────┐
│  Router                 │
│  Verifica canActivate   │
└──────┬──────────────────┘
       │ 2. Ejecuta permissionGuard
       ↓
┌─────────────────────────┐
│  permissionGuard        │
│  Lee route.data         │
│  component: 'alerts'    │
└──────┬──────────────────┘
       │ 3. Llama canAccessRoute()
       ↓
┌─────────────────────────┐
│  PermissionService      │
│  Busca permiso de       │
│  component 'alerts'     │
└──────┬──────────────────┘
       │ 4. Consulta permissions$
       ↓
┌─────────────────────────┐
│  ProfileService         │
│  Retorna permissions    │
└──────┬──────────────────┘
       │ 5. Valida access (nivel de acceso)
       ↓
    ┌──┴───┐
    │ ¿Tiene permiso? │
    └──┬───┴──────────┘
       │
   ┌───┴────┐
   │ Sí │ No │
   ↓      ↓
┌──────┐ ┌────────────┐
│ PASS │ │ REDIRECT   │
│      │ │ dashboard  │
└──┬───┘ └────────────┘
   │ 6. Permite navegación
   ↓
┌─────────────────────────┐
│  AlertsComponent        │
│  ngOnInit()             │
│  Inicializa permisos    │
└──────┬──────────────────┘
       │ 7. canSearch$ = canExecute$(...)
       │    canExport$ = canExecute$(...)
       ↓
┌─────────────────────────┐
│  Template               │
│  *ngIf con async pipe   │
│  Muestra/oculta         │
│  elementos              │
└─────────────────────────┘
```

### 5.3. Flujo: Validación de Elemento Específico

```
┌─────────────┐
│  Template   │
│  Renderiza  │
└──────┬──────┘
       │ *ngIf="canCreate$ | async"
       ↓
┌─────────────────────────┐
│  Angular                │
│  Suscribe a Observable  │
└──────┬──────────────────┘
       │ Consulta valor
       ↓
┌─────────────────────────┐
│  Component              │
│  canCreate$ = ...       │
└──────┬──────────────────┘
       │ Observable creado en constructor
       ↓
┌─────────────────────────┐
│  PermissionService      │
│  canExecute$(           │
│    'users',             │
│    'btn-create-user'    │
│  )                      │
└──────┬──────────────────┘
       │ Busca en permissions$
       ↓
┌─────────────────────────┐
│  ProfileService         │
│  permissions$           │
└──────┬──────────────────┘
       │ Retorna array de permisos
       ↓
┌─────────────────────────┐
│  PermissionService      │
│  Filtra component:      │
│  'users'                │
│  Busca element_key:     │
│  'btn-create-user'      │
│  Retorna access         │
└──────┬──────────────────┘
       │
    ┌──┴───┐
    │ access === 'execute' ? │
    └──┬───┴──────────────┘
       │
   ┌───┴────┐
   │ Sí │ No │
   ↓      ↓
┌──────┐ ┌────────┐
│ true │ │ false  │
└──┬───┘ └───┬────┘
   │         │
   ↓         ↓
┌──────────────────────────┐
│  Template                │
│  Elemento visible o      │
│  elemento oculto         │
└──────────────────────────┘
```

---

## 6. Implementación Frontend

### 6.1. ProfileService

**Archivo**: `src/app/core/services/profile.service.ts`

```typescript
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { BehaviorSubject, Observable, of } from 'rxjs';
import { tap, catchError } from 'rxjs/operators';

export interface User {
  iduser: string;
  username: string;
  name: string;
  email: string;
  phone: string | null;
  photo: string | null;
  roles: string[];
}

export interface MenuItem {
  id: string;
  name: string;
  title: string;
  icon?: string;
  icon_type?: string;
  route: string | null;
  location: string;
  item_type: 'ITEM' | 'GROUP' | 'DIVIDER' | 'EXTERNAL_LINK';
  access: 'execute' | 'view' | 'hidden';
  order_index: number;
  children: MenuItem[];
}

export interface PermissionElement {
  element_key: string;
  access: 'execute' | 'view' | 'hidden';
}

export interface Permission {
  component: string;
  route: string;
  access: 'execute' | 'view' | 'hidden';
  elements: PermissionElement[];
}

export interface Profile {
  user: User;
  menus: MenuItem[];
  permissions: Permission[];
  token: string | null;
}

@Injectable({
  providedIn: 'root'
})
export class ProfileService {
  
  private readonly PROFILE_KEY = 'profile';
  
  // Subjects privados
  private userSubject = new BehaviorSubject<User | null>(null);
  private menusSubject = new BehaviorSubject<MenuItem[]>([]);
  private permissionsSubject = new BehaviorSubject<Permission[]>([]);
  
  // Observables públicos
  public user$ = this.userSubject.asObservable();
  public menus$ = this.menusSubject.asObservable();
  public permissions$ = this.permissionsSubject.asObservable();
  
  constructor(private http: HttpClient) {
    this.loadFromStorage();
  }
  
  /**
   * Carga el perfil desde el servidor
   */
  loadProfile(): Observable<Profile> {
    return this.http.get<Profile>('/api/profile').pipe(
      tap(profile => this.setProfile(profile)),
      catchError(error => {
        console.error('Error loading profile:', error);
        return of(null as any);
      })
    );
  }
  
  /**
   * Guarda el perfil en memoria y localStorage
   */
  setProfile(profile: Profile): void {
    if (!profile) return;
    
    this.userSubject.next(profile.user);
    this.menusSubject.next(profile.menus);
    this.permissionsSubject.next(profile.permissions);
    
    // Guardar en localStorage
    localStorage.setItem(this.PROFILE_KEY, JSON.stringify(profile));
  }
  
  /**
   * Carga el perfil desde localStorage al iniciar
   */
  private loadFromStorage(): void {
    const stored = localStorage.getItem(this.PROFILE_KEY);
    if (stored) {
      try {
        const profile: Profile = JSON.parse(stored);
        this.userSubject.next(profile.user);
        this.menusSubject.next(profile.menus);
        this.permissionsSubject.next(profile.permissions);
      } catch (error) {
        console.error('Error parsing profile from localStorage:', error);
        this.clearProfile();
      }
    }
  }
  
  /**
   * Limpia el perfil
   */
  clearProfile(): void {
    this.userSubject.next(null);
    this.menusSubject.next([]);
    this.permissionsSubject.next([]);
    localStorage.removeItem(this.PROFILE_KEY);
  }
  
  /**
   * Obtiene los menús filtrados por ubicación
   */
  getMenusByLocation(location: string): Observable<MenuItem[]> {
    return this.menus$.pipe(
      map(menus => menus.filter(menu => menu.location === location))
    );
  }
  
  /**
   * Obtiene el usuario actual
   */
  getCurrentUser(): User | null {
    return this.userSubject.value;
  }
  
  /**
   * Verifica si el usuario tiene un rol específico
   */
  hasRole(roleName: string): boolean {
    const user = this.userSubject.value;
    return user?.roles?.includes(roleName) ?? false;
  }
}
```

### 6.2. PermissionService

**Archivo**: `src/app/core/services/permission.service.ts`

```typescript
import { Injectable } from '@angular/core';
import { Observable, of } from 'rxjs';
import { map, shareReplay } from 'rxjs/operators';
import { ProfileService, Permission } from './profile.service';

@Injectable({
  providedIn: 'root'
})
export class PermissionService {
  
  constructor(private profileService: ProfileService) {}
  
  /**
   * Verifica si el usuario puede VER un componente
   * @param component Nombre del componente (ej: 'dashboard')
   * @returns Observable<boolean>
   */
  canView$(component: string): Observable<boolean> {
    return this.getComponentAccess$(component).pipe(
      map(access => access === 'view' || access === 'execute')
    );
  }
  
  /**
   * Verifica si el usuario puede EJECUTAR acciones en un componente
   * @param component Nombre del componente
   * @returns Observable<boolean>
   */
  canExecute$(component: string): Observable<boolean> {
    return this.getComponentAccess$(component).pipe(
      map(access => access === 'execute')
    );
  }
  
  /**
   * Verifica si el usuario puede EJECUTAR un elemento específico
   * @param component Nombre del componente
   * @param elementKey Identificador del elemento (ej: 'btn-create-user')
   * @returns Observable<boolean>
   */
  canExecute$(component: string, elementKey: string): Observable<boolean> {
    return this.getElementAccess$(component, elementKey).pipe(
      map(access => access === 'execute')
    );
  }
  
  /**
   * Verifica si el usuario puede VER un elemento específico
   * @param component Nombre del componente
   * @param elementKey Identificador del elemento
   * @returns Observable<boolean>
   */
  canView$(component: string, elementKey: string): Observable<boolean> {
    return this.getElementAccess$(component, elementKey).pipe(
      map(access => access === 'view' || access === 'execute')
    );
  }
  
  /**
   * Obtiene el nivel de acceso de un componente
   * @param component Nombre del componente
   * @returns Observable<'execute' | 'view' | 'hidden'>
   */
  private getComponentAccess$(component: string): Observable<string> {
    return this.profileService.permissions$.pipe(
      map(permissions => {
        const permission = permissions.find(p => p.component === component);
        return permission?.access ?? 'hidden';
      }),
      shareReplay(1)
    );
  }
  
  /**
   * Obtiene el nivel de acceso de un elemento
   * @param component Nombre del componente
   * @param elementKey Identificador del elemento
   * @returns Observable<'execute' | 'view' | 'hidden'>
   */
  private getElementAccess$(component: string, elementKey: string): Observable<string> {
    return this.profileService.permissions$.pipe(
      map(permissions => {
        const permission = permissions.find(p => p.component === component);
        if (!permission) return 'hidden';
        
        const element = permission.elements.find(e => e.element_key === elementKey);
        return element?.access ?? 'hidden';
      }),
      shareReplay(1)
    );
  }
  
  /**
   * Verifica si el usuario puede acceder a una ruta (usado por el Guard)
   * @param component Nombre del componente
   * @returns Promise<boolean>
   */
  async canAccessRoute(component: string): Promise<boolean> {
    return new Promise((resolve) => {
      this.profileService.permissions$.pipe(
        map(permissions => {
          const permission = permissions.find(p => p.component === component);
          
          if (!permission) {
            console.warn(`[PermissionService] No permission found for component: ${component}`);
            return false;
          }
          
          const canAccess = permission.access === 'view' || permission.access === 'execute';
          
          if (!canAccess) {
            console.warn(`[PermissionService] Access denied for component: ${component} (access: ${permission.access})`);
          }
          
          return canAccess;
        })
      ).subscribe(result => resolve(result));
    });
  }
}
```

### 6.3. permissionGuard

**Archivo**: `src/app/core/guards/permission.guard.ts`

```typescript
import { inject } from '@angular/core';
import { CanActivateFn, Router, ActivatedRouteSnapshot } from '@angular/router';
import { PermissionService } from '../services/permission.service';

/**
 * Guard que protege rutas según los permisos del usuario
 * 
 * Uso en rutas:
 * {
 *   path: 'alerts',
 *   component: AlertsComponent,
 *   canActivate: [permissionGuard],
 *   data: { component: 'alerts' }
 * }
 */
export const permissionGuard: CanActivateFn = async (route: ActivatedRouteSnapshot) => {
  const permissionService = inject(PermissionService);
  const router = inject(Router);
  
  // Obtener el nombre del componente desde route.data
  const componentName = route.data?.['component'];
  
  if (!componentName) {
    console.error('[permissionGuard] No component name found in route.data');
    router.navigate(['/dashboard']);
    return false;
  }
  
  // Verificar si el usuario tiene permiso para acceder
  const hasAccess = await permissionService.canAccessRoute(componentName);
  
  if (!hasAccess) {
    console.warn(`[permissionGuard] Access denied to: ${route.url.join('/')}`);
    router.navigate(['/dashboard']);
    return false;
  }
  
  return true;
};
```

### 6.4. Configuración de Rutas

**Archivo**: `src/app/app.routes.ts`

```typescript
import { Routes } from '@angular/router';
import { authGuard } from './core/guards/auth.guard';
import { permissionGuard } from './core/guards/permission.guard';

// Componentes
import { DashboardComponent } from './features/dashboard/dashboard.component';
import { AlertsComponent } from './features/alerts/alerts.component';
import { IncidentsComponent } from './features/incidents/incidents.component';
import { TrapsComponent } from './features/traps/traps.component';
import { UserManagementComponent } from './features/admin/user-management/user-management.component';
import { RoleManagementComponent } from './features/admin/role-management/role-management.component';
import { MenuManagementComponent } from './features/admin/menu-management/menu-management.component';
import { AuditViewerComponent } from './features/admin/audit-viewer/audit-viewer.component';

export const routes: Routes = [
  {
    path: '',
    redirectTo: '/dashboard',
    pathMatch: 'full'
  },
  {
    path: 'dashboard',
    component: DashboardComponent,
    canActivate: [authGuard, permissionGuard],
    data: { component: 'dashboard' }  // ← Nombre del componente para validación
  },
  {
    path: 'graphics',
    component: DashboardComponent,
    canActivate: [authGuard, permissionGuard],
    data: { component: 'dashboard' }
  },
  {
    path: 'alerts',
    component: AlertsComponent,
    canActivate: [authGuard, permissionGuard],
    data: { component: 'alerts' }
  },
  {
    path: 'incidents',
    component: IncidentsComponent,
    canActivate: [authGuard, permissionGuard],
    data: { component: 'incidents' }
  },
  {
    path: 'traps',
    component: TrapsComponent,
    canActivate: [authGuard, permissionGuard],
    data: { component: 'traps' }
  },
  {
    path: 'admin',
    canActivate: [authGuard],
    children: [
      {
        path: 'users',
        component: UserManagementComponent,
        canActivate: [permissionGuard],
        data: { component: 'user-management' }
      },
      {
        path: 'roles',
        component: RoleManagementComponent,
        canActivate: [permissionGuard],
        data: { component: 'role-management' }
      },
      {
        path: 'menus',
        component: MenuManagementComponent,
        canActivate: [permissionGuard],
        data: { component: 'menu-management' }
      },
      {
        path: 'audit',
        component: AuditViewerComponent,
        canActivate: [permissionGuard],
        data: { component: 'audit-viewer' }
      }
    ]
  }
];
```

### 6.5. Ejemplo de Componente con Permisos

**Archivo**: `src/app/features/alerts/alerts.component.ts`

```typescript
import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Observable, firstValueFrom } from 'rxjs';
import { PermissionService } from '@core/services/permission.service';

@Component({
  selector: 'app-alerts',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './alerts.component.html',
  styleUrls: ['./alerts.component.scss']
})
export class AlertsComponent implements OnInit {
  
  // Observables de permisos
  canSearch$: Observable<boolean>;
  canExport$: Observable<boolean>;
  canViewColumns$: Observable<boolean>;
  canPaginate$: Observable<boolean>;
  
  // Propiedades del componente
  searchTerm: string = '';
  alerts: any[] = [];
  
  constructor(private permissionService: PermissionService) {
    // Inicializar permisos en constructor
    this.canSearch$ = this.permissionService.canExecute$('alerts', 'searchInput');
    this.canExport$ = this.permissionService.canExecute$('alerts', 'btn-export');
    this.canViewColumns$ = this.permissionService.canExecute$('alerts', 'columnsMenuBtn');
    this.canPaginate$ = this.permissionService.canExecute$('alerts', 'paginator');
  }
  
  ngOnInit(): void {
    this.loadAlerts();
  }
  
  async exportData() {
    // Validar permiso antes de ejecutar acción crítica
    const canExport = await firstValueFrom(this.canExport$);
    if (!canExport) {
      console.warn('User does not have permission to export');
      return;
    }
    
    // Lógica de exportación
    console.log('Exporting data...');
  }
  
  loadAlerts() {
    // Lógica para cargar alertas
  }
}
```

**Template**: `src/app/features/alerts/alerts.component.html`

```html
<div class="alerts-container">
  
  <!-- Header con título y acciones -->
  <div class="alerts-header">
    <h1>Alertas</h1>
    
    <!-- Botón de exportar (solo si tiene permiso) -->
    <button *ngIf="canExport$ | async"
            class="btn btn-primary"
            (click)="exportData()">
      <mat-icon>download</mat-icon>
      Exportar
    </button>
  </div>
  
  <!-- Barra de búsqueda (solo si tiene permiso) -->
  <div class="alerts-filters" *ngIf="canSearch$ | async">
    <input type="text"
           placeholder="Buscar alertas..."
           class="search-input"
           [(ngModel)]="searchTerm">
  </div>
  
  <!-- Tabla de alertas -->
  <div class="alerts-table">
    <table mat-table [dataSource]="alerts">
      
      <!-- Columnas -->
      <ng-container matColumnDef="timestamp">
        <th mat-header-cell *matHeaderCellDef>Fecha</th>
        <td mat-cell *matCellDef="let alert">{{ alert.timestamp | date }}</td>
      </ng-container>
      
      <ng-container matColumnDef="severity">
        <th mat-header-cell *matHeaderCellDef>Severidad</th>
        <td mat-cell *matCellDef="let alert">{{ alert.severity }}</td>
      </ng-container>
      
      <tr mat-header-row *matHeaderRowDef="displayedColumns"></tr>
      <tr mat-row *matRowDef="let row; columns: displayedColumns;"></tr>
    </table>
    
    <!-- Paginador (solo si tiene permiso) -->
    <mat-paginator *ngIf="canPaginate$ | async"
                   [pageSize]="10"
                   [pageSizeOptions]="[5, 10, 25, 100]">
    </mat-paginator>
  </div>
  
</div>
```

### 6.6. NavbarComponent (Consumiendo Menús)

**Archivo**: `src/app/core/components/navbar/navbar.component.ts`

```typescript
import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { ProfileService, MenuItem } from '@core/services/profile.service';

@Component({
  selector: 'app-navbar',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './navbar.component.html',
  styleUrls: ['./navbar.component.scss']
})
export class NavbarComponent implements OnInit {
  
  navbarMenus$: Observable<MenuItem[]>;
  
  constructor(private profileService: ProfileService) {
    // Filtrar menús con location: 'navbar'
    this.navbarMenus$ = this.profileService.menus$.pipe(
      map(menus => menus.filter(menu => menu.location === 'navbar')),
      map(menus => menus.sort((a, b) => a.order_index - b.order_index))
    );
  }
  
  ngOnInit(): void {}
}
```

**Template**: `src/app/core/components/navbar/navbar.component.html`

```html
<nav class="navbar">
  <ul class="navbar-menu">
    <li *ngFor="let menu of navbarMenus$ | async" class="navbar-item">
      
      <!-- Menú tipo ITEM (enlace directo) -->
      <a *ngIf="menu.item_type === 'ITEM'"
         [routerLink]="menu.route"
         routerLinkActive="active"
         [class.disabled]="menu.access === 'view'">
        <i [class]="'icon-' + menu.icon"></i>
        <span>{{ menu.title }}</span>
      </a>
      
      <!-- Menú tipo GROUP (dropdown) -->
      <div *ngIf="menu.item_type === 'GROUP'" class="navbar-dropdown">
        <button class="dropdown-trigger">
          <i [class]="'icon-' + menu.icon"></i>
          <span>{{ menu.title }}</span>
          <i class="icon-chevron-down"></i>
        </button>
        
        <ul class="dropdown-menu">
          <li *ngFor="let child of menu.children">
            <a [routerLink]="child.route"
               [class.disabled]="child.access === 'view'">
              <i [class]="'icon-' + child.icon"></i>
              <span>{{ child.title }}</span>
            </a>
          </li>
        </ul>
      </div>
      
    </li>
  </ul>
</nav>
```

---

## 7. Testing

### 7.1. Unit Tests: PermissionService

**Archivo**: `src/app/core/services/permission.service.spec.ts`

```typescript
import { TestBed } from '@angular/core/testing';
import { PermissionService } from './permission.service';
import { ProfileService, Permission } from './profile.service';
import { BehaviorSubject } from 'rxjs';

describe('PermissionService', () => {
  let service: PermissionService;
  let profileServiceSpy: jasmine.SpyObj<ProfileService>;
  let permissionsSubject: BehaviorSubject<Permission[]>;
  
  beforeEach(() => {
    // Mock data
    const mockPermissions: Permission[] = [
      {
        component: 'dashboard',
        route: '/graphics',
        access: 'execute',
        elements: [
          { element_key: 'filterButton', access: 'hidden' },
          { element_key: 'refreshButton', access: 'execute' }
        ]
      },
      {
        component: 'alerts',
        route: '/alerts',
        access: 'view',
        elements: [
          { element_key: 'btn-create', access: 'hidden' }
        ]
      }
    ];
    
    permissionsSubject = new BehaviorSubject<Permission[]>(mockPermissions);
    
    // Spy de ProfileService
    const spy = jasmine.createSpyObj('ProfileService', [], {
      permissions$: permissionsSubject.asObservable()
    });
    
    TestBed.configureTestingModule({
      providers: [
        PermissionService,
        { provide: ProfileService, useValue: spy }
      ]
    });
    
    service = TestBed.inject(PermissionService);
    profileServiceSpy = TestBed.inject(ProfileService) as jasmine.SpyObj<ProfileService>;
  });
  
  it('should be created', () => {
    expect(service).toBeTruthy();
  });
  
  describe('canExecute$() - component level', () => {
    it('should return true for component with EXECUTE access', (done) => {
      service.canExecute$('dashboard').subscribe(result => {
        expect(result).toBe(true);
        done();
      });
    });
    
    it('should return false for component with VIEW access', (done) => {
      service.canExecute$('alerts').subscribe(result => {
        expect(result).toBe(false);
        done();
      });
    });
    
    it('should return false for non-existent component', (done) => {
      service.canExecute$('non-existent').subscribe(result => {
        expect(result).toBe(false);
        done();
      });
    });
  });
  
  describe('canView$() - component level', () => {
    it('should return true for component with EXECUTE access', (done) => {
      service.canView$('dashboard').subscribe(result => {
        expect(result).toBe(true);
        done();
      });
    });
    
    it('should return true for component with VIEW access', (done) => {
      service.canView$('alerts').subscribe(result => {
        expect(result).toBe(true);
        done();
      });
    });
    
    it('should return false for non-existent component', (done) => {
      service.canView$('non-existent').subscribe(result => {
        expect(result).toBe(false);
        done();
      });
    });
  });
  
  describe('canExecute$() - element level', () => {
    it('should return true for element with EXECUTE access', (done) => {
      service.canExecute$('dashboard', 'refreshButton').subscribe(result => {
        expect(result).toBe(true);
        done();
      });
    });
    
    it('should return false for element with HIDDEN access', (done) => {
      service.canExecute$('dashboard', 'filterButton').subscribe(result => {
        expect(result).toBe(false);
        done();
      });
    });
    
    it('should return false for non-existent element', (done) => {
      service.canExecute$('dashboard', 'non-existent').subscribe(result => {
        expect(result).toBe(false);
        done();
      });
    });
  });
  
  describe('canAccessRoute()', () => {
    it('should return true for component with EXECUTE access', async () => {
      const result = await service.canAccessRoute('dashboard');
      expect(result).toBe(true);
    });
    
    it('should return true for component with VIEW access', async () => {
      const result = await service.canAccessRoute('alerts');
      expect(result).toBe(true);
    });
    
    it('should return false for non-existent component', async () => {
      const result = await service.canAccessRoute('non-existent');
      expect(result).toBe(false);
    });
  });
});
```

### 7.2. Unit Tests: permissionGuard

**Archivo**: `src/app/core/guards/permission.guard.spec.ts`

```typescript
import { TestBed } from '@angular/core/testing';
import { Router, ActivatedRouteSnapshot } from '@angular/router';
import { permissionGuard } from './permission.guard';
import { PermissionService } from '../services/permission.service';

describe('permissionGuard', () => {
  let permissionServiceSpy: jasmine.SpyObj<PermissionService>;
  let routerSpy: jasmine.SpyObj<Router>;
  
  beforeEach(() => {
    const permSpy = jasmine.createSpyObj('PermissionService', ['canAccessRoute']);
    const routSpy = jasmine.createSpyObj('Router', ['navigate']);
    
    TestBed.configureTestingModule({
      providers: [
        { provide: PermissionService, useValue: permSpy },
        { provide: Router, useValue: routSpy }
      ]
    });
    
    permissionServiceSpy = TestBed.inject(PermissionService) as jasmine.SpyObj<PermissionService>;
    routerSpy = TestBed.inject(Router) as jasmine.SpyObj<Router>;
  });
  
  it('should allow access when user has permission', async () => {
    // Arrange
    const route = {
      data: { component: 'dashboard' },
      url: []
    } as any as ActivatedRouteSnapshot;
    
    permissionServiceSpy.canAccessRoute.and.returnValue(Promise.resolve(true));
    
    // Act
    const result = await TestBed.runInInjectionContext(() => permissionGuard(route, {} as any));
    
    // Assert
    expect(result).toBe(true);
    expect(permissionServiceSpy.canAccessRoute).toHaveBeenCalledWith('dashboard');
    expect(routerSpy.navigate).not.toHaveBeenCalled();
  });
  
  it('should deny access and redirect when user lacks permission', async () => {
    // Arrange
    const route = {
      data: { component: 'alerts' },
      url: [{ path: 'alerts' }]
    } as any as ActivatedRouteSnapshot;
    
    permissionServiceSpy.canAccessRoute.and.returnValue(Promise.resolve(false));
    
    // Act
    const result = await TestBed.runInInjectionContext(() => permissionGuard(route, {} as any));
    
    // Assert
    expect(result).toBe(false);
    expect(permissionServiceSpy.canAccessRoute).toHaveBeenCalledWith('alerts');
    expect(routerSpy.navigate).toHaveBeenCalledWith(['/dashboard']);
  });
  
  it('should deny access when component name is missing', async () => {
    // Arrange
    const route = {
      data: {},
      url: []
    } as any as ActivatedRouteSnapshot;
    
    // Act
    const result = await TestBed.runInInjectionContext(() => permissionGuard(route, {} as any));
    
    // Assert
    expect(result).toBe(false);
    expect(routerSpy.navigate).toHaveBeenCalledWith(['/dashboard']);
  });
});
```

### 7.3. Integration Tests: Component con Permisos

**Archivo**: `src/app/features/alerts/alerts.component.spec.ts`

```typescript
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { AlertsComponent } from './alerts.component';
import { PermissionService } from '@core/services/permission.service';
import { of } from 'rxjs';
import { DebugElement } from '@angular/core';
import { By } from '@angular/platform-browser';

describe('AlertsComponent', () => {
  let component: AlertsComponent;
  let fixture: ComponentFixture<AlertsComponent>;
  let permissionServiceSpy: jasmine.SpyObj<PermissionService>;
  
  beforeEach(async () => {
    const spy = jasmine.createSpyObj('PermissionService', ['canExecute$']);
    
    await TestBed.configureTestingModule({
      imports: [AlertsComponent],
      providers: [
        { provide: PermissionService, useValue: spy }
      ]
    }).compileComponents();
    
    permissionServiceSpy = TestBed.inject(PermissionService) as jasmine.SpyObj<PermissionService>;
    
    // Mock default responses
    permissionServiceSpy.canExecute$.and.callFake((component: string, element?: string) => {
      if (element === 'searchInput') return of(true);
      if (element === 'btn-export') return of(false);
      if (element === 'columnsMenuBtn') return of(true);
      if (element === 'paginator') return of(true);
      return of(false);
    });
    
    fixture = TestBed.createComponent(AlertsComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });
  
  it('should create', () => {
    expect(component).toBeTruthy();
  });
  
  it('should show search input when user has permission', () => {
    const searchInput: DebugElement = fixture.debugElement.query(By.css('.search-input'));
    expect(searchInput).toBeTruthy();
  });
  
  it('should hide export button when user lacks permission', () => {
    const exportButton: DebugElement = fixture.debugElement.query(By.css('.btn-export'));
    expect(exportButton).toBeNull();
  });
  
  it('should not call exportData when user lacks permission', async () => {
    spyOn(console, 'warn');
    
    await component.exportData();
    
    expect(console.warn).toHaveBeenCalledWith('User does not have permission to export');
  });
});
```

### 7.4. E2E Tests: Flujo Completo

**Archivo**: `e2e/src/permissions.e2e-spec.ts`

```typescript
import { browser, by, element, ExpectedConditions as EC } from 'protractor';

describe('Permissions E2E Tests', () => {
  
  beforeEach(async () => {
    await browser.get('/');
  });
  
  describe('User with TENANT_ADMIN role', () => {
    
    beforeEach(async () => {
      // Login como TENANT_ADMIN
      await element(by.id('username')).sendKeys('admin.tenant');
      await element(by.id('password')).sendKeys('password123');
      await element(by.css('button[type="submit"]')).click();
      
      // Esperar código OTP
      await browser.wait(EC.visibilityOf(element(by.id('otp-input'))), 5000);
      await element(by.id('otp-input')).sendKeys('123456');
      await element(by.css('button[type="submit"]')).click();
      
      // Esperar que cargue el dashboard
      await browser.wait(EC.urlContains('/dashboard'), 5000);
    });
    
    it('should see Dashboard menu in navbar', async () => {
      const dashboardMenu = element(by.css('.navbar-item[href="/graphics"]'));
      expect(await dashboardMenu.isDisplayed()).toBe(true);
    });
    
    it('should see Alerts menu in navbar', async () => {
      const alertsMenu = element(by.css('.navbar-item[href="/alerts"]'));
      expect(await alertsMenu.isDisplayed()).toBe(true);
    });
    
    it('should navigate to Alerts page', async () => {
      await element(by.css('.navbar-item[href="/alerts"]')).click();
      await browser.wait(EC.urlContains('/alerts'), 5000);
      
      expect(await browser.getCurrentUrl()).toContain('/alerts');
    });
    
    it('should see search input in Alerts page', async () => {
      await element(by.css('.navbar-item[href="/alerts"]')).click();
      await browser.wait(EC.urlContains('/alerts'), 5000);
      
      const searchInput = element(by.css('.search-input'));
      expect(await searchInput.isDisplayed()).toBe(true);
    });
    
    it('should NOT see Administration menu (hidden)', async () => {
      const adminMenu = element(by.css('.navbar-item:contains("Administración")'));
      expect(await adminMenu.isPresent()).toBe(false);
    });
  });
  
  describe('User with VIEWER role', () => {
    
    beforeEach(async () => {
      // Login como VIEWER
      await element(by.id('username')).sendKeys('viewer.user');
      await element(by.id('password')).sendKeys('password123');
      await element(by.css('button[type="submit"]')).click();
      
      await browser.wait(EC.visibilityOf(element(by.id('otp-input'))), 5000);
      await element(by.id('otp-input')).sendKeys('123456');
      await element(by.css('button[type="submit"]')).click();
      
      await browser.wait(EC.urlContains('/dashboard'), 5000);
    });
    
    it('should NOT see create button in Alerts page', async () => {
      await browser.get('/alerts');
      
      const createButton = element(by.css('.btn-create'));
      expect(await createButton.isPresent()).toBe(false);
    });
    
    it('should be redirected when trying to access /admin/users', async () => {
      await browser.get('/admin/users');
      await browser.wait(EC.urlContains('/dashboard'), 5000);
      
      expect(await browser.getCurrentUrl()).toContain('/dashboard');
    });
  });
});
```

---

## 8. Validaciones y Reglas de Negocio

### 8.1. Validaciones en Base de Datos

#### 8.1.1. Integridad Referencial

```sql
-- Un menú no puede ser padre de sí mismo
ALTER TABLE nxc_menu.menu_items 
ADD CONSTRAINT chk_menu_not_self_parent 
CHECK (id != parent_id);

-- Un menú tipo ITEM debe tener ruta
ALTER TABLE nxc_menu.menu_items 
ADD CONSTRAINT chk_item_has_route 
CHECK (item_type != 'ITEM' OR route IS NOT NULL);

-- Un menú tipo GROUP no debe tener ruta
ALTER TABLE nxc_menu.menu_items 
ADD CONSTRAINT chk_group_no_route 
CHECK (item_type != 'GROUP' OR route IS NULL);
```

#### 8.1.2. Validaciones de Permisos

```sql
-- No puede haber permisos duplicados para el mismo tenant + rol + componente
-- (Ya garantizado por UNIQUE constraint)

-- Validar que access tenga valores válidos
-- (Ya garantizado por ENUM type: nxc_menu.access_level)
```

### 8.2. Reglas de Negocio

#### 8.2.1. Jerarquía de Acceso

**Regla**: Si un usuario tiene múltiples roles, se toma el nivel de acceso más permisivo.

**Ejemplo**:
- Usuario tiene roles: VIEWER y EDITOR
- VIEWER: component 'alerts' → access: VIEW
- EDITOR: component 'alerts' → access: EXECUTE
- **Resultado**: access: EXECUTE (más permisivo)

**Implementación**: Las vistas SQL ya aplican esta lógica con `CASE WHEN COUNT(*) FILTER`.

#### 8.2.2. Permisos de Elementos Heredan del Componente

**Regla**: Si un componente tiene access: HIDDEN, todos sus elementos se consideran HIDDEN automáticamente.

**Implementación en Frontend**:

```typescript
canExecute$(component: string, elementKey: string): Observable<boolean> {
  return this.getComponentAccess$(component).pipe(
    switchMap(componentAccess => {
      // Si el componente está oculto, todos sus elementos también
      if (componentAccess === 'hidden') {
        return of(false);
      }
      
      // Si no, consultar el permiso específico del elemento
      return this.getElementAccess$(component, elementKey).pipe(
        map(access => access === 'execute')
      );
    })
  );
}
```

#### 8.2.3. Menús Padre e Hijos

**Regla**: Si un menú GROUP tiene access: HIDDEN, todos sus hijos se ocultan automáticamente.

**Implementación**: El frontend no renderiza los hijos de un GROUP oculto.

```typescript
// En NavbarComponent
navbarMenus$ = this.profileService.menus$.pipe(
  map(menus => menus.filter(menu => 
    menu.location === 'navbar' && menu.access !== 'hidden'
  )),
  map(menus => menus.map(menu => ({
    ...menu,
    // Solo incluir hijos visibles
    children: menu.children.filter(child => child.access !== 'hidden')
  })))
);
```

#### 8.2.4. Usuarios Sin Roles

**Regla**: Si un usuario no tiene roles asignados, no puede acceder a ningún componente.

**Implementación**: Las vistas SQL no retornan datos si no hay roles.

---

## 9. Consideraciones de Seguridad

### 9.1. Validación Backend

⚠️ **CRÍTICO**: Los permisos en frontend son solo para UX. **Siempre validar en backend**.

**Ejemplo de validación en backend**:

```java
@RestController
@RequestMapping("/api/alerts")
public class AlertController {
    
    @Autowired
    private PermissionService permissionService;
    
    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteAlert(@PathVariable UUID id, Authentication auth) {
        // Validar permiso antes de ejecutar
        if (!permissionService.hasPermission(auth.getUserId(), "alerts", "btn-delete")) {
            throw new AccessDeniedException("You don't have permission to delete alerts");
        }
        
        // Proceder con la lógica
        alertService.delete(id);
        return ResponseEntity.ok().build();
    }
}
```

### 9.2. Tokens y Autenticación

- **Access Token**: Se envía en header `Authorization: Bearer <token>`
- **Refresh Token**: Preferir gestión en `HttpOnly` cookies
- **Expiración**: Recargar perfil cuando el token expire o se renueve

### 9.3. Prevención de Escalada de Privilegios

- No permitir que un usuario modifique sus propios roles desde frontend
- Toda modificación de roles/permisos debe pasar por auditoría
- Implementar RLS (Row-Level Security) en PostgreSQL para multi-tenancy

---

## 10. Casos de Uso Adicionales

### 10.1. Agregar un Nuevo Componente

**Pasos**:

1. **Backend**: Crear componente en BD
```sql
INSERT INTO nxc_menu.components (id, tenant_id, module_key, name, route, is_system)
VALUES (
  gen_random_uuid(), 
  '<tenant_id>', 
  'reports', 
  'Reportes', 
  '/reports',
  FALSE
);
```

2. **Backend**: Crear elementos del componente
```sql
INSERT INTO nxc_menu.component_elements (id, tenant_id, component_id, element_key, label, element_type)
VALUES 
(
  gen_random_uuid(), 
  '<tenant_id>', 
  (SELECT id FROM nxc_menu.components WHERE module_key = 'reports' AND tenant_id = '<tenant_id>'), 
  'btn-create', 
  'Botón Crear',
  'BUTTON'
),
(
  gen_random_uuid(), 
  '<tenant_id>',
  (SELECT id FROM nxc_menu.components WHERE module_key = 'reports' AND tenant_id = '<tenant_id>'), 
  'btn-export', 
  'Botón Exportar',
  'BUTTON'
);
```

3. **Backend**: Asignar permisos a roles
```sql
INSERT INTO nxc_menu.component_permissions (id, tenant_id, role_id, component_id, access)
VALUES (
  gen_random_uuid(), 
  '<tenant_id>', 
  '<role_id>', 
  (SELECT id FROM nxc_menu.components WHERE module_key = 'reports' AND tenant_id = '<tenant_id>'),
  'EXECUTE'
);
```

4. **Frontend**: Crear componente Angular
```bash
ng generate component features/reports
```

5. **Frontend**: Configurar ruta con guard
```typescript
{
  path: 'reports',
  component: ReportsComponent,
  canActivate: [authGuard, permissionGuard],
  data: { component: 'reports' }
}
```

6. **Frontend**: Implementar permisos en componente
```typescript
canCreate$ = this.permissionService.canExecute$('reports', 'btn-create');
```

### 10.2. Cambiar Ubicación de un Menú

**Situación**: Mover "Reportes" de navbar a profile dropdown

```sql
UPDATE nxc_menu.menu_items
SET location = 'profile',
    parent_id = (SELECT id FROM nxc_menu.menu_items WHERE name = 'ProfileMenu')
WHERE name = 'Reports';
```

**Resultado**: El frontend automáticamente mostrará "Reportes" en el dropdown de perfil.

### 10.3. Deshabilitar Temporalmente un Componente

```sql
-- Opción 1: Ocultar el menú enlazado al componente
UPDATE nxc_menu.menu_items
SET is_visible = false
WHERE component_id = (SELECT id FROM nxc_menu.components WHERE module_key = 'reports' AND tenant_id = '<tenant_id>');

-- Opción 2: Cambiar todos los permisos a HIDDEN
UPDATE nxc_menu.component_permissions
SET access = 'HIDDEN'
WHERE component_id = (SELECT id FROM nxc_menu.components WHERE module_key = 'reports' AND tenant_id = '<tenant_id>');

-- Opción 3: Marcar como eliminado (soft delete)
UPDATE nxc_menu.components
SET deleted_at = NOW()
WHERE module_key = 'reports' AND tenant_id = '<tenant_id>';
```

---

## 11. Troubleshooting

### 11.1. Menú No Aparece en Navbar

**Posibles causas**:

1. ✅ Verificar que el menú existe en `menu_items`
```sql
SELECT * FROM nxc_menu.menu_items WHERE name = 'Reports';
```

2. ✅ Verificar que el componente enlazado tiene permisos para el rol
```sql
SELECT 
    mi.name, 
    mi.title, 
    c.module_key, 
    r.role_name, 
    cp.access AS component_access,
    mi.default_access
FROM nxc_menu.menu_items mi
LEFT JOIN nxc_menu.components c ON c.id = mi.component_id
LEFT JOIN nxc_menu.component_permissions cp ON cp.component_id = c.id
LEFT JOIN nxc_tenant.roles r ON r.id = cp.role_id
WHERE mi.name = 'Reports'
  AND mi.tenant_id = '<tenant_id>';
```

3. ✅ Verificar que el acceso efectivo no sea 'HIDDEN'
4. ✅ Verificar que `location` sea 'navbar' y `is_visible` sea TRUE
5. ✅ Recargar perfil en frontend (logout + login)

### 11.2. Guard Bloquea la Ruta

**Posibles causas**:

1. ✅ Verificar que el componente existe en `components`
2. ✅ Verificar que hay permiso para el rol
```sql
SELECT 
    cp.*, 
    c.module_key, 
    c.name AS component_name,
    r.role_name, 
    cp.access
FROM nxc_menu.component_permissions cp
JOIN nxc_menu.components c ON c.id = cp.component_id
JOIN nxc_tenant.roles r ON r.id = cp.role_id
WHERE c.module_key = 'reports'
  AND cp.tenant_id = '<tenant_id>';
```

3. ✅ Verificar que `access` sea 'EXECUTE' o 'VIEW'
4. ✅ Verificar que `route.data.component` coincida con `module_key`

### 11.3. Todos los Botones Aparecen

**Posibles causas**:

1. ✅ Verificar que existen permisos de elementos
```sql
SELECT 
    ep.*, 
    ce.element_key, 
    ce.label,
    ep.access,
    r.role_name
FROM nxc_menu.element_permissions ep
JOIN nxc_menu.component_elements ce ON ce.id = ep.element_id
JOIN nxc_tenant.roles r ON r.id = ep.role_id
WHERE ce.component_id = (SELECT id FROM nxc_menu.components WHERE module_key = 'reports' AND tenant_id = '<tenant_id>')
  AND ep.tenant_id = '<tenant_id>';
```

2. ✅ Verificar que el componente usa `*ngIf` con permisos
3. ✅ Verificar que se inicializan los Observables en constructor
4. ✅ Verificar que se usa `async pipe` en template

---

## 12. Glosario

| Término | Definición |
|---------|------------|
| **RBAC** | Role-Based Access Control - Control de acceso basado en roles |
| **Component** | Módulo o página de la aplicación (ej: dashboard, alerts) |
| **Element** | Parte específica de un componente (botón, input, sección) |
| **Menu Item** | Opción de navegación que aparece en UI |
| **Access Level** | Nivel de permiso: EXECUTE, VIEW o HIDDEN |
| **Guard** | Función que protege rutas antes de permitir navegación |
| **Observable** | Stream reactivo de RxJS que emite valores en el tiempo |
| **async pipe** | Pipe de Angular que se suscribe automáticamente a Observables |

---

## 13. Referencias

- Documentación PostgreSQL Row-Level Security: https://www.postgresql.org/docs/current/ddl-rowsecurity.html
- Angular Router Guards: https://angular.io/guide/router#preventing-unauthorized-access
- RxJS Operators: https://rxjs.dev/guide/operators
- Tabler Icons: https://tabler.io/icons

---

**Fecha de especificación**: 23 de mayo de 2026  
**Versión**: 1.0  
**Autor**: GitHub Copilot  
**Estado**: ✅ Completa y lista para implementación
