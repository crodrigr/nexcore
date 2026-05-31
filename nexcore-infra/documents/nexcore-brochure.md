# NexCore Platform
## La base técnica que acelera el desarrollo de software empresarial

---

> **Construye sobre cimientos sólidos. Entrega en semanas, no en meses.**

NexCore es una plataforma backend + frontend lista para producción, diseñada para ser el punto de partida de cualquier sistema empresarial SaaS. Elimina los meses de trabajo repetitivo y te permite concentrarte en lo que realmente importa: la lógica de negocio de tu cliente.

---

## ¿Por qué NexCore?

Todo proyecto empresarial necesita las mismas piezas antes de escribir una línea de negocio: autenticación, usuarios, roles, permisos, multi-tenancy, seguridad, infraestructura. **NexCore ya las tiene construidas, probadas y listas.**

```
Sin NexCore:   ████████████████░░░░░░░░░░  6 meses
Con NexCore:   ████░░░░░░░░░░░░░░░░░░░░░░  6 semanas
               └── Base del sistema        └── Lógica de negocio
```

---

## Stack tecnológico de última generación

| Capa | Tecnología | Versión | Ventaja |
|---|---|---|---|
| Backend | Spring Boot | 4.0 | El framework Java más usado en enterprise |
| Lenguaje | Java | 25 + Hilos Virtuales | Máximo rendimiento, concurrencia sin bloqueos |
| Frontend | Angular | 20 | Signals, SSR, arquitectura standalone moderna |
| Base de datos | PostgreSQL | 15 | Esquemas separados por módulo |
| Caché | Redis | 7 | Políticas de acceso en memoria, respuesta <1ms |
| Contenedores | Docker + Compose | — | Deploy en cualquier cloud con un comando |
| Estilo | — | — | SCSS, diseño responsivo |

### Hilos Virtuales (Java 25 + Project Loom)

NexCore aprovecha los **Virtual Threads** de Java 25, lo que permite manejar miles de peticiones concurrentes con mínimo uso de recursos. Un servidor pequeño puede atender lo que antes requería clusters completos.

```
Thread tradicional:  1 hilo = 1 MB memoria
Hilo virtual:        1 hilo = ~1 KB memoria  →  1000x más eficiente
```

---

## Arquitectura

### Monolítico Modular → Listo para Microservicios

NexCore nace como un monolito modular con separación clara entre módulos. Cuando el negocio lo requiera, cada módulo puede extraerse como microservicio independiente **sin reescribir el código**, solo reorganizando el deployment.

```
Fase 1 — Monolito modular (NexCore hoy)     Fase 2 — Microservicios (cuando escale)
┌─────────────────────────────────┐          ┌──────────┐  ┌──────────┐  ┌──────────┐
│         nexcore-core            │          │  users   │  │ tenants  │  │   crm    │
│  ┌────────┐ ┌────────┐          │   →→→    │ service  │  │ service  │  │ service  │
│  │ users  │ │tenants │  ┌─────┐ │          └──────────┘  └──────────┘  └──────────┘
│  └────────┘ └────────┘  │ crm │ │
│  ┌────────┐ ┌────────┐  └─────┘ │
│  │  menu  │ │ roles  │          │
│  └────────┘ └────────┘          │
└─────────────────────────────────┘
```

### Domain-Driven Design (DDD)

Cada módulo sigue la arquitectura DDD con capas bien definidas:

```
módulo/
├── domain/          ← Entidades, repositorios (interfaces), reglas de negocio
├── application/     ← Casos de uso, servicios de aplicación
└── infrastructure/  ← Controladores REST, JPA, adaptadores externos
```

Esta separación garantiza que el código de negocio no depende de ningún framework, facilitando el mantenimiento y los tests.

### Esquemas de Base de Datos Separados por Módulo

```sql
nxc_tenant     → usuarios, roles, tenants, invitaciones
nxc_auth       → sesiones, tokens, OTP, intentos de login, resets
nxc_menu       → menú dinámico, componentes, permisos de UI
nxc_preference → preferencias de usuario y tenant
nxc_config     → configuración del sistema
```

Cada módulo es dueño de sus datos. No hay acoplamiento entre esquemas. Esto facilita la migración a microservicios y el mantenimiento a largo plazo.

---

## Funcionalidades incluidas

### Autenticación y Seguridad

- **2FA con OTP por email** — Segundo factor de autenticación en cada login
- **JWT + Refresh Tokens** — Sesiones seguras sin estado en el servidor
- **Brute Force Protection** — Bloqueo automático ante intentos repetidos de login
- **Gestión de sesiones** — Control de sesiones activas por usuario
- **Password Reset seguro** — Flujo completo via email con tokens de expiración
- **OTP fijo para testing** — Código configurable para entornos de desarrollo/QA

### Multi-Tenant SaaS

- **Aislamiento por tenant** — Cada empresa/cliente ve solo sus datos
- **Gestión de tenants desde UI** — Alta, baja y modificación sin código
- **Roles por tenant** — Cada tenant define sus propios roles y permisos
- **Invitaciones por email** — Los administradores invitan usuarios directamente

### Usuarios, Roles y Permisos

- **Gestor visual completo** — CRUD de usuarios, roles y permisos desde el frontend
- **Permisos a nivel de API** — Control qué endpoints puede llamar cada rol
- **Permisos a nivel de UI** — Qué componentes y elementos ve cada usuario
- **Caché inteligente con Redis** — Los permisos se cachean automáticamente, sin impacto en BD
- **Actualización sin redeploy** — Cambiar permisos en BD se refleja en el próximo ciclo de caché

```
Rol TENANT_ADMIN  →  puede GET /api/*/users/**
Rol EDITOR        →  puede GET /api/*/users, no puede DELETE
Rol VIEWER        →  solo lectura
```

### Menú Dinámico por Rol

- El menú de navegación se construye dinámicamente según el rol del usuario
- Cada tenant puede tener una estructura de menú diferente
- Los ítems de menú se gestionan desde la base de datos, sin modificar código
- Control granular por componente y por elemento de UI

### Módulo de Auditoría

- Registro de acciones críticas del sistema
- Trazabilidad de quién hizo qué y cuándo
- Esencial para cumplimiento regulatorio y debugging en producción

### Email y Notificaciones

- **Plantillas HTML** para OTP, reset de contraseña y bienvenida
- **Gmail SMTP** listo para usar con App Passwords
- **Postfix relay** incluido en Docker para entornos controlados
- Fácil extensión para SendGrid, AWS SES u otros proveedores

### Internacionalización (i18n)

- Soporte multi-idioma con **Transloco** (Angular)
- Preparado para agregar idiomas sin modificar componentes

---

## Infraestructura y DevOps

### Docker — Un comando para levantar todo

```bash
make up          # Levanta toda la plataforma
make down        # Baja todo
make restart     # Reinicio completo
make core        # Solo recompila y redeploya el backend
make frontend    # Solo recompila y redeploya el frontend
```

### Cloud-Ready desde el día 1

```
Cualquier cloud que soporte Docker → AWS ECS / GCP Cloud Run / Azure ACI
                                   → DigitalOcean / Hetzner / VPS propio
                                   → Kubernetes
```

### Automatización del ciclo completo

```
Código fuente
    │
    ├── gradle bootJar     → Compila JAR (Spring Boot)
    ├── docker build       → Crea imagen Docker
    └── docker compose up  → Levanta contenedor con variables de entorno
```

---

## Servicios que ofrecemos

### 1. NexCore como base de tu proyecto

Te entregamos la plataforma configurada para tu negocio. Tu equipo desarrolla solo los módulos de negocio específicos.

```
Tiempo de arranque:  1–2 semanas (vs 2–3 meses desde cero)
```

### 2. Desarrollo de módulos de negocio

Sobre la plataforma NexCore, construimos los módulos que necesita tu cliente:

| Módulo típico | Tiempo estimado |
|---|---|
| CRM básico (contactos, seguimiento) | 3–5 semanas |
| Facturación y pagos | 4–6 semanas |
| Reportes y dashboards | 2–4 semanas |
| Integración con APIs externas | 1–3 semanas |
| Módulo a medida | Estimación personalizada |

### 3. Proyecto llave en mano

Plataforma + módulos de negocio + despliegue en producción + documentación.

```
Proyecto estándar:  8–14 semanas
Proyecto complejo:  16–24 semanas
```

---

## Lo que NexCore NO necesita que construyas

Cada ítem de esta lista representa **semanas de trabajo** que NexCore ya hizo por ti:

- [ ] ~~Sistema de autenticación~~
- [ ] ~~Gestión de sesiones y tokens~~
- [ ] ~~2FA / OTP~~
- [ ] ~~Sistema de roles y permisos~~
- [ ] ~~Multi-tenancy~~
- [ ] ~~Gestión de usuarios~~
- [ ] ~~Reset de contraseña~~
- [ ] ~~Invitaciones por email~~
- [ ] ~~Menú dinámico~~
- [ ] ~~Caché de permisos~~
- [ ] ~~Brute force protection~~
- [ ] ~~Infraestructura Docker~~
- [ ] ~~CI/CD base~~
- [ ] ~~Auditoría~~

---

## Comparativa de tiempo y costo

| | Desarrollo desde cero | Con NexCore |
|---|---|---|
| **Tiempo hasta primera demo** | 3–4 meses | 2–3 semanas |
| **Tiempo hasta producción** | 6–12 meses | 2–4 meses |
| **Costo base** | Alto (todo desde cero) | Reducido (reutilizamos la plataforma) |
| **Riesgo técnico** | Alto (decisiones de arquitectura) | Bajo (arquitectura probada) |
| **Escalabilidad** | Depende del diseño inicial | Garantizada por diseño |
| **Mantenibilidad** | Variable | DDD + separación clara |

---

## Casos de uso ideales para NexCore

- **Sistemas de gestión empresarial (ERP/CRM)** para PYMEs
- **Plataformas SaaS** donde múltiples empresas usan el mismo sistema
- **Portales de clientes** con acceso diferenciado por rol
- **Backoffice** de startups que necesitan moverse rápido
- **Sistemas de administración** con múltiples niveles de acceso
- **Proyectos de modernización** de sistemas legados

---

## Tecnologías del ecosistema

```
Backend          Frontend         Infraestructura      Seguridad
──────────        ────────         ───────────────      ─────────
Spring Boot 4    Angular 20       Docker               JWT RS256
Java 25          TypeScript       PostgreSQL 15        OTP / TOTP
Virtual Threads  Signals API      Redis 7              Brute Force
Hibernate 7      Standalone       Docker Compose       Session Mgmt
REST API         SCSS             Makefile             CORS
Spring Security  Transloco        nginx                HTTPS ready
Actuator         Reactive Forms   Postfix              bcrypt
```

---

## Inversión en el proyecto

NexCore representa **2–3 meses de trabajo de un equipo senior** construyendo:
- Arquitectura empresarial probada
- Seguridad de nivel producción
- Infraestructura lista para cloud
- Documentación técnica

Al contratar desarrollo sobre NexCore, **no pagas por reinventar la rueda**. Pagas por tu lógica de negocio.

---

*NexCore Platform — Arquitectura empresarial, entrega ágil.*
