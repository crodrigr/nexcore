ifneq (,$(wildcard .env))
  include .env
  export
endif

COMPOSE_INFRA = nexcore-infra/docker/docker-compose.yml
COMPOSE_APPS  = nexcore-infra/docker/docker-compose.apps.yml

DOCKERFILE_CORE     = nexcore-infra/docker/dockerfiles/Dockerfile-core.yml
DOCKERFILE_AUTH     = nexcore-infra/docker/dockerfiles/Dockerfile-auth.yml
DOCKERFILE_FRONTEND = nexcore-infra/docker/dockerfiles/Dockerfile-frontend.yml

PROJECT_INFRA = nexcore-infra
PROJECT_APPS  = nexcore-apps

DB_CONTAINER = postgres-db
DB_SCHEMA    = nexcore-infra/database/schema-nexcore.sql
DB_SEED      = nexcore-infra/database/01-migrate-base.sql

DB_NAME ?= postgres
DB_USER ?= admin

.PHONY: infra core auth frontend up down restart logs install db-reset

# ── Instalación inicial — crea BD y carga datos ───────────────────
install:
	@echo ">>> [1/4] Levantando infraestructura..."
	$(MAKE) infra
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
	@echo "✓ NexCore instalado correctamente en la base de datos '$(DB_NAME)'."

# ── Reset de BD — destruye y recrea (solo desarrollo) ─────────────
db-reset:
	@echo ""
	@read -p "  ⚠ ADVERTENCIA: se borrarán TODOS los datos de '$(DB_NAME)'. ¿Continuar? [y/N] " ans && [ "$$ans" = "y" ]
	@echo ">>> [1/2] Recreando schemas y tablas (DDL)..."
	docker exec -i $(DB_CONTAINER) psql -U $(DB_USER) -d $(DB_NAME) < $(DB_SCHEMA)
	@echo ">>> [2/2] Cargando datos iniciales (seed)..."
	docker exec -i $(DB_CONTAINER) psql -U $(DB_USER) -d $(DB_NAME) < $(DB_SEED)
	@echo ""
	@echo "✓ Base de datos '$(DB_NAME)' recreada."

# ── Infraestructura (postgres, redis, postfix) ─────────────────────
infra:
	docker compose -p $(PROJECT_INFRA) -f $(COMPOSE_INFRA) up -d

# ── nexcore-core ──────────────────────────────────────────────────
core:
	@echo ">>> [1/3] Compilando nexcore-core con Gradle..."
	cd nexcore-core && ./gradlew clean bootJar -x test
	@echo ">>> [2/3] Construyendo imagen Docker nexcore-core..."
	docker build -f $(DOCKERFILE_CORE) -t nexcore-core:latest nexcore-core/
	@echo ">>> [3/3] Levantando contenedor nexcore-core..."
	docker compose -p $(PROJECT_APPS) -f $(COMPOSE_APPS) up -d nexcore-core

# ── nexcore-auth-service ──────────────────────────────────────────
auth:
	@echo ">>> [1/3] Compilando nexcore-auth-service con Gradle..."
	cd nexcore-auth-service && ./gradlew clean bootJar -x test
	@echo ">>> [2/3] Construyendo imagen Docker nexcore-auth..."
	docker build -f $(DOCKERFILE_AUTH) -t nexcore-auth:latest nexcore-auth-service/
	@echo ">>> [3/3] Levantando contenedor nexcore-auth..."
	docker compose -p $(PROJECT_APPS) -f $(COMPOSE_APPS) up -d nexcore-auth

# ── nexcore-frontend ──────────────────────────────────────────────
frontend:
	@echo ">>> [1/3] Compilando nexcore-frontend con Angular..."
	cd nexcore-frontend && npm run build
	@echo ">>> [2/3] Construyendo imagen Docker nexcore-frontend..."
	docker build -f $(DOCKERFILE_FRONTEND) -t nexcore-frontend:latest nexcore-frontend/
	@echo ">>> [3/3] Levantando contenedor nexcore-frontend..."
	docker compose -p $(PROJECT_APPS) -f $(COMPOSE_APPS) up -d nexcore-frontend

# ── Todo el sistema ───────────────────────────────────────────────
up:
	$(MAKE) infra
	$(MAKE) core
	$(MAKE) auth
	$(MAKE) frontend

# ── Bajar todo ────────────────────────────────────────────────────
down:
	-docker stop nexcore-frontend nexcore-auth nexcore-core 2>/dev/null
	-docker rm   nexcore-frontend nexcore-auth nexcore-core 2>/dev/null
	-docker stop postgres-db nexcore-redis postfix-relay 2>/dev/null
	-docker rm   postgres-db nexcore-redis postfix-relay 2>/dev/null

# ── Reiniciar todo el sistema ─────────────────────────────────────
restart:
	$(MAKE) down
	$(MAKE) up

# ── Logs de los servicios ─────────────────────────────────────────
logs:
	docker compose -p $(PROJECT_APPS) -f $(COMPOSE_APPS) logs -f
