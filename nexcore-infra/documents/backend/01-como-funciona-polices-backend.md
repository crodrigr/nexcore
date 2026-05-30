# Cómo funcionan las API Policies en el Backend

**Servicios involucrados:** `nexcore-core` (puerto 8080) · `nexcore-auth-service` (puerto 8081)  
**Tecnologías:** Spring MVC Interceptor · Redis · PostgreSQL · Spring PathPatternParser

---

## 1. ¿Qué problema resuelve?

Cada endpoint del backend necesita saber si el usuario que llega tiene permiso para ejecutarlo. En lugar de poner anotaciones `@PreAuthorize` en cada método o lógica dispersa por los controladores, NexCore centraliza esta decisión en una **tabla de base de datos** (`role_api_policies`) y la cachea en **Redis**.

El resultado: agregar o quitar permisos a un rol es un `INSERT`/`DELETE` en la base de datos. El backend lo aplica automáticamente en el siguiente ciclo de caché, sin redeploy.

---

## 2. La tabla en base de datos

```sql
-- Esquema: nxc_tenant
-- Tabla: role_api_policies
```

| Columna        | Tipo      | Descripción                                               |
|----------------|-----------|-----------------------------------------------------------|
| `id`           | UUID      | Clave primaria (generada por la BD con `gen_random_uuid()`) |
| `role_name`    | TEXT      | Nombre del rol (`SUPER_ADMIN`, `TENANT_ADMIN`, `EDITOR`, `*`) |
| `http_method`  | TEXT      | `GET`, `POST`, `PUT`, `PATCH`, `DELETE` o `*`            |
| `path_pattern` | TEXT      | Patrón de ruta (`/api/*/users`, `/api/*/users/**`)        |
| `effect`       | TEXT      | `ALLOW` o `DENY`                                         |
| `service`      | TEXT      | Servicio dueño de la política (`core`, `auth`)           |
| `priority`     | INT       | Número más alto = mayor precedencia                       |
| `module`       | TEXT      | Módulo lógico (ej: `users`, `tenants`)                   |
| `description`  | TEXT      | Descripción legible                                       |

**Nota importante sobre `role_name`:**  
- Un valor `*` significa "cualquier usuario autenticado".  
- Un valor específico como `EDITOR` significa que solo usuarios con ese rol pueden acceder.

**Nota sobre `path_pattern`:**  
- `*` coincide con **un** segmento de ruta. Ejemplo: `/api/*/users` cubre `/api/v1/users` y `/api/v2/users`.  
- `**` coincide con **uno o más** segmentos. Ejemplo: `/api/*/users/**` cubre `/api/v1/users/123/roles`.

---

## 3. Arquitectura general

```
┌─────────────────────────────────────────────────────────────────────┐
│                        ARRANQUE DEL SERVICIO                        │
│                                                                     │
│  PolicyCacheLoader                                                  │
│  @EventListener(ApplicationReadyEvent.class)                        │
│  loadOnStartup()  ──►  RoleApiPolicyCacheService.refreshPolicies()  │
│                         │                                           │
│                         ▼                                           │
│                   PostgreSQL                                        │
│                   nxc_tenant.role_api_policies                      │
│                   WHERE service = 'core'                            │
│                   ORDER BY priority DESC                            │
│                         │                                           │
│                         ▼                                           │
│                   Redis  key: nxc:policies:core  (TTL 300s)         │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                        CADA REQUEST HTTP                            │
│                                                                     │
│  Cliente HTTP                                                       │
│  X-Actor-Id: <uuid>                                                 │
│  X-Tenant-Id: <uuid>                                                │
│       │                                                             │
│       ▼                                                             │
│  WebConfig.addInterceptors()                                        │
│  Intercepta: /api/**                                                │
│  Excluye:    /api/*/users/invitations/accept                        │
│       │                                                             │
│       ▼                                                             │
│  RoleApiPolicyInterceptor.preHandle()                               │
│       │                                                             │
│       ├─► Redis: nxc:user_roles:{actorId}:{tenantId}  (TTL 120s)   │
│       │   (roles del usuario en ese tenant)                         │
│       │                                                             │
│       ├─► Redis: nxc:policies:core  (TTL 300s)                      │
│       │   (lista de políticas del servicio)                         │
│       │                                                             │
│       └─► Evaluación: isAllowed()                                   │
│                │                                                    │
│                ├─ ALLOW → continúa al controlador (return true)     │
│                └─ DENY  → responde 403 Forbidden  (return false)    │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 4. Flujo de arranque — Carga de políticas

### Paso 1: Spring lanza el evento `ApplicationReadyEvent`

Cuando el servicio termina de arrancar completamente (todos los beans listos, servidor HTTP activo), Spring publica el evento `ApplicationReadyEvent`.

### Paso 2: `PolicyCacheLoader.loadOnStartup()` recibe el evento

**Clase:** `com.nexore.core.config.security.PolicyCacheLoader`

```java
@EventListener(ApplicationReadyEvent.class)
public void loadOnStartup() {
    try {
        cacheService.refreshPolicies();   // <── delega al servicio de caché
    } catch (Exception e) {
        log.error("Could not load API policies into Redis on startup — interceptor will use DB fallback: {}", e.getMessage());
    }
}
```

Si Redis no está disponible al arrancar, el error se logea pero el servicio **no cae**. El interceptor tiene su propio fallback a BD.

### Paso 3: `RoleApiPolicyCacheService.refreshPolicies()` consulta la BD

**Clase:** `com.nexore.core.config.security.RoleApiPolicyCacheService`

```java
public void refreshPolicies() {
    // 1. Consulta la BD ordenada por prioridad descendente
    List<RoleApiPolicyJpaEntity> entities =
        policyRepository.findByServiceOrderByPriorityDesc(serviceName);  // serviceName = "core"

    // 2. Mapea entidades JPA → DTOs serializables
    List<RoleApiPolicyDto> dtos = entities.stream()
        .map(e -> new RoleApiPolicyDto(
            e.getRoleName(), e.getHttpMethod(),
            e.getPathPattern(), e.getEffect(), e.getPriority()))
        .toList();

    // 3. Serializa a JSON y guarda en Redis con TTL
    String key = "nxc:policies:core";
    redisTemplate.opsForValue().set(key, serialize(dtos), Duration.ofSeconds(300));
}
```

**Repositorio usado:** `SpringDataRoleApiPolicyRepository`  
**Método:** `findByServiceOrderByPriorityDesc(String service)`  
→ Spring Data JPA genera automáticamente el SQL: `SELECT * FROM nxc_tenant.role_api_policies WHERE service = ? ORDER BY priority DESC`

### Paso 4: Las políticas quedan en Redis

```
Redis key:   nxc:policies:core
Redis value: JSON array de RoleApiPolicyDto
TTL:         300 segundos (5 minutos)
```

Ejemplo del valor JSON en Redis:
```json
[
  { "roleName": "SUPER_ADMIN", "httpMethod": "GET",  "pathPattern": "/api/*/tenants", "effect": "ALLOW", "priority": 100 },
  { "roleName": "EDITOR",      "httpMethod": "GET",  "pathPattern": "/api/*/users/*", "effect": "ALLOW", "priority": 100 },
  { "roleName": "EDITOR",      "httpMethod": "GET",  "pathPattern": "/api/*/users",   "effect": "DENY",  "priority": 90  }
]
```

---

## 5. Flujo por request — Validación de permisos (nexcore-core)

### Paso 1: El request llega al servidor

El cliente envía las cabeceras de identidad:
```http
GET /api/v1/users HTTP/1.1
X-Actor-Id:  550e8400-e29b-41d4-a716-446655440000
X-Tenant-Id: 00000000-0000-0000-0000-000000000002
```

### Paso 2: `WebConfig` dirige el request al interceptor

**Clase:** `com.nexore.core.config.WebConfig`  
**Método:** `addInterceptors(InterceptorRegistry registry)`

```java
registry.addInterceptor(roleApiPolicyInterceptor)
    .addPathPatterns("/api/**")                          // intercepta todo bajo /api/
    .excludePathPatterns("/api/*/users/invitations/accept"); // excepto aceptar invitación (es público)
```

Spring MVC llama automáticamente a `preHandle()` antes de ejecutar el método del controlador.

### Paso 3: `RoleApiPolicyInterceptor.preHandle()` valida la identidad

**Clase:** `com.nexore.core.config.security.RoleApiPolicyInterceptor`

```java
@Override
public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {

    // 1. Verificar que las cabeceras de identidad existan
    String actorIdHeader  = request.getHeader("X-Actor-Id");
    String tenantIdHeader = request.getHeader("X-Tenant-Id");

    if (actorIdHeader == null || tenantIdHeader == null) {
        deny(response, 401, "Authentication required");
        return false;   // corta el flujo — el controlador nunca se ejecuta
    }

    // 2. Parsear como UUID (evita injection de valores malformados)
    UUID actorId  = UUID.fromString(actorIdHeader);
    UUID tenantId = UUID.fromString(tenantIdHeader);

    // 3. Obtener roles del usuario y las políticas del servicio
    List<String> userRoles      = cacheService.getUserRoles(actorId, tenantId);
    List<RoleApiPolicyDto> policies = cacheService.getPolicies();

    // 4. Evaluar si está permitido
    if (!isAllowed(request.getMethod(), request.getRequestURI(), userRoles, policies)) {
        deny(response, 403, "Access denied");
        return false;
    }

    return true;  // permite continuar al controlador
}
```

### Paso 4: `RoleApiPolicyCacheService.getUserRoles()` obtiene los roles

```java
public List<String> getUserRoles(UUID userId, UUID tenantId) {
    String key = "nxc:user_roles:" + userId + ":" + tenantId;

    // 1. Buscar en Redis primero (caché caliente)
    String json = redisTemplate.opsForValue().get(key);
    if (json != null) {
        return deserializeStrings(json);  // ← hit de caché
    }

    // 2. Si no está en Redis, consultar la BD
    List<String> roles = userRoleRepository.findRoleNamesByUserIdAndTenantId(userId, tenantId);

    // 3. Guardar en Redis para las próximas peticiones (TTL 120s)
    redisTemplate.opsForValue().set(key, serialize(roles), Duration.ofSeconds(120));

    return roles;
}
```

**Repositorio usado:** `SpringDataUserRoleRepository`  
**Método:** `findRoleNamesByUserIdAndTenantId(UUID userId, UUID tenantId)`  
→ Query nativa que hace JOIN entre `user_roles` y `roles`, filtrando roles no expirados y no eliminados:

```sql
SELECT r.name
FROM nxc_tenant.user_roles ur
JOIN nxc_tenant.roles r ON r.id = ur.role_id
WHERE ur.user_id     = :userId
  AND ur.tenant_id   = :tenantId
  AND r.deleted_at   IS NULL
  AND (ur.expires_at IS NULL OR ur.expires_at > NOW())
```

**Clave Redis del resultado:**
```
nxc:user_roles:{userId}:{tenantId}
TTL: 120 segundos (2 minutos)
```

### Paso 5: `RoleApiPolicyCacheService.getPolicies()` obtiene las políticas

```java
public List<RoleApiPolicyDto> getPolicies() {
    String key = "nxc:policies:core";
    String json = redisTemplate.opsForValue().get(key);

    if (json != null) {
        return deserializePolicies(json);   // ← hit de caché normal
    }

    // Cache miss (TTL expiró): recargar de la BD
    log.warn("Policy cache miss for service 'core', loading from DB");
    refreshPolicies();
    return deserializePolicies(redisTemplate.opsForValue().get(key));
}
```

Si Redis no está disponible, cae al método `loadPoliciesFromDb()` que consulta PostgreSQL directamente.

### Paso 6: `isAllowed()` evalúa la primera política que coincide

**Método:** `RoleApiPolicyInterceptor.isAllowed()`

```java
private boolean isAllowed(String method, String path,
                           List<String> userRoles,
                           List<RoleApiPolicyDto> policies) {

    PathContainer pathContainer = PathContainer.parsePath(path);

    // Iterar políticas ya ordenadas por priority DESC
    for (RoleApiPolicyDto policy : policies) {

        // Condición 1: ¿el rol de la política aplica al usuario?
        if (!roleMatches(policy.getRoleName(), userRoles))         continue;

        // Condición 2: ¿el método HTTP coincide?
        if (!methodMatches(policy.getHttpMethod(), method))        continue;

        // Condición 3: ¿el path coincide con el patrón?
        if (!pathMatches(policy.getPathPattern(), pathContainer))  continue;

        // Primera coincidencia gana (first-match-wins)
        return "ALLOW".equals(policy.getEffect());
    }

    return false;  // fail-closed: si no hay ninguna política que coincida → DENY
}
```

**Submétodos de coincidencia:**

```java
// Rol: coincide si la política es para todos ('*') o el usuario tiene ese rol
private boolean roleMatches(String policyRole, List<String> userRoles) {
    return "*".equals(policyRole) || userRoles.contains(policyRole);
}

// Método HTTP: coincide si la política acepta todos ('*') o el método es igual
private boolean methodMatches(String policyMethod, String requestMethod) {
    return "*".equals(policyMethod) || policyMethod.equalsIgnoreCase(requestMethod);
}

// Path: usa Spring PathPatternParser para evaluar el patrón
private boolean pathMatches(String pattern, PathContainer pathContainer) {
    return patternParser.parse(pattern).matches(pathContainer);
}
```

**`PathPatternParser`** es el mismo motor que usa Spring MVC para sus routes. Esto garantiza que `*` y `**` se comportan igual que en las anotaciones `@GetMapping`.

### Paso 7: Resultado de la evaluación

| Resultado       | HTTP Status | Acción                                  |
|-----------------|-------------|-----------------------------------------|
| Política ALLOW  | —           | `return true` → controlador se ejecuta |
| Política DENY   | 403         | `return false` → respuesta de error    |
| Sin coincidencia| 403         | `return false` → fail-closed           |
| Sin cabeceras   | 401         | `return false` → respuesta de error    |
| UUID inválido   | 400         | `return false` → respuesta de error    |

---

## 6. El servicio de autenticación — `nexcore-auth-service`

El `nexcore-auth-service` implementa el mismo patrón pero con una diferencia importante: sus endpoints son **pre-autenticación** (login, refresh token, logout), por lo que **no tienen `X-Actor-Id` ni `X-Tenant-Id`**.

En lugar de validar roles, solo verifica que el endpoint exista en la tabla de políticas con `role_name = '*'` (cualquier llamada, autenticada o no). La autenticación real (validar el JWT o refresh token) la hace el código de aplicación dentro del controlador.

### Clases equivalentes en auth-service

| Clase en nexcore-core | Equivalente en nexcore-auth-service | Diferencia |
|---|---|---|
| `PolicyCacheLoader` | `PolicyCacheLoader` | Idéntica — mismo patrón |
| `RoleApiPolicyCacheService` | `RoleApiPolicyCacheService` | Sin `getUserRoles()` — auth no necesita roles |
| `RoleApiPolicyInterceptor` | `AuthApiPolicyInterceptor` | Sin validación de `X-Actor-Id`/`X-Tenant-Id` |
| `WebConfig` | `WebConfig` | Intercepta `/auth/**` en vez de `/api/**` |

### Endpoints excluidos del interceptor (son completamente públicos)

**Clase:** `com.nexore.auth.infrastructure.config.WebConfig`

```java
registry.addInterceptor(authApiPolicyInterceptor)
    .addPathPatterns("/auth/**")
    .excludePathPatterns(
        "/auth/login",                   // iniciar sesión
        "/auth/verify-otp",              // verificar código OTP
        "/auth/password/reset/request",  // solicitar reset de contraseña
        "/auth/password/reset/confirm"   // confirmar reset de contraseña
    );
```

### Flujo simplificado para auth-service

```
Request: POST /auth/refresh
       │
       ▼
AuthApiPolicyInterceptor.preHandle()
       │
       ├─► Redis: nxc:policies:auth  → lista de políticas del servicio auth
       │
       └─► isAllowed(method, path, policies)
               │
               ├─ methodMatches("POST", "POST") → true
               ├─ pathMatches("/auth/**", "/auth/refresh") → true
               └─ effect = "ALLOW" → return true
                       │
                       ▼
               Controlador: RefreshTokenController.refresh()
```

---

## 7. Claves Redis y TTLs

| Clave Redis                         | Contenido                              | TTL      | Se invalida cuando                      |
|-------------------------------------|----------------------------------------|----------|-----------------------------------------|
| `nxc:policies:core`                 | Lista de políticas del core-service    | 5 min    | Expiración automática                   |
| `nxc:policies:auth`                 | Lista de políticas del auth-service    | 5 min    | Expiración automática                   |
| `nxc:user_roles:{userId}:{tenantId}`| Nombres de roles del usuario en tenant | 2 min    | Expiración automática o cambio de roles |

Para forzar recarga inmediata (ej: se actualizaron políticas en BD) se puede llamar a `RoleApiPolicyCacheService.refreshPolicies()` o simplemente eliminar la clave de Redis con `DEL nxc:policies:core`.

---

## 8. Configuración por servicio

### nexcore-core (`application-local.yml`)

```yaml
spring:
  data:
    redis:
      host: ${REDIS_HOST:localhost}
      port: ${REDIS_PORT:6379}

app:
  api-policy:
    service-name: core          # filtra políticas WHERE service = 'core'
    policy-ttl-seconds: 300     # TTL de la caché de políticas (5 min)
    user-roles-ttl-seconds: 120 # TTL de la caché de roles de usuario (2 min)
```

### nexcore-auth-service (`application.yml`)

```yaml
spring:
  data:
    redis:
      host: ${REDIS_HOST:localhost}
      port: ${REDIS_PORT:6379}
```

El `auth-service` tiene el `service-name` hardcodeado como `"auth"` directamente en `RoleApiPolicyCacheService`.

---

## 9. Diagrama de clases

```
nexcore-core
─────────────────────────────────────────────────
PolicyCacheLoader
  └─► RoleApiPolicyCacheService
        ├─► SpringDataRoleApiPolicyRepository (JPA)
        │     └─► RoleApiPolicyJpaEntity (@Table "nxc_tenant.role_api_policies")
        └─► SpringDataUserRoleRepository (JPA)
              └─► UserRoleJpaEntity (@Table "nxc_tenant.user_roles")

WebConfig
  └─► RoleApiPolicyInterceptor
        └─► RoleApiPolicyCacheService
              └─► RoleApiPolicyDto (DTO serializable a Redis)

nexcore-auth-service
─────────────────────────────────────────────────
PolicyCacheLoader
  └─► RoleApiPolicyCacheService
        └─► RoleApiPolicyJpaRepository (JPA)
              └─► RoleApiPolicyEntity (@Table "nxc_tenant.role_api_policies")

WebConfig
  └─► AuthApiPolicyInterceptor
        └─► RoleApiPolicyCacheService
              └─► RoleApiPolicyDto (DTO serializable a Redis)
```

---

## 10. Cómo agregar una nueva política

No es necesario tocar código. Solo insertar en la base de datos:

```sql
INSERT INTO nxc_tenant.role_api_policies
    (id, role_name, http_method, path_pattern, effect, service, module, priority, description)
VALUES
    (gen_random_uuid(), 'EDITOR', 'POST', '/api/*/reports', 'ALLOW', 'core', 'reports', 100,
     'EDITOR puede crear reportes');
```

La política se aplicará en el siguiente ciclo de TTL (máximo 5 minutos). Para aplicarla de forma inmediata:

```bash
# Eliminar la caché para forzar recarga en el próximo request
redis-cli DEL nxc:policies:core
```

---

## 11. Resumen del flujo completo

```
ARRANQUE
  1. Spring lanza ApplicationReadyEvent
  2. PolicyCacheLoader.loadOnStartup()
  3. RoleApiPolicyCacheService.refreshPolicies()
  4. SpringDataRoleApiPolicyRepository.findByServiceOrderByPriorityDesc("core")
  5. Políticas guardadas en Redis → nxc:policies:core (TTL 5min)

REQUEST HTTP (nexcore-core)
  1. GET /api/v1/users  con X-Actor-Id y X-Tenant-Id
  2. WebConfig dirige al RoleApiPolicyInterceptor.preHandle()
  3. Valida que X-Actor-Id y X-Tenant-Id existan y sean UUIDs válidos
  4. getUserRoles(): Redis → hit/miss → BD → Redis (TTL 2min)
  5. getPolicies(): Redis → hit/miss → BD → Redis (TTL 5min)
  6. isAllowed(): itera políticas por priority DESC
       roleMatches() + methodMatches() + pathMatches()
       → primera coincidencia determina ALLOW o DENY
       → sin coincidencia → DENY (fail-closed)
  7a. ALLOW → return true → Spring MVC ejecuta el controlador
  7b. DENY  → return false → respuesta JSON {status: 403, error: "Access denied"}
```
