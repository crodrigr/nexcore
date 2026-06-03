#!/bin/bash
# =============================================================================
# NexCore — EC2 User Data
# AMI objetivo : Ubuntu 24.04 LTS (arm64 o x86_64)
# Instala      : git · make · Java 25 (Temurin) · Node 22 LTS · Angular CLI
#                Docker Engine · Docker Compose plugin
# Uso          : pegar este script en "Advanced details > User data" al crear
#                la instancia, o ejecutarlo manualmente:
#                  chmod +x ec2-user-data.sh && sudo ./ec2-user-data.sh
# =============================================================================
set -euo pipefail

NEXCORE_USER="${NEXCORE_USER:-ubuntu}"          # usuario OS de la instancia
NEXCORE_REPO="${NEXCORE_REPO:-}"               # ej. git@github.com:org/nexcore.git
NEXCORE_DIR="/home/${NEXCORE_USER}/nexcore"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

# ── 1. Sistema base ───────────────────────────────────────────────────────────
log "1/7 Actualizando paquetes base..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y \
    git make curl wget unzip gnupg ca-certificates \
    lsb-release apt-transport-https software-properties-common

# ── 2. Docker Engine + Compose plugin ────────────────────────────────────────
log "2/7 Instalando Docker Engine..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl enable --now docker
usermod -aG docker "${NEXCORE_USER}"

# ── 3. Java 25 (Eclipse Temurin) ─────────────────────────────────────────────
log "3/7 Instalando Java 25 (Eclipse Temurin)..."
wget -qO /etc/apt/keyrings/adoptium.asc \
    https://packages.adoptium.net/artifactory/api/gpg/key/public

echo \
  "deb [signed-by=/etc/apt/keyrings/adoptium.asc] \
  https://packages.adoptium.net/artifactory/deb \
  $(lsb_release -cs) main" \
  > /etc/apt/sources.list.d/adoptium.list

apt-get update -y
apt-get install -y temurin-25-jdk

# JAVA_HOME global
JAVA_HOME_PATH="$(dirname "$(dirname "$(readlink -f "$(which java)")")")"
cat > /etc/profile.d/java.sh <<EOF
export JAVA_HOME=${JAVA_HOME_PATH}
export PATH=\$JAVA_HOME/bin:\$PATH
EOF
export JAVA_HOME="${JAVA_HOME_PATH}"
export PATH="${JAVA_HOME}/bin:${PATH}"

java -version

# ── 4. Node.js 22 LTS ─────────────────────────────────────────────────────────
log "4/7 Instalando Node.js 22 LTS..."
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs

node --version
npm --version

# ── 5. Angular CLI ────────────────────────────────────────────────────────────
log "5/7 Instalando Angular CLI..."
npm install -g @angular/cli

ng version --skip-git 2>/dev/null || true

# ── 6. Gradle wrapper — permisos de ejecución (se descarga solo al usar ./gradlew)
log "6/7 Herramientas auxiliares listas (Gradle wrapper se descarga al compilar)."

# ── 7. Clonar el repositorio (opcional) ──────────────────────────────────────
if [[ -n "${NEXCORE_REPO}" ]]; then
    log "7/7 Clonando ${NEXCORE_REPO} en ${NEXCORE_DIR}..."
    sudo -u "${NEXCORE_USER}" git clone "${NEXCORE_REPO}" "${NEXCORE_DIR}"

    # Crear .env a partir de .env.example si existe
    if [[ -f "${NEXCORE_DIR}/.env.example" && ! -f "${NEXCORE_DIR}/.env" ]]; then
        sudo -u "${NEXCORE_USER}" cp "${NEXCORE_DIR}/.env.example" "${NEXCORE_DIR}/.env"
        log "  → .env creado desde .env.example  ⚠ Edita las variables antes de continuar."
    fi

    log ""
    log "  ╔══════════════════════════════════════════════════════════╗"
    log "  ║  Pasos siguientes:                                       ║"
    log "  ║  1. Edita ${NEXCORE_DIR}/.env con tus valores           ║"
    log "  ║  2. cd ${NEXCORE_DIR}                                   ║"
    log "  ║  3. make install   ← levanta infra + crea BD            ║"
    log "  ║  4. make up        ← compila y levanta todos los apps   ║"
    log "  ╚══════════════════════════════════════════════════════════╝"
    log ""
else
    log "7/7 NEXCORE_REPO no definida — omitiendo clonado."
    log ""
    log "  ╔══════════════════════════════════════════════════════════╗"
    log "  ║  Pasos siguientes:                                       ║"
    log "  ║  1. Clona el repo: git clone <url> ~/nexcore            ║"
    log "  ║  2. Copia .env.example → .env y ajusta las variables    ║"
    log "  ║  3. cd ~/nexcore                                        ║"
    log "  ║  4. make install   ← levanta infra + crea BD            ║"
    log "  ║  5. make up        ← compila y levanta todos los apps   ║"
    log "  ╚══════════════════════════════════════════════════════════╝"
    log ""
fi

log "Instalación completada."
log "  java   : $(java -version 2>&1 | head -1)"
log "  node   : $(node --version)"
log "  npm    : $(npm --version)"
log "  ng     : $(ng version --skip-git 2>/dev/null | grep 'Angular CLI' | head -1 || echo 'ok')"
log "  docker : $(docker --version)"
log "  compose: $(docker compose version)"
