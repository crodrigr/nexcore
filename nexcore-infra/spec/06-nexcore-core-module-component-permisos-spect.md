# NexCore — Especificaciones y Criterios de Aceptación
## Módulo: `module-menu` — Gestión de Componentes y Permisos
**Versión:** 1.0  
**Schemas DB:** `nxc_menu`, `nxc_tenant`  
**Paquete base:** `com.nexore.core.module.menu`  
**Ubicación:** `nexcore-core/src/main/java/com/nexore/core/module/menu/`  
**Fecha:** 2026-05

---

## 1. Contexto y propósito

Este spec amplía el módulo `module-menu` (ver `02-nexcore-core-module-menu-specs.md`) con la responsabilidad de **gestionar componentes de UI, sus elementos interactivos y los permisos por rol**.

Hasta ahora el módulo solo exponía lectura del perfil de usuario (`UC-MNU-001`). En esta extensión, el módulo agrega el CRUD de las entidades de configuración de permisos que el administrador del tenant opera desde la interfaz de administración.

El modelo de permisos opera en dos niveles:

| Nivel | Entidad DB | Descripción |
|---|---|---|
| **Componente** | `nxc_menu.component_permissions` | Acceso de un rol a un módulo/página completo |
| **Elemento** | `nxc_menu.element_permissions` | Acceso granular de un rol a un botón, tab, campo o sección |

Adicionalmente existe un nivel de **override por usuario** (`nxc_menu.user_element_overrides`) que permite excepciones individuales sobre los permisos de rol.

**Dependencias de dominio:**

```
module-menu (permisos) → nxc_menu.components
                       → nxc_menu.component_elements
                       → nxc_menu.component_permissions
                       → nxc_menu.element_permissions
                       → nxc_menu.user_element_overrides
                       → nxc_tenant.roles  (validación de existencia y tenant)
                       → nxc_tenant.users  (validación para overrides)
```

> **Nota de nomenclatura:** El nombre `menu` del módulo queda corto para describir su responsabilidad real. Se contempla renombrarlo a `module-component-web` en una iteración futura. Por ahora todo permanece bajo `module-menu` para no romper paquetes existentes.

---

## 2. Entidades del dominio

---

### 2.1 Component *(aggregate root)*

Representa un módulo o página de la aplicación Angular. Es la unidad mínima de control de acceso a nivel de ruta.

| Campo | Tipo | Descripción |
|---|---|---|
| `id` | UUID | PK generada automáticamente |
| `tenantId` | UUID | FK a `nxc_tenant.tenants`. Scope del componente |
| `moduleKey` | VARCHAR(150) | Clave técnica única por tenant: `"user-management"`, `"audit-viewer"` |
| `name` | VARCHAR(150) | Nombre legible: `"Gestión de usuarios"` |
| `route` | VARCHAR(255) | Ruta Angular: `"/admin/users"` |
| `description` | VARCHAR(500) | Descripción del propósito del componente |
| `isSystem` | BOOLEAN | `TRUE`: componente del sistema, no editable por el tenant |
| `createdAt` | TIMESTAMPTZ | Fecha de creación |
| `updatedAt` | TIMESTAMPTZ | Última modificación (trigger automático) |
| `createdBy` | UUID | FK al usuario que lo creó |
| `updatedBy` | UUID | FK al último modificador |
| `deletedAt` | TIMESTAMPTZ | Soft delete |
| `version` | INTEGER | Control de concurrencia optimista |

**Invariantes de negocio:**
- `(tenantId, moduleKey)` es único entre componentes activos.
- Los componentes con `isSystem = TRUE` no pueden eliminarse ni modificar `moduleKey`.
- Los componentes de sistema (`is_system = TRUE`) pertenecen al tenant `system` pero son visibles para todos los tenants por la política RLS.

---

### 2.2 ComponentElement *(entidad)*

Elemento de UI controlable individualmente dentro de un componente: botón, tab, campo, sección, acción.

| Campo | Tipo | Descripción |
|---|---|---|
| `id` | UUID | PK |
| `tenantId` | UUID | FK a `nxc_tenant.tenants` |
| `componentId` | UUID | FK a `nxc_menu.components` |
| `elementKey` | VARCHAR(150) | Clave técnica: `"btn-create-user"`, `"tab-roles"`, `"searchInput"` |
| `label` | VARCHAR(200) | Descripción legible para el administrador |
| `elementType` | VARCHAR(50) | `BUTTON \| TAB \| FIELD \| SECTION \| ACTION` |
| `createdAt` | TIMESTAMPTZ | Fecha de creación |
| `updatedAt` | TIMESTAMPTZ | Última modificación |
| `deletedAt` | TIMESTAMPTZ | Soft delete |
| `version` | INTEGER | Control de concurrencia optimista |

**Invariantes de negocio:**
- `(tenantId, componentId, elementKey)` es único entre elementos activos.
- No puede existir un elemento sin su componente (`componentId` debe apuntar a un componente activo del mismo tenant).

---

### 2.3 ComponentPermission *(entidad)*

Permiso de un rol sobre un componente completo. Si un rol tiene `EXECUTE` sobre un componente, hereda `EXECUTE` en todos sus elementos salvo que `ElementPermission` lo restrinja.

| Campo | Tipo | Descripción |
|---|---|---|
| `id` | UUID | PK |
| `tenantId` | UUID | FK a `nxc_tenant.tenants` |
| `roleId` | UUID | FK a `nxc_tenant.roles` |
| `componentId` | UUID | FK a `nxc_menu.components` |
| `access` | `access_level` | `HIDDEN \| VIEW \| EXECUTE` |
| `createdAt` | TIMESTAMPTZ | Fecha de creación |
| `updatedAt` | TIMESTAMPTZ | Última modificación |
| `createdBy` | UUID | FK al usuario que lo configuró |
| `updatedBy` | UUID | FK al último modificador |

**Invariantes de negocio:**
- `(tenantId, roleId, componentId)` es único — solo existe un permiso por combinación (upsert).
- `roleId` y `componentId` deben pertenecer al mismo `tenantId`.
- Eliminar el permiso (DELETE) restaura el comportamiento por defecto (`default_access` del `menu_item`).

---

### 2.4 ElementPermission *(entidad)*

Permiso de un rol sobre un elemento específico. Permite granularidad fina: un rol `EDITOR` puede ver el botón eliminar (`VIEW`) pero no ejecutarlo.

| Campo | Tipo | Descripción |
|---|---|---|
| `id` | UUID | PK |
| `tenantId` | UUID | FK a `nxc_tenant.tenants` |
| `roleId` | UUID | FK a `nxc_tenant.roles` |
| `elementId` | UUID | FK a `nxc_menu.component_elements` |
| `access` | `access_level` | `HIDDEN \| VIEW \| EXECUTE` |
| `createdAt` | TIMESTAMPTZ | Fecha de creación |
| `updatedAt` | TIMESTAMPTZ | Última modificación |
| `createdBy` | UUID | FK al usuario que lo configuró |
| `updatedBy` | UUID | FK al último modificador |

**Invariantes de negocio:**
- `(tenantId, roleId, elementId)` es único (upsert).
- `roleId` y `elementId` (a través de su `component`) deben pertenecer al mismo `tenantId`.

---

### 2.5 UserElementOverride *(entidad)*

Override individual de un elemento para un usuario específico. Anula el permiso del rol. Útil para excepciones puntuales.

| Campo | Tipo | Descripción |
|---|---|---|
| `id` | UUID | PK |
| `tenantId` | UUID | FK a `nxc_tenant.tenants` |
| `userId` | UUID | FK a `nxc_tenant.users` |
| `elementId` | UUID | FK a `nxc_menu.component_elements` |
| `access` | `access_level` | `HIDDEN \| VIEW \| EXECUTE` |
| `reason` | VARCHAR(500) | Justificación del override (obligatoria) |
| `expiresAt` | TIMESTAMPTZ | `NULL` = permanente. Permite overrides temporales |
| `createdAt` | TIMESTAMPTZ | Fecha de creación |
| `updatedAt` | TIMESTAMPTZ | Última modificación |
| `createdBy` | UUID | FK al usuario que lo creó |
| `updatedBy` | UUID | FK al último modificador |

**Invariantes de negocio:**
- `(tenantId, userId, elementId)` es único (upsert).
- `reason` es obligatorio — el sistema rechaza overrides sin justificación.
- Un override con `expiresAt` en el pasado se ignora en la resolución de acceso efectivo.

---

### 2.6 AccessLevel *(enum, compartido con module-menu existente)*

| Valor | Descripción |
|---|---|
| `HIDDEN` | No visible. El elemento no se renderiza en el frontend |
| `VIEW` | Visible pero deshabilitado |
| `EXECUTE` | Visible y habilitado — el usuario puede interactuar |

---

## 3. Resolución de acceso efectivo

La jerarquía de resolución, de mayor a menor prioridad:

```
1. UserElementOverride (válido, no expirado)   ← gana siempre
2. ElementPermission   (máximo entre roles)
3. ComponentPermission (máximo entre roles)    ← hereda a elementos sin ElementPermission
4. default_access del menu_item                ← fallback final
```

Para usuarios con múltiples roles, se aplica el **máximo** entre los valores de acceso de todos sus roles activos:

```
EXECUTE (2) > VIEW (1) > HIDDEN (0)
```

---

## 4. Casos de uso

---

### UC-PRM-001 — Listar componentes del tenant

**Actor:** TENANT_ADMIN  
**Endpoint:** `GET /api/v1/menu/components`

**Flujo principal:**
1. El sistema extrae `tenant_id` del contexto de seguridad.
2. El sistema consulta `nxc_menu.components` filtrando por `tenant_id` y `deleted_at IS NULL`.
3. El sistema aplica paginación y filtros opcionales.
4. Retorna HTTP 200 con `PageResponse<ComponentSummaryResponse>`.

**Filtros soportados:** `search` (sobre `name` y `moduleKey`), `isSystem`.

---

### UC-PRM-002 — Obtener detalle de un componente con sus elementos

**Actor:** TENANT_ADMIN  
**Endpoint:** `GET /api/v1/menu/components/{componentId}`

**Flujo principal:**
1. El sistema busca el componente por `id` dentro del tenant activo.
2. Carga sus `component_elements` activos (`deleted_at IS NULL`).
3. Retorna HTTP 200 con `ComponentDetailResponse` (componente + lista de elementos).

**Flujo alternativo:**
- Componente no encontrado o de otro tenant → HTTP 404 con código `NXC-CMP-0001`.

---

### UC-PRM-003 — Crear componente

**Actor:** TENANT_ADMIN  
**Precondición:** El actor no intenta crear un componente con `isSystem = TRUE` (reservado para SUPER_ADMIN).

**Flujo principal:**
1. El actor envía `POST /api/v1/menu/components` con `moduleKey`, `name`, `route`.
2. El sistema valida que `(tenantId, moduleKey)` no exista.
3. El sistema persiste el componente con `isSystem = FALSE`.
4. Retorna HTTP 201 con `ComponentSummaryResponse` y header `Location`.

**Flujos alternativos:**
- `moduleKey` duplicado en el tenant → HTTP 409 con código `NXC-CMP-0002`.
- TENANT_ADMIN intenta `isSystem = TRUE` → HTTP 403 con código `NXC-CMP-0003`.

---

### UC-PRM-004 — Actualizar componente

**Actor:** TENANT_ADMIN / SUPER_ADMIN  
**Restricciones:** Los componentes con `isSystem = TRUE` no pueden cambiar su `moduleKey`.

**Flujo principal:**
1. El actor envía `PATCH /api/v1/menu/components/{componentId}`.
2. El sistema valida que el componente pertenece al tenant.
3. El sistema aplica los cambios permitidos según el rol del actor.
4. Incrementa `version` y persiste con `updatedBy`.
5. Retorna HTTP 200.

**Flujos alternativos:**
- Conflicto de versión → HTTP 409 con código `NXC-CMP-0004`.
- Intento de cambiar `moduleKey` de un componente de sistema → HTTP 422 con código `NXC-CMP-0005`.

---

### UC-PRM-005 — Eliminar componente (soft delete)

**Actor:** TENANT_ADMIN  
**Precondición:** El componente no es de sistema (`isSystem = FALSE`).

**Flujo principal:**
1. El actor envía `DELETE /api/v1/menu/components/{componentId}`.
2. El sistema verifica que `isSystem = FALSE`.
3. El sistema hace soft delete del componente y en cascada de sus elementos (`deletedAt = NOW()`).
4. El sistema elimina los `component_permissions` y `element_permissions` asociados.
5. Retorna HTTP 204.

**Flujos alternativos:**
- Componente de sistema → HTTP 422 con código `NXC-CMP-0006`.

---

### UC-PRM-006 — Crear elemento de un componente

**Actor:** TENANT_ADMIN  
**Endpoint:** `POST /api/v1/menu/components/{componentId}/elements`

**Flujo principal:**
1. El actor envía `elementKey`, `label`, `elementType`.
2. El sistema valida que `(tenantId, componentId, elementKey)` no exista.
3. El sistema persiste el elemento.
4. Retorna HTTP 201.

**Flujo alternativo:**
- `elementKey` duplicado en el componente → HTTP 409 con código `NXC-ELM-0001`.

---

### UC-PRM-007 — Actualizar elemento

**Actor:** TENANT_ADMIN  
**Endpoint:** `PATCH /api/v1/menu/components/{componentId}/elements/{elementId}`

**Flujo principal:**
1. El actor modifica `label` y/o `elementType`.
2. El sistema valida que el elemento pertenece al componente y al tenant.
3. Persiste los cambios con `version` incrementado.
4. Retorna HTTP 200.

---

### UC-PRM-008 — Eliminar elemento (soft delete)

**Actor:** TENANT_ADMIN  
**Endpoint:** `DELETE /api/v1/menu/components/{componentId}/elements/{elementId}`

**Flujo principal:**
1. El sistema hace soft delete del elemento.
2. El sistema elimina los `element_permissions` y `user_element_overrides` asociados.
3. Retorna HTTP 204.

---

### UC-PRM-009 — Obtener matriz de permisos de un rol

**Actor:** TENANT_ADMIN  
**Endpoint:** `GET /api/v1/menu/permissions/roles/{roleId}`

Esta es la **API central** del módulo de gestión de permisos. Retorna la matriz completa del rol: todos los componentes del tenant con su acceso configurado, y dentro de cada componente todos sus elementos con su acceso.

**Flujo principal:**
1. El sistema valida que `roleId` pertenece al tenant activo.
2. El sistema consulta todos los componentes del tenant (activos).
3. Para cada componente busca la entrada en `component_permissions` para el `roleId`. Si no existe, el acceso es `HIDDEN` (sin permiso explícito = sin acceso).
4. Para cada componente carga sus elementos y busca las entradas en `element_permissions`. Si no existe para un elemento, el acceso se hereda del componente (`inherited: true`).
5. Retorna HTTP 200 con `RolePermissionMatrixResponse`.

**Flujo alternativo:**
- `roleId` no pertenece al tenant → HTTP 404 con código `NXC-PRM-0001`.

---

### UC-PRM-010 — Actualizar permiso de un componente para un rol (upsert)

**Actor:** TENANT_ADMIN  
**Endpoint:** `PUT /api/v1/menu/permissions/roles/{roleId}/components/{componentId}`

**Flujo principal:**
1. El actor envía `{ "access": "EXECUTE" }`.
2. El sistema valida que `roleId` y `componentId` pertenecen al mismo tenant.
3. El sistema ejecuta upsert en `component_permissions` (`ON CONFLICT DO UPDATE`).
4. Persiste `updatedBy` con el actor.
5. Retorna HTTP 200 con el permiso resultante.

**Flujos alternativos:**
- `roleId` no pertenece al tenant → HTTP 404 con código `NXC-PRM-0001`.
- `componentId` no pertenece al tenant → HTTP 404 con código `NXC-CMP-0001`.

---

### UC-PRM-011 — Eliminar permiso de componente para un rol

**Actor:** TENANT_ADMIN  
**Endpoint:** `DELETE /api/v1/menu/permissions/roles/{roleId}/components/{componentId}`

**Flujo principal:**
1. El sistema elimina la entrada en `component_permissions`.
2. El acceso vuelve al `default_access` del `menu_item` asociado.
3. Retorna HTTP 204.

---

### UC-PRM-012 — Actualización masiva de permisos de componentes para un rol

**Actor:** TENANT_ADMIN  
**Endpoint:** `PUT /api/v1/menu/permissions/roles/{roleId}/components/batch`

Permite actualizar los permisos de múltiples componentes en una sola operación (útil para el UI de "aplicar a todos").

**Flujo principal:**
1. El actor envía un array de `{ componentId, access }`.
2. El sistema valida que todos los `componentId` pertenecen al tenant.
3. El sistema ejecuta upsert masivo dentro de una transacción.
4. Retorna HTTP 200 con la lista de permisos resultantes.

**Flujo alternativo:**
- Algún `componentId` no pertenece al tenant → HTTP 422 con código `NXC-PRM-0002`, indicando los IDs inválidos.

---

### UC-PRM-013 — Actualizar permiso de un elemento para un rol (upsert)

**Actor:** TENANT_ADMIN  
**Endpoint:** `PUT /api/v1/menu/permissions/roles/{roleId}/elements/{elementId}`

**Flujo principal:**
1. El actor envía `{ "access": "VIEW" }`.
2. El sistema valida que `roleId` y el componente padre del `elementId` pertenecen al mismo tenant.
3. El sistema ejecuta upsert en `element_permissions`.
4. Retorna HTTP 200.

---

### UC-PRM-014 — Eliminar permiso de elemento para un rol

**Actor:** TENANT_ADMIN  
**Endpoint:** `DELETE /api/v1/menu/permissions/roles/{roleId}/elements/{elementId}`

**Flujo principal:**
1. El sistema elimina la entrada en `element_permissions`.
2. El acceso del elemento vuelve a heredarse del `ComponentPermission` del rol.
3. Retorna HTTP 204.

---

### UC-PRM-015 — Actualización masiva de permisos de elementos para un rol

**Actor:** TENANT_ADMIN  
**Endpoint:** `PUT /api/v1/menu/permissions/roles/{roleId}/elements/batch`

**Flujo principal:**
1. El actor envía un array de `{ elementId, access }`.
2. El sistema valida que todos los `elementId` pertenecen a componentes del tenant.
3. El sistema ejecuta upsert masivo en transacción.
4. Retorna HTTP 200.

---

### UC-PRM-016 — Listar overrides de elemento por usuario

**Actor:** TENANT_ADMIN  
**Endpoint:** `GET /api/v1/menu/permissions/users/{userId}/overrides`

**Flujo principal:**
1. El sistema valida que `userId` pertenece al tenant activo.
2. El sistema consulta `user_element_overrides` para ese usuario.
3. Retorna HTTP 200 con lista de `UserOverrideResponse` (incluyendo los expirados marcados como `expired: true`).

---

### UC-PRM-017 — Crear o actualizar override de elemento para un usuario (upsert)

**Actor:** TENANT_ADMIN  
**Endpoint:** `PUT /api/v1/menu/permissions/users/{userId}/overrides/{elementId}`

**Flujo principal:**
1. El actor envía `{ "access": "EXECUTE", "reason": "Justificación", "expiresAt": "2026-12-31T23:59:59Z" }`.
2. El sistema valida que `userId` y el componente padre del `elementId` pertenecen al tenant.
3. El sistema valida que `reason` no está vacío.
4. El sistema ejecuta upsert en `user_element_overrides`.
5. Retorna HTTP 200.

**Flujos alternativos:**
- `reason` vacío → HTTP 422 con código `NXC-PRM-0003`.
- `userId` no pertenece al tenant → HTTP 404 con código `NXC-PRM-0004`.

---

### UC-PRM-018 — Eliminar override de elemento para un usuario

**Actor:** TENANT_ADMIN  
**Endpoint:** `DELETE /api/v1/menu/permissions/users/{userId}/overrides/{elementId}`

**Flujo principal:**
1. El sistema elimina la entrada en `user_element_overrides`.
2. El acceso del elemento vuelve a calcularse desde el permiso de rol del usuario.
3. Retorna HTTP 204.

---

## 5. DTOs de request

### ComponentCreateRequest
```
moduleKey       String  REQUERIDO  Patrón: ^[a-z0-9]+(-[a-z0-9]+)*$  Max: 150
name            String  REQUERIDO  Min: 2  Max: 150
route           String  OPCIONAL   Max: 255
description     String  OPCIONAL   Max: 500
```

### ComponentUpdateRequest (PATCH — todos opcionales)
```
name            String  OPCIONAL  Min: 2  Max: 150
route           String  OPCIONAL  Max: 255
description     String  OPCIONAL  Max: 500
```

### ComponentElementCreateRequest
```
elementKey      String  REQUERIDO  Patrón: ^[a-zA-Z0-9._#-]+$  Max: 150
label           String  OPCIONAL   Max: 200
elementType     String  OPCIONAL   Enum: BUTTON | TAB | FIELD | SECTION | ACTION
```

### ComponentElementUpdateRequest (PATCH)
```
label           String  OPCIONAL  Max: 200
elementType     String  OPCIONAL  Enum: BUTTON | TAB | FIELD | SECTION | ACTION
```

### ComponentPermissionUpsertRequest
```
access          String  REQUERIDO  Enum: HIDDEN | VIEW | EXECUTE
```

### BatchComponentPermissionRequest
```
permissions     ComponentPermissionItem[]  REQUERIDO  Min: 1
  componentId   UUID    REQUERIDO
  access        String  REQUERIDO  Enum: HIDDEN | VIEW | EXECUTE
```

### BatchElementPermissionRequest
```
permissions     ElementPermissionItem[]  REQUERIDO  Min: 1
  elementId     UUID    REQUERIDO
  access        String  REQUERIDO  Enum: HIDDEN | VIEW | EXECUTE
```

### UserElementOverrideRequest
```
access          String  REQUERIDO  Enum: HIDDEN | VIEW | EXECUTE
reason          String  REQUERIDO  Min: 5  Max: 500
expiresAt       String  OPCIONAL   ISO-8601. NULL = permanente
```

---

## 6. DTOs de respuesta

### ComponentSummaryResponse
```
id              UUID
tenantId        UUID
moduleKey       String
name            String
route           String
description     String
isSystem        Boolean
elementCount    Integer    Cantidad de elementos activos del componente
createdAt       String     ISO-8601
updatedAt       String     ISO-8601
```

### ComponentDetailResponse
```
id              UUID
tenantId        UUID
moduleKey       String
name            String
route           String
description     String
isSystem        Boolean
elements        ComponentElementResponse[]
createdAt       String
updatedAt       String
```

### ComponentElementResponse
```
id              UUID
componentId     UUID
elementKey      String
label           String
elementType     String
createdAt       String
updatedAt       String
```

### RolePermissionMatrixResponse

Respuesta principal del módulo de gestión de permisos. Alimenta la pantalla de configuración de permisos del TENANT_ADMIN.

```
roleId          UUID
roleName        String
tenantId        UUID
components      RoleComponentPermissionResponse[]
```

### RoleComponentPermissionResponse
```
componentId     UUID
moduleKey       String
name            String
route           String
access          String     "execute" | "view" | "hidden" (minúscula, igual que el perfil)
elements        RoleElementPermissionResponse[]
```

### RoleElementPermissionResponse
```
elementId       UUID
elementKey      String
label           String
elementType     String
access          String     "execute" | "view" | "hidden"
inherited       Boolean    TRUE si el acceso es heredado del componente, no de un ElementPermission explícito
```

**Ejemplo de `RolePermissionMatrixResponse`:**

```json
{
  "roleId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "roleName": "EDITOR",
  "tenantId": "00000000-0000-0000-0000-000000000002",
  "components": [
    {
      "componentId": "uuid-comp-1",
      "moduleKey": "user-management",
      "name": "Gestión de usuarios",
      "route": "/admin/users",
      "access": "execute",
      "elements": [
        {
          "elementId": "uuid-elm-1",
          "elementKey": "btn-create-user",
          "label": "Botón Crear Usuario",
          "elementType": "BUTTON",
          "access": "execute",
          "inherited": false
        },
        {
          "elementId": "uuid-elm-2",
          "elementKey": "btn-delete-user",
          "label": "Botón Eliminar Usuario",
          "elementType": "BUTTON",
          "access": "view",
          "inherited": false
        },
        {
          "elementId": "uuid-elm-3",
          "elementKey": "searchInput",
          "label": "Campo de búsqueda",
          "elementType": "FIELD",
          "access": "execute",
          "inherited": true
        }
      ]
    },
    {
      "componentId": "uuid-comp-2",
      "moduleKey": "audit-viewer",
      "name": "Visor de auditoría",
      "route": "/audit",
      "access": "hidden",
      "elements": []
    }
  ]
}
```

### UserOverrideResponse
```
id              UUID
userId          UUID
elementId       UUID
elementKey      String
componentModuleKey  String
access          String     "execute" | "view" | "hidden"
reason          String
expiresAt       String     ISO-8601. null si permanente
expired         Boolean    TRUE si expiresAt < NOW()
createdAt       String
updatedAt       String
createdBy       UUID
```

---

## 7. Endpoints REST

### 7.1 Gestión de componentes

| Método | Ruta | UC | Descripción | Roles |
|---|---|---|---|---|
| `GET` | `/api/v1/menu/components` | UC-PRM-001 | Lista paginada de componentes del tenant. Soporta filtros `search` (sobre `name` y `moduleKey`) e `isSystem`. | TENANT_ADMIN |
| `POST` | `/api/v1/menu/components` | UC-PRM-003 | Crea un nuevo componente de UI en el tenant. El `moduleKey` debe ser único dentro del tenant. Solo puede crear componentes con `isSystem = FALSE`. | TENANT_ADMIN |
| `GET` | `/api/v1/menu/components/{componentId}` | UC-PRM-002 | Retorna el detalle completo de un componente incluyendo la lista de todos sus elementos de UI activos. | TENANT_ADMIN |
| `PATCH` | `/api/v1/menu/components/{componentId}` | UC-PRM-004 | Actualiza los campos editables de un componente (`name`, `route`, `description`). El `moduleKey` de los componentes de sistema no puede modificarse. | TENANT_ADMIN |
| `DELETE` | `/api/v1/menu/components/{componentId}` | UC-PRM-005 | Elimina (soft delete) un componente y en cascada todos sus elementos. También limpia los `component_permissions` y `element_permissions` asociados. Solo aplica a componentes con `isSystem = FALSE`. | TENANT_ADMIN |

### 7.2 Gestión de elementos de un componente

| Método | Ruta | UC | Descripción | Roles |
|---|---|---|---|---|
| `GET` | `/api/v1/menu/components/{componentId}/elements` | UC-PRM-002 | Lista todos los elementos de UI activos de un componente (botones, tabs, campos, secciones). | TENANT_ADMIN |
| `POST` | `/api/v1/menu/components/{componentId}/elements` | UC-PRM-006 | Registra un nuevo elemento de UI dentro del componente. El `elementKey` debe ser único dentro del componente. | TENANT_ADMIN |
| `PATCH` | `/api/v1/menu/components/{componentId}/elements/{elementId}` | UC-PRM-007 | Actualiza la etiqueta (`label`) y/o el tipo (`elementType`) de un elemento de UI. | TENANT_ADMIN |
| `DELETE` | `/api/v1/menu/components/{componentId}/elements/{elementId}` | UC-PRM-008 | Elimina (soft delete) un elemento. Limpia sus `element_permissions` y `user_element_overrides` asociados. | TENANT_ADMIN |

### 7.3 Permisos por rol

| Método | Ruta | UC | Descripción | Roles |
|---|---|---|---|---|
| `GET` | `/api/v1/menu/permissions/roles/{roleId}` | UC-PRM-009 | Retorna la **matriz completa de permisos** del rol: todos los componentes del tenant con su nivel de acceso (`hidden`/`view`/`execute`) y, dentro de cada uno, todos sus elementos con su acceso y si es heredado del componente (`inherited: true`) o configurado explícitamente. Es la API principal que alimenta la pantalla de gestión de permisos. | TENANT_ADMIN |
| `PUT` | `/api/v1/menu/permissions/roles/{roleId}/components/{componentId}` | UC-PRM-010 | Asigna o actualiza (upsert) el nivel de acceso de un rol sobre un componente completo. Si no existía el permiso, lo crea; si ya existía, lo actualiza. | TENANT_ADMIN |
| `DELETE` | `/api/v1/menu/permissions/roles/{roleId}/components/{componentId}` | UC-PRM-011 | Elimina el permiso explícito del rol sobre el componente. El acceso del componente vuelve al `default_access` definido en el ítem de menú asociado. | TENANT_ADMIN |
| `PUT` | `/api/v1/menu/permissions/roles/{roleId}/components/batch` | UC-PRM-012 | Asigna o actualiza (upsert) los permisos de un rol sobre múltiples componentes en una sola transacción. Útil para operaciones "aplicar a todos" desde el UI. | TENANT_ADMIN |
| `PUT` | `/api/v1/menu/permissions/roles/{roleId}/elements/{elementId}` | UC-PRM-013 | Asigna o actualiza (upsert) el nivel de acceso de un rol sobre un elemento de UI específico. Sobreescribe la herencia del componente con un permiso granular. | TENANT_ADMIN |
| `DELETE` | `/api/v1/menu/permissions/roles/{roleId}/elements/{elementId}` | UC-PRM-014 | Elimina el permiso explícito del rol sobre el elemento. El elemento vuelve a heredar el acceso del `ComponentPermission` del rol. | TENANT_ADMIN |
| `PUT` | `/api/v1/menu/permissions/roles/{roleId}/elements/batch` | UC-PRM-015 | Asigna o actualiza (upsert) los permisos de un rol sobre múltiples elementos en una sola transacción. | TENANT_ADMIN |

### 7.4 Overrides por usuario

| Método | Ruta | UC | Descripción | Roles |
|---|---|---|---|---|
| `GET` | `/api/v1/menu/permissions/users/{userId}/overrides` | UC-PRM-016 | Lista todos los overrides de elementos configurados para un usuario específico, incluyendo los ya expirados (marcados con `expired: true`). | TENANT_ADMIN |
| `PUT` | `/api/v1/menu/permissions/users/{userId}/overrides/{elementId}` | UC-PRM-017 | Crea o actualiza (upsert) un override de acceso para un usuario sobre un elemento de UI. Requiere justificación (`reason`). Puede configurarse con fecha de expiración (`expiresAt`). Este permiso tiene prioridad sobre cualquier permiso de rol. | TENANT_ADMIN |
| `DELETE` | `/api/v1/menu/permissions/users/{userId}/overrides/{elementId}` | UC-PRM-018 | Elimina el override del usuario sobre el elemento. El acceso efectivo vuelve a calcularse desde los permisos de rol del usuario. | TENANT_ADMIN |

---

## 8. Catálogo de códigos de error del módulo

| Código | HTTP | Descripción |
|---|---|---|
| `NXC-CMP-0001` | 404 | Component not found in this tenant |
| `NXC-CMP-0002` | 409 | Module key already exists in this tenant |
| `NXC-CMP-0003` | 403 | TENANT_ADMIN cannot create system components |
| `NXC-CMP-0004` | 409 | Version conflict while updating component |
| `NXC-CMP-0005` | 422 | Module key of a system component cannot be changed |
| `NXC-CMP-0006` | 422 | System components cannot be deleted |
| `NXC-ELM-0001` | 409 | Element key already exists in this component |
| `NXC-ELM-0002` | 404 | Element not found in this component |
| `NXC-PRM-0001` | 404 | Role not found in this tenant |
| `NXC-PRM-0002` | 422 | One or more componentIds do not belong to this tenant |
| `NXC-PRM-0003` | 422 | Override reason is required and cannot be empty |
| `NXC-PRM-0004` | 404 | User not found in this tenant |
| `NXC-PRM-0005` | 422 | One or more elementIds do not belong to this tenant |
| `NXC-VALIDATION-0001` | 422 | Bean Validation failure; field detail included in message |
| `NXC-INTERNAL-0001` | 500 | Unexpected internal server error |

---

## 9. Criterios de aceptación

### CA-PRM-001 — Crear componente con moduleKey único

**Dado** un TENANT_ADMIN del tenant demo,  
**cuando** crea un componente con `moduleKey = "incident-manager"`,  
**entonces:**
- El sistema persiste el componente con `isSystem = FALSE`, `tenantId` del actor, `createdBy` del actor.
- Retorna HTTP 201 con `ComponentSummaryResponse` y header `Location`.
- Un segundo intento con el mismo `moduleKey` retorna HTTP 409 con código `NXC-CMP-0002`.

---

### CA-PRM-002 — Soft delete en cascada de componente

**Dado** un componente con 3 elementos activos y permisos configurados para 2 roles,  
**cuando** un TENANT_ADMIN lo elimina (`DELETE /api/v1/menu/components/{id}`),  
**entonces:**
- El componente queda con `deleted_at` poblado (no se elimina físicamente).
- Los 3 elementos también quedan con `deleted_at` poblado.
- Las entradas en `component_permissions` y `element_permissions` para ese componente son eliminadas.
- `GET /api/v1/menu/components/{id}` retorna HTTP 404.

---

### CA-PRM-003 — Componente de sistema no eliminable

**Dado** el componente `user-management` con `isSystem = TRUE`,  
**cuando** un TENANT_ADMIN intenta eliminarlo,  
**entonces:**
- El sistema retorna HTTP 422 con código `NXC-CMP-0006`.
- El componente permanece sin cambios.

---

### CA-PRM-004 — Matriz de permisos para un rol sin configurar

**Dado** un rol `EDITOR` recién creado sin ningún permiso explícito configurado,  
**cuando** se invoca `GET /api/v1/menu/permissions/roles/{roleId}`,  
**entonces:**
- La respuesta retorna HTTP 200.
- Todos los componentes del tenant aparecen en `components` con `access = "hidden"`.
- Para cada componente, todos sus elementos aparecen con `access = "hidden"` e `inherited = true`.

---

### CA-PRM-005 — Upsert de permiso de componente

**Dado** un rol `EDITOR` sin permiso sobre `user-management`,  
**cuando** un TENANT_ADMIN invoca `PUT /api/v1/menu/permissions/roles/{roleId}/components/{componentId}` con `{ "access": "EXECUTE" }`,  
**entonces:**
- El sistema crea la entrada en `component_permissions`.
- Retorna HTTP 200 con el permiso configurado.
- Una segunda invocación con `{ "access": "VIEW" }` actualiza el registro existente (no crea uno nuevo).
- `GET /api/v1/menu/permissions/roles/{roleId}` refleja el cambio.

---

### CA-PRM-006 — Herencia de acceso de componente a elemento

**Dado** un rol `EDITOR` con `EXECUTE` sobre el componente `user-management` y sin `ElementPermission` explícita para `searchInput`,  
**cuando** se invoca `GET /api/v1/menu/permissions/roles/{roleId}`,  
**entonces:**
- El elemento `searchInput` aparece con `access = "execute"` e `inherited = true`.
- Los elementos con `ElementPermission` explícita diferente aparecen con `inherited = false`.

---

### CA-PRM-007 — Override de usuario tiene prioridad sobre rol

**Dado** un usuario con rol `VIEWER` (sin acceso a `btn-delete-user`) que tiene un override activo `EXECUTE` sobre ese elemento,  
**cuando** el `UserProfileService` resuelve su acceso efectivo (UC-MNU-001),  
**entonces:**
- El elemento `btn-delete-user` aparece en el perfil con `access = "execute"`.
- La resolución tiene en cuenta `expires_at IS NULL OR expires_at > NOW()`.

---

### CA-PRM-008 — Override expirado se ignora

**Dado** un usuario con override `EXECUTE` sobre `btn-create-user` con `expiresAt` en el pasado,  
**cuando** el sistema resuelve el acceso efectivo,  
**entonces:**
- El override expirado es ignorado.
- El acceso efectivo se calcula desde el permiso de rol del usuario.
- `GET /api/v1/menu/permissions/users/{userId}/overrides` muestra el override con `expired = true`.

---

### CA-PRM-009 — Override requiere justificación

**Dado** un TENANT_ADMIN que intenta crear un override,  
**cuando** envía `PUT /api/v1/menu/permissions/users/{userId}/overrides/{elementId}` con `reason = ""`,  
**entonces:**
- El sistema retorna HTTP 422 con código `NXC-PRM-0003`.
- No se crea ningún registro en `user_element_overrides`.

---

### CA-PRM-010 — Actualización masiva de permisos de componentes

**Dado** un tenant con 5 componentes y un rol `VIEWER`,  
**cuando** un TENANT_ADMIN invoca `PUT /api/v1/menu/permissions/roles/{roleId}/components/batch` con los 5 componentIds y `access = "VIEW"`,  
**entonces:**
- El sistema ejecuta upsert para los 5 componentes en una sola transacción.
- Si el permiso de alguno ya existía con otro valor, queda actualizado a `VIEW`.
- Retorna HTTP 200 con los 5 permisos resultantes.
- Si algún `componentId` no pertenece al tenant, la operación entera falla con HTTP 422 y código `NXC-PRM-0002`.

---

### CA-PRM-011 — Eliminar permiso restaura acceso por defecto

**Dado** un rol `EDITOR` con `ElementPermission EXECUTE` sobre `btn-delete-user`,  
**cuando** se invoca `DELETE /api/v1/menu/permissions/roles/{roleId}/elements/{elementId}`,  
**entonces:**
- El registro en `element_permissions` es eliminado.
- En la matriz de permisos (`GET /api/v1/menu/permissions/roles/{roleId}`), el elemento `btn-delete-user` aparece con `inherited = true` y el acceso heredado del `ComponentPermission` del rol.

---

### CA-PRM-012 — Aislamiento multi-tenant en permisos

**Dado** un TENANT_ADMIN del tenant A,  
**cuando** consulta o modifica permisos para roleIds y componentIds,  
**entonces:**
- El sistema no devuelve ni acepta roleIds, componentIds ni elementIds del tenant B.
- Los intentos de acceder a recursos de otro tenant retornan HTTP 404.
- El aislamiento está garantizado tanto por la capa de aplicación como por RLS de PostgreSQL.

---

### CA-PRM-013 — Validación de pertenencia al mismo tenant

**Dado** que un TENANT_ADMIN intenta asignar un permiso usando un `roleId` de su tenant pero un `componentId` de otro tenant,  
**cuando** invoca `PUT /api/v1/menu/permissions/roles/{roleId}/components/{componentId}`,  
**entonces:**
- El sistema retorna HTTP 404 con código `NXC-CMP-0001` (el componentId no existe en su tenant).

---

### CA-PRM-014 — Rendimiento de la matriz de permisos

- `GET /api/v1/menu/permissions/roles/{roleId}` para un tenant con 15 componentes y 80 elementos responde en menos de **400ms en p95**.
- El sistema ejecuta como máximo **3 consultas SQL**: (1) componentes del tenant, (2) `component_permissions` del rol, (3) `element_permissions` del rol con JOIN a `component_elements`.

---

## 10. Restricciones técnicas

**Upsert en permisos:** Las operaciones `PUT` sobre `component_permissions` y `element_permissions` son siempre upsert (`INSERT ON CONFLICT DO UPDATE`). No existen endpoints separados de creación y actualización para permisos.

**Transacciones en batch:** Las operaciones batch (`/batch`) ejecutan todos los upserts dentro de una única transacción `@Transactional`. El fallo de una validación cancela toda la operación.

**RLS activo:** El interceptor de Hibernate establece `SET LOCAL app.tenant_id = ':tenantId'` antes de cada operación. No es posible operar sobre datos de otro tenant aunque se proporcione el UUID correcto.

**Cascade delete lógico:** El soft delete de un componente debe propagar `deletedAt` a sus elementos en la misma transacción. La eliminación de `component_permissions` y `element_permissions` es física (DELETE) dado que son tablas de configuración sin auditoría propia.

**MapStruct:** Los mapeos dominio ↔ DTOs se implementan con MapStruct en `application/mapper/`. Los mapeos proyecciones SQL ↔ dominio en `infrastructure/persistence/mapper/`. Ningún servicio ni controlador mapea manualmente.

**ArchUnit:** El módulo debe pasar las reglas de `HexagonalArchTest.java` y `ModuleBoundaryTest.java`. Ninguna clase de `domain` importa de `infrastructure` ni de `module.tenant`.

**Manejo de errores:** Reutiliza el `GlobalExceptionHandler` de `module-tenant`. Los códigos `NXC-CMP-*`, `NXC-ELM-*` y `NXC-PRM-*` se añaden como factory methods a `BusinessException`.

---

## 11. Estructura de archivos del módulo (extensión)

Los archivos nuevos se añaden al módulo existente en:  
`nexcore-core/src/main/java/com/nexore/core/module/menu/`

> Los archivos existentes del perfil de usuario (`UserProfileService`, `UserProfileController`, etc.) no se modifican.

```
module/menu/
├── domain/
│   ├── model/
│   │   ├── [existente] AccessLevel.java
│   │   ├── [existente] ComponentPermission.java   ← extender con campo id y tenantId para escritura
│   │   ├── [existente] ElementPermission.java     ← ídem
│   │   ├── [nuevo] Component.java
│   │   ├── [nuevo] ComponentElement.java
│   │   └── [nuevo] UserElementOverride.java
│   └── repository/
│       ├── [existente] UserProfileRepository.java
│       ├── [nuevo] ComponentRepository.java
│       ├── [nuevo] ComponentElementRepository.java
│       ├── [nuevo] ComponentPermissionRepository.java
│       ├── [nuevo] ElementPermissionRepository.java
│       └── [nuevo] UserElementOverrideRepository.java
│
├── application/
│   ├── service/
│   │   ├── [existente] UserProfileService.java
│   │   ├── [nuevo] ComponentService.java             ← UC-PRM-001 a UC-PRM-005
│   │   ├── [nuevo] ComponentElementService.java      ← UC-PRM-006 a UC-PRM-008
│   │   └── [nuevo] PermissionService.java            ← UC-PRM-009 a UC-PRM-018
│   ├── dto/
│   │   ├── request/
│   │   │   ├── [nuevo] ComponentCreateRequest.java
│   │   │   ├── [nuevo] ComponentUpdateRequest.java
│   │   │   ├── [nuevo] ComponentElementCreateRequest.java
│   │   │   ├── [nuevo] ComponentElementUpdateRequest.java
│   │   │   ├── [nuevo] ComponentPermissionUpsertRequest.java
│   │   │   ├── [nuevo] BatchComponentPermissionRequest.java
│   │   │   ├── [nuevo] BatchElementPermissionRequest.java
│   │   │   └── [nuevo] UserElementOverrideRequest.java
│   │   └── response/
│   │       ├── [existente] ComponentPermissionResponse.java
│   │       ├── [existente] ElementPermissionResponse.java
│   │       ├── [nuevo] ComponentSummaryResponse.java
│   │       ├── [nuevo] ComponentDetailResponse.java
│   │       ├── [nuevo] ComponentElementResponse.java
│   │       ├── [nuevo] RolePermissionMatrixResponse.java
│   │       ├── [nuevo] RoleComponentPermissionResponse.java
│   │       ├── [nuevo] RoleElementPermissionResponse.java
│   │       └── [nuevo] UserOverrideResponse.java
│   └── mapper/
│       ├── [existente] UserProfileMapper.java
│       ├── [nuevo] ComponentMapper.java
│       └── [nuevo] PermissionMapper.java
│
└── infrastructure/
    ├── web/
    │   ├── [existente] UserProfileController.java
    │   ├── [nuevo] ComponentController.java           ← GET|POST /components, PATCH|DELETE /{id}
    │   ├── [nuevo] ComponentElementController.java    ← GET|POST /{componentId}/elements, PATCH|DELETE /{id}
    │   └── [nuevo] PermissionController.java          ← todos los endpoints /permissions/**
    └── persistence/
        ├── [existente] JpaUserProfileRepositoryAdapter.java
        ├── [nuevo] JpaComponentRepositoryAdapter.java
        ├── [nuevo] JpaComponentElementRepositoryAdapter.java
        ├── [nuevo] JpaComponentPermissionRepositoryAdapter.java
        ├── [nuevo] JpaElementPermissionRepositoryAdapter.java
        ├── [nuevo] JpaUserElementOverrideRepositoryAdapter.java
        ├── entity/
        │   ├── [nuevo] ComponentJpaEntity.java
        │   ├── [nuevo] ComponentElementJpaEntity.java
        │   ├── [nuevo] ComponentPermissionJpaEntity.java
        │   ├── [nuevo] ElementPermissionJpaEntity.java
        │   └── [nuevo] UserElementOverrideJpaEntity.java
        ├── jpa/
        │   ├── [nuevo] SpringDataComponentRepository.java
        │   ├── [nuevo] SpringDataComponentElementRepository.java
        │   ├── [nuevo] SpringDataComponentPermissionRepository.java
        │   ├── [nuevo] SpringDataElementPermissionRepository.java
        │   └── [nuevo] SpringDataUserElementOverrideRepository.java
        └── mapper/
            ├── [existente] UserProfilePersistenceMapper.java
            ├── [nuevo] ComponentPersistenceMapper.java
            └── [nuevo] PermissionPersistenceMapper.java
```

---

## 12. Convención temporal de autenticación (fase MVP)

> Hasta que Spring Security con JWT esté implementado, los controladores nuevos siguen la misma convención que el resto del backend.

| Header | Tipo | Controlador | Descripción |
|---|---|---|---|
| `X-Tenant-Id` | UUID | `ComponentController`, `ComponentElementController`, `PermissionController` | Tenant del actor autenticado |
| `X-Actor-Id` | UUID | Los mismos | UUID del usuario autenticado |
| `X-Is-Tenant-Admin` | boolean | Los mismos | `true` si el actor tiene rol TENANT_ADMIN |

---

## 13. Pendientes

| Área | Estado | Descripción |
|---|---|---|
| Renombre de módulo | `PENDIENTE` | Evaluar renombrar `module-menu` a `module-component-web` para reflejar mejor su responsabilidad real. Requiere refactorizar paquetes y rutas de API |
| Eventos de dominio | `PENDIENTE` | Los cambios de permisos deberían emitir eventos (`ComponentPermissionChangedEvent`, `UserOverrideCreatedEvent`) para auditoría vía Kafka. No implementado aún |
| Invalidación de caché de perfil | `PENDIENTE` | Cuando se modifica un permiso, el perfil cacheado en Redis del usuario afectado debe invalidarse. Requiere coordinar con el futuro módulo de caché |
| SUPER_ADMIN — CRUD de componentes de sistema | `PENDIENTE` | Los componentes con `isSystem = TRUE` solo pueden gestionarlos usuarios del tenant `system` con rol `SUPER_ADMIN`. Los endpoints actuales solo contemplan TENANT_ADMIN |
| Paginación en `GET /elements` | `PENDIENTE` | Los componentes con muchos elementos (>100) deberían paginar. En esta versión se retorna la lista completa |
```
