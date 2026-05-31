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

.PHONY: infra core auth frontend up down restart logs

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
