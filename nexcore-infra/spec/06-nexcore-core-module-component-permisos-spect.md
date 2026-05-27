# NexCore — Especificaciones y Criterios de Aceptación
## Módulo: `module-menu` — Gestión de Componentes y Permisos
**Versión:** 1.1 (Fase 1)  
**Schemas DB:** `nxc_menu`, `nxc_tenant`  
**Paquete base:** `com.nexore.core.module.menu`  
**Ubicación:** `nexcore-core/src/main/java/com/nexore/core/module/menu/`  
**Fecha:** 2026-05

---

## Alcance de esta versión

Este spec cubre **únicamente Fase 1**: los endpoints necesarios para que la pantalla de gestión de permisos funcione. Los componentes y elementos se registran por seed/script; la pantalla de administración solo lee esa configuración y permite al TENANT_ADMIN configurar los niveles de acceso por rol.

| Fase | Responsabilidad | Estado |
|---|---|---|
| **Fase 1** | Consulta de componentes y elementos + gestión de permisos por rol | **Este documento** |
| Fase 2 | CRUD de componentes y elementos vía API | Pendiente |
| Fase 2 | Overrides de permisos por usuario | Pendiente |

---

## 1. Contexto y propósito

Este spec amplía el módulo `module-menu` (ver `02-nexcore-core-module-menu-specs.md`) con la responsabilidad de **gestionar los permisos de UI por rol**.

Hasta ahora el módulo solo exponía lectura del perfil de usuario (`UC-MNU-001`). En esta extensión el módulo agrega los endpoints que el TENANT_ADMIN utiliza para configurar qué puede ver y ejecutar cada rol en la interfaz.

El modelo de permisos opera en dos niveles:

| Nivel | Entidad DB | Descripción |
|---|---|---|
| **Componente** | `nxc_menu.component_permissions` | Acceso de un rol a un módulo/página completo |
| **Elemento** | `nxc_menu.element_permissions` | Acceso granular de un rol a un botón, tab, campo o sección |

**Dependencias de dominio:**

```
module-menu (permisos) → nxc_menu.components
                       → nxc_menu.component_elements
                       → nxc_menu.component_permissions
                       → nxc_menu.element_permissions
                       → nxc_tenant.roles  (validación de existencia y tenant)
```

> **Nota de nomenclatura:** El nombre `menu` del módulo queda corto para describir su responsabilidad real. Se contempla renombrarlo a `module-component-web` en una iteración futura. Por ahora todo permanece bajo `module-menu` para no romper paquetes existentes.

---

## 2. Entidades del dominio

---

### 2.1 Component *(aggregate root)*

Representa un módulo o página de la aplicación Angular. Es la unidad mínima de control de acceso a nivel de ruta. En Fase 1 es de **solo lectura** vía API — se registra por seed/script.

| Campo | Tipo | Descripción |
|---|---|---|
| `id` | UUID | PK generada automáticamente |
| `tenantId` | UUID | FK a `nxc_tenant.tenants`. Scope del componente |
| `moduleKey` | VARCHAR(150) | Clave técnica única por tenant: `"user-management"`, `"audit-viewer"` |
| `name` | VARCHAR(150) | Nombre legible: `"Gestión de usuarios"` |
| `route` | VARCHAR(255) | Ruta Angular: `"/admin/users"` |
| `description` | VARCHAR(500) | Descripción del propósito del componente |
| `isSystem` | BOOLEAN | `TRUE`: componente del sistema, visible para todos los tenants |
| `createdAt` | TIMESTAMPTZ | Fecha de creación |
| `updatedAt` | TIMESTAMPTZ | Última modificación |
| `deletedAt` | TIMESTAMPTZ | Soft delete |

---

### 2.2 ComponentElement *(entidad)*

Elemento de UI controlable individualmente dentro de un componente: botón, tab, campo, sección, acción. En Fase 1 es de **solo lectura** vía API — se registra por seed/script.

| Campo | Tipo | Descripción |
|---|---|---|
| `id` | UUID | PK |
| `tenantId` | UUID | FK a `nxc_tenant.tenants` |
| `componentId` | UUID | FK a `nxc_menu.components` |
| `elementKey` | VARCHAR(150) | Clave técnica: `"btn-create-user"`, `"tab-roles"`, `"searchInput"` |
| `label` | VARCHAR(200) | Descripción legible para el administrador |
| `elementType` | VARCHAR(50) | `BUTTON \| TAB \| FIELD \| SECTION \| ACTION` |
| `deletedAt` | TIMESTAMPTZ | Soft delete |

---

### 2.3 ComponentPermission *(entidad)*

Permiso de un rol sobre un componente completo. Si un rol tiene `EXECUTE` sobre un componente, todos sus elementos heredan `EXECUTE` salvo que `ElementPermission` lo restrinja individualmente.

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
- `(tenantId, roleId, componentId)` es único — solo un permiso por combinación (upsert).
- `roleId` y `componentId` deben pertenecer al mismo `tenantId`.

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

### 2.5 AccessLevel *(enum, compartido con module-menu existente)*

| Valor | Descripción |
|---|---|
| `HIDDEN` | No visible. El elemento no se renderiza en el frontend |
| `VIEW` | Visible pero deshabilitado |
| `EXECUTE` | Visible y habilitado — el usuario puede interactuar |

---

## 3. Resolución de acceso efectivo

La jerarquía de resolución, de mayor a menor prioridad:

```
1. UserElementOverride (válido, no expirado)   ← gana siempre  [Fase 2]
2. ElementPermission   (máximo entre roles)
3. ComponentPermission (máximo entre roles)    ← hereda a elementos sin ElementPermission
4. default_access del menu_item                ← fallback final
```

Para usuarios con múltiples roles, se aplica el **máximo** entre los valores de acceso de todos sus roles activos:

```
EXECUTE (2) > VIEW (1) > HIDDEN (0)
```

> En Fase 1 el nivel 1 (UserElementOverride) ya es tenido en cuenta por `UserProfileService` al construir el perfil (UC-MNU-001). Su gestión vía API se implementa en Fase 2.

---

## 4. Casos de uso — Fase 1

---

### UC-PRM-001 — Listar componentes del tenant

**Actor:** TENANT_ADMIN  
**Endpoint:** `GET /api/v1/menu/components`

**Flujo principal:**
1. El sistema extrae `tenant_id` del contexto de seguridad.
2. Consulta `nxc_menu.components` filtrando por `tenant_id` y `deleted_at IS NULL`. Incluye los componentes de sistema (`is_system = TRUE`) visibles para el tenant.
3. Aplica paginación y filtros opcionales.
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

### UC-PRM-003 — Obtener matriz de permisos de un rol

**Actor:** TENANT_ADMIN  
**Endpoint:** `GET /api/v1/menu/permissions/roles/{roleId}`

Esta es la **API central** de la pantalla de gestión de permisos. Retorna todos los componentes del tenant con su acceso configurado para el rol, y dentro de cada componente todos sus elementos con su acceso y si es heredado.

**Flujo principal:**
1. El sistema valida que `roleId` pertenece al tenant activo.
2. Consulta todos los componentes del tenant activos.
3. Para cada componente busca la entrada en `component_permissions` para el `roleId`. Si no existe, el acceso es `HIDDEN`.
4. Para cada componente carga sus elementos y busca las entradas en `element_permissions`. Si no existe para un elemento, el acceso se hereda del componente (`inherited: true`).
5. Retorna HTTP 200 con `RolePermissionMatrixResponse`.

**Flujo alternativo:**
- `roleId` no pertenece al tenant → HTTP 404 con código `NXC-PRM-0001`.

**Estrategia de consulta (máximo 3 queries):**

```sql
-- 1. Componentes del tenant (incluye is_system = TRUE)
SELECT id, module_key, name, route, description, is_system
FROM nxc_menu.components
WHERE (tenant_id = :tenantId OR is_system = TRUE)
  AND deleted_at IS NULL;

-- 2. Permisos del rol sobre componentes
SELECT component_id, access
FROM nxc_menu.component_permissions
WHERE tenant_id = :tenantId
  AND role_id = :roleId;

-- 3. Elementos con sus permisos de rol
SELECT ce.id, ce.component_id, ce.element_key, ce.label, ce.element_type,
       ep.access AS explicit_access
FROM nxc_menu.component_elements ce
LEFT JOIN nxc_menu.element_permissions ep
    ON ep.element_id = ce.id
    AND ep.tenant_id = :tenantId
    AND ep.role_id = :roleId
WHERE ce.tenant_id = :tenantId
  AND ce.deleted_at IS NULL;
```

---

### UC-PRM-004 — Actualizar permiso de un componente para un rol (upsert)

**Actor:** TENANT_ADMIN  
**Endpoint:** `PUT /api/v1/menu/permissions/roles/{roleId}/components/{componentId}`

**Flujo principal:**
1. El actor envía `{ "access": "EXECUTE" }`.
2. El sistema valida que `roleId` pertenece al tenant activo.
3. El sistema valida que `componentId` pertenece al tenant activo (o es `isSystem = TRUE`).
4. Ejecuta upsert en `component_permissions` (`ON CONFLICT (tenant_id, role_id, component_id) DO UPDATE SET access = EXCLUDED.access, updated_by = EXCLUDED.updated_by, updated_at = NOW()`).
5. Retorna HTTP 200 con el permiso resultante.

**Flujos alternativos:**
- `roleId` no pertenece al tenant → HTTP 404 con código `NXC-PRM-0001`.
- `componentId` no encontrado en el tenant → HTTP 404 con código `NXC-CMP-0001`.

---

### UC-PRM-005 — Actualización masiva de permisos de componentes para un rol

**Actor:** TENANT_ADMIN  
**Endpoint:** `PUT /api/v1/menu/permissions/roles/{roleId}/components/batch`

Permite actualizar los permisos de múltiples componentes en una sola operación. Útil para la acción "aplicar a todos" en el UI.

**Flujo principal:**
1. El actor envía un array de `{ componentId, access }`.
2. El sistema valida que `roleId` pertenece al tenant.
3. El sistema valida que **todos** los `componentId` del array pertenecen al tenant. Si alguno falla, rechaza toda la operación.
4. Ejecuta upsert masivo dentro de una única transacción `@Transactional`.
5. Retorna HTTP 200 con la lista de permisos resultantes.

**Flujo alternativo:**
- Algún `componentId` inválido → HTTP 422 con código `NXC-PRM-0002`, listando los IDs inválidos.

---

### UC-PRM-006 — Actualizar permiso de un elemento para un rol (upsert)

**Actor:** TENANT_ADMIN  
**Endpoint:** `PUT /api/v1/menu/permissions/roles/{roleId}/elements/{elementId}`

**Flujo principal:**
1. El actor envía `{ "access": "VIEW" }`.
2. El sistema valida que `roleId` pertenece al tenant.
3. El sistema valida que `elementId` existe y su componente pertenece al tenant.
4. Ejecuta upsert en `element_permissions`.
5. Retorna HTTP 200 con el permiso resultante.

**Flujos alternativos:**
- `roleId` no pertenece al tenant → HTTP 404 con código `NXC-PRM-0001`.
- `elementId` no encontrado → HTTP 404 con código `NXC-ELM-0001`.

---

## 5. DTOs de request

### ComponentPermissionUpsertRequest
```
access          String  REQUERIDO  Enum: HIDDEN | VIEW | EXECUTE
```

### BatchComponentPermissionRequest
```
permissions     ComponentPermissionItem[]  REQUERIDO  Min: 1  Max: 100
  componentId   UUID    REQUERIDO
  access        String  REQUERIDO  Enum: HIDDEN | VIEW | EXECUTE
```

### ElementPermissionUpsertRequest
```
access          String  REQUERIDO  Enum: HIDDEN | VIEW | EXECUTE
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
elementType     String     BUTTON | TAB | FIELD | SECTION | ACTION
```

### RolePermissionMatrixResponse

Respuesta principal del módulo. Alimenta la pantalla de configuración de permisos.

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
access          String     "execute" | "view" | "hidden"  (minúscula)
elements        RoleElementPermissionResponse[]
```

### RoleElementPermissionResponse
```
elementId       UUID
elementKey      String
label           String
elementType     String
access          String     "execute" | "view" | "hidden"
inherited       Boolean    TRUE si hereda el acceso del componente (sin ElementPermission explícita)
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

### ComponentPermissionResultResponse
```
componentId     UUID
moduleKey       String
access          String     "execute" | "view" | "hidden"
updatedAt       String     ISO-8601
```
> Usado como respuesta de `PUT .../components/{componentId}` y en el array del batch.

### ElementPermissionResultResponse
```
elementId       UUID
elementKey      String
access          String     "execute" | "view" | "hidden"
inherited       Boolean    Siempre false — al hacer PUT se crea un permiso explícito
updatedAt       String     ISO-8601
```

---

## 7. Endpoints REST — Fase 1

| Método | Ruta | UC | Descripción | Roles |
|---|---|---|---|---|
| `GET` | `/api/v1/menu/components` | UC-PRM-001 | Lista paginada de componentes del tenant (incluye componentes de sistema). Soporta filtros `search` e `isSystem`. Alimenta el selector de componentes en la pantalla de permisos. | TENANT_ADMIN |
| `GET` | `/api/v1/menu/components/{componentId}` | UC-PRM-002 | Retorna el detalle de un componente con la lista completa de sus elementos de UI activos. | TENANT_ADMIN |
| `GET` | `/api/v1/menu/components/{componentId}/elements` | UC-PRM-002 | Lista los elementos de UI activos de un componente. Alimenta la tabla de elementos en la pantalla de permisos. | TENANT_ADMIN |
| `GET` | `/api/v1/menu/permissions/roles/{roleId}` | UC-PRM-003 | Retorna la **matriz completa de permisos** del rol: todos los componentes con su acceso y, dentro de cada uno, todos sus elementos con su acceso y el campo `inherited`. Es la API principal de la pantalla de gestión de permisos. | TENANT_ADMIN |
| `PUT` | `/api/v1/menu/permissions/roles/{roleId}/components/{componentId}` | UC-PRM-004 | Asigna o actualiza (upsert) el nivel de acceso de un rol sobre un componente. Si no existía el permiso lo crea; si ya existía lo actualiza. | TENANT_ADMIN |
| `PUT` | `/api/v1/menu/permissions/roles/{roleId}/components/batch` | UC-PRM-005 | Asigna o actualiza (upsert) en una sola transacción los permisos de un rol sobre múltiples componentes. Útil para la acción "aplicar a todos". | TENANT_ADMIN |
| `PUT` | `/api/v1/menu/permissions/roles/{roleId}/elements/{elementId}` | UC-PRM-006 | Asigna o actualiza (upsert) el nivel de acceso de un rol sobre un elemento de UI específico. Sobreescribe la herencia del componente con un permiso granular. | TENANT_ADMIN |

> **7 endpoints — Fase 1**

---

## 8. Catálogo de códigos de error — Fase 1

| Código | HTTP | Descripción |
|---|---|---|
| `NXC-CMP-0001` | 404 | Component not found in this tenant |
| `NXC-ELM-0001` | 404 | Element not found in this component |
| `NXC-PRM-0001` | 404 | Role not found in this tenant |
| `NXC-PRM-0002` | 422 | One or more componentIds do not belong to this tenant |
| `NXC-VALIDATION-0001` | 422 | Bean Validation failure; field detail included in message |
| `NXC-INTERNAL-0001` | 500 | Unexpected internal server error |

---

## 9. Criterios de aceptación — Fase 1

### CA-PRM-001 — Lista de componentes del tenant

**Dado** un TENANT_ADMIN del tenant demo,  
**cuando** invoca `GET /api/v1/menu/components`,  
**entonces:**
- Retorna HTTP 200 con `PageResponse<ComponentSummaryResponse>`.
- Incluye los componentes propios del tenant y los componentes de sistema (`isSystem = TRUE`).
- El campo `elementCount` refleja la cantidad de elementos activos de cada componente.
- Los componentes con `deleted_at IS NOT NULL` no aparecen.

---

### CA-PRM-002 — Detalle de componente con elementos

**Dado** el componente `user-management` con 8 elementos activos,  
**cuando** se invoca `GET /api/v1/menu/components/{componentId}`,  
**entonces:**
- Retorna HTTP 200 con `ComponentDetailResponse`.
- El campo `elements` contiene los 8 elementos activos con `elementKey`, `label` y `elementType`.
- Un `componentId` de otro tenant retorna HTTP 404 con código `NXC-CMP-0001`.

---

### CA-PRM-003 — Matriz de permisos para rol sin configurar

**Dado** un rol `EDITOR` recién creado sin ningún permiso explícito,  
**cuando** se invoca `GET /api/v1/menu/permissions/roles/{roleId}`,  
**entonces:**
- Retorna HTTP 200.
- Todos los componentes aparecen con `access = "hidden"`.
- Todos los elementos aparecen con `access = "hidden"` e `inherited = true`.
- Un `roleId` de otro tenant retorna HTTP 404 con código `NXC-PRM-0001`.

---

### CA-PRM-004 — Upsert de permiso de componente (crear y actualizar)

**Dado** un rol `EDITOR` sin permiso sobre `user-management`,  
**cuando** se invoca `PUT /api/v1/menu/permissions/roles/{roleId}/components/{componentId}` con `{ "access": "EXECUTE" }`,  
**entonces:**
- El sistema crea la entrada en `component_permissions` con `createdBy` del actor.
- Retorna HTTP 200 con `ComponentPermissionResultResponse`.
- Una segunda invocación con `{ "access": "VIEW" }` actualiza el registro (no crea uno nuevo).
- `GET /api/v1/menu/permissions/roles/{roleId}` refleja el nuevo valor.

---

### CA-PRM-005 — Herencia de acceso de componente a elemento

**Dado** un rol `EDITOR` con `EXECUTE` sobre `user-management` y sin `ElementPermission` explícita para `searchInput`,  
**cuando** se invoca `GET /api/v1/menu/permissions/roles/{roleId}`,  
**entonces:**
- El elemento `searchInput` aparece con `access = "execute"` e `inherited = true`.
- Un elemento con `ElementPermission` explícita diferente aparece con `inherited = false`.

---

### CA-PRM-006 — Upsert de permiso de elemento

**Dado** un rol `EDITOR` con `EXECUTE` heredado en `btn-delete-user`,  
**cuando** se invoca `PUT /api/v1/menu/permissions/roles/{roleId}/elements/{elementId}` con `{ "access": "VIEW" }`,  
**entonces:**
- El sistema crea la entrada en `element_permissions`.
- El elemento pasa a tener `access = "view"` e `inherited = false` en la matriz.
- El perfil del usuario (`GET /api/v1/me/profile`) refleja el nuevo acceso en la próxima llamada.

---

### CA-PRM-007 — Actualización masiva de permisos (batch)

**Dado** un tenant con 5 componentes y un rol `VIEWER` sin permisos,  
**cuando** se invoca `PUT /api/v1/menu/permissions/roles/{roleId}/components/batch` con los 5 componentIds y `access = "VIEW"`,  
**entonces:**
- El sistema ejecuta upsert para los 5 componentes en una sola transacción.
- Retorna HTTP 200 con los 5 `ComponentPermissionResultResponse`.
- Si algún `componentId` no pertenece al tenant, la operación entera falla con HTTP 422, código `NXC-PRM-0002` y la lista de IDs inválidos. Ningún permiso es modificado.

---

### CA-PRM-008 — Aislamiento multi-tenant

**Dado** un TENANT_ADMIN del tenant A,  
**cuando** consulta o modifica permisos,  
**entonces:**
- `GET /api/v1/menu/components` solo retorna componentes del tenant A (más los de sistema).
- `GET /api/v1/menu/permissions/roles/{roleId}` retorna HTTP 404 si el `roleId` pertenece al tenant B.
- `PUT /api/v1/menu/permissions/roles/{roleId}/components/{componentId}` retorna HTTP 404 si el `componentId` pertenece al tenant B.
- El aislamiento está garantizado por la capa de aplicación y por RLS de PostgreSQL.

---

### CA-PRM-009 — Rendimiento de la matriz de permisos

- `GET /api/v1/menu/permissions/roles/{roleId}` para un tenant con 15 componentes y 80 elementos responde en menos de **400ms en p95**.
- El sistema ejecuta como máximo **3 consultas SQL** por invocación (componentes, permisos de componente, elementos con permisos de elemento).

---

## 10. Restricciones técnicas

**Solo upsert en permisos:** Los endpoints `PUT` sobre `component_permissions` y `element_permissions` son siempre upsert (`INSERT ON CONFLICT DO UPDATE`). No hay endpoint de creación separado del de actualización.

**Transacciones en batch:** La operación batch ejecuta todos los upserts dentro de una única transacción `@Transactional`. El fallo de una validación previa cancela toda la operación antes de ejecutar ningún upsert.

**RLS activo:** El interceptor de Hibernate establece `SET LOCAL app.tenant_id = ':tenantId'` antes de cada operación. No es posible leer ni escribir datos de otro tenant aunque se proporcione el UUID correcto.

**Componentes de sistema:** Los componentes con `is_system = TRUE` pertenecen al tenant `system` pero son visibles para todos los tenants por la política RLS. Los permisos sobre estos componentes se registran en `component_permissions` con el `tenant_id` del tenant que configura (no el tenant `system`).

**Solo lectura de componentes y elementos:** En Fase 1 los controladores no exponen `POST`, `PATCH` ni `DELETE` sobre componentes ni elementos. Los servicios `ComponentService` y `ComponentElementService` solo implementan métodos de consulta.

**MapStruct:** Los mapeos dominio ↔ DTOs en `application/mapper/`. Los mapeos proyecciones SQL ↔ dominio en `infrastructure/persistence/mapper/`. Ningún servicio ni controlador mapea manualmente.

**ArchUnit:** El módulo debe pasar `HexagonalArchTest.java` y `ModuleBoundaryTest.java`. Ninguna clase de `domain` importa de `infrastructure` ni de `module.tenant`.

**Manejo de errores:** Reutiliza el `GlobalExceptionHandler` de `module-tenant`. Los códigos `NXC-CMP-*`, `NXC-ELM-*` y `NXC-PRM-*` se añaden como factory methods a `BusinessException`.

---

## 11. Estructura de archivos del módulo — Fase 1

`nexcore-core/src/main/java/com/nexore/core/module/menu/`

> Los archivos existentes del perfil de usuario no se modifican.

```
module/menu/
├── domain/
│   ├── model/
│   │   ├── [existente] AccessLevel.java
│   │   ├── [existente] ComponentPermission.java   ← extender con id, tenantId, createdBy, updatedBy
│   │   ├── [existente] ElementPermission.java     ← ídem
│   │   ├── [nuevo] Component.java
│   │   └── [nuevo] ComponentElement.java
│   └── repository/
│       ├── [existente] UserProfileRepository.java
│       ├── [nuevo] ComponentRepository.java          ← findByTenant(), findById()
│       ├── [nuevo] ComponentElementRepository.java   ← findByComponent()
│       ├── [nuevo] ComponentPermissionRepository.java  ← upsert(), findByRoleId()
│       └── [nuevo] ElementPermissionRepository.java    ← upsert(), findByRoleId()
│
├── application/
│   ├── service/
│   │   ├── [existente] UserProfileService.java
│   │   ├── [nuevo] ComponentService.java          ← UC-PRM-001, UC-PRM-002
│   │   └── [nuevo] PermissionService.java         ← UC-PRM-003 a UC-PRM-006
│   ├── dto/
│   │   ├── request/
│   │   │   ├── [nuevo] ComponentPermissionUpsertRequest.java
│   │   │   ├── [nuevo] BatchComponentPermissionRequest.java
│   │   │   └── [nuevo] ElementPermissionUpsertRequest.java
│   │   └── response/
│   │       ├── [existente] ComponentPermissionResponse.java
│   │       ├── [existente] ElementPermissionResponse.java
│   │       ├── [nuevo] ComponentSummaryResponse.java
│   │       ├── [nuevo] ComponentDetailResponse.java
│   │       ├── [nuevo] ComponentElementResponse.java
│   │       ├── [nuevo] RolePermissionMatrixResponse.java
│   │       ├── [nuevo] RoleComponentPermissionResponse.java
│   │       ├── [nuevo] RoleElementPermissionResponse.java
│   │       ├── [nuevo] ComponentPermissionResultResponse.java
│   │       └── [nuevo] ElementPermissionResultResponse.java
│   └── mapper/
│       ├── [existente] UserProfileMapper.java
│       ├── [nuevo] ComponentMapper.java
│       └── [nuevo] PermissionMapper.java
│
└── infrastructure/
    ├── web/
    │   ├── [existente] UserProfileController.java
    │   ├── [nuevo] ComponentController.java      ← GET /components, GET /components/{id}, GET /{id}/elements
    │   └── [nuevo] PermissionController.java     ← GET y PUT /permissions/**
    └── persistence/
        ├── [existente] JpaUserProfileRepositoryAdapter.java
        ├── [nuevo] JpaComponentRepositoryAdapter.java
        ├── [nuevo] JpaComponentElementRepositoryAdapter.java
        ├── [nuevo] JpaComponentPermissionRepositoryAdapter.java
        └── [nuevo] JpaElementPermissionRepositoryAdapter.java
        ├── entity/
        │   ├── [nuevo] ComponentJpaEntity.java
        │   ├── [nuevo] ComponentElementJpaEntity.java
        │   ├── [nuevo] ComponentPermissionJpaEntity.java
        │   └── [nuevo] ElementPermissionJpaEntity.java
        ├── jpa/
        │   ├── [nuevo] SpringDataComponentRepository.java
        │   ├── [nuevo] SpringDataComponentElementRepository.java
        │   ├── [nuevo] SpringDataComponentPermissionRepository.java
        │   └── [nuevo] SpringDataElementPermissionRepository.java
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
| `X-Tenant-Id` | UUID | `ComponentController`, `PermissionController` | Tenant del actor autenticado |
| `X-Actor-Id` | UUID | Los mismos | UUID del usuario autenticado |
| `X-Is-Tenant-Admin` | boolean | Los mismos | `true` si el actor tiene rol TENANT_ADMIN |

---

## 13. Pendientes / Fase 2

| Área | Endpoints diferidos | Descripción |
|---|---|---|
| **CRUD de componentes** | `POST /components`, `PATCH /components/{id}`, `DELETE /components/{id}` | En Fase 1 los componentes se registran por seed/script. Se expone cuando el UI incorpore un formulario de alta y edición. Requiere: `ComponentCreateRequest`, `ComponentUpdateRequest`, códigos `NXC-CMP-0002` a `NXC-CMP-0006` |
| **CRUD de elementos** | `POST /components/{id}/elements`, `PATCH /{id}/elements/{elmId}`, `DELETE /{id}/elements/{elmId}` | Ídem para elementos. Requiere: `ComponentElementCreateRequest`, `ComponentElementUpdateRequest`, códigos `NXC-ELM-0001`, `NXC-ELM-0002` |
| **DELETE de permisos** | `DELETE /permissions/roles/{roleId}/components/{componentId}`, `DELETE /permissions/roles/{roleId}/elements/{elementId}` | Elimina el permiso explícito y vuelve al `default_access`. En Fase 1 basta con hacer `PUT` a `HIDDEN` para el mismo efecto práctico |
| **Batch de elementos** | `PUT /permissions/roles/{roleId}/elements/batch` | Actualización masiva de permisos de elementos. Baja prioridad: el UI actualiza elemento a elemento |
| **Overrides por usuario** | `GET/PUT/DELETE /permissions/users/{userId}/overrides/{elementId}` | Excepción individual de permiso por usuario. La resolución del override en el perfil (`UC-MNU-001`) ya funciona; solo falta la gestión vía API. Requiere: `UserElementOverride` domain model, entidad JPA, repositorio, `UserElementOverrideRequest`, `UserOverrideResponse`, códigos `NXC-PRM-0003`, `NXC-PRM-0004` |
| **Renombre de módulo** | — | Evaluar renombrar `module-menu` a `module-component-web`. Requiere refactorizar paquetes y rutas |
| **Eventos de dominio** | — | Los cambios de permisos deberían emitir `ComponentPermissionChangedEvent` para auditoría vía Kafka |
| **Invalidación de caché** | — | Al modificar un permiso, invalidar el perfil cacheado en Redis del usuario afectado |
