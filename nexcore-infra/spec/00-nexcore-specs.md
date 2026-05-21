# NexCore — Especificación General
**Versión:** 0.2  
**Fecha:** 2026-05  
**Estado:** En desarrollo activo

---

## 1. Visión general

NexCore es una **base de ingeniería** para construir aplicaciones empresariales escalables, mantenibles y distribuidas. No está atado a ningún dominio de negocio específico: es el casco estructural sobre el que se levanta cualquier producto, proveyendo desde el primer día los patrones, la seguridad y la infraestructura que un proyecto de alta ingeniería necesita.

Está construido como un conjunto de microservicios y un monolito modular (`nexcore-core`), con un frontend Angular que consume una API unificada a través de un gateway. El desarrollador arranca con la estructura resuelta y se concentra en el dominio de su negocio.

### 1.1 Qué resuelve NexCore

| Problema común | Solución incluida |
|---|---|
| Multi-tenancy desde cero | PostgreSQL RLS + `nxc_tenant` schema |
| Autenticación segura con 2FA | `nexcore-auth-service` con JWT + OTP email |
| Permisos dinámicos de UI | `module-menu`: roles → componentes → elementos → menús |
| Auditoría de cambios | `nexcore-audit-service` (Kafka + MongoDB) |
| Notificaciones en tiempo real | `nexcore-notification-service` (STOMP/WebSocket) |
| Gateway unificado | `nexcore-gateway` con rate limiting, JWT validation, CORS |
| Frontend estructurado | Angular 18 + Nx con design system y feature libs |
| IaC lista para producción | Helm + Terraform + GitHub Actions |

### 1.2 Principios de diseño

- **Multi-tenant con Row-Level Security**: cada tenant solo accede a sus datos vía PostgreSQL RLS
- **Arquitectura hexagonal** en todos los servicios backend (domain → application → infrastructure)
- **Permisos dinámicos**: roles → componentes de UI → elementos → menús, sin hard-coding en frontend
- **Sin secretos en código**: configuración por variables de entorno / Vault en producción
- **Dominio-agnóstico**: los módulos base (tenant, menu, auth, config) son genéricos; el negocio se añade encima

### 1.3 Envío de correos (SMTP/Postfix)

- Todos los correos transaccionales (OTP, recuperación, notificaciones) se envían vía **SMTP** usando un servidor Postfix corporativo o de desarrollo.
- La configuración SMTP (host, puerto, usuario, contraseña, TLS) se define por variables de entorno o archivos de configuración (`application.yml`).
- El servicio usa `spring-boot-starter-mail` (JavaMailSender) para enviar los correos.
- Las plantillas pueden ser HTML (Thymeleaf) o texto plano, según la configuración del proyecto.
- No se debe usar ningún proveedor externo (SendGrid, SES, etc.) salvo que se indique explícitamente.

---

## 2. Servicios y estado actual

| Servicio | Tecnología | Puerto | Estado | Spec |
|---|---|---|---|---|
| `nexcore-gateway` | Spring Cloud Gateway (WebFlux) | 8080 | Pendiente | — |
| `nexcore-auth-service` | Spring Boot MVC | 8081 | En diseño | [03-nexcore-auth-service.md](03-nexcore-auth-service.md) |
| `nexcore-core` | Spring Boot MVC | 8082 | En desarrollo | [01-module-tenant](01-nexcore-core-module-tenant-specs.md) · [02-module-menu](02-nexcore-core-module-menu-specs.md) |
| `nexcore-audit-service` | WebFlux + MongoDB + Kafka | 8083 | Pendiente | — |
| `nexcore-notification-service` | WebFlux + STOMP + Kafka | 8084 | Pendiente | — |
| `nexcore-reporting` | Spring Boot MVC | 8085 | Pendiente | — |
| `nexcore-admin` | Spring Boot MVC + Security | 8086 | Pendiente | — |
| `nexcore-commons` | Librería JAR compartida | — | Pendiente | — |
| `nexcore-frontend` | Angular 18 (Nx workspace) | 4200 | En desarrollo | — |

---

## 3. Stack tecnológico base

| Componente | Tecnología | Versión |
|---|---|---|
| Lenguaje | Java | 25 |
| Framework | Spring Boot | 4.0.6 |
| Build | Gradle | 9.x |
| Base de datos | PostgreSQL | 15 |
| Seguridad BD | Row-Level Security (RLS) | — |
| Migraciones | Flyway | — |
| Frontend | Angular + Nx | 18 |
| Contenedores | Docker + Compose | — |
| Orquestación | Kubernetes + Helm | — |
| IaC | Terraform | — |
| CI/CD | GitHub Actions | — |
| Observabilidad | Prometheus + Grafana + Jaeger + Loki | — |

---

## 4. Dependencias por servicio — Spring Initializr

### 4.1 Dependencias seleccionables en [start.spring.io](https://start.spring.io)

| Dependencia (nombre en Initializr) | commons | gateway | auth | audit | notification | core | reporting | admin |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **Spring Web** (MVC) | | | ✓ | | | ✓ | ✓ | ✓ |
| **Spring Reactive Web** (WebFlux) | | ✓ | | ✓ | ✓ | | | |
| **Spring Security** | | ✓ | ✓ | | | | | ✓ |
| **Spring Data JPA** | | | ✓ | | | ✓ | ✓ | ✓ |
| **Spring Data R2DBC** | | | | ✓ | | | | |
| **Spring Data MongoDB Reactive** | | | | ✓ | | | | |
| **Flyway Migration** | | | ✓ | | | ✓ | | |
| **Validation** | | | ✓ | | ✓ | ✓ | ✓ | ✓ |
| **Java Mail Sender** | | | ✓ | | ✓ | | | |
| **Spring Boot Actuator** | | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **PostgreSQL Driver** | | | ✓ | ✓ | | ✓ | ✓ | ✓ |
| **Spring Data Redis** | | ✓ | | | ✓ | | | |
| **Lombok** | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **Spring Boot DevTools** | | | ✓ | | | ✓ | ✓ | ✓ |
| **H2 Database** (test) | | | ✓ | | | ✓ | ✓ | ✓ |
| **Thymeleaf** | | | ✓ | | ✓ | | | |

### 4.2 Dependencias manuales (no disponibles en Initializr)

| Dependencia | Versión | Servicio(s) | Motivo |
|---|---|---|---|
| `io.jsonwebtoken:jjwt-api` | 0.12.6 | auth, gateway | Generación de JWT |
| `io.jsonwebtoken:jjwt-impl` | 0.12.6 | auth, gateway | Implementación JJWT (runtime) |
| `io.jsonwebtoken:jjwt-jackson` | 0.12.6 | auth, gateway | Serialización JWT (runtime) |
| `spring-cloud-starter-gateway` | — | gateway | Routing reactivo (reemplaza spring-web) |
| `com.icegreen:greenmail-junit5` | 2.1.2 | auth, notification | SMTP embebido para tests |
| `org.springframework.security:spring-security-test` | — | auth, admin | Tests con contexto de seguridad |
| `io.github.bucket4j:bucket4j-core` | — | gateway, auth | Rate limiting |

### 4.3 `nexcore-core` — build.gradle actual

```gradle
plugins {
    id 'java'
    id 'org.springframework.boot' version '4.0.6'
    id 'io.spring.dependency-management' version '1.1.7'
}

group = 'com.nexore'
version = '0.0.1-SNAPSHOT'

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(25)
    }
}

dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-webmvc'
    implementation 'org.springframework.boot:spring-boot-starter-data-jpa'
    implementation 'org.springframework.boot:spring-boot-starter-validation'
    compileOnly 'org.projectlombok:lombok'
    developmentOnly 'org.springframework.boot:spring-boot-devtools'
    runtimeOnly 'org.postgresql:postgresql'
    annotationProcessor 'org.projectlombok:lombok'
    testImplementation 'org.springframework.boot:spring-boot-starter-webmvc-test'
    testCompileOnly 'org.projectlombok:lombok'
    testAnnotationProcessor 'org.projectlombok:lombok'
    testRuntimeOnly 'org.junit.platform:junit-platform-launcher'
    testRuntimeOnly 'com.h2database:h2'
}
```

### 4.4 `nexcore-auth-service` — build.gradle propuesto

```gradle
plugins {
    id 'java'
    id 'org.springframework.boot' version '4.0.6'
    id 'io.spring.dependency-management' version '1.1.7'
}

group = 'com.nexore'
version = '0.0.1-SNAPSHOT'

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(25)
    }
}

dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-webmvc'
    implementation 'org.springframework.boot:spring-boot-starter-security'
    implementation 'org.springframework.boot:spring-boot-starter-data-jpa'
    implementation 'org.springframework.boot:spring-boot-starter-validation'
    implementation 'org.springframework.boot:spring-boot-starter-mail'
    implementation 'org.springframework.boot:spring-boot-starter-actuator'
    implementation 'org.flywaydb:flyway-database-postgresql'

    // JWT
    implementation 'io.jsonwebtoken:jjwt-api:0.12.6'
    runtimeOnly 'io.jsonwebtoken:jjwt-impl:0.12.6'
    runtimeOnly 'io.jsonwebtoken:jjwt-jackson:0.12.6'

    runtimeOnly 'org.postgresql:postgresql'
    compileOnly 'org.projectlombok:lombok'
    developmentOnly 'org.springframework.boot:spring-boot-devtools'
    annotationProcessor 'org.projectlombok:lombok'

    testImplementation 'org.springframework.boot:spring-boot-starter-webmvc-test'
    testImplementation 'org.springframework.security:spring-security-test'
    testImplementation 'com.icegreen:greenmail-junit5:2.1.2'
    testCompileOnly 'org.projectlombok:lombok'
    testAnnotationProcessor 'org.projectlombok:lombok'
    testRuntimeOnly 'org.junit.platform:junit-platform-launcher'
    testRuntimeOnly 'com.h2database:h2'
}
```

---

## 5. Schemas de base de datos

Todos los servicios comparten la misma instancia PostgreSQL (en desarrollo). Cada servicio tiene su propio schema:

| Schema | Dueño | Contenido |
|---|---|---|
| `nxc_tenant` | nexcore-core | Tenants, usuarios, roles, user_roles |
| `nxc_menu` | nexcore-core | Menús, componentes, permisos, elements |
| `nxc_config` | nexcore-core | Feature flags, configuración dinámica |
| `nxc_preference` | nexcore-core | Preferencias de usuario |
| `nxc_auth` | nexcore-auth-service | Sesiones, OTP, login_attempts, password_resets |
| `public` | — | Sin uso (evitar) |

---

## 6. Árbol general del proyecto

> Estado actual: `✓` implementado · `⚙` en desarrollo · `○` pendiente

```
nexcore/
│
├── nexcore-commons/                          ○ librería compartida (jar)
│   └── src/main/java/com/nexcore/commons/
│       ├── audit/
│       │   ├── AuditEvent.java
│       │   ├── AuditEventBuilder.java
│       │   ├── AuditableSdk.java
│       │   └── Audited.java                  ← @Audited(entity="User")
│       ├── notification/
│       │   ├── NotificationCommand.java
│       │   ├── NotificationSdk.java
│       │   └── NotificationBuilder.java
│       ├── security/
│       │   ├── TenantContext.java
│       │   ├── CurrentUser.java
│       │   └── NexcoreAuthority.java         ← constantes: users:read, etc.
│       ├── messaging/
│       │   ├── KafkaTopics.java
│       │   └── NexcoreKafkaTemplate.java
│       └── validation/
│           ├── NxcValidator.java
│           └── TenantExists.java
│
├── nexcore-gateway/                          ○ Spring Cloud Gateway (WebFlux)
│   └── src/main/java/com/nexcore/gateway/
│       ├── NexcoreGatewayApplication.java
│       ├── config/
│       │   ├── GatewayRoutesConfig.java      ← /auth→8081, /api→8082
│       │   ├── RateLimitConfig.java
│       │   ├── CorsConfig.java
│       │   └── CircuitBreakerConfig.java
│       └── filter/
│           ├── JwtValidationFilter.java
│           ├── TenantResolutionFilter.java
│           ├── RequestIdFilter.java
│           ├── LoggingFilter.java
│           └── RateLimitFilter.java
│
├── nexcore-auth-service/                     ○ En diseño (ver spec 03)
│   └── src/main/java/com/nexcore/auth/
│       ├── NexcoreAuthApplication.java
│       ├── config/
│       │   ├── SecurityConfig.java
│       │   └── JwtConfig.java
│       ├── domain/
│       │   ├── model/
│       │   │   ├── Session.java
│       │   │   ├── OtpCode.java
│       │   │   ├── LoginAttempt.java
│       │   │   └── PasswordReset.java
│       │   ├── repository/
│       │   │   ├── SessionRepository.java
│       │   │   ├── OtpCodeRepository.java
│       │   │   ├── LoginAttemptRepository.java
│       │   │   └── PasswordResetRepository.java
│       │   └── service/
│       │       ├── TokenService.java
│       │       ├── OtpService.java
│       │       └── BruteForceProtection.java
│       ├── application/
│       │   ├── service/
│       │   │   ├── AuthService.java
│       │   │   └── PasswordService.java
│       │   └── dto/
│       │       ├── request/
│       │       │   ├── LoginRequest.java
│       │       │   ├── VerifyOtpRequest.java
│       │       │   ├── PasswordResetRequest.java
│       │       │   ├── PasswordResetConfirmRequest.java
│       │       │   └── ChangePasswordRequest.java
│       │       └── response/
│       │           ├── ChallengeResponse.java
│       │           └── SessionResponse.java
│       └── infrastructure/
│           ├── web/
│           │   ├── AuthController.java
│           │   └── PasswordController.java
│           ├── email/
│           │   └── EmailService.java
│           ├── client/
│           │   └── NexcoreCoreClient.java    ← RestClient → GET /api/v1/me/profile
│           └── persistence/jpa/
│               └── (repositorios nxc_auth.*)
│
├── nexcore-audit-service/                    ○ pendiente
│   └── src/main/java/com/nexcore/audit/
│       ├── NexcoreAuditApplication.java
│       ├── domain/
│       │   ├── model/
│       │   │   ├── AuditRecord.java          ← @Document MongoDB
│       │   │   └── AuditSnapshot.java
│       │   └── repository/
│       │       └── AuditRecordRepository.java
│       ├── application/
│       │   └── service/
│       │       ├── AuditIngestionService.java
│       │       └── AuditQueryService.java
│       └── infrastructure/
│           ├── kafka/
│           │   └── AuditEventConsumer.java   ← @KafkaListener
│           └── web/
│               └── AuditController.java
│
├── nexcore-notification-service/             ○ pendiente
│   └── src/main/java/com/nexcore/notification/
│       ├── NexcoreNotificationApplication.java
│       ├── domain/
│       │   └── model/
│       │       ├── Notification.java
│       │       └── NotificationChannel.java  ← IN_APP | EMAIL | PUSH
│       └── infrastructure/
│           ├── kafka/
│           │   └── NotificationEventConsumer.java
│           └── websocket/
│               ├── WebSocketConfig.java      ← STOMP
│               └── NotificationWebSocketHandler.java
│
├── nexcore-core/                             ⚙ en desarrollo activo
│   ├── build.gradle
│   ├── settings.gradle
│   └── src/
│       ├── main/
│       │   ├── java/com/nexore/core/
│       │   │   ├── CoreApplication.java
│       │   │   │
│       │   │   └── module/
│       │   │       ├── tenant/               ✓ implementado (ver spec 01)
│       │   │       │   ├── domain/
│       │   │       │   │   ├── model/
│       │   │       │   │   │   ├── Tenant.java
│       │   │       │   │   │   ├── User.java
│       │   │       │   │   │   ├── Role.java
│       │   │       │   │   │   └── UserRole.java
│       │   │       │   │   └── repository/
│       │   │       │   │       ├── TenantRepository.java
│       │   │       │   │       ├── UserRepository.java
│       │   │       │   │       └── RoleRepository.java
│       │   │       │   ├── application/
│       │   │       │   │   ├── dto/
│       │   │       │   │   │   ├── request/
│       │   │       │   │   │   └── response/
│       │   │       │   │   ├── exception/
│       │   │       │   │   │   ├── ApiError.java
│       │   │       │   │   │   └── BusinessException.java  ← códigos NXC-TNT-* y NXC-MNU-*
│       │   │       │   │   ├── mapper/
│       │   │       │   │   │   ├── TenantMapper.java
│       │   │       │   │   │   ├── UserMapper.java
│       │   │       │   │   │   └── RoleMapper.java
│       │   │       │   │   └── service/
│       │   │       │   │       ├── TenantService.java
│       │   │       │   │       ├── UserService.java
│       │   │       │   │       └── RoleService.java
│       │   │       │   └── infrastructure/
│       │   │       │       ├── persistence/
│       │   │       │       └── web/
│       │   │       │           ├── TenantController.java
│       │   │       │           ├── UserController.java
│       │   │       │           └── RoleController.java
│       │   │       │
│       │   │       └── menu/                 ✓ implementado (ver spec 02)
│       │   │           ├── domain/
│       │   │           │   ├── model/
│       │   │           │   │   ├── AccessLevel.java      ← HIDDEN|VIEW|EXECUTE + @JsonValue
│       │   │           │   │   ├── MenuItemType.java     ← GROUP|ITEM|DIVIDER|EXTERNAL_LINK
│       │   │           │   │   ├── UserInfo.java
│       │   │           │   │   ├── ElementPermission.java
│       │   │           │   │   ├── ComponentPermission.java
│       │   │           │   │   ├── MenuItem.java         ← incluye location
│       │   │           │   │   └── UserProfile.java
│       │   │           │   └── repository/
│       │   │           │       └── UserProfileRepository.java  ← puerto
│       │   │           ├── application/
│       │   │           │   ├── dto/response/
│       │   │           │   │   ├── UserProfileResponse.java
│       │   │           │   │   ├── UserInfoResponse.java
│       │   │           │   │   ├── ComponentPermissionResponse.java
│       │   │           │   │   ├── ElementPermissionResponse.java
│       │   │           │   │   └── MenuItemResponse.java
│       │   │           │   ├── mapper/
│       │   │           │   │   └── UserProfileMapper.java
│       │   │           │   └── service/
│       │   │           │       └── UserProfileService.java
│       │   │           └── infrastructure/
│       │   │               ├── persistence/
│       │   │               │   ├── jpa/
│       │   │               │   │   └── UserProfileQueryRepository.java  ← EntityManager nativo
│       │   │               │   ├── mapper/
│       │   │               │   │   └── UserProfilePersistenceMapper.java
│       │   │               │   └── JpaUserProfileRepositoryAdapter.java
│       │   │               └── web/
│       │   │                   └── UserProfileController.java  ← GET /api/v1/me/profile
│       │   │
│       │   └── resources/
│       │       ├── application.properties
│       │       ├── application-local.yml     ← conecta a postgres:5432/postgres
│       │       ├── postman/
│       │       │   └── nexcore-tenant-module.postman_collection.json
│       │       └── spec/
│       │           ├── 01-nexcore-module-tenant-specs.md
│       │           └── 02-nexcore-module-menu-specs.md
│       └── test/
│           └── java/com/nexore/core/
│               └── CoreApplicationTests.java
│
├── nexcore-frontend/                         ○ pendiente (Angular 18 + Nx)
│   ├── apps/shell/
│   └── libs/
│       ├── ui/
│       ├── data-access-tenant/
│       ├── feature-tenant/
│       ├── feature-preferences/
│       └── feature-audit/
│
└── nexcore-infra/                            ⚙ parcialmente implementado
    ├── database/
    │   ├── schema-nexcore.sql               ✓ schemas nxc_tenant, nxc_menu, nxc_config, nxc_auth
    │   └── 02-migrate-base.sql             ✓ seed completo (tenants, usuarios, roles, menús)
    ├── docker/
    │   ├── docker-compose.yml              ✓ postgres-db corriendo en localhost:5432
    │   └── dockerfiles/
    │       └── Dockerfile-core.yml
    ├── helm/                               ○ pendiente
    ├── terraform/                          ○ pendiente
    ├── ci/                                 ○ pendiente
    ├── observability/                      ○ pendiente
    └── spec/
        ├── 00-nexcore-specs.md             ← este archivo
        ├── 01-nexcore-core-module-tenant-specs.md
        ├── 02-nexcore-core-module-menu-specs.md
        └── 03-nexcore-auth-service.md
