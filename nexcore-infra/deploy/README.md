# NexCore — Despliegue vía Docker Hub

Esta carpeta contiene la configuración para desplegar NexCore en cualquier servidor
usando imágenes pre-construidas desde Docker Hub, sin necesidad de código fuente ni
herramientas de compilación (Gradle, Node.js) en el servidor de producción.

---

## Requisitos

### Máquina de desarrollo (donde se compila y publica)
- Docker + Docker Compose
- Java 25 (Temurin)
- Gradle 9.5.1
- Node.js 20 + npm 10.8.2
- Angular CLI 20.1.4
- Cuenta en [hub.docker.com](https://hub.docker.com)

### Servidor EC2 (donde se ejecuta)
- Ubuntu 24.04 LTS
- Docker Engine + Docker Compose plugin
- El script `nexcore-infra/ec2-user-data.sh` instala todo automáticamente

---

## Estructura de archivos

```
nexcore-infra/deploy/
├── Makefile                  ← comandos de despliegue
├── docker-compose.hub.yml    ← todos los servicios usando imágenes de Docker Hub
└── README.md                 ← este documento
```

El `docker-compose.hub.yml` incluye en un solo archivo:
- **Infraestructura**: PostgreSQL 15, Redis 7, Postfix
- **Aplicaciones**: nexcore-core, nexcore-auth, nexcore-frontend (desde Docker Hub)

---

## Configuración inicial

### 1. Configurar variables de entorno

En el archivo `.env` de la **raíz del proyecto** (no en esta carpeta), agrega o verifica:

```env
# Tu username de Docker Hub (NO el email, el username)
DOCKER_HUB_USER=tu-usuario-dockerhub
IMAGE_TAG=latest

# Base de datos
DB_NAME=postgres
DB_USER=admin
DB_PASSWORD=tu-password-seguro

# JWT (generar con: openssl rand -hex 32)
JWT_SECRET=tu-secreto-de-256-bits

# URLs — en EC2 reemplaza con la IP pública o dominio
CORS_ALLOWED_ORIGINS=http://<IP-EC2>:4200
APP_FRONTEND_URL=http://<IP-EC2>:4200
FRONTEND_URL=http://<IP-EC2>:4200
```

> **Nota:** El archivo `.env` nunca debe subirse a git. Ya está en `.gitignore`.

---

## Flujo de trabajo

### Paso 1 — Publicar imágenes a Docker Hub (máquina de desarrollo)

```bash
cd nexcore-infra/deploy

# Iniciar sesión en Docker Hub (solo la primera vez)
make login

# Compilar y publicar los 3 servicios
make push
```

También se puede publicar por separado:

```bash
make push-core       # solo nexcore-core
make push-auth       # solo nexcore-auth-service
make push-frontend   # solo nexcore-frontend
```

Con un tag específico (ej. para versionar releases):

```bash
make push IMAGE_TAG=v1.0.0
```

Lo que hace `make push` por cada servicio:
1. Compila el proyecto (`./gradlew bootJar` o `npm run build`)
2. Construye la imagen Docker
3. La sube a `docker.io/<DOCKER_HUB_USER>/nexcore-<servicio>:<IMAGE_TAG>`

---

### Paso 2 — Preparar el servidor EC2

Si es una instancia nueva, ejecutar el script de instalación:

```bash
sudo bash nexcore-infra/ec2-user-data.sh
```

Esto instala: Docker, Java 25, Gradle 9.5.1, Node 20, Angular CLI 20.1.4.

Verificar que Docker funciona sin `sudo`:

```bash
groups
# debe incluir: docker

# Si no aparece docker:
sudo usermod -aG docker ubuntu && newgrp docker
```

---

### Paso 3 — Instalar NexCore en el servidor (primera vez)

```bash
cd nexcore-infra/deploy

# Configura el .env con los valores del servidor
nano ../../.env

# Levanta PostgreSQL + Redis + Postfix y carga la base de datos
make install
```

`make install` realiza:
1. Levanta los servicios de infraestructura
2. Espera a que PostgreSQL esté listo
3. Ejecuta el DDL (schemas y tablas)
4. Carga los datos iniciales (seed)

> Solo se ejecuta una vez. Si la BD ya está inicializada, muestra un error y pide
> usar `make db-reset` para empezar de cero.

---

### Paso 4 — Levantar todos los servicios

```bash
make up-hub
```

Este comando:
1. Descarga las imágenes más recientes desde Docker Hub
2. Levanta los 6 contenedores (infra + apps)

URLs disponibles tras el arranque:

| Servicio | URL |
|---|---|
| Frontend | `http://<IP-EC2>:4200` |
| nexcore-core API | `http://<IP-EC2>:8080` |
| nexcore-auth API | `http://<IP-EC2>:8081` |

> Las llamadas del frontend a `/auth/*` y `/api/*` son proxeadas por nginx
> hacia los contenedores internos. El navegador solo necesita acceso al puerto 4200.

---

## Comandos disponibles

```bash
make install        # Primera instalación: infra + BD (ejecutar solo una vez)
make up-hub         # Descargar imágenes y levantar todos los servicios
make down-hub       # Detener todos los servicios
make restart-hub    # Reiniciar solo las apps (sin tocar la BD ni la infra)
make logs           # Ver logs en tiempo real de todos los servicios
make status         # Ver estado de los contenedores
make db-reset       # Recrear la BD desde cero (⚠ borra todos los datos)
make login          # Iniciar sesión en Docker Hub
make push           # Compilar y publicar las 3 imágenes
make push-core      # Publicar solo nexcore-core
make push-auth      # Publicar solo nexcore-auth
make push-frontend  # Publicar solo nexcore-frontend
```

---

## Actualizar a una nueva versión

Cuando hay cambios en el código:

**En la máquina de desarrollo:**
```bash
cd nexcore-infra/deploy
make push           # o make push-core / push-auth / push-frontend según lo que cambió
```

**En el servidor EC2:**
```bash
cd nexcore-infra/deploy
make down-hub
make up-hub         # descarga las nuevas imágenes y levanta
```

No es necesario re-ejecutar `make install` en actualizaciones, solo en la primera instalación.

---

## Puertos del Security Group de AWS

Asegúrate de que el Security Group de la instancia EC2 permita el tráfico entrante en:

| Puerto | Protocolo | Descripción |
|---|---|---|
| 22 | TCP | SSH |
| 4200 | TCP | Frontend (nginx) |
| 8080 | TCP | nexcore-core API (opcional, para debug) |
| 8081 | TCP | nexcore-auth API (opcional, para debug) |

> En producción, exponer solo el puerto 4200 y dejar 8080/8081 cerrados al exterior.
> El frontend ya proxea `/api/` y `/auth/` internamente vía nginx.

---

## Solución de problemas frecuentes

### `permission denied` al usar docker

```bash
sudo usermod -aG docker ubuntu && newgrp docker
# o
sudo chmod 660 /var/run/docker.sock && sudo chown root:docker /var/run/docker.sock
```

### `ENOSPC: no space left on device` al compilar frontend

```bash
docker system prune -af      # libera imágenes y capas sin usar
npm cache clean --force
```

Si el disco es pequeño (< 20 GB): ampliar el volumen EBS desde la consola de AWS
y aplicar el cambio con `sudo growpart /dev/xvda 1 && sudo resize2fs /dev/xvda1`.

### `invalid tag` al hacer push

El `DOCKER_HUB_USER` en `.env` debe ser el **username** de Docker Hub,
no el email (`crodrigr`, no `crodrigr@gmail.com`).

### Login falla con `Unknown Error` / `localhost:8081`

El frontend está llamando a `localhost` en lugar del servidor real.
Verificar que `environment.ts` tenga `authBaseUrl: ''` (cadena vacía) y que
`nginx.conf` incluya el bloque `location /auth/`. Reconstruir y publicar la imagen:

```bash
make push-frontend
make down-hub && make up-hub
```

### La BD ya está inicializada

```bash
make db-reset    # ⚠ borra TODOS los datos
```
