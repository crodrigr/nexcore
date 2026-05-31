# Configuración del Entorno de Desarrollo y Despliegue

**Servicios:** `nexcore-core` (8080) · `nexcore-auth-service` (8081) · `nexcore-frontend` (4200)  
**Tecnologías:** Docker · Docker Compose · Gradle · Angular · Make

---

## 1. Visión general

NexCore es un sistema compuesto por tres proyectos independientes que se comunican entre sí:

```
┌─────────────────────────────────────────────────────────────────┐
│                        NAVEGADOR                                │
│                   http://localhost:4200                          │
└──────────────────────────┬──────────────────────────────────────┘
                           │
              ┌────────────▼────────────┐
              │   nexcore-frontend      │  Angular / nginx
              │   puerto 4200           │
              └──────┬─────────┬────────┘
                     │ /api/   │ http://localhost:8081
                     │         │
        ┌────────────▼───┐  ┌──▼──────────────────┐
        │  nexcore-core  │  │  nexcore-auth-service│
        │  puerto 8080   │  │  puerto 8081         │
        │  Spring Boot   │  │  Spring Boot         │
        └────────┬───────┘  └──────────┬───────────┘
                 │                     │
        ┌────────▼─────────────────────▼───────────┐
        │              INFRAESTRUCTURA              │
        │  PostgreSQL (5432) · Redis (6379)         │
        │  Postfix relay (1587)                     │
        └───────────────────────────────────────────┘
```

**nexcore-core** expone las APIs de negocio (usuarios, tenants, permisos).  
**nexcore-auth-service** gestiona autenticación, JWT y OTP.  
**nexcore-frontend** es la interfaz Angular que consume ambos servicios.

---

## 2. Estructura de archivos de infraestructura

```
nexcore/
├── Makefile                                  ← Automatización principal
├── .env.example                              ← Plantilla de variables de entorno
├── .env                                      ← Variables reales (NO commitear)
├── nexcore-core/
│   └── src/main/resources/
│       ├── application.properties            ← Nombre del app y perfil por defecto
│       ├── application-local.yml             ← Config para desarrollo local
│       └── application-docker.yml            ← Config para contenedor Docker
├── nexcore-auth-service/
│   └── src/main/resources/
│       └── application.yml                   ← Config con variables de entorno
├── nexcore-frontend/
│   ├── proxy.conf.json                       ← Proxy para desarrollo local (ng serve)
│   ├── nginx.conf                            ← Config nginx para Docker
│   └── src/environments/
│       └── environment.ts                    ← URLs de los servicios backend
└── nexcore-infra/
    └── docker/
        ├── docker-compose.yml                ← Infraestructura: postgres, redis, postfix
        ├── docker-compose.apps.yml           ← Servicios Spring Boot y frontend
        └── dockerfiles/
            ├── Dockerfile-core.yml           ← Imagen Docker nexcore-core
            ├── Dockerfile-auth.yml           ← Imagen Docker nexcore-auth-service
            └── Dockerfile-frontend.yml       ← Imagen Docker nexcore-frontend
```

---

## 3. Dockerfiles explicados

### 3.1 nexcore-core y nexcore-auth-service (Spring Boot)

Los Dockerfiles de los proyectos Java son de **una sola etapa**: reciben el JAR ya compilado por Gradle en el host y lo empaquetan en una imagen JRE ligera.

```dockerfile
# Dockerfile-core.yml
FROM eclipse-temurin:25-jre      # ← Imagen base JRE (sin JDK, más liviana)
WORKDIR /app
COPY build/libs/*.jar app.jar    # ← Copia el JAR compilado por Gradle
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

> **¿Por qué no compilar dentro del Docker?**  
> Compilar en el host permite que Gradle reutilice su caché entre builds, lo que es
> significativamente más rápido. En CI/CD la imagen se construye desde el JAR ya generado
> por el pipeline de build.

El Dockerfile de auth-service es idéntico pero expone el puerto 8081.

### 3.2 nexcore-frontend (Angular + nginx)

El frontend también se compila en el host con `npm run build` y luego se sirve con nginx:

```dockerfile
# Dockerfile-frontend.yml
FROM nginx:alpine
COPY dist/nexcore-frontend/browser /usr/share/nginx/html   # ← Build de Angular
COPY nginx.conf /etc/nginx/conf.d/default.conf             # ← Config del proxy
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

**nginx.conf** — proxy inverso dentro del contenedor:

```nginx
server {
    listen 80;
    root /usr/share/nginx/html;
    index index.html;

    # Redirige /api/ al contenedor nexcore-core
    location /api/ {
        proxy_pass http://nexcore-core:8080/api/;
        proxy_set_header Authorization $http_authorization;
        proxy_set_header X-Actor-Id $http_x_actor_id;
        proxy_set_header X-Tenant-Id $http_x_tenant_id;
    }

    # Rutas de Angular (SPA) — todas apuntan al index.html
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

> **Importante:** Las llamadas a `/api/` que el navegador hace al puerto 4200 son redirigidas
> internamente por nginx al contenedor `nexcore-core` en la red Docker. El navegador no sabe
> que hay un proxy de por medio.

---

## 4. Docker Compose explicado

### 4.1 `docker-compose.yml` — Infraestructura

Este archivo levanta los servicios de soporte que necesitan los proyectos Spring Boot.

```yaml
services:
  postgres:
    image: postgres:15
    container_name: postgres-db
    ports:
      - "5432:5432"             # Puerto accesible desde el host
    environment:
      POSTGRES_DB: incidents
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: admin
    volumes:
      - nexcore_postgres_data:/var/lib/postgresql/data   # Datos persistentes

  redis:
    image: redis:7-alpine
    container_name: nexcore-redis
    ports:
      - "6379:6379"

  postfix:                      # Relay de correo para envíos reales
    image: boky/postfix:latest
    container_name: postfix-relay
    ports:
      - "1587:587"

volumes:
  nexcore_postgres_data:
    name: docker_nexcore_postgres_data   # ← Nombre fijo para no perder datos al recrear
  nexcore_redis_data:
    name: docker_nexcore_redis_data

networks:
  nexcore-network:
    driver: bridge
    name: nexcore-network                # ← Nombre fijo (evita prefijos automáticos)
```

> **Volúmenes con nombre fijo:** Docker Compose normalmente prefija los volúmenes con el
> nombre del directorio (ej: `docker_nexcore_postgres_data`). Al definir `name:` explícito,
> el volumen siempre tiene el mismo nombre independientemente de cómo se ejecute el comando,
> preservando los datos de la base de datos entre reinicios.

> **Red con nombre fijo:** Lo mismo aplica para la red. El campo `name: nexcore-network`
> garantiza que `docker-compose.apps.yml` pueda conectarse a ella como red externa.

### 4.2 `docker-compose.apps.yml` — Servicios de aplicación

Este archivo levanta los contenedores de los proyectos Spring Boot y el frontend. Usa la red
creada por el compose de infraestructura.

```yaml
services:

  nexcore-core:
    image: nexcore-core:latest           # ← Imagen construida con `make core`
    container_name: nexcore-core
    ports:
      - "8080:8080"
    environment:
      SPRING_PROFILES_ACTIVE: docker
      SPRING_DATASOURCE_URL: jdbc:postgresql://postgres-db:5432/postgres
      DB_USER: ${DB_USER:-admin}         # ← Usa variable de entorno o default admin
      DB_PASSWORD: ${DB_PASSWORD:-admin}
      REDIS_HOST: nexcore-redis          # ← Nombre del contenedor Redis en la red Docker
      REDIS_PORT: 6379
      CORS_ALLOWED_ORIGINS: ${CORS_ALLOWED_ORIGINS:-http://localhost:4200}

  nexcore-auth:
    image: nexcore-auth:latest
    container_name: nexcore-auth
    ports:
      - "8081:8081"
    environment:
      SPRING_PROFILES_ACTIVE: docker
      SPRING_DATASOURCE_URL: jdbc:postgresql://postgres-db:5432/postgres
      DB_USER: ${DB_USER:-admin}
      DB_PASSWORD: ${DB_PASSWORD:-admin}
      REDIS_HOST: nexcore-redis
      JWT_SECRET: ${JWT_SECRET:-changeme-...}
      NEXCORE_CORE_URL: http://nexcore-core:8080  # ← URL interna entre contenedores
    depends_on:
      - nexcore-core                     # ← Auth espera que Core esté disponible

  nexcore-frontend:
    image: nexcore-frontend:latest
    ports:
      - "4200:80"                        # ← nginx escucha en 80, mapeado al 4200 del host
    depends_on:
      - nexcore-core
      - nexcore-auth

networks:
  nexcore-network:
    external: true                       # ← Usa la red creada por docker-compose.yml
```

> **`external: true`:** Le dice a Docker Compose que la red `nexcore-network` fue creada
> por otro proceso (el compose de infra) y que no debe intentar crearla ni eliminarla.

> **`NEXCORE_CORE_URL: http://nexcore-core:8080`:** Dentro de la red Docker los contenedores
> se comunican por nombre de contenedor, no por `localhost`. Esta URL es solo para llamadas
> internas entre auth-service y nexcore-core.

---

## 5. Variables de entorno

### 5.1 Archivo `.env`

Las variables sensibles (credenciales, secrets) no se hardcodean en el compose. Se leen de
un archivo `.env` en la raíz del proyecto.

**Crear el archivo por primera vez:**

```bash
cp .env.example .env
```

**Editar `.env` con los valores reales:**

```bash
# Gmail SMTP (App Password de Google — no la contraseña normal de Gmail)
GMAIL_USER=tu-correo@gmail.com
GMAIL_PASS=xxxx xxxx xxxx xxxx

# JWT — cambiar en producción por un valor largo y aleatorio
JWT_SECRET=mi-secret-seguro-de-al-menos-256-bits

# Base de datos (opcionales, por defecto admin/admin)
DB_USER=admin
DB_PASSWORD=admin
```

> **Nunca commitear `.env` al repositorio.** El archivo `.gitignore` ya lo excluye.
> El archivo `.env.example` SÍ se commitea como referencia para el equipo.

### 5.2 Cómo fluyen las variables

```
.env (en el host)
    │
    ├── Makefile lo lee con: include .env / export
    │       │
    │       └── docker compose lo pasa al contenedor vía:
    │               GMAIL_PASS: ${GMAIL_PASS}
    │
    └── Spring Boot lo lee como:
            ${GMAIL_PASS:valor_default_si_no_existe}
```

### 5.3 Tabla de variables por servicio

| Variable | Servicio | Default | Descripción |
|---|---|---|---|
| `SPRING_DATASOURCE_URL` | core, auth | `jdbc:postgresql://postgres-db:5432/postgres` | URL de conexión a postgres |
| `DB_USER` | core, auth | `admin` | Usuario de la base de datos |
| `DB_PASSWORD` | core, auth | `admin` | Contraseña de la base de datos |
| `REDIS_HOST` | core, auth | `nexcore-redis` | Host de Redis (nombre del contenedor) |
| `REDIS_PORT` | core, auth | `6379` | Puerto de Redis |
| `GMAIL_USER` | auth | `crodrigr.test1@gmail.com` | Cuenta Gmail para enviar emails |
| `GMAIL_PASS` | auth | *(en application.yml)* | App Password de Gmail |
| `JWT_SECRET` | auth | `changeme-...` | Clave para firmar tokens JWT |
| `NEXCORE_CORE_URL` | auth | `http://nexcore-core:8080` | URL interna de nexcore-core |
| `CORS_ALLOWED_ORIGINS` | core, auth | `http://localhost:4200` | Orígenes permitidos por CORS |
| `OTP_FIXED_ENABLED` | auth | `true` | Habilita OTP fijo para pruebas |
| `OTP_FIXED_CODE` | auth | `111111` | Código OTP fijo para usuarios de prueba |

---

## 6. Perfiles de Spring Boot por entorno

Los proyectos Spring Boot usan perfiles para cargar configuración diferente según el entorno:

| Perfil | Archivo cargado | Cuándo se usa |
|---|---|---|
| `local` | `application-local.yml` | Desarrollo local con Gradle (`bootRun`) |
| `docker` | `application-docker.yml` | Contenedor Docker (`make up`) |

**nexcore-core** tiene los dos archivos:
- `application-local.yml` → datasource `localhost:5432`, show-sql: true
- `application-docker.yml` → datasource `postgres-db:5432`, show-sql: false

**nexcore-auth-service** tiene un único `application.yml` con variables de entorno que
funcionan en ambos contextos.

---

## 7. El Makefile — automatización completa

El `Makefile` en la raíz del proyecto automatiza los tres pasos necesarios para desplegar
cada servicio: **compilar → construir imagen → levantar contenedor**.

### 7.1 Comandos disponibles

```bash
make infra       # Levanta postgres, redis y postfix
make core        # Compila nexcore-core + imagen Docker + contenedor
make auth        # Compila nexcore-auth + imagen Docker + contenedor
make frontend    # Compila Angular + imagen Docker + contenedor nginx
make up          # Levanta todo el sistema completo (infra + los 3 servicios)
make down        # Detiene y elimina todos los contenedores
make restart     # Baja todo y vuelve a levantar (equivalente a down + up)
make logs        # Muestra logs en tiempo real de core, auth y frontend
```

### 7.2 ¿Qué hace `make core` por dentro?

```
make core
│
├── [1/3] cd nexcore-core && ./gradlew clean bootJar -x test
│         └── Compila el proyecto Java y genera:
│             nexcore-core/build/libs/core-0.0.1-SNAPSHOT.jar
│
├── [2/3] docker build -f Dockerfile-core.yml -t nexcore-core:latest nexcore-core/
│         └── Empaqueta el JAR en una imagen Docker con eclipse-temurin:25-jre
│             La imagen queda guardada localmente: nexcore-core:latest
│
└── [3/3] docker compose -f docker-compose.apps.yml up -d nexcore-core
          └── Levanta el contenedor con las variables de entorno del compose
              El contenedor está disponible en http://localhost:8080
```

El mismo patrón aplica para `make auth` (puerto 8081) y `make frontend` (npm build + nginx).

### 7.3 ¿Qué hace `make up` por dentro?

```
make up
│
├── make infra    → docker compose -f docker-compose.yml up -d
│                   (postgres, redis, postfix)
├── make core     → gradle + docker build + docker compose up nexcore-core
├── make auth     → gradle + docker build + docker compose up nexcore-auth
└── make frontend → npm build + docker build + docker compose up nexcore-frontend
```

### 7.4 Cargar variables de entorno automáticamente

El Makefile incluye el archivo `.env` si existe:

```makefile
ifneq (,$(wildcard .env))
  include .env
  export               # ← Exporta todas las variables al entorno del shell
endif
```

Esto significa que al ejecutar `make up`, las variables del `.env` están disponibles
automáticamente para todos los comandos Docker Compose.

---

## 8. Modo desarrollo sin Docker (Gradle + ng serve)

Para desarrollo del día a día es más cómodo usar los servidores nativos. Solo se necesita
Docker para la infraestructura (postgres, redis).

### 8.1 Paso 1: Levantar la infraestructura

```bash
make infra
# o directamente:
cd nexcore-infra/docker && docker compose up -d
```

Esto levanta postgres (5432), redis (6379) y postfix (1587).

### 8.2 Paso 2: Iniciar nexcore-core

```bash
cd nexcore-core
./gradlew bootRun
```

Spring Boot arranca con el perfil `local` (definido en `application.properties`).
Conecta a `localhost:5432` y queda disponible en `http://localhost:8080`.

> El hot-reload de Spring DevTools está activo: los cambios en el código se reflejan
> automáticamente sin reiniciar manualmente.

### 8.3 Paso 3: Iniciar nexcore-auth-service

```bash
cd nexcore-auth-service
./gradlew bootRun
```

Conecta a `localhost:5432` y `localhost:6379`. Disponible en `http://localhost:8081`.

### 8.4 Paso 4: Iniciar el frontend

```bash
cd nexcore-frontend
npm install      # Solo la primera vez o cuando cambien dependencias
ng serve
# o: npm run start
```

El servidor de desarrollo de Angular levanta en `http://localhost:4200`.

El archivo `proxy.conf.json` redirige automáticamente las llamadas a `/api/` hacia
`http://localhost:8080` (nexcore-core):

```json
{
  "/api": {
    "target": "http://localhost:8080",
    "secure": false,
    "changeOrigin": true
  }
}
```

Las llamadas a auth-service usan la URL absoluta `http://localhost:8081` definida en
`environment.ts`.

### 8.5 Resumen de puertos en modo desarrollo

| Servicio | URL | Modo |
|---|---|---|
| nexcore-core | `http://localhost:8080` | Gradle bootRun |
| nexcore-auth-service | `http://localhost:8081` | Gradle bootRun |
| nexcore-frontend | `http://localhost:4200` | ng serve |
| PostgreSQL | `localhost:5432` | Docker |
| Redis | `localhost:6379` | Docker |
| Postfix relay | `localhost:1587` | Docker |

---

## 9. Comparación de modos

| | Desarrollo local | Docker completo (`make up`) |
|---|---|---|
| **Comando** | `./gradlew bootRun` + `ng serve` | `make up` |
| **Velocidad de arranque** | Más rápido (sin Docker build) | Más lento (compila + build imagen) |
| **Hot-reload** | Sí (DevTools + ng serve) | No (requiere `make core` para rebuild) |
| **Perfil Spring** | `local` | `docker` |
| **Datasource** | `localhost:5432` | `postgres-db:5432` |
| **Redis** | `localhost:6379` | `nexcore-redis:6379` |
| **Proxy `/api/`** | `proxy.conf.json` de Angular | `nginx.conf` dentro del contenedor |
| **Recomendado para** | Desarrollo activo | QA, staging, cloud |

---

## 10. Despliegue en cloud

El sistema está diseñado para funcionar en cualquier entorno cloud que soporte Docker.

### 10.1 Flujo de despliegue automatizado

```
Repositorio Git
      │
      ▼
Pipeline CI/CD
      │
      ├── ./gradlew bootJar -x test         (compila JAR)
      ├── docker build -t nexcore-core:v1.0  (crea imagen)
      ├── docker push registry/nexcore-core  (sube al registry)
      │
      └── En el servidor cloud:
          docker compose -f docker-compose.apps.yml up -d
```

### 10.2 Variables de entorno en producción

En producción NO se usa `.env`. Las variables se configuran directamente en el sistema:

**Docker Swarm / Kubernetes:**
```bash
# Crear secret
docker secret create jwt_secret - <<< "mi-secret-seguro"
```

**Variables directas en el servidor:**
```bash
export DB_USER=prod_user
export DB_PASSWORD=mi-password-seguro
export JWT_SECRET=mi-secret-de-256-bits-minimo
export GMAIL_USER=sistema@miempresa.com
export GMAIL_PASS=xxxx xxxx xxxx xxxx
```

**Docker Compose en el servidor:**
```bash
docker compose -f docker-compose.yml -f docker-compose.apps.yml up -d
```

### 10.3 Consideraciones para producción

| Aspecto | Configuración |
|---|---|
| **JWT_SECRET** | Mínimo 256 bits, generado con `openssl rand -hex 32` |
| **DB_PASSWORD** | Contraseña fuerte, distinta al default `admin` |
| **OTP_FIXED_ENABLED** | Cambiar a `false` en producción |
| **CORS_ALLOWED_ORIGINS** | Dominio real de la app, no `localhost` |
| **ddl-auto** | Mantener en `validate`, nunca `create` o `update` en prod |
| **show-sql** | `false` en producción |
| **Volúmenes postgres** | Usar volúmenes gestionados por el cloud provider |

---

## 11. Solución de problemas comunes

### "Connection to localhost:5432 refused"
La infraestructura Docker no está corriendo. Ejecutar `make infra` o `docker compose -f nexcore-infra/docker/docker-compose.yml up -d`.

### "no password specified?" (email)
La variable `GMAIL_PASS` está vacía en el contenedor. Verificar que el `.env` existe y tiene el valor correcto. Ejecutar `docker exec nexcore-auth env | grep GMAIL` para confirmar.

### "network nexcore-network not found"
La red de infra no existe. Ejecutar `make infra` primero para crearla antes de `make core` o `make auth`.

### "Cannot read properties of null (reading 'user')"
El frontend llama a `/api/v1/me/profile` y no llega a nexcore-core. En modo Docker, verificar que el `nginx.conf` esté correctamente copiado en la imagen. Ejecutar `make frontend` para reconstruir.

### Los datos de postgres desaparecen entre reinicios
El volumen se está recreando con diferente nombre. Verificar que `docker-compose.yml` tiene `name: docker_nexcore_postgres_data` en la definición del volumen. Ejecutar `docker volume ls | grep postgres` para ver qué volúmenes existen.
