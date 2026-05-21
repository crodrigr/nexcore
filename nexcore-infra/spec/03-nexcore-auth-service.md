# NexCore — Especificaciones y Criterios de Aceptación
## Servicio: `nexcore-auth-service`
**Versión:** 0.1 (Exploración)
**Tipo:** Microservicio independiente
**Puerto sugerido:** 8081
**Base de datos propia:** `nxc_auth` (schema compartido con nexcore-core vía Postgres)
**Fecha:** 2026-05

---

## 1. Contexto y propósito

`nexcore-auth-service` es el microservicio responsable de todo el ciclo de autenticación y gestión de credenciales de los usuarios de cualquier aplicación construida sobre NexCore. Está diseñado como un servicio independiente del core para permitir escalado, despliegue y mantenimiento autónomo.

### 1.1 Alcance de este documento

Este spec cubre tres flujos funcionales:

| # | Flujo | Descripción |
|---|---|---|
| F-01 | **Login con 2FA vía email** | El usuario ingresa credenciales; si son correctas, recibe un código OTP por email; al validarlo obtiene su perfil de UI |
| F-02 | **Recuperación de contraseña** | El usuario solicita un enlace de restablecimiento por email; lo usa para definir una nueva contraseña |
| F-03 | **Cambio de contraseña** | El usuario autenticado cambia su contraseña actual por una nueva |

### 1.2 Dependencias de dominio

```
nexcore-auth-service → nxc_tenant.users          (identidad, status, email)
                     → nxc_tenant.user_roles      (roles asignados al usuario)
                     → nxc_auth.login_attempts    (registro de intentos)
                     → nxc_auth.otp_codes         (códigos 2FA transitorios)
                     → nxc_auth.refresh_tokens    (tokens de renovación)
                     → nxc_auth.sessions          (sesiones activas)
                     → nxc_auth.password_resets   (tokens de recuperación)
nexcore-auth-service → nexcore-core (HTTP)        (GET /api/v1/me/profile tras login exitoso)
nexcore-auth-service → SMTP / proveedor email     (envío de OTP y enlaces de reset)
```

### 1.3 Relación con nexcore-core

Tras un login exitoso (2FA completado), `nexcore-auth-service` llama a `nexcore-core GET /api/v1/me/profile` para obtener el perfil de UI y lo incluye en la respuesta al cliente. El campo `token` del perfil será el JWT emitido por este servicio.

### 1.4 Infraestructura de correo (SMTP/Postfix)

- El envío de OTP, enlaces de recuperación y confirmaciones se realiza vía **SMTP** usando un servidor Postfix (desarrollo o producción).
- La configuración SMTP se define en variables de entorno/configuración (`application.yml`), nunca en código fuente.
- Se utiliza `spring-boot-starter-mail` (JavaMailSender) para el envío.
- Las plantillas de correo pueden ser Thymeleaf (HTML) o texto plano.
- No se usan proveedores externos de email salvo configuración explícita.

---

## 2. Modelos del dominio (exploración)

### 2.1 Session

Representa una sesión activa de usuario.

| Campo | Tipo | Descripción |
|---|---|---|
| `id` | UUID | Identificador de sesión |
| `userId` | UUID | Usuario autenticado |
| `tenantId` | UUID | Tenant del usuario |
| `accessToken` | String | JWT de corta duración (ej. 15 min) |
| `refreshToken` | String | Token de renovación (ej. 7 días) |
| `createdAt` | Timestamp | Inicio de sesión |
| `expiresAt` | Timestamp | Expiración del refresh token |
| `ipAddress` | String | IP del cliente al momento del login |
| `userAgent` | String | User-Agent del cliente |

### 2.2 OtpCode

Código de un solo uso enviado por email para 2FA.

| Campo | Tipo | Descripción |
|---|---|---|
| `id` | UUID | Identificador |
| `userId` | UUID | Usuario propietario |
| `tenantId` | UUID | Tenant |
| `code` | String | Código numérico de 6 dígitos (hasheado en BD) |
| `purpose` | Enum | `LOGIN_2FA` \| `PASSWORD_RESET` |
| `expiresAt` | Timestamp | Expiración (ej. 10 minutos) |
| `usedAt` | Timestamp | Momento en que fue consumido. `null` si aún válido |
| `attempts` | Integer | Intentos fallidos de ingreso del código |

### 2.3 LoginAttempt

Registro de cada intento de autenticación para protección anti-fuerza-bruta.

| Campo | Tipo | Descripción |
|---|---|---|
| `id` | UUID | Identificador |
| `userId` | UUID | Usuario (puede ser `null` si el username no existe) |
| `tenantId` | UUID | Tenant |
| `username` | String | Username intentado |
| `success` | Boolean | Si el intento fue exitoso |
| `stage` | Enum | `CREDENTIALS` \| `OTP` |
| `ipAddress` | String | IP del cliente |
| `attemptedAt` | Timestamp | Momento del intento |

### 2.4 PasswordReset

Token de recuperación de contraseña.

| Campo | Tipo | Descripción |
|---|---|---|
| `id` | UUID | Identificador |
| `userId` | UUID | Usuario propietario |
| `token` | String | Token URL-safe (hasheado en BD) |
| `expiresAt` | Timestamp | Expiración (ej. 30 minutos) |
| `usedAt` | Timestamp | Momento de uso. `null` si aún válido |
| `ipAddress` | String | IP desde donde se solicitó |

---

## 3. Flujos funcionales

---

### F-01 — Login con 2FA vía email

#### 3.1.1 Descripción del flujo

```
Cliente                      nexcore-auth-service              nexcore-core
  │                                  │                              │
  │── POST /auth/login ─────────────>│                              │
  │   {username, password, tenantId} │                              │
  │                                  │── Valida credenciales        │
  │                                  │── Genera OTP, guarda hash    │
  │                                  │── Envía OTP por email        │
  │<── 200 {challengeToken} ─────────│                              │
  │                                  │                              │
  │── POST /auth/verify-otp ────────>│                              │
  │   {challengeToken, code}         │                              │
  │                                  │── Valida OTP                 │
  │                                  │── Crea sesión (JWT + refresh)│
  │                                  │── GET /api/v1/me/profile ───>│
  │                                  │<── perfil de UI ─────────────│
  │<── 200 {profile + token} ────────│                              │
```

#### 3.1.2 Paso 1 — Validación de credenciales (`POST /auth/login`)

**Request:**
```json
{
  "tenantId": "uuid",
  "username": "string",
  "password": "string"
}
```

**Proceso interno:**
1. Resolver el tenant por `tenantId` → debe estar `ACTIVE`
2. Buscar el usuario por `username` + `tenantId` en `nxc_tenant.users`
3. Verificar que el usuario no esté `SUSPENDED` o `BLOCKED`
4. Verificar la contraseña contra el hash almacenado (bcrypt)
5. Verificar límite de intentos fallidos (anti-brute-force)
6. Generar un `challengeToken` (JWT temporal de corta duración, p.ej. 5 minutos, sin acceso a recursos)
7. Generar código OTP de 6 dígitos, hashear y guardar en `nxc_auth.otp_codes` con TTL 10 min
8. Enviar el código por email al correo del usuario
9. Registrar el intento en `nxc_auth.login_attempts` (stage: CREDENTIALS, success: true)

**Response exitoso (200):**
```json
{
  "challengeToken": "jwt-string",
  "message": "Código de verificación enviado al correo registrado",
  "expiresIn": 300
}
```

**Errores:**

| Código | HTTP | Condición |
|---|---|---|
| `NXC-AUTH-0001` | 401 | Credenciales incorrectas (username o password inválido) |
| `NXC-AUTH-0002` | 403 | Usuario suspendido o bloqueado |
| `NXC-AUTH-0003` | 403 | Tenant inactivo |
| `NXC-AUTH-0004` | 429 | Demasiados intentos fallidos (anti-brute-force) |
| `NXC-AUTH-0005` | 503 | Error al enviar email (el OTP no fue enviado) |

> **Seguridad:** Ante credenciales incorrectas, siempre retornar el mismo mensaje genérico ("Credenciales incorrectas"), sin indicar si el usuario existe o no.

---

#### 3.1.3 Paso 2 — Verificación OTP (`POST /auth/verify-otp`)

**Request:**
```json
{
  "challengeToken": "jwt-string",
  "code": "123456"
}
```

**Proceso interno:**
1. Validar y decodificar `challengeToken` (debe ser válido y no expirado)
2. Buscar el OTP activo del usuario (purpose: LOGIN_2FA, no usado, no expirado)
3. Comparar el `code` con el hash almacenado
4. Registrar intento en `nxc_auth.login_attempts` (stage: OTP)
5. Si correcto: marcar el OTP como usado, crear sesión, emitir JWT de acceso y refresh token
6. Llamar a `nexcore-core GET /api/v1/me/profile` con los headers `X-Tenant-Id` y `X-Actor-Id`
7. Retornar perfil completo con `token` = JWT de acceso

**Response exitoso (200):**
```json
{
  "token": "jwt-access-token",
  "refreshToken": "refresh-token-opaco",
  "expiresIn": 900,
  "profile": { /* objeto UserProfile de nexcore-core */ }
}
```

**Errores:**

| Código | HTTP | Condición |
|---|---|---|
| `NXC-AUTH-0006` | 401 | `challengeToken` inválido o expirado |
| `NXC-AUTH-0007` | 401 | Código OTP incorrecto |
| `NXC-AUTH-0008` | 401 | Código OTP expirado |
| `NXC-AUTH-0009` | 429 | Demasiados intentos fallidos de OTP (bloquear tras N intentos) |

---

### F-02 — Recuperación de contraseña

#### 3.2.1 Paso 1 — Solicitud de reset (`POST /auth/password-reset/request`)

**Request:**
```json
{
  "tenantId": "uuid",
  "email": "string"
}
```

**Proceso interno:**
1. Buscar el usuario por `email` + `tenantId`
2. Si no existe: **no revelar** — responder igual que si existiera
3. Si existe y está activo: generar token URL-safe, hashear y guardar en `nxc_auth.password_resets` con TTL 30 min
4. Enviar email con enlace: `https://app.nexcore.com/reset-password?token={token-plano}`
5. Invalidar tokens de reset anteriores del mismo usuario

**Response (200 siempre, incluso si el email no existe):**
```json
{
  "message": "Si el correo está registrado, recibirás un enlace para restablecer tu contraseña"
}
```

**Errores:**

| Código | HTTP | Condición |
|---|---|---|
| `NXC-AUTH-0010` | 429 | Demasiadas solicitudes de reset en un período corto |
| `NXC-AUTH-0011` | 503 | Error al enviar email |

---

#### 3.2.2 Paso 2 — Confirmación de reset (`POST /auth/password-reset/confirm`)

**Request:**
```json
{
  "token": "token-plano-del-email",
  "newPassword": "string",
  "confirmPassword": "string"
}
```

**Proceso interno:**
1. Hashear el token recibido y buscar en `nxc_auth.password_resets`
2. Validar que no esté usado ni expirado
3. Validar que `newPassword == confirmPassword`
4. Validar política de contraseñas (ver §7)
5. Actualizar el hash de contraseña en `nxc_tenant.users`
6. Marcar el token como usado
7. Invalidar todas las sesiones activas del usuario (logout forzado)
8. Enviar email de confirmación de cambio de contraseña

**Response exitoso (200):**
```json
{
  "message": "Contraseña restablecida correctamente. Por favor inicia sesión."
}
```

**Errores:**

| Código | HTTP | Condición |
|---|---|---|
| `NXC-AUTH-0012` | 400 | Token inválido o ya utilizado |
| `NXC-AUTH-0013` | 400 | Token expirado |
| `NXC-AUTH-0014` | 400 | Las contraseñas no coinciden |
| `NXC-AUTH-0015` | 400 | La contraseña no cumple la política de seguridad |

---

### F-03 — Cambio de contraseña (usuario autenticado)

#### 3.3.1 Descripción (`PUT /auth/password`)

El usuario ya tiene sesión activa y desea cambiar su contraseña voluntariamente.

**Headers requeridos:**
```
Authorization: Bearer {accessToken}
```

**Request:**
```json
{
  "currentPassword": "string",
  "newPassword": "string",
  "confirmPassword": "string"
}
```

**Proceso interno:**
1. Validar el JWT del header
2. Verificar `currentPassword` contra el hash actual en BD
3. Validar que `newPassword != currentPassword` (no reutilizar)
4. Validar que `newPassword == confirmPassword`
5. Validar política de contraseñas (ver §7)
6. Actualizar el hash en `nxc_tenant.users`
7. Invalidar todas las sesiones activas excepto la actual (o todas, según configuración)
8. Enviar email de notificación de cambio

**Response exitoso (200):**
```json
{
  "message": "Contraseña actualizada correctamente"
}
```

**Errores:**

| Código | HTTP | Condición |
|---|---|---|
| `NXC-AUTH-0016` | 401 | Token inválido o expirado |
| `NXC-AUTH-0017` | 400 | Contraseña actual incorrecta |
| `NXC-AUTH-0018` | 400 | La nueva contraseña es igual a la actual |
| `NXC-AUTH-0019` | 400 | Las contraseñas no coinciden |
| `NXC-AUTH-0020` | 400 | La contraseña no cumple la política de seguridad |

---

## 4. Criterios de aceptación

### CA-01 — Login con 2FA

| ID | Criterio |
|---|---|
| CA-01-01 | Dado un usuario activo con credenciales correctas, el sistema envía el OTP al email registrado y retorna `challengeToken` en <= 3 segundos |
| CA-01-02 | Dado un `challengeToken` válido y un OTP correcto, el sistema retorna el perfil de UI completo con un JWT de acceso válido |
| CA-01-03 | Dado un OTP incorrecto, el sistema retorna 401 e incrementa el contador de intentos fallidos del OTP |
| CA-01-04 | Dado 5 intentos fallidos de OTP consecutivos, el sistema bloquea el `challengeToken` y retorna 429 |
| CA-01-05 | Dado un OTP correcto pero expirado (> 10 min), el sistema retorna 401 con código `NXC-AUTH-0008` |
| CA-01-06 | Dado un `challengeToken` expirado (> 5 min), el sistema retorna 401 con código `NXC-AUTH-0006` sin importar el OTP |
| CA-01-07 | Dado 10 intentos fallidos de credenciales desde la misma IP en 15 minutos, el sistema retorna 429 |
| CA-01-08 | Un OTP no puede ser reutilizado: si ya fue consumido, el sistema retorna 401 |
| CA-01-09 | El endpoint de login siempre retorna el mismo tiempo de respuesta ante usuario existente o inexistente (timing-safe) |
| CA-01-10 | El `challengeToken` no otorga acceso a ningún recurso protegido: es inválido fuera del flujo 2FA |

### CA-02 — Recuperación de contraseña

| ID | Criterio |
|---|---|
| CA-02-01 | La respuesta de solicitud de reset es idéntica si el email existe o no (no revela existencia) |
| CA-02-02 | El token de reset expira a los 30 minutos de su generación |
| CA-02-03 | El token de reset es de un solo uso: un segundo intento con el mismo token retorna 400 |
| CA-02-04 | Al confirmar el reset, todas las sesiones activas del usuario son invalidadas |
| CA-02-05 | Una nueva solicitud de reset invalida tokens de reset anteriores del mismo usuario |
| CA-02-06 | El email de confirmación de cambio se envía al correo del usuario tras el reset exitoso |
| CA-02-07 | No se permiten más de 3 solicitudes de reset por usuario en un período de 1 hora (CA: 429) |

### CA-03 — Cambio de contraseña

| ID | Criterio |
|---|---|
| CA-03-01 | El cambio requiere sesión activa válida (JWT no expirado) |
| CA-03-02 | La contraseña actual debe coincidir con el hash en BD |
| CA-03-03 | La nueva contraseña no puede ser igual a la actual |
| CA-03-04 | Tras el cambio exitoso, se envía email de notificación al usuario |
| CA-03-05 | Tras el cambio, las demás sesiones activas del usuario son invalidadas |

### CA-04 — Política de contraseñas

| ID | Criterio |
|---|---|
| CA-04-01 | Mínimo 8 caracteres |
| CA-04-02 | Al menos una letra mayúscula |
| CA-04-03 | Al menos una letra minúscula |
| CA-04-04 | Al menos un número |
| CA-04-05 | Al menos un carácter especial (`!@#$%^&*()_+-=[]{}`) |
| CA-04-06 | Máximo 128 caracteres |

---

## 5. Contratos de API (resumen)

| Método | Endpoint | Auth | Descripción |
|---|---|---|---|
| POST | `/auth/login` | — | Paso 1: valida credenciales, envía OTP |
| POST | `/auth/verify-otp` | challengeToken | Paso 2: valida OTP, retorna sesión + perfil |
| POST | `/auth/refresh` | refreshToken | Renueva el accessToken usando refreshToken |
| DELETE | `/auth/logout` | Bearer JWT | Cierra la sesión actual |
| POST | `/auth/password-reset/request` | — | Solicita enlace de reset por email |
| POST | `/auth/password-reset/confirm` | resetToken | Confirma el nuevo password con el token |
| PUT | `/auth/password` | Bearer JWT | Cambia la contraseña (usuario autenticado) |

---

## 6. JWT — Estructura del token de acceso

El `accessToken` emitido tras un login exitoso tiene la siguiente estructura de payload:

```json
{
  "sub": "uuid-usuario",
  "tid": "uuid-tenant",
  "roles": ["TENANT_ADMIN"],
  "sid": "uuid-sesion",
  "iat": 1716123456,
  "exp": 1716124356
}
```

| Claim | Descripción |
|---|---|
| `sub` | ID del usuario (`nxc_tenant.users.id`) |
| `tid` | ID del tenant |
| `roles` | Lista de nombres de roles activos |
| `sid` | ID de sesión (para invalidación selectiva) |
| `iat` | Issued at |
| `exp` | Expira a los 15 minutos de emisión |

El `refreshToken` es un token opaco (UUID v4), almacenado hasheado en `nxc_auth.refresh_tokens`, con TTL de 7 días.

---

## 7. Consideraciones de seguridad

| Aspecto | Decisión |
|---|---|
| Hash de contraseñas | bcrypt con cost factor 12 |
| Hash de OTP y tokens | SHA-256 antes de almacenar en BD |
| OTP | 6 dígitos numéricos, generados con `SecureRandom` |
| Timing-safe comparisons | Usar comparación en tiempo constante para OTP y tokens |
| Anti-brute-force | Rate limiting por IP y por usuario, registro en `login_attempts` |
| HTTPS | Requerido en todos los ambientes (excepto localhost dev) |
| Rotación de refresh token | Emitir nuevo refresh token en cada renovación (rotation) |
| Expiración de sesión | accessToken: 15 min. refreshToken: 7 días |

---

## 8. Estructura del microservicio (propuesta)

```
nexcore-auth-service/
├── src/main/java/com/nexcore/auth/
│   ├── NexcoreAuthApplication.java
│   ├── domain/
│   │   ├── model/
│   │   │   ├── Session.java
│   │   │   ├── OtpCode.java
│   │   │   ├── LoginAttempt.java
│   │   │   └── PasswordReset.java
│   │   ├── repository/
│   │   │   ├── SessionRepository.java
│   │   │   ├── OtpCodeRepository.java
│   │   │   ├── LoginAttemptRepository.java
│   │   │   └── PasswordResetRepository.java
│   │   └── service/
│   │       ├── TokenService.java          ← genera/valida JWT y refresh tokens
│   │       ├── OtpService.java            ← genera/valida códigos OTP
│   │       └── BruteForceProtection.java  ← lógica anti-brute-force
│   ├── application/
│   │   ├── service/
│   │   │   ├── AuthService.java           ← orquesta F-01 (login + 2FA)
│   │   │   └── PasswordService.java       ← orquesta F-02 y F-03
│   │   └── dto/
│   │       ├── request/
│   │       │   ├── LoginRequest.java
│   │       │   ├── VerifyOtpRequest.java
│   │       │   ├── PasswordResetRequest.java
│   │       │   ├── PasswordResetConfirmRequest.java
│   │       │   └── ChangePasswordRequest.java
│   │       └── response/
│   │           ├── ChallengeResponse.java
│   │           └── SessionResponse.java
│   └── infrastructure/
│       ├── web/
│       │   ├── AuthController.java
│       │   └── PasswordController.java
│       ├── email/
│       │   └── EmailService.java          ← envío de OTP y enlaces
│       ├── client/
│       │   └── NexcoreCoreClient.java     ← llama GET /api/v1/me/profile
│       └── persistence/
│           └── jpa/                       ← repositorios JPA para nxc_auth.*
├── src/main/resources/
│   ├── application.yml
│   └── db/migration/
│       ├── V001__auth_schema.sql          ← CREATE SCHEMA nxc_auth
│       └── V002__auth_tables.sql          ← tablas sessions, otp_codes, etc.
└── src/test/java/com/nexcore/auth/
    ├── AuthServiceTest.java
    ├── OtpServiceTest.java
    ├── PasswordServiceTest.java
    └── AuthControllerTest.java
```

---

## 9. Tablas de base de datos requeridas (schema `nxc_auth`)

### `nxc_auth.otp_codes`

| Columna | Tipo | Descripción |
|---|---|---|
| `id` | UUID PK | Identificador |
| `user_id` | UUID FK | Referencia a `nxc_tenant.users` |
| `tenant_id` | UUID | Tenant del usuario |
| `code_hash` | VARCHAR(255) | Hash SHA-256 del código enviado |
| `purpose` | ENUM | `LOGIN_2FA`, `PASSWORD_RESET` |
| `expires_at` | TIMESTAMPTZ | Expiración |
| `used_at` | TIMESTAMPTZ NULL | Cuándo fue consumido |
| `attempts` | INTEGER | Intentos fallidos |
| `created_at` | TIMESTAMPTZ | Creación |

### `nxc_auth.sessions`

| Columna | Tipo | Descripción |
|---|---|---|
| `id` | UUID PK | Identificador de sesión |
| `user_id` | UUID FK | Usuario |
| `tenant_id` | UUID | Tenant |
| `refresh_token_hash` | VARCHAR(255) | Hash del refresh token |
| `ip_address` | VARCHAR(45) | IP del cliente |
| `user_agent` | TEXT | User-Agent |
| `expires_at` | TIMESTAMPTZ | Expiración del refresh token |
| `revoked_at` | TIMESTAMPTZ NULL | Cuándo fue revocada |
| `created_at` | TIMESTAMPTZ | Creación |

### `nxc_auth.login_attempts`

| Columna | Tipo | Descripción |
|---|---|---|
| `id` | UUID PK | Identificador |
| `user_id` | UUID NULL | Usuario (null si username no existe) |
| `tenant_id` | UUID | Tenant |
| `username` | VARCHAR(150) | Username intentado |
| `success` | BOOLEAN | Si fue exitoso |
| `stage` | ENUM | `CREDENTIALS`, `OTP` |
| `ip_address` | VARCHAR(45) | IP |
| `attempted_at` | TIMESTAMPTZ | Momento |

### `nxc_auth.password_resets`

| Columna | Tipo | Descripción |
|---|---|---|
| `id` | UUID PK | Identificador |
| `user_id` | UUID FK | Usuario |
| `token_hash` | VARCHAR(255) | Hash SHA-256 del token enviado por email |
| `expires_at` | TIMESTAMPTZ | Expiración (30 min) |
| `used_at` | TIMESTAMPTZ NULL | Cuándo fue consumido |
| `ip_address` | VARCHAR(45) | IP de la solicitud |
| `created_at` | TIMESTAMPTZ | Creación |

---

## 10. Pendientes / decisiones abiertas

| # | Tema | Descripción |
|---|---|---|
| P-01 | Proveedor de email | Definir si se usa SMTP propio, SendGrid, AWS SES u otro |
| P-02 | Integración Okta | El árbol de archivos propone Okta como IdP externo opcional; evaluar si aplica al MVP |
| P-03 | Plantillas de email | Diseño HTML de los emails de OTP, reset y notificación de cambio |
| P-04 | Rate limiting | Definir si se implementa en el servicio o en un API Gateway |
| P-05 | Redis | Evaluar uso de Redis para blacklist de tokens JWT y cache de intentos fallidos |
| P-06 | nexcore-core integration | Definir si el auth-service llama a core vía HTTP o si core lee el JWT directamente |
| P-07 | Política de contraseñas por tenant | Permitir que cada tenant configure su propia política de contraseñas |
| P-08 | MFA app (TOTP) | Evaluar soporte futuro de autenticadores (Google Authenticator, etc.) además del email |
