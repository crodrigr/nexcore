# NexCore — Arquitectura del nexcore-auth-service

Referencia de patrones, convenciones y flujos del servicio de autenticación.
Usar esta guía al agregar features de seguridad, nuevos flujos de auth, o
integrar con nuevos proveedores.

---

## Datos técnicos

| Item | Valor |
|---|---|
| Puerto | 8081 |
| Grupo | `com.nexore.auth` |
| Spring Boot | 4.0.6 |
| Java | 25 |
| Build | Gradle |
| BD Schema | `nxc_auth` (PostgreSQL) |
| Seguridad | Spring Security + JWT (JJWT 0.12.5) |

---

## Arquitectura Hexagonal (DDD)

```
com.nexore.auth/
├── application/
│   ├── dto/
│   │   ├── request/       ← DTOs de entrada (LoginRequest, VerifyOtpRequest, etc.)
│   │   └── response/      ← DTOs de salida (SessionResponse, ChallengeResponse, etc.)
│   ├── port/
│   │   ├── in/            ← Interfaces de casos de uso (puertos de entrada)
│   │   │                     AuthUseCase, PasswordUseCase
│   │   └── out/           ← Puertos de salida no-persistencia
│   │                         EmailPort, NexcoreCoreClientPort
│   └── service/           ← Implementaciones de casos de uso
│                             AuthService, PasswordService
├── domain/
│   ├── exception/         ← Excepciones de dominio (RuntimeException)
│   ├── model/             ← Entidades de dominio (POJO puro con Lombok)
│   ├── repository/        ← Puertos de salida de persistencia (sin Spring)
│   │                         UserRepository, SessionRepository, etc.
│   └── service/           ← Servicios de dominio (lógica de negocio pura)
│                             TokenService, OtpService, BruteForceProtection
└── infrastructure/
    ├── client/            ← NexcoreCoreClientImpl (implementa NexcoreCoreClientPort)
    ├── config/
    │   └── security/      ← AuthApiPolicyInterceptor, RoleApiPolicyCacheService,
    │                         PolicyCacheLoader, RoleApiPolicyDto
    ├── email/             ← EmailServiceImpl (implementa EmailPort)
    │                         JavaMailSender + Thymeleaf
    ├── persistence/
    │   ├── adapter/       ← Implementaciones de domain/repository/*
    │   │                     *RepositoryAdapter
    │   ├── entity/        ← JPA entities (@Entity, @Table)
    │   ├── jpa/           ← Spring Data interfaces (*JpaRepository)
    │   └── mapper/        ← EntityMapper (dominio ↔ entity)
    └── web/
        ├── AuthController.java
        ├── PasswordController.java
        └── GlobalExceptionHandler.java
```

### Reglas de capas

| Capa | Puede depender de | No puede depender de |
|---|---|---|
| `domain` | Nadie | `application`, `infrastructure` |
| `application` | `domain` | `infrastructure` |
| `infrastructure` | `application`, `domain` | Nadie |

### Clasificación de servicios de dominio vs puertos de salida

| Clase | Tipo | Ubicación correcta |
|---|---|---|
| `TokenService` | Servicio de dominio (lógica JWT pura) | `domain/service/` |
| `OtpService` | Servicio de dominio (hashing + validación OTP) | `domain/service/` |
| `BruteForceProtection` | Servicio de dominio (conteo de intentos) | `domain/service/` |
| `EmailPort` | Puerto de salida (infra externa) | `application/port/out/` |
| `NexcoreCoreClientPort` | Puerto de salida (HTTP externo) | `application/port/out/` |
| `*Repository` | Puerto de salida (persistencia) | `domain/repository/` |

---

## Flujo completo de autenticación

```
1. POST /api/v1/auth/login
   ├── Buscar tenant (tenantId)
   ├── Buscar user (username en tenant)
   ├── BruteForceProtection.checkRateLimit(userId, ip)
   ├── BCrypt.checkpw(password, user.passwordHash)
   ├── OtpService.createLoginOtp(userId, tenantId, username)
   ├── EmailService.sendOtpEmail(email, username, otpCode)
   ├── TokenService.generateChallengeToken(userId, tenantId, otpCodeId)
   └── → ChallengeResponse { challengeToken, expiresIn: 300s }

2. POST /api/v1/auth/verify-otp
   ├── TokenService.validateToken(challengeToken) → Claims
   ├── OtpService.validateOtp(otpCodeId, code)
   ├── TokenService.generateRefreshToken() + hashOtp(token)
   ├── SessionRepository.save(session)
   ├── TokenService.generateAccessToken(userId, tenantId, sessionId)
   ├── NexcoreCoreClient.getUserProfile(accessToken) → profile
   └── → SessionResponse { accessToken (15min), refreshToken (7 días), profile }

3. POST /api/v1/auth/refresh
   ├── hashOtp(refreshToken) → buscar sesión activa
   ├── Verificar sesión no revocada y no expirada
   ├── TokenService.generateAccessToken(userId, tenantId, sessionId)
   ├── NexcoreCoreClient.getUserProfile(accessToken) → profile
   └── → SessionResponse { nuevos tokens, profile }
```

---

## JWT — Claims y configuración

```yaml
# application.yml
nexcore.auth.jwt:
  secret: ${JWT_SECRET}
  access-expiry-seconds: 900      # 15 minutos
  challenge-expiry-seconds: 300   # 5 minutos (OTP)
  refresh-expiry-days: 7
```

**Claims del accessToken:**
```json
{
  "sub": "<userId UUID>",
  "tid": "<tenantId UUID>",
  "sid": "<sessionId UUID>",
  "exp": <timestamp>,
  "iat": <timestamp>
}
```

**Claims del challengeToken:**
```json
{
  "sub": "<userId UUID>",
  "tid": "<tenantId UUID>",
  "otpCodeId": "<otpCodeId UUID>",
  "exp": <timestamp>
}
```

---

## OTP — Configuración y flujo

```yaml
nexcore.auth.otp:
  length: 6
  expiry-minutes: 10
  max-attempts: 5
  fixed:                               # Solo desarrollo
    enabled: true
    code: "111111"
    allowed-usernames: super.admin,test.admin,test.editor
    allowed-tenant-ids: 00000000-0000-0000-0000-000000000002
    allow-in-prod: false
```

**OtpCode entity:** almacena el hash del OTP (no el código en claro), con contador
de intentos y expiración. Después de `max-attempts` errores, el código queda inválido.

---

## Brute Force Protection

```yaml
nexcore.auth.brute-force:
  max-attempts: 10
  window-minutes: 15
```

- Cuenta intentos fallidos por `userId` y por `ipAddress` (tabla `login_attempts`).
- Si supera `max-attempts` en `window-minutes`, lanza `TooManyAttemptsException`.
- Se resetea con `resetAttempts(userId, ip)` al hacer login exitoso.

---

## Modelos de dominio

### User (solo lectura — la fuente es nexcore-core)
```java
UUID id, UUID tenantId, String username, String email,
String passwordHash, boolean active, boolean suspended
```

### Session
```java
UUID id, UUID userId, UUID tenantId,
String refreshTokenHash,  // SHA-256 del refresh token
String ipAddress, String userAgent,
Instant createdAt, Instant expiresAt, Instant revokedAt
```

### OtpCode
```java
UUID id, UUID userId, UUID tenantId, String username,
String codeHash,       // hash del código OTP
String purpose,        // "LOGIN", "PASSWORD_RESET", etc.
int attempts,
Instant expiresAt, Instant usedAt, Instant createdAt
```

### LoginAttempt (auditoría)
```java
UUID id, UUID userId, UUID tenantId, String username,
boolean success, String stage, String ipAddress, Instant attemptedAt
```

### PasswordReset
```java
UUID id, UUID userId, UUID tenantId,
String tokenHash,
Instant expiresAt, Instant usedAt, Instant createdAt
```

---

## Servicios e interfaces

### Servicios de dominio — `domain/service/` (lógica pura, sin dependencias de infra)

| Interface | Responsabilidad |
|---|---|
| `TokenService` | Generar/validar JWT (access, challenge, refresh string) |
| `OtpService` | Crear, validar y hashear OTPs |
| `BruteForceProtection` | Control de intentos fallidos por usuario/IP |

### Puertos de salida — `application/port/out/` (contratos hacia infraestructura externa)

| Interface | Responsabilidad | Implementación en infra |
|---|---|---|
| `EmailPort` | Enviar emails (OTP, password reset, etc.) | `EmailServiceImpl` |
| `NexcoreCoreClientPort` | Obtener perfil del usuario desde nexcore-core | `NexcoreCoreClientImpl` |

### Puertos de entrada — `application/port/in/` (contratos de casos de uso)

| Interface | Responsabilidad | Implementación |
|---|---|---|
| `AuthUseCase` | Login, verify-otp, refresh, logout | `AuthService` |
| `PasswordUseCase` | Change password, reset request, reset confirm | `PasswordService` |

---

## Excepciones de dominio

Cada excepción es un `RuntimeException` específico; **no** usar `BusinessException` del core:

```java
InvalidCredentialsException      // usuario/contraseña incorrectos
InvalidOtpException              // OTP inválido o expirado
UserSuspendedException           // usuario suspendido
TenantNotFoundException          // tenant no existe
TenantInactiveException          // tenant inactivo
SessionNotFoundException         // sesión no encontrada
EmailSendingException            // fallo al enviar email
BruteForceProtection.TooManyAttemptsException
InvalidPasswordResetTokenException
PasswordMismatchException
TooManyPasswordResetAttemptsException
```

`GlobalExceptionHandler` (`@RestControllerAdvice`) vive en `infrastructure/web/` y mapea
las excepciones de dominio a `ApiError` JSON. Spring Security maneja los 401/403 por separado.

---

## Cliente HTTP al nexcore-core

```java
// NexcoreCoreClientImpl usa RestTemplate
// Endpoint configurado en application.yml:
nexcore.core.url: http://localhost:8080
nexcore.core.endpoints.user-profile: /api/v1/me/profile

// Llama con el accessToken recién generado para obtener el perfil completo
// que incluye menus[] y permissions[]
```

---

## Agregar un nuevo flujo de autenticación

1. **Dominio:** crear modelo en `domain/model/`, interfaz de repositorio en `domain/repository/`.
2. **Servicio de dominio** (solo si es lógica de negocio pura): crear interfaz en `domain/service/` e implementación en `infrastructure/`.
3. **Puerto de salida** (si requiere infra externa — HTTP, email, etc.): crear interfaz en `application/port/out/` e implementación en `infrastructure/`.
4. **Puerto de entrada:** agregar método a la interfaz en `application/port/in/` (`AuthUseCase` o `PasswordUseCase`).
5. **Application service:** implementar el caso de uso en `application/service/`.
6. **DTOs:** crear request/response en `application/dto/`.
7. **Controller:** agregar endpoint en `infrastructure/web/`.
8. **Persistencia:** entity → JpaRepository → Adapter implementa `domain/repository/`.
9. **Email (si aplica):** template HTML en `src/main/resources/templates/email/` + método en `EmailPort`.

---

## Convenciones

| Tema | Regla |
|---|---|
| Passwords | `BCrypt.checkpw` para verificar; nunca almacenar en claro |
| Tokens sensibles | Siempre almacenar el **hash** (SHA-256 via `OtpService.hashOtp`), no el valor |
| IPs | Leer de `X-Forwarded-For` primero, luego `request.getRemoteAddr()` |
| Logs | `@Slf4j` en services; no loggear passwords ni tokens en producción |
| OTP fijo | Solo para usuarios específicos y tenants de desarrollo; desactivado en prod |
| Config | Variables de entorno: `DB_USER`, `DB_PASSWORD`, `JWT_SECRET`, `GMAIL_USER`, `GMAIL_PASS`, `CORS_ALLOWED_ORIGINS`, `APP_FRONTEND_URL` |
| Sesiones | Revocar al logout; `expiresAt` se verifica en cada refresh |
| Reset password | `max-requests-per-hour: 0` deshabilita el límite (útil en dev) |
