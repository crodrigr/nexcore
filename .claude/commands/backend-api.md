# NexCore — Referencia de API REST y convenciones del backend

Referencia completa de los endpoints disponibles en `nexcore-core` (puerto 8080)
y `nexcore-auth-service` (puerto 8081). Usar esta guía al integrar el frontend,
crear tests, o agregar nuevos endpoints.

---

## Servicios

| Servicio | Puerto | Base URL | Schema BD |
|---|---|---|---|
| nexcore-core | 8080 | `http://localhost:8080` | `nxc_tenant`, `nxc_menu` |
| nexcore-auth-service | 8081 | `http://localhost:8081` | `nxc_auth` |

---

## Headers de autenticación (fase MVP)

Todos los endpoints de `nexcore-core` (excepto `/api/v1/users/invitations/accept`)
requieren estos headers extraídos del JWT por el frontend/gateway:

| Header | Tipo | Descripción |
|---|---|---|
| `X-Tenant-Id` | UUID | Tenant del usuario autenticado |
| `X-Actor-Id` | UUID | UUID del usuario autenticado |
| `X-Is-Tenant-Admin` | boolean | `true` si tiene rol TENANT_ADMIN |
| `X-Actor-Super-Admin` | boolean | `true` si es SUPER_ADMIN (solo endpoints de tenant) |

> **Nota:** estos headers serán reemplazados por extracción del JWT cuando
> Spring Security esté implementado en nexcore-core.

---

## nexcore-auth-service (puerto 8081)

### Autenticación

```
POST /api/v1/auth/login
Body: { tenantId: UUID, username: string, password: string }
Response 200: { challengeToken: string, message: string, expiresIn: number }

POST /api/v1/auth/verify-otp
Body: { challengeToken: string, code: string }
Response 200: { token: string, refreshToken: string, expiresIn: number, profile: object }

POST /api/v1/auth/refresh
Body: { refreshToken: string }
Response 200: { token: string, refreshToken: string, expiresIn: number, profile: object }

POST /api/v1/auth/logout
Header: Authorization: Bearer <accessToken>
Response 204

POST /api/v1/auth/logout-all
Header: Authorization: Bearer <accessToken>
Response 204
```

### Contraseña

```
POST /api/v1/auth/password/reset-request
Body: { tenantId: UUID, email: string }
Response 200: { message: string }

POST /api/v1/auth/password/reset-confirm
Body: { token: string, newPassword: string }
Response 200: { message: string }

POST /api/v1/auth/password/change
Header: Authorization: Bearer <accessToken>
Body: { currentPassword: string, newPassword: string }
Response 200: { message: string }
```

### Flujo de login

```
1. POST /auth/login → challengeToken + envía OTP al email
2. POST /auth/verify-otp → accessToken (15 min) + refreshToken (7 días) + profile
3. Adjuntar accessToken en Authorization: Bearer <token>
4. Cuando expire → POST /auth/refresh con refreshToken
```

**OTP fijo para desarrollo** (activado en application.yml):
- Código: `111111`
- Usuarios permitidos: `super.admin`, `test.admin`, `test.editor`

---

## nexcore-core (puerto 8080)

### Tenants `/api/v1/tenants`

```
GET    /api/v1/tenants                     → PageResponse<TenantResponse>   (SUPER_ADMIN)
POST   /api/v1/tenants                     → TenantResponse 201             (SUPER_ADMIN)
GET    /api/v1/tenants/{id}                → TenantResponse
PATCH  /api/v1/tenants/{id}                → TenantResponse
POST   /api/v1/tenants/{id}/suspend        → 204                            (SUPER_ADMIN)
POST   /api/v1/tenants/{id}/activate       → 204                            (SUPER_ADMIN)
```

**TenantCreateRequest:**
```json
{
  "slug": "mi-empresa",
  "name": "Mi Empresa SAS",
  "legalName": "Mi Empresa S.A.S.",
  "taxId": "900123456-1",
  "plan": "FREE|STARTER|PROFESSIONAL|ENTERPRISE",
  "mode": "SAAS_SHARED|SAAS_DEDICATED|ON_PREMISE",
  "timezone": "America/Bogota",
  "locale": "es-CO",
  "dateFormat": "DD/MM/YYYY",
  "currency": "COP"
}
```

---

### Usuarios `/api/v1/users`

```
GET    /api/v1/users                       → PageResponse<UserResponse>
       Params: status, search, page, size, sort, dir
POST   /api/v1/users                       → UserResponse 201
GET    /api/v1/users/me                    → UserResponse
GET    /api/v1/users/{id}                  → UserResponse
PATCH  /api/v1/users/{id}                  → UserResponse
POST   /api/v1/users/{id}/suspend          → 204
POST   /api/v1/users/{id}/activate         → 204
DELETE /api/v1/users/{id}                  → 204  (soft delete)
PUT    /api/v1/users/{id}/roles            → UserResponse
POST   /api/v1/users/invite                → UserInvitationResponse 201
GET    /api/v1/users/invitations           → List<UserInvitationResponse>
POST   /api/v1/users/invitations/accept    → UserResponse 201  (público, sin headers)
POST   /api/v1/users/invitations/{id}/revoke  → 204
POST   /api/v1/users/invitations/{id}/resend  → UserInvitationResponse
```

**UserCreateRequest:**
```json
{
  "fullName": "Juan Pérez",
  "username": "juan.perez",
  "email": "juan@empresa.com",
  "phone": "+57 300 000 0000",
  "sendInvite": true,
  "roleIds": ["uuid-rol-1"]
}
```

**UserStatus:** `ACTIVE | PENDING_ACTIVATION | SUSPENDED | BLOCKED`

---

### Roles `/api/v1/roles`

```
GET    /api/v1/roles                       → List<RoleResponse>
POST   /api/v1/roles                       → RoleResponse 201
GET    /api/v1/roles/{id}                  → RoleResponse
PATCH  /api/v1/roles/{id}                  → RoleResponse
DELETE /api/v1/roles/{id}                  → 204
```

**RoleCreateRequest:**
```json
{
  "name": "SUPERVISOR",
  "description": "Rol de supervisión",
  "isDefault": false
}
```

**Roles de sistema (no editables):** `SUPER_ADMIN`, `TENANT_ADMIN`, `EDITOR`

---

### Perfil de usuario `/api/v1/me`

```
GET /api/v1/me/profile                     → UserProfileResponse
```

**UserProfileResponse** (almacenado en localStorage como `profile`):
```json
{
  "user": {
    "iduser": "uuid",
    "username": "juan.perez",
    "name": "Juan Pérez",
    "email": "juan@empresa.com",
    "roles": ["TENANT_ADMIN"]
  },
  "menus": [
    {
      "id": "uuid",
      "name": "admin",
      "title": "Administración",
      "icon": "shield",
      "route": null,
      "location": "sidebar",
      "item_type": "GROUP",
      "access": "execute",
      "order_index": 10,
      "children": [
        { "name": "users", "title": "Usuarios", "route": "/users", "access": "execute", ... },
        { "name": "permisos", "title": "Permisos", "route": "/permissions", "access": "execute", ... }
      ]
    }
  ],
  "permissions": [
    { "component": "admin-panel", "route": null, "access": "execute", "elements": [...] }
  ]
}
```

---

### Componentes de UI `/api/v1/menu/components`

```
GET /api/v1/menu/components                → PageResponse<ComponentSummaryResponse>
    Params: search, isSystem, page, size
GET /api/v1/menu/components/{componentId}  → ComponentDetailResponse
GET /api/v1/menu/components/{componentId}/elements → List<ComponentElementResponse>
```

---

### Permisos por rol `/api/v1/menu/permissions`

```
GET /api/v1/menu/permissions/roles/{roleId}             → RolePermissionMatrixResponse
PUT /api/v1/menu/permissions/roles/{roleId}/components/{componentId}  → ComponentPermissionResultResponse
PUT /api/v1/menu/permissions/roles/{roleId}/components/batch          → List<ComponentPermissionResultResponse>
PUT /api/v1/menu/permissions/roles/{roleId}/elements/{elementId}      → ElementPermissionResultResponse
```

**AccessLevel:** `execute | view | hidden`

---

## Estructura de respuestas

### PageResponse\<T\>
```json
{
  "content": [...],
  "page": 0,
  "size": 20,
  "totalElements": 45,
  "totalPages": 3,
  "last": false
}
```

### ApiError (en caso de error)
```json
{
  "code": "NXC-TEN-0001",
  "message": "Slug 'mi-empresa' already exists in an active tenant.",
  "status": 409,
  "timestamp": "2025-05-29T10:00:00Z"
}
```

---

## Códigos de error BusinessException

| Prefijo | Módulo | Ejemplos |
|---|---|---|
| `NXC-TEN-*` | Tenants | 0001=slug duplicado, 0003=not found, 0006=admin no puede cambiar plan |
| `NXC-USR-*` | Usuarios | 0001=email duplicado, 0003=not found, 0010=quota, 0020=invitation inválida |
| `NXC-ROL-*` | Roles | 0001=nombre duplicado, 0020=sistema no borrable, 0021=tiene usuarios |
| `NXC-MNU-*` | Menú/Perfil | 0001=usuario not found, 0002=tenant inactivo, 0003=usuario suspendido |
| `NXC-CMP-*` | Componentes | 0001=componente not found |
| `NXC-ELM-*` | Elementos | 0001=elemento not found |
| `NXC-PRM-*` | Permisos | 0001=rol not found, 0002=componentId inválido |
| `NXC-VALIDATION-0001` | Validación | Bean validation fallida |
| `NXC-INTERNAL-0001` | Interno | Error inesperado del servidor |

---

## Convenciones al agregar endpoints

1. **Verbos HTTP:** `GET` lista/detalle, `POST` crear/acciones, `PATCH` actualización parcial, `PUT` reemplazo/batch, `DELETE` soft-delete.
2. **Acciones de estado** (suspend, activate, revoke): `POST /{id}/accion` → 204.
3. **Creación:** devolver `201 Created` con header `Location: /api/v1/recurso/{id}`.
4. **Paginación:** query params `page` (0-based) y `size` (default 20).
5. **Ordenamiento:** query params `sort` (campo) y `dir` (`asc`/`desc`).
6. **Búsqueda:** query param `search` (texto libre).
7. **Multi-tenant:** todos los endpoints de nexcore-core filtran por `X-Tenant-Id`.
8. **No exponer IDs internos** de otras tablas si no pertenecen al tenant.
9. **CORS:** configurado en `WebConfig.java`; origins en `app.cors.allowed-origins`.
10. **Actuator:** health en `/actuator/health` (nexcore-auth-service).
