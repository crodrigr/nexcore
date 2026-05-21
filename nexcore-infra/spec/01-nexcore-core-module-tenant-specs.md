# NexCore — Especificaciones y Criterios de Aceptación
## Módulo: `module-tenant`
**Versión:** 1.1  
**Schema DB:** `nxc_tenant`  
**Paquete base:** `com.nexore.core.module.tenant`  
**Ubicación:** `nexcore-core/src/main/java/com/nexore/core/module/tenant/`  
**Fecha:** 2026-05

---

## 1. Contexto y propósito

El módulo `module-tenant` es el núcleo de identidad de NexCore. Gestiona las tres entidades raíz sobre las que cualquier aplicación multi-tenant se construye: **tenants** (organizaciones o empresas cliente), **usuarios** (miembros de cada tenant) y **roles** (perfiles de acceso dentro de cada tenant).

Aplica el **Modelo B de identidad local**: un usuario pertenece a exactamente un tenant. No existe un usuario global. El aislamiento entre tenants se garantiza a dos niveles: la capa de aplicación valida `tenant_id` en cada operación, y PostgreSQL aplica Row-Level Security (RLS) como segunda línea de defensa.

Existe un tenant especial (`slug = 'system'`) cuyos usuarios con rol `SUPER_ADMIN` administran la instancia completa de NexCore y tienen bypass de RLS.

---

## 2. Entidades del dominio

### 2.1 Tenant

Representa una organización o empresa que usa la aplicación. Es la raíz de todo el aislamiento de datos.

| Campo | Tipo | Descripción |
|---|---|---|
| `id` | UUID | PK generada automáticamente |
| `slug` | VARCHAR(100) | Identificador URL-safe e inmutable. Usado en subdominios y JWT |
| `name` | VARCHAR(200) | Nombre comercial de la empresa |
| `legal_name` | VARCHAR(300) | Razón social (opcional) |
| `tax_id` | VARCHAR(50) | NIT / RUT / RFC (opcional) |
| `plan` | ENUM | `FREE \| STARTER \| PROFESSIONAL \| ENTERPRISE` |
| `mode` | ENUM | `SAAS_SHARED \| SAAS_DEDICATED \| ON_PREMISE` |
| `status` | ENUM | `TRIAL \| ACTIVE \| SUSPENDED \| CANCELLED` |
| `logo_url` | VARCHAR(500) | URL del logo del tenant |
| `primary_color` | VARCHAR(7) | Color principal en formato `#RRGGBB` |
| `custom_domain` | VARCHAR(255) | Dominio propio: `portal.acme.com` |
| `timezone` | VARCHAR(50) | Zona horaria del tenant (default: `UTC`) |
| `locale` | VARCHAR(10) | Idioma/región (default: `es-CO`) |
| `date_format` | VARCHAR(30) | Formato de fecha (default: `DD/MM/YYYY`) |
| `currency` | VARCHAR(3) | Moneda (default: `COP`) |
| `mfa_required` | BOOLEAN | Si todos los usuarios del tenant deben usar MFA |
| `session_timeout_minutes` | INTEGER | Tiempo de inactividad antes de cerrar sesión |
| `max_login_attempts` | INTEGER | Intentos fallidos antes de bloquear usuario |
| `password_min_length` | INTEGER | Longitud mínima de contraseña |
| `password_requires_upper` | BOOLEAN | Exige al menos una mayúscula |
| `password_requires_special` | BOOLEAN | Exige al menos un carácter especial |
| `password_expiry_days` | INTEGER | Días antes de que expire la contraseña. NULL = nunca |
| `max_users` | INTEGER | Límite de usuarios del plan. NULL = ilimitado |
| `audit_retention_days` | INTEGER | Días de retención de auditoría (default: 90) |
| `trial_ends_at` | TIMESTAMPTZ | Fin del período de prueba |
| `subscription_ends_at` | TIMESTAMPTZ | Fin de la suscripción activa |
| `created_at` | TIMESTAMPTZ | Fecha de creación |
| `updated_at` | TIMESTAMPTZ | Última modificación (trigger automático) |
| `deleted_at` | TIMESTAMPTZ | Soft delete. NULL = activo |
| `version` | INTEGER | Control de concurrencia optimista |

**Invariantes de negocio:**
- `slug` es inmutable una vez creado.
- `slug` es único entre tenants activos (índice parcial `WHERE deleted_at IS NULL`).
- `custom_domain` es único globalmente entre tenants activos.
- Al crear un tenant se generan automáticamente los roles base: `TENANT_ADMIN`, `EDITOR`, `VIEWER` (trigger `trg_create_default_roles`).
- El tenant `slug = 'system'` es el tenant de la plataforma. No puede eliminarse ni suspenderse.

---

### 2.2 User

Representa un empleado o colaborador de un tenant. Pertenece a exactamente un tenant.

| Campo | Tipo | Descripción |
|---|---|---|
| `id` | UUID | PK generada automáticamente |
| `tenant_id` | UUID | FK a `tenants`. No cambia nunca |
| `username` | VARCHAR(100) | Único dentro del tenant |
| `email` | VARCHAR(200) | Único dentro del tenant |
| `password_hash` | VARCHAR(255) | Hash BCrypt de la contraseña |
| `full_name` | VARCHAR(200) | Nombre completo |
| `phone` | VARCHAR(30) | Teléfono de contacto |
| `photo_url` | VARCHAR(500) | URL de la foto de perfil |
| `observaciones` | VARCHAR(3000) | Notas internas |
| `status` | ENUM | `PENDING_ACTIVATION \| ACTIVE \| SUSPENDED \| BLOCKED \| DELETED` |
| `is_tenant_admin` | BOOLEAN | Si puede gestionar usuarios y roles del propio tenant |
| `email_verified` | BOOLEAN | Si el email fue verificado |
| `email_verified_at` | TIMESTAMPTZ | Momento de la verificación |
| `totp_secret` | VARCHAR(255) | Secret TOTP cifrado a nivel de aplicación |
| `totp_enabled` | BOOLEAN | Si el usuario activó autenticación TOTP |
| `totp_backup_codes` | JSONB | Códigos de recuperación (hashed) |
| `temporal_code` | VARCHAR(50) | Código 2FA de un solo uso (email/SMS) |
| `temporal_code_expires_at` | TIMESTAMPTZ | Expiración del código temporal |
| `invited_by` | UUID | FK al usuario que realizó la invitación |
| `invited_at` | TIMESTAMPTZ | Momento de la invitación |
| `activated_at` | TIMESTAMPTZ | Momento en que aceptó la invitación |
| `last_login_at` | TIMESTAMPTZ | Último inicio de sesión exitoso |
| `last_login_ip` | VARCHAR(45) | IP del último login |
| `created_at` | TIMESTAMPTZ | Fecha de creación |
| `updated_at` | TIMESTAMPTZ | Última modificación (trigger automático) |
| `created_by` | UUID | FK al usuario que lo creó |
| `updated_by` | UUID | FK al último usuario que lo modificó |
| `deleted_at` | TIMESTAMPTZ | Soft delete |
| `version` | INTEGER | Control de concurrencia optimista |

**Invariantes de negocio:**
- `email` y `username` son únicos dentro del mismo `tenant_id`, no globalmente.
- `tenant_id` es inmutable una vez creado.
- El `totp_secret` nunca se almacena en texto plano. La capa de aplicación lo cifra antes de persistir.
- Al crear un usuario se asigna automáticamente el rol marcado como `is_default = TRUE` del tenant (trigger `trg_assign_default_role`).
- Un usuario con `status = DELETED` no puede autenticarse. El campo `deleted_at` se puebla pero el registro no se elimina físicamente.
- El campo `is_tenant_admin` no es un rol — es un flag de privilegio dentro del propio tenant. No da acceso a otros tenants.

---

### 2.3 Role

Perfil de acceso definido dentro de un tenant. Determina qué puede ver y ejecutar un usuario en la interfaz.

| Campo | Tipo | Descripción |
|---|---|---|
| `id` | UUID | PK generada automáticamente |
| `tenant_id` | UUID | FK a `tenants` |
| `name` | VARCHAR(100) | Nombre del rol. Único dentro del tenant |
| `description` | VARCHAR(500) | Descripción del propósito del rol |
| `is_system_role` | BOOLEAN | Si es un rol base no eliminable del sistema |
| `is_default` | BOOLEAN | Si se asigna automáticamente a nuevos usuarios |
| `created_at` | TIMESTAMPTZ | Fecha de creación |
| `updated_at` | TIMESTAMPTZ | Última modificación |
| `created_by` | UUID | FK al usuario que lo creó |
| `updated_by` | UUID | FK al último modificador |
| `deleted_at` | TIMESTAMPTZ | Soft delete |
| `version` | INTEGER | Control de concurrencia optimista |

**Invariantes de negocio:**
- Los roles `TENANT_ADMIN`, `EDITOR` y `VIEWER` son `is_system_role = TRUE`: no pueden eliminarse ni renombrarse.
- Solo puede existir un rol con `is_default = TRUE` por tenant en un momento dado. Cambiar el default desactiva el anterior.
- Un rol no puede eliminarse si tiene usuarios asignados activos.

---

### 2.4 UserRole

Asignación de un rol a un usuario dentro del mismo tenant.

| Campo | Tipo | Descripción |
|---|---|---|
| `id` | UUID | PK |
| `tenant_id` | UUID | FK a `tenants` |
| `user_id` | UUID | FK a `users` |
| `role_id` | UUID | FK a `roles` |
| `assigned_at` | TIMESTAMPTZ | Momento de la asignación |
| `assigned_by` | UUID | FK al usuario que realizó la asignación |
| `expires_at` | TIMESTAMPTZ | Expiración del rol. NULL = permanente |

**Invariantes de negocio:**
- `user_id` y `role_id` deben pertenecer al mismo `tenant_id` (validado por trigger `trg_validate_user_role_tenant`).
- La combinación `(tenant_id, user_id, role_id)` es única.
- Un usuario puede tener múltiples roles simultáneamente.
- Los roles con `expires_at` en el pasado se tratan como no asignados. Un job nocturno los revoca formalmente.

---

### 2.5 UserInvitation

Token de invitación enviado por email para incorporar nuevos usuarios.

| Campo | Tipo | Descripción |
|---|---|---|
| `id` | UUID | PK |
| `tenant_id` | UUID | FK a `tenants` |
| `email` | VARCHAR(200) | Email del invitado |
| `token_hash` | VARCHAR(255) | SHA-256 del token enviado por email |
| `role_ids` | UUID[] | Roles a asignar al aceptar |
| `invited_by` | UUID | FK al usuario que invitó |
| `invited_at` | TIMESTAMPTZ | Momento de la invitación |
| `expires_at` | TIMESTAMPTZ | Expiración del token |
| `accepted_at` | TIMESTAMPTZ | Momento de aceptación. NULL = pendiente |
| `user_id` | UUID | FK al usuario creado al aceptar |
| `is_revoked` | BOOLEAN | Si fue revocada manualmente |

---

## 3. Casos de uso y especificaciones funcionales

---

### UC-001 — Crear tenant

**Actor:** SUPER_ADMIN (usuario del tenant `system`)  
**Precondición:** El actor está autenticado con rol `SUPER_ADMIN`.

**Flujo principal:**
1. El actor envía los datos del nuevo tenant: `slug`, `name`, `plan`, `mode` (obligatorios); campos opcionales de localización y seguridad.
2. El sistema valida que `slug` no exista entre tenants activos.
3. El sistema valida que `custom_domain`, si se provee, no esté en uso.
4. El sistema persiste el tenant con `status = TRIAL`.
5. El trigger `trg_create_default_roles` crea automáticamente los roles `TENANT_ADMIN`, `EDITOR` y `VIEWER`.
6. El sistema emite el evento de dominio `TenantCreatedEvent` al bus de mensajería.
7. El sistema retorna el tenant creado con HTTP 201 y el header `Location`.

**Flujos alternativos:**
- `slug` ya existe → HTTP 409 con código `NXC-TEN-0001`.
- `custom_domain` ya está en uso → HTTP 409 con código `NXC-TEN-0002`.
- `slug` contiene caracteres inválidos (no URL-safe) → HTTP 422 con código `NXC-TEN-0010`.

---

### UC-002 — Consultar tenant

**Actor:** SUPER_ADMIN / TENANT_ADMIN del propio tenant  
**Precondición:** El actor está autenticado.

**Flujo principal:**
1. El actor solicita `GET /api/v1/tenants/{id}`.
2. El sistema aplica RLS: un TENANT_ADMIN solo puede ver su propio tenant; el SUPER_ADMIN puede ver cualquiera.
3. El sistema retorna el tenant sin campos sensibles (`password_*`).

**Flujos alternativos:**
- El tenant no existe o está soft-deleted → HTTP 404 con código `NXC-TEN-0003`.
- El actor intenta ver un tenant ajeno sin ser SUPER_ADMIN → HTTP 403 con código `NXC-TEN-0004`.

---

### UC-003 — Actualizar tenant

**Actor:** SUPER_ADMIN / TENANT_ADMIN  
**Restricciones:** El TENANT_ADMIN solo puede actualizar campos de localización, seguridad y apariencia de su propio tenant. No puede cambiar `plan`, `mode`, `status`, ni `slug`.

**Flujo principal:**
1. El actor envía `PATCH /api/v1/tenants/{id}` con los campos a modificar.
2. El sistema valida los permisos según el rol del actor.
3. Si el actor es TENANT_ADMIN, el sistema rechaza cambios en campos restringidos.
4. Si se modifica `custom_domain`, el sistema valida que no esté en uso.
5. El sistema incrementa `version` (optimistic locking) y persiste los cambios.
6. El sistema emite `TenantUpdatedEvent`.

**Flujos alternativos:**
- Conflicto de versión (edición concurrente) → HTTP 409 con código `NXC-TEN-0005`.
- TENANT_ADMIN intenta cambiar `plan` → HTTP 403 con código `NXC-TEN-0006`.

---

### UC-004 — Suspender / reactivar tenant

**Actor:** SUPER_ADMIN  
**Flujo principal:**
1. El actor envía `POST /api/v1/tenants/{id}/suspend` con motivo opcional.
2. El sistema cambia `status` a `SUSPENDED`.
3. El sistema revoca todas las sesiones activas del tenant (tabla `nxc_auth.sessions`).
4. El sistema emite `TenantSuspendedEvent`.
5. Todos los intentos de login de usuarios de ese tenant fallan con error `NXC-AUTH-0020`.

**Reactivación:** `POST /api/v1/tenants/{id}/activate` → cambia `status` a `ACTIVE` y emite `TenantActivatedEvent`.

---

### UC-005 — Invitar usuario

**Actor:** TENANT_ADMIN o usuario con `is_tenant_admin = TRUE`  
**Precondición:** El tenant tiene cuota disponible (`max_users` no alcanzado).

**Flujo principal:**
1. El actor envía `POST /api/v1/users/invite` con `email` y `role_ids`.
2. El sistema valida que el email no pertenezca a un usuario activo del tenant.
3. El sistema valida que todos los `role_ids` pertenezcan al tenant.
4. El sistema valida que no exista una invitación pendiente para ese email en el tenant.
5. El sistema genera un token criptográfico (UUID v4), lo hashea con SHA-256 y persiste la invitación con `expires_at = NOW() + 72h`.
6. El sistema envía el email de invitación con el template `invitation.html` y el token en texto plano como query param.
7. El sistema retorna HTTP 201 con los datos de la invitación (sin el token).

**Flujos alternativos:**
- Email ya tiene usuario activo en el tenant → HTTP 409 con código `NXC-USR-0001`.
- Cuota de usuarios alcanzada → HTTP 422 con código `NXC-USR-0010`.
- Invitación pendiente para ese email → HTTP 409 con código `NXC-USR-0002`. (Ofrece reenviar.)
- Algún `role_id` no pertenece al tenant → HTTP 422 con código `NXC-USR-0011`.

---

### UC-006 — Aceptar invitación

**Actor:** El invitado (no autenticado)  
**Precondición:** El token de invitación existe, no está expirado y no fue revocado.

**Flujo principal:**
1. El invitado accede a la URL con el token.
2. El sistema busca la invitación por `SHA-256(token)`. Valida que `is_revoked = FALSE` y `expires_at > NOW()` y `accepted_at IS NULL`.
3. El invitado completa el formulario: `full_name`, `username`, `password`.
4. El sistema valida que `username` y `email` no existan en el tenant.
5. El sistema valida la contraseña contra las políticas del tenant.
6. El sistema crea el usuario con `status = ACTIVE`, `email_verified = TRUE`, `activated_at = NOW()`.
7. El sistema asigna los roles de la invitación vía `user_roles`.
8. El sistema marca la invitación como aceptada (`accepted_at = NOW()`, `user_id = nuevo_usuario_id`).
9. El sistema emite `UserCreatedEvent`.
10. El sistema retorna HTTP 201 con el perfil del usuario creado.

**Flujos alternativos:**
- Token inválido o expirado → HTTP 400 con código `NXC-USR-0020`.
- Token ya usado → HTTP 400 con código `NXC-USR-0021`.
- `username` ya existe en el tenant → HTTP 409 con código `NXC-USR-0003`.
- Contraseña no cumple políticas del tenant → HTTP 422 con código `NXC-USR-0030` con detalle de la regla incumplida.

---

### UC-007 — Crear usuario directamente (sin invitación)

**Actor:** TENANT_ADMIN  
**Precondición:** Cuota disponible.

**Flujo principal:**
1. El actor envía `POST /api/v1/users` con `email`, `username`, `full_name`, `role_ids`, `sendInvite`.
2. Si `sendInvite = TRUE`: el sistema ejecuta UC-005 internamente.
3. Si `sendInvite = FALSE`: el sistema crea el usuario con `status = PENDING_ACTIVATION` y genera una contraseña temporal que se envía por email.
4. El sistema emite `UserCreatedEvent`.
5. Retorna HTTP 201 con el perfil del usuario.

---

### UC-008 — Consultar usuario

**Actor:** TENANT_ADMIN / el propio usuario (para `GET /api/v1/users/me`)

**Flujo principal:**
1. El sistema aplica RLS: el usuario solo ve usuarios de su tenant.
2. Retorna el perfil sin `password_hash`, `totp_secret`, `totp_backup_codes`, `temporal_code`.

---

### UC-009 — Actualizar usuario

**Actor:** TENANT_ADMIN (cualquier usuario del tenant) / el propio usuario (solo su perfil)

**Restricciones por actor:**
- El propio usuario puede cambiar: `full_name`, `phone`, `photo_url`, `observaciones`.
- El TENANT_ADMIN puede cambiar adicionalmente: `status`, `is_tenant_admin`, y reasignar roles.
- Ningún usuario puede cambiar `email`, `username`, ni `tenant_id` una vez creado.

**Flujo principal:**
1. El actor envía `PATCH /api/v1/users/{id}` con los campos permitidos.
2. El sistema valida los permisos según el rol.
3. El sistema incrementa `version` y persiste los cambios con `updated_by`.
4. El sistema emite `UserUpdatedEvent`.

**Flujos alternativos:**
- Actor intenta cambiar `email` → HTTP 422 con código `NXC-USR-0040`.
- Conflicto de versión → HTTP 409 con código `NXC-USR-0041`.

---

### UC-010 — Suspender usuario

**Actor:** TENANT_ADMIN  
**Precondición:** El usuario existe y su `status` es `ACTIVE`.

**Flujo principal:**
1. El actor envía `POST /api/v1/users/{id}/suspend`.
2. El sistema cambia `status` a `SUSPENDED`.
3. El sistema revoca todas las sesiones activas del usuario en la tabla `nxc_auth.sessions`.
4. El sistema emite `UserSuspendedEvent`.

**Flujo alternativo:**
- El actor intenta suspenderse a sí mismo → HTTP 422 con código `NXC-USR-0050`.
- El actor intenta suspender al último `TENANT_ADMIN` activo → HTTP 422 con código `NXC-USR-0051`.

---

### UC-011 — Reactivar usuario

**Actor:** TENANT_ADMIN  
**Precondición:** El usuario tiene `status = SUSPENDED` o `status = BLOCKED`.

**Flujo principal:**
1. El actor envía `POST /api/v1/users/{id}/activate`.
2. El sistema cambia `status` a `ACTIVE`.
3. Si el usuario estaba `BLOCKED`, el sistema resetea el contador de intentos fallidos.
4. El sistema emite `UserActivatedEvent`.

---

### UC-012 — Eliminar usuario (soft delete)

**Actor:** TENANT_ADMIN  
**Precondición:** El usuario no es el último `TENANT_ADMIN` activo.

**Flujo principal:**
1. El actor envía `DELETE /api/v1/users/{id}`.
2. El sistema puebla `deleted_at = NOW()` y cambia `status = DELETED`.
3. El sistema revoca todas las sesiones activas.
4. El sistema retorna HTTP 204.

**Flujo alternativo:**
- Intento de eliminar al último TENANT_ADMIN → HTTP 422 con código `NXC-USR-0060`.
- Intento de eliminar al propio usuario → HTTP 422 con código `NXC-USR-0061`.

---

### UC-013 — Listar usuarios con paginación y filtros

**Actor:** TENANT_ADMIN / EDITOR / VIEWER (según permisos del componente)

**Query params soportados:**
- `page`, `size`, `sort`, `direction` — paginación estándar.
- `status` — filtro exacto por estado.
- `search` — búsqueda full-text sobre `email`, `username`, `full_name` (índice GIN `pg_trgm`).
- `roleId` — filtro por rol asignado.
- `isActive` — shortcut para `status=ACTIVE`.
- `fields` — sparse fieldsets para reducir payload.

**Flujo principal:**
1. El sistema aplica RLS automáticamente: solo usuarios del tenant activo.
2. El sistema aplica filtros y paginación.
3. Retorna HTTP 200 con el envelope paginado `PageResponse<UserResponse>`.

---

### UC-014 — Crear rol personalizado

**Actor:** TENANT_ADMIN

**Flujo principal:**
1. El actor envía `POST /api/v1/roles` con `name` y `description`.
2. El sistema valida que `name` no exista en el tenant.
3. El sistema persiste el rol con `is_system_role = FALSE`.
4. Retorna HTTP 201.

**Flujo alternativo:**
- Nombre duplicado en el tenant → HTTP 409 con código `NXC-ROL-0001`.
- Nombre igual a un rol de sistema (`TENANT_ADMIN`, `EDITOR`, `VIEWER`) → HTTP 422 con código `NXC-ROL-0002`.

---

### UC-015 — Actualizar rol

**Actor:** TENANT_ADMIN

**Restricciones:**
- Los roles con `is_system_role = TRUE` no pueden renombrarse ni eliminarse.
- Solo se pueden modificar `description` e `is_default` de roles de sistema.

**Flujo alternativo:**
- Intento de renombrar un rol de sistema → HTTP 422 con código `NXC-ROL-0010`.

---

### UC-016 — Eliminar rol

**Actor:** TENANT_ADMIN  
**Precondición:** El rol no es de sistema y no tiene usuarios activos asignados.

**Flujo principal:**
1. El actor envía `DELETE /api/v1/roles/{id}`.
2. El sistema verifica que no existan `user_roles` activos (sin `expires_at` expirado) para ese rol.
3. El sistema hace soft delete del rol.
4. Retorna HTTP 204.

**Flujos alternativos:**
- Rol de sistema → HTTP 422 con código `NXC-ROL-0020`.
- Rol con usuarios asignados → HTTP 422 con código `NXC-ROL-0021` con la cantidad de usuarios afectados.

---

### UC-017 — Asignar roles a usuario

**Actor:** TENANT_ADMIN

**Flujo principal:**
1. El actor envía `PUT /api/v1/users/{id}/roles` con el array completo de `roleIds` y opcionalmente `expiresAt` por rol.
2. El sistema reemplaza todas las asignaciones actuales por las nuevas.
3. El sistema valida que cada `role_id` pertenezca al tenant.
4. El sistema valida que la operación no deje al tenant sin ningún `TENANT_ADMIN` activo.
5. El sistema emite `UserRolesChangedEvent`.

**Flujos alternativos:**
- Algún `role_id` no pertenece al tenant → HTTP 422 con código `NXC-ROL-0030`.
- La operación eliminaría el último TENANT_ADMIN del tenant → HTTP 422 con código `NXC-ROL-0031`.

---

### UC-018 — Revocar invitación

**Actor:** TENANT_ADMIN

**Flujo principal:**
1. El actor envía `POST /api/v1/users/invitations/{id}/revoke`.
2. El sistema valida que la invitación esté pendiente (`accepted_at IS NULL`).
3. El sistema marca `is_revoked = TRUE`.
4. Retorna HTTP 204.

**Flujo alternativo:**
- La invitación ya fue aceptada → HTTP 422 con código `NXC-USR-0070`.

---

### UC-019 — Reenviar invitación

**Actor:** TENANT_ADMIN

**Flujo principal:**
1. El actor envía `POST /api/v1/users/invitations/{id}/resend`.
2. El sistema revoca el token anterior (`is_revoked = TRUE`).
3. El sistema crea una nueva invitación con un nuevo token y `expires_at` extendido 72h.
4. El sistema envía el nuevo email.
5. Retorna HTTP 200 con los datos de la nueva invitación.

---

### UC-020 — Consultar perfil propio

**Actor:** Cualquier usuario autenticado

**Flujo principal:**
1. El actor envía `GET /api/v1/users/me`.
2. El sistema extrae el `user_id` del JWT (no de query params — evita suplantación).
3. Retorna el perfil completo del usuario con sus roles actuales.

---

## 4. Estructura de DTOs

### TenantCreateRequest
```
slug            String  REQUERIDO  Patrón: ^[a-z0-9]+(-[a-z0-9]+)*$  Max: 100
name            String  REQUERIDO  Min: 2  Max: 200
legalName       String  OPCIONAL   Max: 300
taxId           String  OPCIONAL   Max: 50
plan            Enum    OPCIONAL   Default: FREE
mode            Enum    OPCIONAL   Default: SAAS_SHARED
timezone        String  OPCIONAL   Default: UTC  Validar contra ZoneId de Java
locale          String  OPCIONAL   Default: es-CO
```

### TenantResponse
```
id              UUID
slug            String
name            String
legalName       String
taxId           String
plan            Enum
mode            Enum
status          Enum
logoUrl         String
primaryColor    String
customDomain    String
timezone        String
locale          String
dateFormat      String
currency        String
mfaRequired     Boolean
sessionTimeoutMinutes  Integer
maxLoginAttempts       Integer
passwordMinLength      Integer
passwordRequiresUpper  Boolean
passwordRequiresSpecial Boolean
passwordExpiryDays     Integer
maxUsers        Integer
auditRetentionDays     Integer
trialEndsAt     String  ISO-8601
subscriptionEndsAt     String  ISO-8601
createdAt       String  ISO-8601
updatedAt       String  ISO-8601
```

### TenantUpdateRequest (PATCH — todos los campos opcionales)
```
name            String  OPCIONAL  Min: 2  Max: 200
legalName       String  OPCIONAL
taxId           String  OPCIONAL
logoUrl         String  OPCIONAL  URL válida
primaryColor    String  OPCIONAL  Patrón: ^#[0-9A-Fa-f]{6}$
customDomain    String  OPCIONAL  Hostname válido
timezone        String  OPCIONAL  ZoneId válido
locale          String  OPCIONAL
dateFormat      String  OPCIONAL
currency        String  OPCIONAL  Exactamente 3 caracteres
mfaRequired     Boolean OPCIONAL
sessionTimeoutMinutes  Integer  OPCIONAL  Min: 5  Max: 1440
maxLoginAttempts       Integer  OPCIONAL  Min: 3  Max: 20
passwordMinLength      Integer  OPCIONAL  Min: 6  Max: 72
passwordExpiryDays     Integer  OPCIONAL  Min: 30
```
**Solo SUPER_ADMIN puede además modificar:** `plan`, `mode`, `status`, `maxUsers`, `auditRetentionDays`, `trialEndsAt`, `subscriptionEndsAt`.

---

### UserCreateRequest
```
email           String  REQUERIDO  Formato email válido  Max: 200
username        String  REQUERIDO  Patrón: ^[a-zA-Z0-9._-]{3,100}$
fullName        String  OPCIONAL   Max: 200
phone           String  OPCIONAL   Max: 30
roleIds         UUID[]  OPCIONAL   Default: rol default del tenant
sendInvite      Boolean OPCIONAL   Default: true
```

### UserResponse
```
id              UUID
tenantId        UUID
username        String
email           String
fullName        String
phone           String
photoUrl        String
status          Enum
isTenantAdmin   Boolean
emailVerified   Boolean
totpEnabled     Boolean
invitedAt       String  ISO-8601
activatedAt     String  ISO-8601
lastLoginAt     String  ISO-8601
roles           RoleSummary[]   [{id, name, assignedAt, expiresAt}]
createdAt       String  ISO-8601
updatedAt       String  ISO-8601
_links          HATEOASLinks    {self, update, suspend/activate, roles}
```

### UserUpdateRequest (PATCH)
```
fullName        String  OPCIONAL  Max: 200
phone           String  OPCIONAL  Max: 30
photoUrl        String  OPCIONAL  URL válida
observaciones   String  OPCIONAL  Max: 3000
```
**TENANT_ADMIN puede además:**
```
status          Enum    OPCIONAL
isTenantAdmin   Boolean OPCIONAL
```

---

### RoleCreateRequest
```
name            String  REQUERIDO  Min: 2  Max: 100
description     String  OPCIONAL   Max: 500
isDefault       Boolean OPCIONAL   Default: false
```
> Este mismo DTO se reutiliza en `PATCH /api/v1/roles/{id}`. No existe un `RoleUpdateRequest` separado.

### RoleResponse
```
id              UUID
tenantId        UUID
name            String
description     String
isSystemRole    Boolean
isDefault       Boolean
userCount       Integer   Cantidad de usuarios activos con este rol
createdAt       String    ISO-8601
updatedAt       String    ISO-8601
```

### AssignRolesRequest
```
roles           RoleAssignment[]  REQUERIDO  Min: 1 elemento
  roleId        UUID    REQUERIDO
  expiresAt     String  OPCIONAL  ISO-8601. NULL = permanente
```
> `RoleAssignment` es un value object independiente (`application/dto/request/RoleAssignment.java`).

### UserInviteRequest
```
email           String  REQUERIDO
roleIds         UUID[]  REQUERIDO  Min: 1
```

### AcceptInvitationRequest
```
token           String  REQUERIDO
username        String  REQUERIDO  Patrón: ^[a-zA-Z0-9._-]{3,100}$
fullName        String  REQUERIDO  Min: 2  Max: 200
password        String  REQUERIDO  Validado contra políticas del tenant
```

---

## 5. Endpoints REST

| Método | Ruta | Descripción | Roles permitidos |
|---|---|---|---|
| `GET` | `/api/v1/tenants` | Listar tenants (paginado) | SUPER_ADMIN |
| `POST` | `/api/v1/tenants` | Crear tenant | SUPER_ADMIN |
| `GET` | `/api/v1/tenants/{id}` | Obtener tenant | SUPER_ADMIN, TENANT_ADMIN (propio) |
| `PATCH` | `/api/v1/tenants/{id}` | Actualizar tenant | SUPER_ADMIN, TENANT_ADMIN (parcial) |
| `POST` | `/api/v1/tenants/{id}/suspend` | Suspender tenant | SUPER_ADMIN |
| `POST` | `/api/v1/tenants/{id}/activate` | Activar tenant | SUPER_ADMIN |
| `GET` | `/api/v1/users` | Listar usuarios del tenant | TENANT_ADMIN, EDITOR, VIEWER |
| `POST` | `/api/v1/users` | Crear usuario | TENANT_ADMIN |
| `GET` | `/api/v1/users/me` | Perfil del usuario autenticado | Cualquier usuario |
| `GET` | `/api/v1/users/{id}` | Obtener usuario | TENANT_ADMIN |
| `PATCH` | `/api/v1/users/{id}` | Actualizar usuario | TENANT_ADMIN, propio usuario (campos limitados) |
| `POST` | `/api/v1/users/{id}/suspend` | Suspender usuario | TENANT_ADMIN |
| `POST` | `/api/v1/users/{id}/activate` | Activar usuario | TENANT_ADMIN |
| `DELETE` | `/api/v1/users/{id}` | Eliminar usuario (soft) | TENANT_ADMIN |
| `PUT` | `/api/v1/users/{id}/roles` | Reemplazar roles del usuario | TENANT_ADMIN |
| `POST` | `/api/v1/users/invite` | Invitar usuario por email | TENANT_ADMIN |
| `POST` | `/api/v1/users/invitations/accept` | Aceptar invitación | Anónimo (con token) |
| `GET` | `/api/v1/users/invitations` | Listar invitaciones del tenant | TENANT_ADMIN |
| `POST` | `/api/v1/users/invitations/{id}/revoke` | Revocar invitación | TENANT_ADMIN |
| `POST` | `/api/v1/users/invitations/{id}/resend` | Reenviar invitación | TENANT_ADMIN |
| `GET` | `/api/v1/roles` | Listar roles del tenant | TENANT_ADMIN |
| `POST` | `/api/v1/roles` | Crear rol | TENANT_ADMIN |
| `GET` | `/api/v1/roles/{id}` | Obtener rol | TENANT_ADMIN |
| `PATCH` | `/api/v1/roles/{id}` | Actualizar rol | TENANT_ADMIN |
| `DELETE` | `/api/v1/roles/{id}` | Eliminar rol | TENANT_ADMIN |

---

## 6. Eventos de dominio

Todos los eventos se publican al bus de mensajería (Kafka) en el topic `nexcore.tenant.events`.
El servicio de auditoría los consume de forma asíncrona y los persiste en MongoDB.
El servicio de notificaciones los consume para alertas en tiempo real.

| Evento | Payload mínimo | Trigger |
|---|---|---|
| `TenantCreatedEvent` | `tenantId, slug, name, plan, mode, actorId, occurredAt` | UC-001 |
| `TenantUpdatedEvent` | `tenantId, changedFields[], actorId, occurredAt` | UC-003 |
| `TenantSuspendedEvent` | `tenantId, reason, actorId, occurredAt` | UC-004 |
| `TenantActivatedEvent` | `tenantId, actorId, occurredAt` | UC-004 |
| `UserCreatedEvent` | `tenantId, userId, email, roleIds[], actorId, occurredAt` | UC-006, UC-007 |
| `UserUpdatedEvent` | `tenantId, userId, changedFields[], actorId, occurredAt` | UC-009 |
| `UserSuspendedEvent` | `tenantId, userId, actorId, occurredAt` | UC-010 |
| `UserActivatedEvent` | `tenantId, userId, actorId, occurredAt` | UC-011 |
| `UserDeletedEvent` | `tenantId, userId, actorId, occurredAt` | UC-012 |
| `UserRolesChangedEvent` | `tenantId, userId, addedRoles[], removedRoles[], actorId, occurredAt` | UC-017 |
| `UserInvitedEvent` | `tenantId, email, invitationId, actorId, occurredAt` | UC-005 |
| `UserInvitationAcceptedEvent` | `tenantId, userId, invitationId, occurredAt` | UC-006 |
| `RoleCreatedEvent` | `tenantId, roleId, name, actorId, occurredAt` | UC-014 |
| `RoleUpdatedEvent` | `tenantId, roleId, changedFields[], actorId, occurredAt` | UC-015 |
| `RoleDeletedEvent` | `tenantId, roleId, actorId, occurredAt` | UC-016 |

---

## 7. Catálogo de códigos de error del módulo

| Código | HTTP | Descripción |
|---|---|---|
| `NXC-TEN-0001` | 409 | Slug already exists in an active tenant |
| `NXC-TEN-0002` | 409 | Custom domain is already in use |
| `NXC-TEN-0003` | 404 | Tenant not found |
| `NXC-TEN-0004` | 403 | Access to this tenant is not allowed |
| `NXC-TEN-0005` | 409 | Version conflict while updating tenant |
| `NXC-TEN-0006` | 403 | TENANT_ADMIN is not allowed to change the plan |
| `NXC-TEN-0010` | 422 | Slug contains invalid characters |
| `NXC-USR-0001` | 409 | Email already exists in the tenant |
| `NXC-USR-0002` | 409 | Pending invitation already exists for this email |
| `NXC-USR-0003` | 409 | Username already exists in the tenant |
| `NXC-USR-0010` | 422 | User quota for the tenant's plan has been reached |
| `NXC-USR-0011` | 422 | One or more roles do not belong to this tenant |
| `NXC-USR-0020` | 400 | Invitation token is invalid or has expired |
| `NXC-USR-0021` | 400 | Invitation token has already been used |
| `NXC-USR-0030` | 422 | Password does not meet tenant policy requirements |
| `NXC-USR-0040` | 422 | Email address cannot be changed after user creation |
| `NXC-USR-0041` | 409 | Version conflict while updating user |
| `NXC-USR-0050` | 422 | A user cannot suspend themselves |
| `NXC-USR-0051` | 422 | Cannot suspend the last active TENANT_ADMIN |
| `NXC-USR-0060` | 422 | Cannot delete the last active TENANT_ADMIN |
| `NXC-USR-0061` | 422 | A user cannot delete themselves |
| `NXC-USR-0070` | 422 | Invitation has already been accepted |
| `NXC-ROL-0001` | 409 | Role name already exists in the tenant |
| `NXC-ROL-0002` | 422 | Role name is reserved for system roles |
| `NXC-ROL-0010` | 422 | System roles cannot be renamed |
| `NXC-ROL-0020` | 422 | System roles cannot be deleted |
| `NXC-ROL-0021` | 422 | Role has active users assigned and cannot be deleted |
| `NXC-ROL-0030` | 422 | One or more roleIds do not belong to this tenant |
| `NXC-ROL-0031` | 422 | Operation would leave the tenant with no active TENANT_ADMIN |
| `NXC-VALIDATION-0001` | 422 | Bean Validation failure; field detail included in message |
| `NXC-INTERNAL-0001` | 500 | Unexpected internal server error |

---

## 8. Criterios de aceptación

### CA-001 — Aislamiento multi-tenant
- Dado un usuario autenticado del tenant A, cuando consulta cualquier endpoint del módulo, entonces el sistema no devuelve ni acepta ningún dato del tenant B, garantizado tanto por la capa de aplicación como por RLS de PostgreSQL.
- Dado un intento de acceder a un recurso de otro tenant con un UUID válido de ese tenant, el sistema responde HTTP 404 (no 403) para no revelar la existencia del recurso.

### CA-002 — Creación de tenant
- Dado un SUPER_ADMIN, cuando crea un tenant con `slug = "acme-corp"`, entonces se crea el tenant con `status = TRIAL` y se generan automáticamente los roles `TENANT_ADMIN`, `EDITOR` y `VIEWER` para ese tenant.
- Dado un `slug` que ya existe en un tenant activo, cuando se intenta crear otro tenant con el mismo `slug`, entonces el sistema retorna HTTP 409 con código `NXC-TEN-0001`.
- Dado un `slug` de un tenant soft-deleted, cuando se intenta crear un tenant con ese mismo `slug`, entonces el sistema lo permite (el índice es parcial `WHERE deleted_at IS NULL`).

### CA-003 — Invitación y activación de usuario
- Dado un TENANT_ADMIN, cuando invita a `ana@acme.com` con rol `EDITOR`, entonces se genera un token único, se envía el email con el template `invitation.html`, y el token expira en exactamente 72 horas.
- Dado un token de invitación válido, cuando el invitado completa el formulario de activación, entonces se crea el usuario con `status = ACTIVE`, `email_verified = TRUE`, los roles de la invitación asignados, y la invitación queda con `accepted_at` poblado.
- Dado un token de invitación ya utilizado, cuando se intenta aceptar de nuevo, entonces el sistema retorna HTTP 400 con código `NXC-USR-0021`.
- Dado un token expirado, cuando se intenta aceptar, entonces el sistema retorna HTTP 400 con código `NXC-USR-0020`.

### CA-004 — Unicidad de email por tenant
- Dado que `ana@empresa.com` existe como usuario en el tenant A, cuando se intenta crear un usuario con el mismo email en el tenant A, entonces el sistema retorna HTTP 409 con código `NXC-USR-0001`.
- Dado que `ana@empresa.com` existe en el tenant A, cuando se crea un usuario con el mismo email en el tenant B, entonces el sistema lo permite sin conflicto (unicidad es por tenant).

### CA-005 — Políticas de contraseña por tenant
- Dado un tenant con `password_min_length = 10` y `password_requires_special = TRUE`, cuando un usuario intenta activar su cuenta con la contraseña `"Simple123"`, entonces el sistema retorna HTTP 422 con código `NXC-USR-0030` indicando qué regla no se cumple.
- Dado el mismo tenant, cuando el usuario ingresa `"Complex@123456"`, entonces el sistema acepta la contraseña.

### CA-006 — Protección del último TENANT_ADMIN
- Dado un tenant con exactamente un usuario con rol `TENANT_ADMIN`, cuando se intenta suspender ese usuario, entonces el sistema retorna HTTP 422 con código `NXC-USR-0051`.
- Dado un tenant con exactamente un usuario con rol `TENANT_ADMIN`, cuando se intenta asignar roles quitándole `TENANT_ADMIN`, entonces el sistema retorna HTTP 422 con código `NXC-ROL-0031`.
- Dado un tenant con dos usuarios con rol `TENANT_ADMIN`, cuando se suspende uno, entonces el sistema permite la operación porque queda uno activo.

### CA-007 — Roles de sistema
- Dado el rol `VIEWER` (is_system_role = TRUE), cuando un TENANT_ADMIN intenta eliminarlo, entonces el sistema retorna HTTP 422 con código `NXC-ROL-0020`.
- Dado el rol `EDITOR`, cuando un TENANT_ADMIN intenta renombrarlo a `"Colaborador"`, entonces el sistema retorna HTTP 422 con código `NXC-ROL-0010`.
- Dado el rol `EDITOR`, cuando un TENANT_ADMIN actualiza solo su `description`, entonces el sistema permite la operación.

### CA-008 — Rol default
- Dado un tenant con `VIEWER` como `is_default = TRUE`, cuando se crea un nuevo usuario, entonces el trigger `trg_assign_default_role` le asigna automáticamente el rol `VIEWER` sin intervención del creador.
- Dado un TENANT_ADMIN que marca un nuevo rol como `is_default = TRUE`, entonces el sistema automáticamente desmarca el rol anterior como default (solo puede haber uno).

### CA-009 — Suspensión de tenant
- Dado un SUPER_ADMIN que suspende el tenant A, cuando un usuario del tenant A intenta hacer login, entonces el servicio de autenticación retorna HTTP 401 con código `NXC-AUTH-0020`.
- Dado el mismo tenant suspendido, cuando el SUPER_ADMIN lo reactiva, entonces los usuarios del tenant pueden volver a autenticarse.
- La suspensión de un tenant revoca todas sus sesiones activas en `nxc_auth.sessions` en la misma transacción.

### CA-010 — Soft delete
- Dado un usuario eliminado (`deleted_at IS NOT NULL`), cuando se consulta `GET /api/v1/users/{id}`, entonces el sistema retorna HTTP 404.
- Dado un usuario eliminado, cuando se intenta crear un nuevo usuario con el mismo email en el mismo tenant, entonces el sistema lo permite (la unicidad es sobre registros activos `WHERE deleted_at IS NULL`).

### CA-011 — Concurrencia optimista
- Dado un usuario con `version = 3`, cuando dos TENANT_ADMIN editan el mismo usuario simultáneamente, entonces el primero en guardar tiene éxito y el segundo recibe HTTP 409 con código `NXC-USR-0041` indicando que el recurso fue modificado.

### CA-012 — Eventos de dominio
- Dado cualquier operación de escritura en el módulo (crear, actualizar, suspender, eliminar), entonces se publica el evento correspondiente en el topic Kafka `nexcore.tenant.events` dentro de la misma unidad lógica de trabajo (outbox pattern).
- Si el broker Kafka no está disponible, la operación de negocio no falla: el evento queda en la tabla outbox y se reintenta de forma asíncrona.

### CA-013 — Auditoría
- Dado cualquier operación de escritura, entonces el servicio de auditoría recibe el evento vía Kafka y persiste un registro en MongoDB con: `tenantId`, `userId` del actor, `entity`, `entityId`, `action`, `diff` (campos anteriores y nuevos), `ip_address`, `correlationId`, `occurredAt`.
- La escritura de auditoría es asíncrona: nunca bloquea ni falla la operación de negocio principal.

### CA-014 — Rendimiento
- `GET /api/v1/users/me` responde en menos de 200ms en p95 (perfil completo con roles desde la vista `v_user_login_profile`).
- `GET /api/v1/users` con hasta 10.000 usuarios en el tenant responde en menos de 500ms en p95 con paginación de 20 elementos.
- La búsqueda full-text por `search=ana` sobre 10.000 usuarios responde en menos de 300ms (índice GIN `pg_trgm`).

### CA-015 — Seguridad de datos sensibles
- La respuesta de cualquier endpoint del módulo nunca incluye `password_hash`, `totp_secret`, `totp_backup_codes`, ni `temporal_code`.
- El `totp_secret` se cifra a nivel de aplicación antes de persistir en base de datos. La base de datos nunca almacena el secret en texto plano.
- Los tokens de invitación y reset de contraseña se almacenan únicamente como hash SHA-256. El token en texto plano solo existe en el email enviado al usuario.

### CA-016 — Compatibilidad modo ON_PREMISE
- Dado un tenant con `mode = ON_PREMISE`, el sistema funciona de forma idéntica al modo `SAAS_SHARED` desde la perspectiva del módulo tenant. La diferencia es operacional (infraestructura dedicada), no funcional.
- El tenant `slug = 'system'` con `mode = ON_PREMISE` puede coexistir como único tenant del sistema cuando se despliega para un cliente dedicado.

---

## 9. Restricciones técnicas

**Transacciones:** Todas las operaciones de escritura del módulo que involucran más de una tabla (crear usuario + asignar rol, aceptar invitación + crear usuario + marcar invitación, suspender tenant + revocar sesiones) deben ejecutarse dentro de una única transacción `@Transactional`. El fallo de cualquier paso revierte toda la operación.

**Outbox pattern:** Los eventos de dominio no se publican directamente a Kafka dentro de la transacción de negocio. Se persisten en una tabla `outbox` en la misma transacción, y un proceso separado los publica de forma asíncrona. Esto garantiza consistencia entre la base de datos y el bus de eventos.

**MapStruct:** Todos los mapeos se implementan con MapStruct. No se mapea manualmente en servicios ni controladores. Existen dos capas independientes: `application/mapper/` (dominio ↔ DTOs) e `infrastructure/persistence/mapper/` (dominio ↔ entidades JPA).

**Validaciones:** Las validaciones de entrada se implementan con Bean Validation (`@NotBlank`, `@Email`, `@Pattern`, `@Size`) en los DTOs de request. Las validaciones de negocio (unicidad en tenant, protección del último admin, roles de sistema) se implementan en la capa de servicio.

**ArchUnit:** El módulo debe pasar las reglas de `HexagonalArchTest.java` (ninguna clase de `domain` importa de `infrastructure`) y `ModuleBoundaryTest.java` (ningún módulo importa clases internas de otro módulo).

**RLS:** Antes de cada operación JPA, el interceptor de Hibernate ejecuta `SET LOCAL app.tenant_id = '{uuid}'` dentro de la transacción activa. El SUPER_ADMIN adicionalmente activa `SET LOCAL app.is_system_admin = 'true'`.

**MapStruct — dos capas de mapeo:** el módulo usa dos conjuntos independientes de mappers:
- `application/mapper/` — mapea entre modelos de dominio y DTOs de request/response.
- `infrastructure/persistence/mapper/` — mapea entre modelos de dominio y entidades JPA.

**Manejo de errores:** `GlobalExceptionHandler` (@RestControllerAdvice) centraliza la traducción de excepciones a respuestas HTTP con el envelope `ApiError { code, message, status, timestamp }`. Cubre tres casos:
- `BusinessException` → código y HTTP status definidos en la excepción.
- `MethodArgumentNotValidException` → HTTP 422, código `NXC-VALIDATION-0001` con detalle de los campos inválidos.
- `Exception` genérica → HTTP 500, código `NXC-INTERNAL-0001`.

---

## 10. Estructura de archivos del módulo

La ruta base en el código fuente es:  
`nexcore-core/src/main/java/com/nexore/core/module/tenant/`

> **Nota:** el grupo Java es `com.nexore.core` (no `com.nexcore.core`).

```
module/tenant/
├── domain/
│   ├── model/
│   │   ├── Tenant.java
│   │   ├── TenantStatus.java            ← enum: TRIAL | ACTIVE | SUSPENDED | CANCELLED
│   │   ├── TenantPlan.java              ← enum: FREE | STARTER | PROFESSIONAL | ENTERPRISE
│   │   ├── TenantMode.java              ← enum: SAAS_SHARED | SAAS_DEDICATED | ON_PREMISE
│   │   ├── User.java
│   │   ├── UserStatus.java              ← enum: PENDING_ACTIVATION | ACTIVE | SUSPENDED | BLOCKED | DELETED
│   │   ├── Role.java
│   │   ├── UserRole.java
│   │   └── UserInvitation.java
│   └── repository/
│       ├── TenantRepository.java        ← port (interfaz de dominio)
│       ├── UserRepository.java          ← port
│       ├── RoleRepository.java          ← port
│       ├── UserRoleRepository.java      ← port
│       └── UserInvitationRepository.java ← port
│
│   [PENDIENTE] domain/event/            ← eventos de dominio (outbox / Kafka) — no implementado aún
│
├── application/
│   ├── service/
│   │   ├── TenantService.java           ← UC-001 a UC-004
│   │   ├── UserService.java             ← UC-005 a UC-013, UC-018, UC-019, UC-020
│   │   └── RoleService.java             ← UC-014 a UC-017
│   │
│   │   Nota: la lógica de invitaciones (UC-018, UC-019) está consolidada en UserService.
│   │
│   ├── dto/
│   │   ├── request/
│   │   │   ├── TenantCreateRequest.java
│   │   │   ├── TenantUpdateRequest.java
│   │   │   ├── UserCreateRequest.java
│   │   │   ├── UserUpdateRequest.java
│   │   │   ├── UserInviteRequest.java
│   │   │   ├── AcceptInvitationRequest.java
│   │   │   ├── RoleCreateRequest.java   ← usado también en PATCH /roles/{id}
│   │   │   ├── AssignRolesRequest.java
│   │   │   └── RoleAssignment.java      ← value object: { roleId, expiresAt }
│   │   └── response/
│   │       ├── TenantResponse.java
│   │       ├── UserResponse.java
│   │       ├── UserInvitationResponse.java
│   │       ├── RoleResponse.java
│   │       ├── RoleSummary.java         ← { id, name, assignedAt, expiresAt }
│   │       └── PageResponse.java        ← envelope paginado genérico
│   ├── mapper/
│   │   ├── TenantMapper.java            ← MapStruct (DTO ↔ dominio)
│   │   ├── UserMapper.java              ← MapStruct
│   │   └── RoleMapper.java             ← MapStruct
│   └── exception/
│       ├── BusinessException.java       ← jerarquía de errores de negocio con factory methods
│       └── ApiError.java               ← DTO del cuerpo de error HTTP { code, message, status, timestamp }
│
└── infrastructure/
    ├── web/
    │   ├── TenantController.java        ← GET|POST /api/v1/tenants, PATCH|POST /{id}/suspend|activate
    │   ├── UserController.java          ← todos los endpoints /api/v1/users/** e invitations/**
    │   ├── RoleController.java          ← GET|POST|PATCH|DELETE /api/v1/roles/**
    │   └── GlobalExceptionHandler.java  ← @RestControllerAdvice: BusinessException, Bean Validation, genérico
    └── persistence/
        ├── JpaTenantRepositoryAdapter.java        ← implementa TenantRepository (port)
        ├── JpaUserRepositoryAdapter.java           ← implementa UserRepository
        ├── JpaRoleRepositoryAdapter.java           ← implementa RoleRepository
        ├── JpaUserRoleRepositoryAdapter.java       ← implementa UserRoleRepository
        ├── JpaUserInvitationRepositoryAdapter.java ← implementa UserInvitationRepository
        ├── entity/
        │   ├── TenantJpaEntity.java
        │   ├── UserJpaEntity.java
        │   ├── RoleJpaEntity.java
        │   ├── UserRoleJpaEntity.java
        │   └── UserInvitationJpaEntity.java
        ├── jpa/
        │   ├── SpringDataTenantRepository.java     ← JpaRepository de Spring Data
        │   ├── SpringDataUserRepository.java
        │   ├── SpringDataRoleRepository.java
        │   ├── SpringDataUserRoleRepository.java
        │   └── SpringDataUserInvitationRepository.java
        └── mapper/
            ├── TenantPersistenceMapper.java        ← MapStruct (entidad JPA ↔ dominio)
            ├── UserPersistenceMapper.java
            ├── RolePersistenceMapper.java
            ├── UserRolePersistenceMapper.java
            └── UserInvitationPersistenceMapper.java

[PENDIENTE] infrastructure/messaging/  ← publishers Kafka / outbox — no implementado aún
[PENDIENTE] infrastructure/email/      ← envío de emails de invitación — no implementado aún
```

---

## 11. Convención temporal de autenticación (fase MVP)

> Hasta que el módulo de seguridad JWT esté implementado, los controladores identifican al actor mediante headers HTTP explícitos. Estos headers **se eliminarán** cuando se integre Spring Security con JWT.

| Header | Tipo | Controlador | Descripción |
|---|---|---|---|
| `X-Tenant-Id` | UUID | `UserController`, `RoleController` | Tenant del actor autenticado |
| `X-Actor-Id` | UUID | `UserController`, `RoleController` | UUID del usuario autenticado |
| `X-Actor-Super-Admin` | boolean | `TenantController` | `true` si el actor es SUPER_ADMIN |
| `X-Is-Tenant-Admin` | boolean | `UserController` | `true` si el actor tiene rol TENANT_ADMIN |
