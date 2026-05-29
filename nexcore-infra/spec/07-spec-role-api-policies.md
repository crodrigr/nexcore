# Spec: Role API Policies — Permisos de API REST por Rol

**Servicio:** `nexcore-core` + `nexcore-auth-service`
**Schema BD:** `nxc_menu`
**Tabla nueva:** `nxc_menu.role_api_policies`
**Scripts:** `06-create-role-api-policies.sql` / `07-seed-role-api-policies.sql`

---

## 1. Objetivo

El sistema ya tiene `component_permissions` que controla qué ítems del menú y
botones de la UI ve cada rol. Pero esa tabla no protege los endpoints del backend.

Un usuario malicioso podría llamar directamente a `POST /api/v1/users/{id}/suspend`
desde Postman aunque su rol EDITOR no tenga el botón en la pantalla.

`role_api_policies` resuelve eso: es una tabla de políticas por nombre de rol que
el backend evalúa en un `HandlerInterceptor` (Spring MVC) antes de llegar al controller.

```
                       ┌──────────────────────────────────────┐
Request HTTP ──────────► JwtAuthFilter (extrae userId + roles) │
(con Bearer token)     └────────────────┬─────────────────────┘
                                        │
                       ┌────────────────▼─────────────────────┐
                       │ RoleApiPolicyInterceptor              │
                       │   1. Lee roles del usuario            │
                       │   2. Carga políticas de BD (cacheadas)│
                       │   3. Evalúa path_pattern + método     │
                       │   4. DENY → 403 | ALLOW → continúa   │
                       └────────────────┬─────────────────────┘
                                        │
                       ┌────────────────▼─────────────────────┐
                       │ Controller + Service + Repository     │
                       └──────────────────────────────────────┘
```

---

## 2. Por qué no reutilizar `component_permissions`

| Dimensión | `component_permissions` | `role_api_policies` |
|---|---|---|
| Propósito | Controla visibilidad de UI | Controla acceso a API HTTP |
| Granularidad | Por componente/pantalla | Por método HTTP + path pattern |
| Consumidor | Frontend (Angular) | Backend (Spring interceptor) |
| Registro | Manual o via seed | Por seed (refleja la API actual) |
| Ejemplo | "EDITOR no ve el menú Admin" | "EDITOR no puede POST /users/*/suspend" |

Son capas ortogonales y complementarias. La primera responde "¿aparece el botón?",
la segunda responde "¿puede ejecutar el endpoint?".

---

## 3. Diseño de la tabla

```sql
nxc_menu.role_api_policies
├── id              UUID PK
├── role_name       VARCHAR(100)    -- 'SUPER_ADMIN' | 'TENANT_ADMIN' | 'EDITOR' | 'VIEWER' | '*'
├── http_method     VARCHAR(10)     -- 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE' | '*'
├── path_pattern    VARCHAR(500)    -- '/api/*/users/*'  (Spring PathPatternParser, * = versión)
├── effect          VARCHAR(5)      -- 'ALLOW' | 'DENY'
├── service         VARCHAR(20)     -- 'core' | 'auth'
├── priority        INTEGER         -- Mayor número = se evalúa primero
├── description     VARCHAR(500)
├── created_at      TIMESTAMPTZ
├── updated_at      TIMESTAMPTZ
└── created_by      UUID → nxc_tenant.users(id)
```

### Decisión: `role_name` TEXT en vez de `role_id` UUID

Los roles `TENANT_ADMIN`, `EDITOR`, `VIEWER` existen con **distintos UUIDs** en
cada tenant (se crean automáticamente via trigger cuando se crea un tenant).

Si usara `role_id UUID`, tendría que insertar la misma política N veces, una por
tenant. Con `role_name TEXT`, una sola fila cubre todos los tenants que tengan ese rol.

El interceptor:
1. Lee los roles del usuario desde la BD (o del JWT si se extiende el payload).
2. Busca en `role_api_policies` donde `role_name IN (roles_del_usuario, '*')`.
3. Evalúa las políticas por prioridad descendente.

---

## 4. Reglas de evaluación (algoritmo paso a paso)

Dado `método = POST`, `path = /api/v2/users/abc-123/suspend`, `roles = ['EDITOR']`:

```
1. Cargar todas las políticas donde:
      service = 'core'
   AND role_name IN ('EDITOR', '*')
   AND http_method IN ('POST', '*')

2. Filtrar las que coinciden con el path usando PathPatternParser:
      - '/api/*/users/*/suspend'  → COINCIDE con /api/v2/users/abc-123/suspend
                                    (role_name=EDITOR, effect=DENY, priority=500)
      - '/api/*/users/**'         → no hay para EDITOR
      - '/api/**'                 → no hay para EDITOR con POST

3. Ordenar por priority DESC → [DENY:500, ...]

4. Evaluar:
      a. ¿Alguna coincide con effect='DENY'? → SÍ (priority=500)
      b. Retornar 403 Forbidden.

5. Si no hay ningún DENY, buscar al menos un ALLOW:
      a. ¿Alguna coincide con effect='ALLOW'? → NO
      b. Retornar 403 Forbidden (fail-closed).
```

**Fail-closed:** si no hay ninguna política que aplique → DENY por defecto. Nunca
se deja pasar algo que no esté explícitamente permitido.

### Convención de patrones de versión

El segmento de versión (`v1`, `v2`, …) se representa siempre con `*`.
`*` coincide con **exactamente un segmento** del path.
`**` coincide con **uno o más segmentos** y se usa en DENY generales.

| Patrón almacenado | Versiones que cubre | Ejemplo de path real que coincide |
|---|---|---|
| `/api/*/users` | v1, v2, v3… | `/api/v1/users` , `/api/v2/users` |
| `/api/*/users/*` | todas | `/api/v1/users/uuid` , `/api/v2/users/uuid` |
| `/api/*/users/invitations/accept` | todas | `/api/v1/…/accept` , `/api/v2/…/accept` |
| `/api/*/users/invitations/*/revoke` | todas | `/api/v2/users/invitations/uuid/revoke` |
| `/api/*/menu/permissions/roles/*/components/*` | todas | `/api/v1/menu/permissions/roles/rid/components/cid` |
| `/api/**` | todas (DENY global) | cualquier path bajo `/api/` sin importar profundidad |

En caso de que múltiples patrones coincidan, el de mayor `priority` gana.

---

## 5. Mapa completo de endpoints → políticas

### nexcore-auth-service (puerto 8081)

| Método | Path | Tipo acceso | Roles |
|---|---|---|---|
| `POST` | `/auth/login` | **Público** | Sin JWT — no requiere política |
| `POST` | `/auth/verify-otp` | **Público** | Usa challenge token — sin política |
| `POST` | `/auth/refresh` | Autenticado | `*` (cualquier usuario con sesión activa) |
| `DELETE` | `/auth/logout` | Autenticado | `*` |
| `DELETE` | `/auth/logout-all` | Autenticado | `*` |
| `POST` | `/auth/password/reset/request` | **Público** | Sin JWT — no requiere política |
| `POST` | `/auth/password/reset/confirm` | **Público** | Usa reset token — sin política |
| `PUT` | `/auth/password` | Autenticado | `*` |

> Los endpoints "Público" deben estar en la lista de exclusión del interceptor
> (`permitAll()` en Spring Security). No necesitan fila en `role_api_policies`.

---

### nexcore-core (puerto 8080) — Tenants

> `*` en la posición de versión cubre `v1`, `v2`, `v3`…

| Método | Patrón almacenado | Roles con ALLOW |
|---|---|---|
| `GET` | `/api/*/tenants` | `SUPER_ADMIN` |
| `POST` | `/api/*/tenants` | `SUPER_ADMIN` |
| `GET` | `/api/*/tenants/*` | `SUPER_ADMIN`, `TENANT_ADMIN` |
| `PATCH` | `/api/*/tenants/*` | `SUPER_ADMIN`, `TENANT_ADMIN` |
| `POST` | `/api/*/tenants/*/suspend` | `SUPER_ADMIN` |
| `POST` | `/api/*/tenants/*/activate` | `SUPER_ADMIN` |

---

### nexcore-core (puerto 8080) — Usuarios

| Método | Patrón almacenado | Roles con ALLOW |
|---|---|---|
| `GET` | `/api/*/users/me` | `*` (cualquier autenticado) |
| `GET` | `/api/*/users` | `SUPER_ADMIN`, `TENANT_ADMIN` |
| `POST` | `/api/*/users` | `SUPER_ADMIN`, `TENANT_ADMIN` |
| `GET` | `/api/*/users/*` | `SUPER_ADMIN`, `TENANT_ADMIN`, `EDITOR` |
| `PATCH` | `/api/*/users/*` | `SUPER_ADMIN`, `TENANT_ADMIN`, `EDITOR` ¹ |
| `POST` | `/api/*/users/*/suspend` | `SUPER_ADMIN`, `TENANT_ADMIN` |
| `POST` | `/api/*/users/*/activate` | `SUPER_ADMIN`, `TENANT_ADMIN` |
| `DELETE` | `/api/*/users/*` | `SUPER_ADMIN`, `TENANT_ADMIN` |
| `PUT` | `/api/*/users/*/roles` | `SUPER_ADMIN`, `TENANT_ADMIN` |
| `POST` | `/api/*/users/invite` | `SUPER_ADMIN`, `TENANT_ADMIN` |
| `GET` | `/api/*/users/invitations` | `SUPER_ADMIN`, `TENANT_ADMIN` |
| `POST` | `/api/*/users/invitations/accept` | **Público** (sin política) |
| `POST` | `/api/*/users/invitations/*/revoke` | `SUPER_ADMIN`, `TENANT_ADMIN` |
| `POST` | `/api/*/users/invitations/*/resend` | `SUPER_ADMIN`, `TENANT_ADMIN` |

¹ EDITOR puede editar solo su propio perfil. Esto lo valida la capa de negocio
(compara `{id}` con el `X-Actor-Id` del header), no esta tabla.

---

### nexcore-core (puerto 8080) — Roles

| Método | Patrón almacenado | Roles con ALLOW |
|---|---|---|
| `GET` | `/api/*/roles` | `SUPER_ADMIN`, `TENANT_ADMIN`, `EDITOR`, `VIEWER` |
| `POST` | `/api/*/roles` | `SUPER_ADMIN`, `TENANT_ADMIN` |
| `GET` | `/api/*/roles/*` | `SUPER_ADMIN`, `TENANT_ADMIN`, `EDITOR`, `VIEWER` |
| `PATCH` | `/api/*/roles/*` | `SUPER_ADMIN`, `TENANT_ADMIN` |
| `DELETE` | `/api/*/roles/*` | `SUPER_ADMIN`, `TENANT_ADMIN` |

---

### nexcore-core (puerto 8080) — Perfil, Componentes y Permisos

| Método | Patrón almacenado | Roles con ALLOW |
|---|---|---|
| `GET` | `/api/*/me/profile` | `*` |
| `GET` | `/api/*/menu/components` | `SUPER_ADMIN`, `TENANT_ADMIN` |
| `GET` | `/api/*/menu/components/*` | `SUPER_ADMIN`, `TENANT_ADMIN` |
| `GET` | `/api/*/menu/components/*/elements` | `SUPER_ADMIN`, `TENANT_ADMIN` |
| `GET` | `/api/*/menu/permissions/roles/*` | `SUPER_ADMIN`, `TENANT_ADMIN` |
| `PUT` | `/api/*/menu/permissions/roles/*/components/*` | `SUPER_ADMIN`, `TENANT_ADMIN` |
| `PUT` | `/api/*/menu/permissions/roles/*/components/batch` | `SUPER_ADMIN`, `TENANT_ADMIN` |
| `PUT` | `/api/*/menu/permissions/roles/*/elements/*` | `SUPER_ADMIN`, `TENANT_ADMIN` |

---

### DENY explícitos (prioridad 500)

| Rol | Método | Patrón almacenado | Motivo |
|---|---|---|---|
| `EDITOR` | `POST` | `/api/*/users/*/suspend` | EDITOR no puede suspender usuarios |
| `EDITOR` | `POST` | `/api/*/users/*/activate` | EDITOR no puede reactivar usuarios |
| `EDITOR` | `DELETE` | `/api/*/users/*` | EDITOR no puede eliminar usuarios |
| `VIEWER` | `POST` | `/api/**` | VIEWER es 100% solo lectura (cubre cualquier versión) |
| `VIEWER` | `PUT` | `/api/**` | VIEWER es 100% solo lectura |
| `VIEWER` | `PATCH` | `/api/**` | VIEWER es 100% solo lectura |
| `VIEWER` | `DELETE` | `/api/**` | VIEWER es 100% solo lectura |

---

## 6. Revisión de los scripts de BD existentes

### `nexcore-infra/database/schema-nexcore.sql`

**Qué hace:** Define toda la estructura de la base de datos desde cero.
Incluye schemas, tipos ENUM, tablas, índices, RLS, triggers y vistas.

**Cuándo ejecutar:** Solo una vez, en un entorno limpio. Contiene `DROP SCHEMA IF EXISTS CASCADE`
al inicio, así que **borra todo** si ya existe. No usar en producción sin backup previo.

**Estructura de bloques:**
```
Bloque 0 — Extensiones (pgcrypto, pg_trgm)
Bloque 1 — Schemas (nxc_tenant, nxc_auth, nxc_menu, nxc_preference, nxc_config)
Bloque 2 — ENUMs (tenant_status, tenant_plan, user_status, access_level, menu_item_type)
Bloque 3 — Tablas (tenants, users, roles, user_roles, sessions, otp_codes, etc.)
Bloque 4 — RLS (políticas de Row-Level Security por tabla)
Bloque 5 — Triggers (updated_at, crear roles default al crear tenant, etc.)
Bloque 6 — Vistas (v_user_login_profile, v_menu_effective_access)
Bloque 7 — Seed básico (usuarios de prueba para tenant demo)
```

**Tablas de permisos de UI que ya existen:**
- `nxc_menu.components` — módulos/páginas de la app
- `nxc_menu.component_elements` — botones, tabs, secciones dentro de un componente
- `nxc_menu.component_permissions` — acceso de un ROL sobre un COMPONENTE
- `nxc_menu.element_permissions` — acceso de un ROL sobre un ELEMENTO específico
- `nxc_menu.user_element_overrides` — override por USUARIO individual

---

### `nexcore-infra/database/01-migrate-base.sql`

**Qué hace:** Script de seed completo de datos iniciales. Se ejecuta después del schema.

**Bloques:**
```
Bloque 1 — Tenant system (slug='system') + usuario super.admin + rol SUPER_ADMIN
Bloque 2 — Tenant demo  (slug='demo')   + usuarios admin.demo, editor.demo, test.admin, test.editor
Bloque 3 — Feature flags globales de la plataforma
Bloque 4 — Configuración base del tenant demo (email, ui.items_per_page, etc.)
Bloque 5 — Componentes, elementos, árbol de menú y permisos por rol para ambos tenants
```

**UUIDs fijos importantes** (usados en Postman):
```
Tenant system   : 00000000-0000-0000-0000-000000000001
Tenant demo     : 00000000-0000-0000-0000-000000000002
super.admin     : 00000000-0000-0000-0001-000000000001
admin.demo      : 00000000-0000-0000-0001-000000000002
test.admin      : 00000000-0000-0000-0001-000000000004
test.editor     : 00000000-0000-0000-0001-000000000005
```

**Contraseña de todos los usuarios seed:** `NexCore@2026!`

---

### `scripts-roles-menu-permisos/change-role-permission-menu.sql`

**Qué hace:** Script operacional para cambiar el permiso de un ROL sobre un ítem de menú.
No es un script de seed — es para operaciones de mantenimiento en entornos vivos.

**Parámetros a editar antes de ejecutar:**
```sql
v_tenant_id    UUID   := '00000000-0000-0000-0000-000000000002';  -- tenant objetivo
v_role_name    TEXT   := 'TENANT_ADMIN';                          -- nombre del rol
v_menu_name    TEXT   := 'Monitoring';                            -- nombre del menu item
v_menu_location TEXT  := 'sidebar';                               -- sidebar | profile
v_access       nxc_menu.access_level := 'EXECUTE';                -- EXECUTE | VIEW | HIDDEN
v_update_menu_default_access BOOLEAN := FALSE;                    -- TRUE = también cambia default
```

**Flujo interno del script:**
1. Valida que el tenant existe.
2. Busca el rol por nombre dentro del tenant.
3. Resuelve el menu item por nombre + location (+ parent opcional).
4. Lee el `component_id` asociado al menu item.
5. Hace UPSERT en `component_permissions`.
6. Opcionalmente actualiza `default_access` en el menu item.

**Cuándo usar:** Cuando se quiere cambiar un permiso de UI sin pasar por la API REST.

---

### `scripts-roles-menu-permisos/create-item-menu.sql`, `delete-item-menu.sql`, `update-item-menu.sql`

Scripts de CRUD manual para `menu_items`. Útiles para agregar, renombrar o eliminar
ítems del menú sin tocar el código de la app.

---

### `scripts-roles-menu-permisos/query-menu-items-by-tenant-role.sql`

Script de consulta para visualizar el árbol de menú con los permisos efectivos
por tenant y por rol. Útil para debugging de permisos.

---

### `scripts-roles-menu-permisos/delete-component.sql`

Elimina un componente y en cascada sus elementos, permisos y menu items asociados.
Usar con precaución: los permisos se pierden.

---

### `nexcore-infra/database/tenants/`

Cuatro scripts de ciclo de vida de tenants de prueba:
```
01-crea-tenants-test.sql     → crea tenant y usuarios de prueba adicionales
02-elimina-tenants-test.sql  → limpia esos datos
03-seed-users-invitations.sql → crea invitaciones de prueba
04-clean-users-invitations.sql → limpia invitaciones
```

---

## 7. Revisión de la colección Postman

**Archivo:** `nexcore-infra/postman/nexcore-collection.json`

### Variables de entorno (Collection Variables)

| Variable | Valor por defecto | Para qué |
|---|---|---|
| `base_url` | `http://localhost:8080` | Base URL del nexcore-core |
| `auth_base_url` | `http://localhost:8081` | Base URL del auth-service |
| `tenant_system_id` | `00000000-0000-0000-0000-000000000001` | Tenant system (SUPER_ADMIN) |
| `tenant_demo_id` | `00000000-0000-0000-0000-000000000002` | Tenant demo |
| `tenant_id` | `00000000-0000-0000-0000-000000000001` | El tenant "activo" en los headers |
| `actor_id` | `00000000-0000-0000-0001-000000000001` | super.admin (tenant system) |
| `actor_demo_id` | `00000000-0000-0000-0001-000000000002` | admin.demo (tenant demo) |
| `challenge_token` | *(vacío)* | Se llena automáticamente en Login Paso 1 |
| `access_token` | *(vacío)* | Se llena automáticamente en Login Paso 2 |
| `refresh_token` | *(vacío)* | Se llena automáticamente en Login Paso 2 |
| `component_id` | *(vacío)* | Completar con UUID real de BD |
| `role_id` | `00000000-0000-0000-0000-000000000010` | UUID del TENANT_ADMIN del tenant demo |
| `element_id` | *(vacío)* | Completar con UUID real de BD |

### Carpetas de la colección

**Tenants** — 6 requests
Gestión de tenants. Todos los requests requieren tener el servicio `nexcore-core`
corriendo en `http://localhost:8080`. No requieren headers de auth (fase MVP).

**Usuarios** — 9 requests
Gestión de usuarios dentro de un tenant. Todos usan el header `X-Tenant-Id`.
Algunos usan `X-Actor-Id` y `X-Is-Tenant-Admin`.

**Invitaciones** — 4 requests
Flujo de invitación: invite → listar → revocar → aceptar (público).

**Roles** — 5 requests
CRUD de roles dentro del tenant. Requiere `X-Tenant-Id`.

**Menu — Perfil de UI** — 4 requests
- 2 requests que prueban el perfil exitoso (super.admin y admin.demo).
- 1 request que prueba 404 (usuario inexistente).
- 1 request que prueba 400 (header faltante).

**Componentes (Permisos)** — 3 requests
Consulta de componentes y elementos de UI. Todos requieren `X-Is-Tenant-Admin: true`.

**Permisos por Rol** — 4 requests
- GET matriz de permisos del rol.
- PUT asignar permiso a un componente (upsert).
- PUT batch de componentes.
- PUT asignar permiso a un elemento.

**Autenticación (Auth Service)** — 8 requests
Flujo completo de login 2FA, refresh, logout, y reset de contraseña.

---

## 8. Guía paso a paso — Ejecución manual completa

### Paso 1: Preparar la base de datos

```bash
# Conectarse a PostgreSQL
psql -h localhost -U postgres -d nexcore_db

# Dentro de psql, ejecutar en orden:
\i /ruta/al/proyecto/nexcore-infra/database/schema-nexcore.sql
\i /ruta/al/proyecto/nexcore-infra/database/01-migrate-base.sql
\i /ruta/al/proyecto/nexcore-infra/database/scripts-roles-menu-permisos/06-create-role-api-policies.sql
\i /ruta/al/proyecto/nexcore-infra/database/scripts-roles-menu-permisos/07-seed-role-api-policies.sql
```

Con DBeaver: File → Open Script → seleccionar cada archivo → ejecutar con F5.

### Paso 2: Verificar que los datos quedaron bien

```sql
-- Contar políticas por rol
SELECT role_name, effect, COUNT(*) AS politicas
FROM nxc_menu.role_api_policies
GROUP BY role_name, effect
ORDER BY role_name;

-- Ver todas las políticas del TENANT_ADMIN
SELECT http_method, path_pattern, effect, priority
FROM nxc_menu.role_api_policies
WHERE role_name = 'TENANT_ADMIN' AND service = 'core'
ORDER BY priority DESC, path_pattern;
```

### Paso 3: Iniciar los servicios backend

```bash
# Terminal 1 — nexcore-core
cd nexcore-core
./gradlew bootRun

# Terminal 2 — nexcore-auth-service
cd nexcore-auth-service
./gradlew bootRun
```

### Paso 4: Importar la colección Postman

1. Abrir Postman.
2. Click en **Import** (esquina superior izquierda).
3. Seleccionar `nexcore-infra/postman/nexcore-collection.json`.
4. La colección aparece como "Nexcore - Platform API".

### Paso 5: Flujo de autenticación (para endpoints que requieren JWT)

```
5.1 — Login Paso 1 (obtener OTP)
   Carpeta: Autenticación → "Login - Paso 1 (Enviar OTP)"
   Body:
     {
       "tenantId": "00000000-0000-0000-0000-000000000001",
       "username": "super.admin",
       "password": "NexCore@2026!"
     }
   El script de Postman guarda automáticamente {{challenge_token}}.

5.2 — Login Paso 2 (verificar OTP)
   Carpeta: Autenticación → "Login - Paso 2 (Verificar OTP)"
   Body:
     {
       "challengeToken": "{{challenge_token}}",
       "code": "111111"     ← OTP fijo de desarrollo
     }
   El script guarda {{access_token}} y {{refresh_token}}.

5.3 — Ahora puedes usar {{access_token}} en los headers Authorization.
```

### Paso 6: Probar los módulos principales

#### Tenants (como SUPER_ADMIN)

```
GET {{base_url}}/api/v1/tenants?page=0&size=20
Headers: (ninguno especial en fase MVP)
→ Esperar: lista de 2 tenants (system y demo)

POST {{base_url}}/api/v1/tenants
Body: { "slug": "acme", "name": "ACME Corp", "plan": "STARTER", ... }
→ Esperar: 201 Created con el nuevo tenant

POST {{base_url}}/api/v1/tenants/{id}/suspend
→ Esperar: 204 No Content
```

#### Usuarios (como TENANT_ADMIN del tenant demo)

```
Cambiar en las variables de colección:
  tenant_id = 00000000-0000-0000-0000-000000000002  (tenant demo)
  actor_id  = 00000000-0000-0000-0001-000000000002  (admin.demo)

GET {{base_url}}/api/v1/users?page=0&size=20
Headers: X-Tenant-Id: {{tenant_id}}
→ Esperar: lista de usuarios del tenant demo

POST {{base_url}}/api/v1/users/invite
Headers: X-Tenant-Id: {{tenant_id}}, X-Actor-Id: {{actor_id}}
Body: { "email": "nuevo@empresa.com", "roleIds": [] }
→ Esperar: 201 Created con la invitación
```

#### Permisos por rol (como TENANT_ADMIN)

```
GET {{base_url}}/api/v1/menu/permissions/roles/{{role_id}}
Headers: X-Tenant-Id: {{tenant_id}}, X-Is-Tenant-Admin: true
→ Esperar: matriz completa con componentes y sus access levels

PUT {{base_url}}/api/v1/menu/permissions/roles/{{role_id}}/components/{{component_id}}
Headers: X-Tenant-Id: {{tenant_id}}, X-Actor-Id: {{actor_id}}, X-Is-Tenant-Admin: true
Body: { "access": "EXECUTE" }
→ Esperar: { componentId, access: "execute", ... }
```

### Paso 7: Cambiar un permiso manualmente en BD (sin API)

Usar el script `change-role-permission-menu.sql`:

```sql
-- Editar los parámetros al inicio del script:
v_tenant_id   := '00000000-0000-0000-0000-000000000002';
v_role_name   := 'EDITOR';
v_menu_name   := 'Monitoring';
v_menu_location := 'sidebar';
v_access      := 'HIDDEN'::nxc_menu.access_level;

-- Ejecutar el script completo.
-- Salida esperada:
-- NOTICE: OK: role EDITOR en tenant ... ahora tiene HIDDEN sobre menu item Monitoring (sidebar).
```

### Paso 8: Agregar una nueva política de API (cuando se agrega un endpoint nuevo)

Cuando el equipo de backend agrega, por ejemplo, `GET /api/v1/audit/logs` (o `v2`):

```sql
-- Usar /api/* para que la política cubra v1, v2 y cualquier versión futura.
INSERT INTO nxc_menu.role_api_policies
    (role_name, http_method, path_pattern, effect, service, priority, description)
VALUES
    ('SUPER_ADMIN',  'GET', '/api/*/audit/logs', 'ALLOW', 'core', 100,
     'Listar logs de auditoría. Solo SUPER_ADMIN.'),
    ('TENANT_ADMIN', 'GET', '/api/*/audit/logs', 'ALLOW', 'core', 100,
     'Listar logs de auditoría del propio tenant.');

-- Después invalidar el caché del interceptor (si está implementado):
-- El interceptor relee la BD cada 2-5 minutos por TTL de caché.
-- Para invalidación inmediata: reiniciar nexcore-core.
```

---

## 9. Próximos pasos (implementación en Spring Boot)

Una vez los datos están en BD, la implementación en `nexcore-core` requiere:

1. **`RoleApiPolicyRepository`** (en `infrastructure/persistence/jpa/`):
   ```java
   List<RoleApiPolicyEntity> findByServiceAndRoleNameIn(String service, List<String> roleNames);
   ```

2. **`RoleApiPolicyService`** (en `domain/service/`):
   - Método `isAllowed(String method, String path, List<String> roleNames)`.
   - Cache Caffeine con TTL 2 min, key = `service + method + path + roleNames`.

3. **`RoleApiPolicyInterceptor`** (en `infrastructure/config/`):
   - Implementa `HandlerInterceptor.preHandle()`.
   - Lee `X-Actor-Id` + `X-Tenant-Id` del request.
   - Consulta roles del usuario en BD.
   - Llama a `RoleApiPolicyService.isAllowed()`.
   - Retorna `false` + `response.setStatus(403)` si DENY.

4. **`WebMvcConfig`**: registrar el interceptor con `addInterceptors()`.
   Excluir rutas públicas: `/api/v1/users/invitations/accept`, `/actuator/health`, etc.

Ver el skill `backend-module.md` para los patrones de implementación hexagonal.

---

## 10. Archivos del spec

| Archivo | Propósito |
|---|---|
| `spec-role-api-policies.md` | Este documento |
| `06-create-role-api-policies.sql` | DDL de la tabla (ejecutar una vez) |
| `07-seed-role-api-policies.sql` | Datos iniciales de políticas (ejecutar después del DDL) |
| `nexcore-infra/postman/nexcore-collection.json` | Colección Postman completa |
| `nexcore-infra/database/schema-nexcore.sql` | Schema completo de la BD |
| `nexcore-infra/database/01-migrate-base.sql` | Seed de datos base (tenants, usuarios, permisos de UI) |
