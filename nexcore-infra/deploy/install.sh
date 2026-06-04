#!/usr/bin/env bash
# =============================================================================
# NexCore — Instalador rápido
# Uso: curl -fsSL https://raw.githubusercontent.com/crodrigr/nexcore/master/nexcore-infra/deploy/install.sh | bash
# =============================================================================
set -euo pipefail

# ── Configura tu repositorio GitHub aquí ──────────────────────────────────────
GITHUB_ORG="crodrigr"
GITHUB_REPO="nexcore"
GITHUB_BRANCH="master"
# ─────────────────────────────────────────────────────────────────────────────

RAW="https://raw.githubusercontent.com/${GITHUB_ORG}/${GITHUB_REPO}/${GITHUB_BRANCH}"
INSTALL_DIR="${HOME}/nexcore"

log()  { echo "[nexcore] $*"; }
fail() { echo "[nexcore] ERROR: $*" >&2; exit 1; }

fetch() {
    curl -fsSL "$1" -o "$2"
}

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

fetch "${RAW}/nexcore-infra/deploy/Makefile"               "${INSTALL_DIR}/nexcore-infra/deploy/Makefile"
fetch "${RAW}/nexcore-infra/deploy/docker-compose.hub.yml" "${INSTALL_DIR}/nexcore-infra/deploy/docker-compose.hub.yml"
fetch "${RAW}/nexcore-infra/database/schema-nexcore.sql"   "${INSTALL_DIR}/nexcore-infra/database/schema-nexcore.sql"
fetch "${RAW}/nexcore-infra/database/01-migrate-base.sql"  "${INSTALL_DIR}/nexcore-infra/database/01-migrate-base.sql"
fetch "${RAW}/nexcore-infra/deploy/.env.example"           "${INSTALL_DIR}/.env.example"

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
