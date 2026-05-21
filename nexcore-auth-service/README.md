# NexCore Auth Service

Microservicio de autenticación para la plataforma NexCore con autenticación 2FA, gestión de sesiones JWT y recuperación de contraseña.

## Características

- ✅ Autenticación en dos pasos (2FA) con OTP por email
- ✅ Tokens JWT (HS256) con access tokens y refresh tokens
- ✅ Protección contra fuerza bruta
- ✅ Recuperación de contraseña por email
- ✅ Gestión de sesiones con revocación
- ✅ Auditoría de intentos de login
- ✅ Arquitectura hexagonal (Domain-Driven Design)
 - ✅ Base de datos PostgreSQL (migraciones gestionadas externamente)

## Tecnologías

- Java 25
- Spring Boot 4.0.6
- Spring Security
- Spring Data JPA
- PostgreSQL
 
- JWT (io.jsonwebtoken)
- JavaMailSender
- Lombok
- Gradle

## Requisitos Previos

- Java 25+ instalado
- PostgreSQL 12+ corriendo
- SMTP server (por defecto Postfix en localhost:25)

## Configuración

### Base de Datos

Crear base de datos PostgreSQL:

```sql
CREATE DATABASE nexcore;
```

### Variables de Entorno

Configurar las siguientes variables de entorno (opcional, existen valores por defecto):

```bash
export DB_USER=admin
export DB_PASSWORD=admin
export JWT_SECRET=tu-clave-secreta-muy-larga-y-segura-minimo-256-bits
export SMTP_HOST=localhost
export SMTP_PORT=25
export NEXCORE_CORE_URL=http://localhost:8080
```

### Archivo application.yml

El servicio viene preconfigurado con valores por defecto en `src/main/resources/application.yml`.

## Instalación y Ejecución

### 1. Compilar el proyecto

```bash
./gradlew clean build
```

### 2. Ejecutar el servicio

```bash
./gradlew bootRun
```

El servicio estará disponible en: `http://localhost:8081`

### 3. Verificar salud del servicio

```bash
curl http://localhost:8081/actuator/health
```

## Endpoints de la API

### Autenticación

#### POST /auth/login
Paso 1: Validar credenciales y enviar OTP por email

**Request:**
```json
{
  "tenantId": "123e4567-e89b-12d3-a456-426614174000",
  "username": "usuario@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "challengeToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "message": "OTP sent to your email",
  "expiresIn": 300
}
```

#### POST /auth/verify-otp
Paso 2: Verificar OTP y crear sesión

**Request:**
```json
{
  "challengeToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "code": "123456"
}
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "550e8400-e29b-41d4-a716-446655440000",
  "expiresIn": 900,
  "profile": {
    "userId": "123e4567-e89b-12d3-a456-426614174000",
    "username": "usuario",
    "email": "usuario@example.com"
  }
}
```

#### POST /auth/refresh
Refrescar access token

**Headers:**
```
X-Refresh-Token: 550e8400-e29b-41d4-a716-446655440000
```

**Response:** Igual que verify-otp

#### DELETE /auth/logout?sessionId={sessionId}
Cerrar sesión

**Response:**
```json
{
  "message": "Logged out successfully"
}
```

### Gestión de Contraseña

#### POST /auth/password/reset/request
Solicitar reset de contraseña

**Request:**
```json
{
  "tenantId": "123e4567-e89b-12d3-a456-426614174000",
  "email": "usuario@example.com"
}
```

**Response:**
```json
{
  "message": "If the email exists, a password reset link has been sent"
}
```

#### POST /auth/password/reset/confirm
Confirmar reset con token

**Request:**
```json
{
  "token": "abc123...",
  "newPassword": "newPassword123",
  "confirmPassword": "newPassword123"
}
```

#### PUT /auth/password?userId={userId}
Cambiar contraseña (usuario autenticado)

**Request:**
```json
{
  "currentPassword": "oldPassword123",
  "newPassword": "newPassword123",
  "confirmPassword": "newPassword123"
}
```

## Estructura del Proyecto

```
nexcore-auth-service/
├── src/main/java/com/nexore/auth/
│   ├── domain/                    # Capa de dominio (lógica de negocio)
│   │   ├── model/                 # Entidades del dominio
│   │   ├── repository/            # Interfaces de repositorio
│   │   ├── service/               # Servicios de dominio
│   │   └── exception/             # Excepciones personalizadas
│   ├── application/               # Capa de aplicación (orquestación)
│   │   ├── service/               # Servicios de aplicación
│   │   └── dto/                   # DTOs (request/response)
│   └── infrastructure/            # Capa de infraestructura
│       ├── persistence/           # JPA entities, adapters
│       ├── web/                   # Controllers, handlers
│       ├── email/                 # Implementación de email
│       ├── client/                # HTTP clients
│       └── config/                # Configuraciones
├── src/main/resources/
│   ├── application.yml            # Configuración principal
└── build.gradle                   # Dependencias
```

## Códigos de Error

| Código | Descripción |
|--------|-------------|
| NXC-AUTH-0001 | Error de validación de campos |
| NXC-AUTH-0002 | Credenciales inválidas |
| NXC-AUTH-0003 | Usuario suspendido |
| NXC-AUTH-0004 | Tenant inactivo |
| NXC-AUTH-0005 | Tenant no encontrado |
| NXC-AUTH-0006 | OTP inválido |
| NXC-AUTH-0007 | Demasiados intentos de OTP |
| NXC-AUTH-0008 | Protección contra fuerza bruta activada |
| NXC-AUTH-0009 | Token JWT inválido |
| NXC-AUTH-0010 | Token JWT expirado |
| NXC-AUTH-0011 | Error al enviar email |
| NXC-AUTH-0012 | Las contraseñas no coinciden |
| NXC-AUTH-0013 | Token de reset inválido |
| NXC-AUTH-0014 | Demasiados intentos de reset |
| NXC-AUTH-0015 | Sesión no encontrada |
| NXC-AUTH-0099 | Error inesperado |

## Seguridad

- **Contraseñas**: BCrypt con cost factor 12
- **OTPs**: SHA-256 hashing con timing-safe comparison
- **Tokens JWT**: HS256, clave configurable de 256+ bits
- **Refresh Tokens**: UUID v4 hasheados con SHA-256
- **Brute Force**: Máximo 10 intentos por 15 minutos
- **Rate Limiting**: Por usuario e IP address

## Testing

Ejecutar tests:

```bash
./gradlew test
```

## Docker

El proyecto incluye configuración Docker en nexcore-infra/docker/:

```bash
cd ../nexcore-infra/docker
docker-compose up -d
```

## Licencia

Copyright © 2025 NexCore Platform

## Autor

Desarrollado como parte del ecosistema NexCore
