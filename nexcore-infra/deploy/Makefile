ifneq (,$(wildcard ../../.env))
  include ../../.env
  export
endif

# ── Variables ──────────────────────────────────────────────────────────────────
DOCKER_HUB_USER ?= changeme          # sobreescribir en .env: DOCKER_HUB_USER=miusuario
IMAGE_TAG       ?= latest

PROJECT      = nexcore-hub
COMPOSE_HUB  = docker-compose.hub.yml

DB_CONTAINER = nxc-postgres
DB_NAME     ?= postgres
DB_USER     ?= admin

DB_SCHEMA    = ../database/schema-nexcore.sql
DB_SEED      = ../database/01-migrate-base.sql

# Rutas a los proyectos fuente (para make push)
DIR_CORE     = ../../nexcore-core
DIR_AUTH     = ../../nexcore-auth-service
DIR_FRONTEND = ../../nexcore-frontend
DOCKERFILE_CORE     = ../docker/dockerfiles/Dockerfile-core.yml
DOCKERFILE_AUTH     = ../docker/dockerfiles/Dockerfile-auth.yml
DOCKERFILE_FRONTEND = ../docker/dockerfiles/Dockerfile-frontend.yml

.PHONY: install up-hub down-hub restart-hub logs status db-reset \
        push push-core push-auth push-frontend login

# ── Guardia: DOCKER_HUB_USER debe estar configurado ───────────────────────────
check-hub-user:
	@if [ "$(DOCKER_HUB_USER)" = "changeme" ]; then \
	    echo ""; \
	    echo "  ERROR: DOCKER_HUB_USER no está configurado."; \
	    echo "         Agrega  DOCKER_HUB_USER=tu-usuario  en el archivo ../../.env"; \
	    echo ""; \
	    exit 1; \
	fi

# ── Instalación inicial — levanta BD y carga datos ────────────────────────────
install:
	@echo ">>> [1/4] Levantando infraestructura (hub)..."
	docker compose -p $(PROJECT) -f $(COMPOSE_HUB) up -d postgres-db nexcore-redis postfix-relay
	@echo ">>> [2/4] Esperando que PostgreSQL esté listo..."
	@until docker exec $(DB_CONTAINER) pg_isready -U $(DB_USER) -q; do \
	    printf "  ... postgres no está listo, reintentando\n"; sleep 2; \
	done
	@if docker exec $(DB_CONTAINER) psql -U $(DB_USER) -d $(DB_NAME) -tAc \
	    "SELECT 1 FROM information_schema.schemata WHERE schema_name='nxc_tenant'" \
	    2>/dev/null | grep -q 1; then \
	    echo ""; \
	    echo "  ERROR: La base de datos ya está inicializada."; \
	    echo "         Usa 'make db-reset' para destruir y recrear (BORRA TODOS LOS DATOS)."; \
	    echo ""; \
	    exit 1; \
	fi
	@echo ">>> [3/4] Creando schemas y tablas (DDL)..."
	docker exec -i $(DB_CONTAINER) psql -U $(DB_USER) -d $(DB_NAME) < $(DB_SCHEMA)
	@echo ">>> [4/4] Cargando datos iniciales (seed)..."
	docker exec -i $(DB_CONTAINER) psql -U $(DB_USER) -d $(DB_NAME) < $(DB_SEED)
	@echo ""
	@echo "✓ NexCore instalado. Ejecuta 'make up-hub' para levantar los servicios."

# ── Levantar todo desde Docker Hub ────────────────────────────────────────────
up-hub: check-hub-user
	@echo ">>> Descargando imágenes desde Docker Hub..."
	docker compose -p $(PROJECT) -f $(COMPOSE_HUB) pull nexcore-core nexcore-auth nexcore-frontend
	@echo ">>> Levantando todos los servicios..."
	docker compose -p $(PROJECT) -f $(COMPOSE_HUB) up -d
	@echo ""
	@echo "✓ NexCore corriendo desde Docker Hub."
	@echo "  frontend : http://localhost:4200"
	@echo "  core     : http://localhost:8080"
	@echo "  auth     : http://localhost:8081"

# ── Bajar todo ────────────────────────────────────────────────────────────────
down-hub:
	docker compose -p $(PROJECT) -f $(COMPOSE_HUB) down

# ── Reiniciar servicios de aplicación (sin tocar la BD) ──────────────────────
restart-hub:
	docker compose -p $(PROJECT) -f $(COMPOSE_HUB) restart nexcore-core nexcore-auth nexcore-frontend

# ── Logs ──────────────────────────────────────────────────────────────────────
logs:
	docker compose -p $(PROJECT) -f $(COMPOSE_HUB) logs -f

# ── Estado ────────────────────────────────────────────────────────────────────
status:
	docker compose -p $(PROJECT) -f $(COMPOSE_HUB) ps

# ── Reset de BD ───────────────────────────────────────────────────────────────
db-reset:
	@read -p "  ⚠ ADVERTENCIA: se borrarán TODOS los datos. ¿Continuar? [y/N] " ans && [ "$$ans" = "y" ]
	docker exec -i $(DB_CONTAINER) psql -U $(DB_USER) -d $(DB_NAME) < $(DB_SCHEMA)
	docker exec -i $(DB_CONTAINER) psql -U $(DB_USER) -d $(DB_NAME) < $(DB_SEED)
	@echo "✓ Base de datos recreada."

# ── Login a Docker Hub ────────────────────────────────────────────────────────
login:
	docker login

# ── Publicar imágenes en Docker Hub ──────────────────────────────────────────
push: check-hub-user push-core push-auth push-frontend
	@echo ""
	@echo "✓ Imágenes publicadas en Docker Hub como $(DOCKER_HUB_USER)/*:$(IMAGE_TAG)"

push-core: check-hub-user
	@echo ">>> [core 1/3] Compilando con Gradle..."
	cd $(DIR_CORE) && ./gradlew clean bootJar -x test
	@echo ">>> [core 2/3] Construyendo imagen..."
	docker build -f $(DOCKERFILE_CORE) -t $(DOCKER_HUB_USER)/nexcore-core:$(IMAGE_TAG) $(DIR_CORE)/
	@echo ">>> [core 3/3] Publicando en Docker Hub..."
	docker push $(DOCKER_HUB_USER)/nexcore-core:$(IMAGE_TAG)

push-auth: check-hub-user
	@echo ">>> [auth 1/3] Compilando con Gradle..."
	cd $(DIR_AUTH) && ./gradlew clean bootJar -x test
	@echo ">>> [auth 2/3] Construyendo imagen..."
	docker build -f $(DOCKERFILE_AUTH) -t $(DOCKER_HUB_USER)/nexcore-auth:$(IMAGE_TAG) $(DIR_AUTH)/
	@echo ">>> [auth 3/3] Publicando en Docker Hub..."
	docker push $(DOCKER_HUB_USER)/nexcore-auth:$(IMAGE_TAG)

push-frontend: check-hub-user
	@echo ">>> [frontend 1/3] Instalando dependencias y compilando Angular..."
	cd $(DIR_FRONTEND) && npm install && npm run build
	@echo ">>> [frontend 2/3] Construyendo imagen..."
	docker build -f $(DOCKERFILE_FRONTEND) -t $(DOCKER_HUB_USER)/nexcore-frontend:$(IMAGE_TAG) $(DIR_FRONTEND)/
	@echo ">>> [frontend 3/3] Publicando en Docker Hub..."
	docker push $(DOCKER_HUB_USER)/nexcore-frontend:$(IMAGE_TAG)
