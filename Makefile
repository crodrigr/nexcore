COMPOSE_INFRA = nexcore-infra/docker/docker-compose.yml
COMPOSE_APPS  = nexcore-infra/docker/docker-compose.apps.yml

.PHONY: infra core auth frontend up down restart logs

# ── Infraestructura (postgres, redis, postfix) ─────────────────────
infra:
	docker compose -f $(COMPOSE_INFRA) up -d

# ── nexcore-core: build jar + imagen + contenedor ──────────────────
core: infra
	docker compose -f $(COMPOSE_APPS) up -d --build nexcore-core

# ── nexcore-auth: build jar + imagen + contenedor ─────────────────
auth: infra
	docker compose -f $(COMPOSE_APPS) up -d --build nexcore-auth

# ── nexcore-frontend: build + imagen + contenedor ─────────────────
frontend: infra
	docker compose -f $(COMPOSE_APPS) up -d --build nexcore-frontend

# ── Todo el sistema ───────────────────────────────────────────────
up: infra
	docker compose -f $(COMPOSE_APPS) up -d --build

# ── Bajar todo ────────────────────────────────────────────────────
down:
	docker compose -f $(COMPOSE_APPS) down
	docker compose -f $(COMPOSE_INFRA) down

# ── Reiniciar todo el sistema ─────────────────────────────────────
restart: down up

# ── Logs (todos los servicios) ────────────────────────────────────
logs:
	docker compose -f $(COMPOSE_APPS) logs -f
