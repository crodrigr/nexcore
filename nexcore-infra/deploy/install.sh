#!/usr/bin/env bash
# =============================================================================
# NexCore — Instalador rápido
# Uso: curl -fsSL https://raw.githubusercontent.com/<ORG>/<REPO>/main/nexcore-infra/deploy/install.sh | bash
# =============================================================================
set -euo pipefail

# ── Configura tu repositorio GitHub aquí ──────────────────────────────────────
GITHUB_ORG="TU_ORG"
GITHUB_REPO="nexcore"
GITHUB_BRANCH="main"
# ─────────────────────────────────────────────────────────────────────────────

RAW="https://raw.githubusercontent.com/${GITHUB_ORG}/${GITHUB_REPO}/${GITHUB_BRANCH}"
INSTALL_DIR="${HOME}/nexcore"

log()  { echo "[nexcore] $*"; }
fail() { echo "[nexcore] ERROR: $*" >&2; exit 1; }

# ── Requisitos ────────────────────────────────────────────────────────────────
command -v docker  >/dev/null 2>&1 || fail "Docker no está instalado. Instálalo desde https://docs.docker.com/engine/install/"
docker compose version >/dev/null 2>&1 || fail "Docker Compose plugin no está instalado."

# ── Evitar reinstalación accidental ──────────────────────────────────────────
if [[ -d "${INSTALL_DIR}" ]]; then
    fail "El directorio ${INSTALL_DIR} ya existe. Elimínalo primero si quieres reinstalar."
fi

log "Creando directorio de instalación en ${INSTALL_DIR}..."
mkdir -p \
    "${INSTALL_DIR}/nexcore-infra/deploy" \
    "${INSTALL_DIR}/nexcore-infra/database"

# ── Descargar archivos ────────────────────────────────────────────────────────
log "Descargando archivos de despliegue..."

curl -fsSL "${RAW}/nexcore-infra/deploy/Makefile"              -o "${INSTALL_DIR}/nexcore-infra/deploy/Makefile"
curl -fsSL "${RAW}/nexcore-infra/deploy/docker-compose.hub.yml" -o "${INSTALL_DIR}/nexcore-infra/deploy/docker-compose.hub.yml"
curl -fsSL "${RAW}/nexcore-infra/database/schema-nexcore.sql"   -o "${INSTALL_DIR}/nexcore-infra/database/schema-nexcore.sql"
curl -fsSL "${RAW}/nexcore-infra/database/01-migrate-base.sql"  -o "${INSTALL_DIR}/nexcore-infra/database/01-migrate-base.sql"
curl -fsSL "${RAW}/nexcore-infra/deploy/.env.example"           -o "${INSTALL_DIR}/.env.example"

# ── Crear .env desde la plantilla ────────────────────────────────────────────
if [[ ! -f "${INSTALL_DIR}/.env" ]]; then
    cp "${INSTALL_DIR}/.env.example" "${INSTALL_DIR}/.env"
    log ".env creado desde .env.example"
fi

# ── Resultado ─────────────────────────────────────────────────────────────────
echo ""
echo "  ╔══════════════════════════════════════════════════════════════╗"
echo "  ║  NexCore descargado en: ${INSTALL_DIR}"
echo "  ║"
echo "  ║  Pasos siguientes:"
echo "  ║"
echo "  ║  1. Edita el archivo .env:"
echo "  ║       nano ${INSTALL_DIR}/.env"
echo "  ║"
echo "  ║  2. Instala la base de datos (solo la primera vez):"
echo "  ║       cd ${INSTALL_DIR}/nexcore-infra/deploy"
echo "  ║       make install"
echo "  ║"
echo "  ║  3. Levanta todos los servicios:"
echo "  ║       make up-hub"
echo "  ║"
echo "  ║  URLs tras el arranque:"
echo "  ║    Frontend : http://localhost:4200"
echo "  ║    API core : http://localhost:8080"
echo "  ║    API auth : http://localhost:8081"
echo "  ╚══════════════════════════════════════════════════════════════╝"
echo ""
