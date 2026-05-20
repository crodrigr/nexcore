# NexCore — Especificaciones y Criterios de Aceptación
## Módulo: `module-menu`
**Versión:** 1.0  
**Schemas DB:** `nxc_menu`, `nxc_tenant`, `nxc_config`  
**Paquete base:** `com.nexore.core.module.menu`  
**Ubicación:** `nexcore-core/src/main/java/com/nexore/core/module/menu/`  
**Fecha:** 2026-05

---

## 1. Contexto y propósito

El módulo `module-menu` es responsable de construir y entregar el **perfil completo de UI** de un usuario autenticado. Este perfil es el contrato entre el backend y el frontend Angular: contiene todo lo que la SPA necesita para saber qué renderizar, qué deshabilitar y cómo organizar la navegación, sin necesidad de hacer llamadas adicionales tras el login.

El perfil se divide en tres bloques:

| Bloque | Contenido |
|---|---|
| `user` | Datos de identidad del usuario (nombre, email, roles asignados) |
| `permissions` | Permisos sobre componentes de UI y sus elementos, filtrados por los roles del usuario |
| `menus` | Árbol de navegación filtrado: solo los ítems accesibles para el usuario |

> **Importante:** La configuración de menús, componentes, elementos y permisos por rol se administra **directamente en la base de datos** mediante el script de seed (`02-migrate-base.sql`). Este módulo **no expone servicios CRUD** para esas entidades. Su única responsabilidad es la consulta y ensamblaje del perfil.

**Dependencias de dominio:**

```
module-menu → nxc_tenant.users, nxc_tenant.roles, nxc_tenant.user_roles
           → nxc_menu.components, nxc_menu.component_elements
           → nxc_menu.menu_items, nxc_menu.component_permissions
           → nxc_menu.element_permissions, nxc_menu.user_element_overrides
           → nxc_tenant.v_user_login_profile  (vista de utilidad)
           → nxc_menu.v_menu_effective_access (vista de utilidad)
```

---

## 2. Modelos del dominio

> Todos los modelos de este módulo son **de solo lectura** (no tienen setters de escritura de negocio). Son value objects o agregados inmutables ensamblados durante la consulta del perfil.

---

### 2.1 UserProfile *(aggregate root)*

Representa el perfil completo de UI que se retorna al frontend.

| Campo | Tipo | Descripción |
|---|---|---|
| `user` | `UserInfo` | Datos de identidad del usuario |
| `permissions` | `List<ComponentPermission>` | Permisos sobre componentes. Solo los accesibles (access ≥ VIEW) |
| `menus` | `List<MenuItem>` | Árbol de menú raíz (parent_id IS NULL). Ítems HIDDEN excluidos |
| `token` | `String` | JWT de sesión. `null` en fase MVP (JWT no implementado aún) |

---

### 2.2 UserInfo *(value object)*

| Campo | Tipo | Descripción |
|---|---|---|
| `id` | UUID | ID del usuario (`nxc_tenant.users.id`) |
| `username` | String | Nombre de usuario |
| `name` | String | Nombre completo (`full_name`) |
| `email` | String | Email del usuario |
| `phone` | String | Teléfono. Puede ser `null` |
| `photo` | String | URL de la foto de perfil. Puede ser `null` |
| `roles` | `List<String>` | Nombres de los roles activos asignados (ej. `["TENANT_ADMIN", "EDITOR"]`) |

---

### 2.3 ComponentPermission *(value object)*

Representa el acceso de un usuario a un componente de UI y sus elementos interactivos.

| Campo | Tipo | Descripción |
|---|---|---|
| `component` | String | `module_key` del componente (ej. `"dashboard"`) |
| `route` | String | Ruta Angular del componente (ej. `"/graphics"`) |
| `allowedActions` | `List<String>` | Acciones semánticas habilitadas para el usuario en este componente |
| `elements` | `List<ElementPermission>` | Elementos de UI con acceso ≥ VIEW |

**Reglas de inclusión:**
- Solo se incluye un componente si el **nivel de acceso efectivo** del usuario sobre él es ≥ `VIEW`.
- Si el acceso es `VIEW`, solo se añade la acción `"view"` y los elementos no ejecutables no tienen acción.
- Si el acceso es `EXECUTE`, se añaden todas las acciones habilitadas por los elementos EXECUTE.

---

### 2.4 ElementPermission *(value object)*

| Campo | Tipo | Descripción |
|---|---|---|
| `elementKey` | String | Clave técnica del elemento (ej. `"filterButton"`, `"app-alert-groups[groupSelected]"`) |
| `action` | String | Evento DOM / acción semántica del elemento (ej. `"click"`, `"emit"`) |

**Solo se incluyen elementos con acceso efectivo ≥ `VIEW`.**  
El campo `action` corresponde al tipo de evento DOM que el frontend escucha sobre ese elemento.

---

### 2.5 MenuItem *(value object)*

Nodo del árbol de navegación visible para el usuario.

| Campo | Tipo | Descripción |
|---|---|---|
| `id` | UUID | ID del ítem de menú |
| `name` | String | Nombre técnico del ítem (ej. `"Dashboard"`, `"ProfileMenu"`) |
| `title` | String | Etiqueta localizable para mostrar al usuario |
| `route` | String | Ruta Angular. `null` para GROUPs sin ruta propia |
| `icon` | String | Nombre del icono (ej. `"layout-dashboard"`, `"bell"`) |
| `iconType` | String | Librería de iconos: `"tabler"` \| `"material"` \| `"custom"` |
| `itemType` | `MenuItemType` | `GROUP \| ITEM \| DIVIDER \| EXTERNAL_LINK` |
| `orderIndex` | Integer | Posición dentro del mismo nivel del árbol |
| `children` | `List<MenuItem>` | Ítems hijo. Lista vacía si no tiene hijos |

---

### 2.6 AccessLevel *(enum)*

| Valor | Orden | Significado |
|---|---|---|
| `HIDDEN` | 0 | No visible. El ítem/elemento no se incluye en la respuesta |
| `VIEW` | 1 | Visible pero deshabilitado. El frontend lo renderiza inactivo |
| `EXECUTE` | 2 | Visible y habilitado. El usuario puede interactuar con él |

> Para usuarios con múltiples roles, se aplica el **nivel máximo** (EXECUTE > VIEW > HIDDEN) entre todos los roles activos del usuario.

---

### 2.7 MenuItemType *(enum)*

| Valor | Descripción |
|---|---|
| `GROUP` | Agrupador sin ruta propia (ej. dropdown "Perfil", sección "Administración") |
| `ITEM` | Ítem navegable con ruta propia |
| `DIVIDER` | Separador visual entre secciones del menú |
| `EXTERNAL_LINK` | Enlace externo que abre en nueva pestaña |

---

## 3. Resolución de nivel de acceso efectivo

Cuando un usuario tiene **múltiples roles**, el sistema debe calcular un único nivel de acceso por componente y por elemento.

### Regla general: máximo entre roles

El nivel de acceso efectivo es el **máximo** nivel de acceso entre todos los roles activos del usuario:

```
acceso_efectivo = MAX(access por role_1, access por role_2, ..., access por role_n)
donde: EXECUTE(2) > VIEW(1) > HIDDEN(0)
```

**Ejemplo:**
| Rol | Acceso dashboard |
|---|---|
| VIEWER | VIEW |
| EDITOR | EXECUTE |
| **Efectivo** | **EXECUTE** |

### Overrides por usuario

La tabla `nxc_menu.user_element_overrides` permite sobreescribir el permiso de rol para un elemento específico. El override de usuario tiene **prioridad** sobre el permiso de rol:

```
acceso_final_elemento = override_usuario ?? acceso_efectivo_por_rol
```

Si existe un override con `expires_at` expirado, se ignora y se usa el acceso por rol.

---

## 4. Derivación de `allowedActions`

El campo `allowedActions` de `ComponentPermission` es una lista de etiquetas semánticas que describen qué puede hacer el usuario en ese componente. Se construye a partir de los elementos con acceso ≥ EXECUTE.

### Tabla de mapeo: element_key → allowed_action

| `element_key` (patrón) | `action` DOM | `allowed_action` semántica |
|---|---|---|
| `*FilterSelect*`, `*Filter*` | `change` | `filter` |
| `filterButton` | `click` | `filter` |
| `refreshButton` | `click` | `refresh` |
| `columnsMenuBtn` | `click` | `toggle-columns` |
| `toggleColumnItem` | `click` | `toggle-columns` |
| `resetColumnsBtn` | `click` | `toggle-columns` |
| `searchInput` | `keyup` | `filter` |
| `paginator` | `page` | `paginate` |
| `matSortHeader` | `sort` | `sort` |
| `rowClickToggle` | `click` | `expand-row` |
| `loginButton` | `click` | `login` |
| `resendCodeButton` | `click` | `2fa` |
| `togglePasswordButton` | `click` | `login` |
| `goBackButton` | `click` | `login` |
| `[groupSelected]` (sufijo) | `emit` | `select-group` |
| `[incidentUpdated]` (sufijo) | `emit` | `update-incident` |
| `btn-create-*` | `click` | `create` |
| `btn-edit-*` | `click` | `edit` |
| `btn-delete-*` | `click` | `delete` |
| `btn-suspend-*` | `click` | `suspend` |
| `btn-invite-*` | `click` | `invite` |
| `btn-assign-*` | `click` | `assign` |
| `tab-*` | `click` | `navigate` |
| *(otros)* | `click` | *(omitir de allowedActions)* |

### Reglas de construcción de `allowedActions`

1. Si acceso al componente ≥ `VIEW` → incluir siempre `"view"`.
2. Si acceso al componente = `EXECUTE` → para cada elemento con acceso ≥ `EXECUTE`, añadir su `allowed_action` semántica (sin duplicados, sin `null`).
3. El orden de `allowedActions` es: `["view", <resto por orden de element_key en la tabla>]`.

### Campo `action` por elemento

El campo `action` de `ElementPermissionResponse` se determina por `element_type`:

| `element_type` (DB) | `action` |
|---|---|
| `BUTTON` | `"click"` |
| `FIELD` | `"keyup"` |
| `TAB` | `"click"` |
| `SELECT` | `"change"` |
| `ACTION` con `element_key` terminando en `[xxx]` | `"emit"` |
| `ACTION` (otros) | `"click"` |
| `PAGINATOR` | `"page"` |

---

## 5. Caso de uso

---

### UC-MNU-001 — Obtener perfil de UI del usuario autenticado

**Actor:** Cualquier usuario con status `ACTIVE`.  
**Trigger:** Login exitoso o recarga de perfil por el frontend.  
**Endpoint:** `GET /api/v1/me/profile`

**Precondiciones:**
- El usuario existe en el tenant indicado y tiene `status = ACTIVE`.
- El tenant existe y tiene `status = ACTIVE`.

**Flujo principal:**

1. El sistema extrae `tenant_id` y `user_id` de los headers `X-Tenant-Id` y `X-Actor-Id`.
2. El sistema consulta `nxc_tenant.v_user_login_profile` con `user_id` y `tenant_id` para obtener los datos del usuario y sus `role_ids` activos (excluyendo roles con `expires_at` expirado).
3. El sistema consulta `nxc_menu.component_permissions` para todos los `role_ids` del usuario en el tenant activo, obteniendo el nivel máximo de acceso por componente (`MAX(access)` agrupado por `component_id`).
4. El sistema descarta los componentes con `acceso_efectivo = HIDDEN`.
5. Para cada componente con `acceso_efectivo ≥ VIEW`, el sistema consulta `nxc_menu.element_permissions` para los `role_ids` del usuario, obteniendo el nivel máximo de acceso por elemento.
6. El sistema aplica los overrides de usuario desde `nxc_menu.user_element_overrides` (donde `expires_at IS NULL OR expires_at > NOW()`), sobreescribiendo el acceso por rol.
7. El sistema descarta los elementos con `acceso_final = HIDDEN`.
8. El sistema construye la lista `elements` y el campo `action` por `element_type`.
9. El sistema calcula `allowedActions` según las reglas de la sección 4.
10. El sistema consulta `nxc_menu.v_menu_effective_access` para los `role_ids` del usuario en el tenant, tomando el nivel máximo por `menu_item_id`.
11. El sistema descarta los ítems de menú con `acceso_efectivo = HIDDEN`.
12. El sistema ordena los ítems por `order_index` y construye el árbol: los ítems con `parent_id IS NULL` son la raíz; los ítems hijo se anidan en el campo `children` del padre correspondiente.
13. El sistema ensambla el `UserProfile` y retorna HTTP 200 con `UserProfileResponse`.

**Flujos alternativos:**

- El usuario no existe o tiene `status ≠ ACTIVE` → HTTP 404 con código `NXC-MNU-0001`.
- El tenant no existe, está `SUSPENDED` o `CANCELLED` → HTTP 403 con código `NXC-MNU-0002`.
- El usuario no tiene roles asignados activos → el perfil retorna `permissions = []` y `menus = []` (sin error).

**Consulta DB (estrategia de implementación):**

```sql
-- Paso 2: perfil y roles del usuario
SELECT * FROM nxc_tenant.v_user_login_profile
WHERE user_id = :userId AND tenant_id = :tenantId;

-- Paso 3: acceso efectivo por componente (multi-rol: MAX)
SELECT
    c.module_key,
    c.route,
    MAX(cp.access::int)::nxc_menu.access_level AS effective_access
FROM nxc_menu.component_permissions cp
JOIN nxc_menu.components c ON c.id = cp.component_id AND c.deleted_at IS NULL
WHERE cp.tenant_id = :tenantId
  AND cp.role_id = ANY(:roleIds)
GROUP BY c.id, c.module_key, c.route
HAVING MAX(cp.access::int) > 0;  -- descarta HIDDEN

-- Paso 5: acceso efectivo por elemento (multi-rol: MAX + override)
SELECT
    ce.element_key,
    ce.element_type,
    COALESCE(
        ueo.access,                                      -- override de usuario
        MAX(ep.access::int)::nxc_menu.access_level       -- máximo por rol
    ) AS effective_access
FROM nxc_menu.component_elements ce
JOIN nxc_menu.element_permissions ep ON ep.element_id = ce.id
LEFT JOIN nxc_menu.user_element_overrides ueo
    ON ueo.element_id = ce.id
    AND ueo.user_id = :userId
    AND (ueo.expires_at IS NULL OR ueo.expires_at > NOW())
WHERE ce.component_id = :componentId
  AND ep.tenant_id = :tenantId
  AND ep.role_id = ANY(:roleIds)
GROUP BY ce.element_key, ce.element_type, ueo.access
HAVING COALESCE(ueo.access::int, MAX(ep.access::int)) > 0;

-- Paso 10: árbol de menú (acceso efectivo por ítem, multi-rol: MAX)
SELECT
    mi.id, mi.parent_id, mi.name, mi.title, mi.route,
    mi.icon, mi.icon_type, mi.item_type, mi.order_index,
    MAX(COALESCE(cp.access::int, mi.default_access::int)) AS effective_access
FROM nxc_menu.menu_items mi
LEFT JOIN nxc_menu.components c ON c.id = mi.component_id AND c.deleted_at IS NULL
LEFT JOIN nxc_menu.component_permissions cp
    ON cp.component_id = c.id
    AND cp.tenant_id = :tenantId
    AND cp.role_id = ANY(:roleIds)
WHERE mi.tenant_id = :tenantId
  AND mi.deleted_at IS NULL
  AND mi.is_visible = TRUE
GROUP BY mi.id, mi.parent_id, mi.name, mi.title, mi.route,
         mi.icon, mi.icon_type, mi.item_type, mi.order_index, mi.default_access
HAVING MAX(COALESCE(cp.access::int, mi.default_access::int)) > 0;
```

---

## 6. DTOs de respuesta

> No existen DTOs de request en este módulo. Toda la configuración de menús y permisos se gestiona en la base de datos.

---

### UserProfileResponse

```
user            UserInfoResponse        REQUERIDO
permissions     ComponentPermissionResponse[]  Lista de componentes accesibles. Puede ser []
menus           MenuItemResponse[]      Lista de raíces del árbol de menú. Puede ser []
token           String                  JWT de sesión. null en fase MVP
```

**Ejemplo completo de respuesta:**

```json
{
  "user": {
    "iduser": "00000000-0000-0000-0001-000000000002",
    "username": "admin.demo",
    "name": "Administrador Demo",
    "email": "admin@demo.nexcore.io",
    "phone": "+573001234567",
    "photo": null,
    "roles": ["TENANT_ADMIN"]
  },
  "permissions": [
    {
      "component": "dashboard",
      "route": "/graphics",
      "allowed_actions": ["view", "filter", "refresh"],
      "elements": [
        { "element_key": "timeFilterSelect#timeFilter", "action": "change" },
        { "element_key": "cityFilterSelect#cityFilter", "action": "change" },
        { "element_key": "hostFilterSelect#hostFilter", "action": "change" },
        { "element_key": "filterButton",               "action": "click"  },
        { "element_key": "refreshButton",              "action": "click"  }
      ]
    },
    {
      "component": "alerts",
      "route": "/alerts",
      "allowed_actions": ["view", "toggle-columns", "filter", "paginate"],
      "elements": [
        { "element_key": "columnsMenuBtn",   "action": "click"  },
        { "element_key": "toggleColumnItem", "action": "click"  },
        { "element_key": "resetColumnsBtn",  "action": "click"  },
        { "element_key": "searchInput",      "action": "keyup"  },
        { "element_key": "paginator",        "action": "page"   }
      ]
    }
  ],
  "menus": [
    {
      "id": "...",
      "name": "Dashboard",
      "title": "Panel Principal",
      "route": "/graphics",
      "icon": "layout-dashboard",
      "icon_type": "tabler",
      "item_type": "ITEM",
      "order_index": 10,
      "children": []
    },
    {
      "id": "...",
      "name": "ProfileMenu",
      "title": "Perfil",
      "route": null,
      "icon": "user-circle",
      "icon_type": "tabler",
      "item_type": "GROUP",
      "order_index": 50,
      "children": [
        {
          "id": "...",
          "name": "Profile",
          "title": "Mi Perfil",
          "route": "/profile",
          "icon": "user",
          "icon_type": "tabler",
          "item_type": "ITEM",
          "order_index": 10,
          "children": []
        },
        {
          "id": "...",
          "name": "Logout",
          "title": "Cerrar Sesión",
          "route": "/auth/login",
          "icon": "logout",
          "icon_type": "tabler",
          "item_type": "ITEM",
          "order_index": 30,
          "children": []
        }
      ]
    }
  ],
  "token": null
}
```

---

### UserInfoResponse

```
iduser          String (UUID)   ID del usuario
username        String          Nombre de usuario
name            String          Nombre completo (full_name)
email           String          Email del usuario
phone           String          Teléfono. null si no registrado
photo           String          URL foto de perfil. null si no registrada
roles           String[]        Nombres de roles activos (ej. ["TENANT_ADMIN"])
```

---

### ComponentPermissionResponse

```
component       String          module_key del componente (ej. "dashboard")
route           String          Ruta Angular (ej. "/graphics")
allowed_actions String[]        Acciones semánticas habilitadas (ej. ["view","filter","refresh"])
elements        ElementPermissionResponse[]  Elementos con acceso ≥ VIEW
```

---

### ElementPermissionResponse

```
element_key     String          Clave técnica del elemento (ej. "filterButton")
action          String          Evento DOM: "click" | "keyup" | "change" | "page" | "sort" | "emit"
```

---

### MenuItemResponse

```
id              String (UUID)   ID del ítem de menú
name            String          Nombre técnico (ej. "Dashboard", "ProfileMenu")
title           String          Etiqueta localizable para mostrar al usuario
route           String          Ruta Angular. null para GROUPs sin ruta
icon            String          Nombre del icono (ej. "layout-dashboard")
icon_type       String          Librería: "tabler" | "material" | "custom"
item_type       String          "GROUP" | "ITEM" | "DIVIDER" | "EXTERNAL_LINK"
order_index     Integer         Posición dentro del mismo nivel
children        MenuItemResponse[]  Ítems hijo, recursivo. Lista vacía si no tiene hijos
```

---

## 7. Endpoints REST

| Método | Ruta | Descripción | Actor |
|---|---|---|---|
| `GET` | `/api/v1/me/profile` | Obtener perfil completo de UI del usuario autenticado | Cualquier usuario ACTIVE |

### Detalle del endpoint

**`GET /api/v1/me/profile`**

| Campo | Valor |
|---|---|
| **Headers requeridos** | `X-Tenant-Id` (UUID), `X-Actor-Id` (UUID) |
| **Respuesta exitosa** | `200 OK` + `UserProfileResponse` |
| **Content-Type** | `application/json` |
| **Cacheable** | No (perfil es dinámico por rol y overrides) |

---

## 8. Catálogo de códigos de error del módulo

| Código | HTTP | Descripción |
|---|---|---|
| `NXC-MNU-0001` | 404 | User not found or not active in this tenant |
| `NXC-MNU-0002` | 403 | Tenant not found or not in an active state |
| `NXC-MNU-0003` | 403 | User account is suspended or blocked |
| `NXC-VALIDATION-0001` | 422 | Bean Validation failure; field detail included in message |
| `NXC-INTERNAL-0001` | 500 | Unexpected internal server error |

---

## 9. Criterios de aceptación

### CA-MNU-001 — Perfil de usuario con un rol

**Dado** un usuario activo del tenant demo con rol `TENANT_ADMIN`,  
**cuando** se invoca `GET /api/v1/me/profile` con sus headers,  
**entonces:**
- La respuesta tiene `status 200`.
- El bloque `user` contiene `roles: ["TENANT_ADMIN"]`.
- El bloque `permissions` incluye todos los componentes con `effective_access ≥ VIEW` para el rol `TENANT_ADMIN` (dashboard, alerts, incidents, traps, auth, user-management, role-management, menu-management, audit-viewer, tenant-settings).
- El bloque `menus` incluye todos los ítems de menú con `effective_access ≠ HIDDEN` para el rol `TENANT_ADMIN`, incluyendo el grupo `Administration` y sus hijos.
- El campo `token` es `null`.

---

### CA-MNU-002 — Perfil de usuario con múltiples roles

**Dado** un usuario activo con roles `VIEWER` y `EDITOR` asignados simultáneamente,  
**cuando** se invoca `GET /api/v1/me/profile`,  
**entonces:**
- Para cada componente, el sistema aplica el nivel máximo: si `VIEWER` tiene `VIEW` y `EDITOR` tiene `EXECUTE`, el resultado es `EXECUTE`.
- El bloque `permissions` refleja el acceso EXECUTE, incluidos los `allowedActions` correspondientes.
- El bloque `user.roles` contiene `["VIEWER", "EDITOR"]`.

---

### CA-MNU-003 — Componentes HIDDEN no aparecen

**Dado** un usuario con rol `VIEWER`,  
**cuando** se invoca `GET /api/v1/me/profile`,  
**entonces:**
- Los componentes `user-management`, `role-management`, `menu-management`, `audit-viewer` y `tenant-settings` **no aparecen** en el bloque `permissions` (acceso efectivo es `HIDDEN` para `VIEWER`).
- Los ítems de menú `Administration` y sus hijos (`Users`, `Roles`, `Menus`, `Audit`) **no aparecen** en el bloque `menus`.

---

### CA-MNU-004 — Elementos de UI excluidos según acceso

**Dado** un usuario con rol `EDITOR`,  
**cuando** se invoca `GET /api/v1/me/profile`,  
**entonces:**
- Los elementos `btn-delete-user`, `btn-suspend-user`, `btn-delete-role` tienen acceso `VIEW` para `EDITOR`. El frontend los recibe pero los renderiza deshabilitados.
- Los elementos con acceso `HIDDEN` no aparecen en la respuesta.
- Los elementos con acceso `EXECUTE` incluyen el campo `action` correcto.

---

### CA-MNU-005 — Override de usuario con prioridad sobre rol

**Dado** un usuario con rol `VIEWER` (acceso `HIDDEN` a `btn-create-user`) que tiene un override activo `EXECUTE` sobre ese elemento,  
**cuando** se invoca `GET /api/v1/me/profile`,  
**entonces:**
- El elemento `btn-create-user` aparece en el bloque `elements` del componente `user-management`.
- La acción es `"click"`.
- El `allowedActions` del componente incluye `"create"`.

---

### CA-MNU-006 — Override de usuario expirado se ignora

**Dado** un usuario con un override sobre `btn-delete-user` con `expires_at` en el pasado,  
**cuando** se invoca `GET /api/v1/me/profile`,  
**entonces:**
- El sistema ignora el override expirado y aplica el acceso por rol del usuario.

---

### CA-MNU-007 — Árbol de menú con jerarquía correcta

**Dado** cualquier usuario activo,  
**cuando** se invoca `GET /api/v1/me/profile`,  
**entonces:**
- Los ítems raíz (`parent_id IS NULL`) están en el array raíz de `menus`.
- Los ítems hijo están anidados en el campo `children` del ítem padre correcto.
- Dentro de cada nivel, los ítems están ordenados por `order_index` ascendente.
- Ningún ítem con `effective_access = HIDDEN` aparece en el árbol (ni en raíz ni en `children`).

---

### CA-MNU-008 — Usuario inactivo rechazado

**Dado** un usuario con `status = SUSPENDED`,  
**cuando** se invoca `GET /api/v1/me/profile`,  
**entonces:**
- El sistema retorna HTTP 403 con código `NXC-MNU-0003`.

---

### CA-MNU-009 — Tenant inactivo rechazado

**Dado** un usuario de un tenant con `status = SUSPENDED`,  
**cuando** se invoca `GET /api/v1/me/profile`,  
**entonces:**
- El sistema retorna HTTP 403 con código `NXC-MNU-0002`.

---

### CA-MNU-010 — Usuario sin roles activos

**Dado** un usuario activo sin ningún rol asignado (o con todos sus roles con `expires_at` expirado),  
**cuando** se invoca `GET /api/v1/me/profile`,  
**entonces:**
- La respuesta tiene `status 200`.
- `permissions` es `[]`.
- `menus` es `[]`.
- `user.roles` es `[]`.

---

### CA-MNU-011 — allowedActions contiene solo acciones EXECUTE

**Dado** un usuario con rol `VIEWER` (acceso `VIEW` al componente `dashboard`),  
**cuando** se invoca `GET /api/v1/me/profile`,  
**entonces:**
- El componente `dashboard` aparece en `permissions` (acceso ≥ VIEW).
- `allowedActions` contiene únicamente `["view"]`.
- Los elementos de `dashboard` aparecen en `elements` pero **no se añaden acciones** a `allowedActions` (porque el acceso al componente es VIEW, no EXECUTE).

---

### CA-MNU-012 — Aislamiento multi-tenant

**Dado** un usuario del tenant A,  
**cuando** se invoca `GET /api/v1/me/profile`,  
**entonces:**
- El bloque `permissions` solo contiene componentes configurados para el tenant A o componentes de sistema (`is_system = TRUE`).
- El bloque `menus` solo contiene ítems de menú del tenant A.
- Ningún dato del tenant B aparece en la respuesta, garantizado por RLS de PostgreSQL.

---

### CA-MNU-013 — Rendimiento

- `GET /api/v1/me/profile` para un usuario con 3 roles y 10 componentes responde en menos de **300ms en p95**.
- El sistema ejecuta como máximo **4 consultas SQL** por invocación: (1) perfil de usuario, (2) permisos de componentes, (3) permisos de elementos (puede ser una query con JOIN a los componentes accesibles), (4) árbol de menú.

---

## 10. Restricciones técnicas

**Solo lectura:** Este módulo no modifica ninguna tabla. No tiene operaciones de escritura. Todos los métodos del repositorio son consultas.

**No hay CRUD de configuración:** La gestión de componentes, elementos de UI, ítems de menú y permisos por rol se hace directamente en la base de datos. No se exponen endpoints para crear, actualizar ni eliminar estos recursos en esta fase.

**RLS activo:** El interceptor de Hibernate establece `SET LOCAL app.tenant_id = ':tenantId'` antes de cada consulta. El SUPER_ADMIN activa adicionalmente `SET LOCAL app.is_system_admin = 'true'` para ver componentes con `is_system = TRUE` de todos los tenants.

**Componentes de sistema:** Los componentes con `is_system = TRUE` pertenecen al tenant `system` pero son visibles para todos los tenants gracias a la política RLS:
```sql
CREATE POLICY rls_tenant ON nxc_menu.components
    USING (... OR is_system = TRUE);
```
Por tanto, los permisos sobre componentes de sistema se buscan en `component_permissions` con el `tenant_id` del usuario (no con el tenant `system`). El seed script registra esas entradas de permisos para cada tenant.

**MapStruct:** Los mapeos dominio → DTO de respuesta se implementan con MapStruct en `application/mapper/`. Los mapeos de proyecciones SQL → dominio se implementan en `infrastructure/persistence/mapper/`.

**Proyecciones Spring Data:** La capa de persistencia usa interfaces de proyección de Spring Data JPA (o `@SqlResultSetMapping`) para las consultas nativas. No se crean entidades JPA completas en este módulo porque los datos son de solo lectura y provienen de múltiples tablas.

**Manejo de errores:** Reutiliza el `GlobalExceptionHandler` definido en `module-tenant`. Las excepciones de negocio propias del módulo se añaden a `BusinessException` con los códigos `NXC-MNU-*`.

---

## 11. Estructura de archivos del módulo

La ruta base en el código fuente es:  
`nexcore-core/src/main/java/com/nexore/core/module/menu/`

> **Nota:** el grupo Java es `com.nexore.core` (no `com.nexcore.core`).

```
module/menu/
├── domain/
│   ├── model/
│   │   ├── UserProfile.java                 ← aggregate root: { user, permissions, menus, token }
│   │   ├── UserInfo.java                    ← value object: { id, username, name, email, phone, photo, roles }
│   │   ├── ComponentPermission.java         ← value object: { component, route, allowedActions, elements }
│   │   ├── ElementPermission.java           ← value object: { elementKey, action }
│   │   ├── MenuItem.java                    ← value object: { id, name, title, route, icon, iconType, itemType, orderIndex, children }
│   │   ├── AccessLevel.java                 ← enum: HIDDEN | VIEW | EXECUTE
│   │   └── MenuItemType.java                ← enum: GROUP | ITEM | DIVIDER | EXTERNAL_LINK
│   └── repository/
│       └── UserProfileRepository.java       ← port (interfaz de dominio): loadProfile(userId, tenantId)
│
├── application/
│   ├── service/
│   │   └── UserProfileService.java          ← UC-MNU-001: ensambla UserProfile desde repositorio
│   ├── dto/
│   │   └── response/
│   │       ├── UserProfileResponse.java     ← { user, permissions, menus, token }
│   │       ├── UserInfoResponse.java        ← { iduser, username, name, email, phone, photo, roles }
│   │       ├── ComponentPermissionResponse.java  ← { component, route, allowed_actions, elements }
│   │       ├── ElementPermissionResponse.java    ← { element_key, action }
│   │       └── MenuItemResponse.java        ← { id, name, title, route, icon, icon_type, item_type, order_index, children }
│   └── mapper/
│       └── UserProfileMapper.java           ← MapStruct (dominio → DTOs de respuesta)
│
└── infrastructure/
    ├── web/
    │   └── UserProfileController.java       ← GET /api/v1/me/profile
    └── persistence/
        ├── JpaUserProfileRepositoryAdapter.java  ← implementa UserProfileRepository (port)
        ├── projection/
        │   ├── UserLoginProfileProjection.java   ← interfaz Spring Data: mapea nxc_tenant.v_user_login_profile
        │   ├── ComponentAccessProjection.java    ← interfaz Spring Data: { moduleKey, route, effectiveAccess }
        │   ├── ElementAccessProjection.java      ← interfaz Spring Data: { elementKey, elementType, effectiveAccess }
        │   └── MenuItemProjection.java           ← interfaz Spring Data: { id, parentId, name, title, route, icon, iconType, itemType, orderIndex }
        ├── jpa/
        │   └── UserProfileQueryRepository.java   ← @Query con SQL nativo sobre vistas y tablas nxc_menu / nxc_tenant
        └── mapper/
            └── UserProfilePersistenceMapper.java ← MapStruct (proyecciones SQL → modelos de dominio)
```

---

## 12. Convención temporal de autenticación (fase MVP)

> Hasta que el módulo de seguridad JWT esté implementado, el controlador identifica al actor mediante headers HTTP explícitos. Estos headers **se eliminarán** cuando se integre Spring Security con JWT.

| Header | Tipo | Controlador | Descripción |
|---|---|---|---|
| `X-Tenant-Id` | UUID | `UserProfileController` | Tenant del usuario autenticado |
| `X-Actor-Id` | UUID | `UserProfileController` | UUID del usuario autenticado |

---

## 13. Integración con vistas de DB

El módulo reutiliza las vistas de utilidad definidas en el schema:

### `nxc_tenant.v_user_login_profile`

Retorna todos los datos del usuario necesarios para construir el bloque `user` del perfil:

| Campo relevante | Uso |
|---|---|
| `user_id` | → `UserInfo.id` |
| `username` | → `UserInfo.username` |
| `full_name` | → `UserInfo.name` |
| `email` | → `UserInfo.email` |
| `photo_url` | → `UserInfo.photo` |
| `status` | Validación: debe ser `ACTIVE` |
| `tenant_status` | Validación: debe ser `ACTIVE` |
| `role_names` | → `UserInfo.roles` |
| `role_ids` | Usado internamente para las queries de permisos |

### `nxc_menu.v_menu_effective_access`

Retorna el árbol de menú con acceso efectivo por rol. El servicio filtra por los `role_ids` del usuario y toma el MAX por `menu_item_id`.

> **Nota:** Para multi-rol, la vista retorna una fila por (menu_item, role). El servicio (o la query del repositorio) agrupa por `menu_item_id` tomando `MAX(effective_access)`.

---

## 14. Pendientes

| Área | Estado | Descripción |
|---|---|---|
| JWT | `PENDIENTE` | El campo `token` siempre es `null` hasta que se implemente `module-auth` con Spring Security |
| Feature flags | `PENDIENTE` | Los ítems de menú con `feature_flag_key` deben filtrarse contra `nxc_config.feature_flags` para el tenant. No implementado aún |
| `tenant_menu_config` | `PENDIENTE` | Overrides por tenant sobre ítems de sistema (`custom_label`, `is_hidden`, `order_override`). No aplicados en la consulta aún |
| `user_preferences` | `PENDIENTE` | Las preferencias del usuario (tema, idioma, densidad) podrían enriquecerse en el bloque `user`. No implementado |
| Caché de perfil | `PENDIENTE` | Para alto tráfico, considerar caché Redis con TTL corto (30-60s). Invalidar en cambio de roles o overrides |
```
