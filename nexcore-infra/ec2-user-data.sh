#!/bin/bash
# =============================================================================
# NexCore — EC2 User Data
# AMI objetivo : Ubuntu 24.04 LTS (arm64 o x86_64)
# Instala      : git · make · Java 25 (Temurin-25+36) · Gradle 9.5.1
#                Node 20 LTS · Angular CLI 20.1.4 · Docker Engine · Docker Compose plugin
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
log "1/8 Actualizando paquetes base..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y \
    git make curl wget unzip gnupg ca-certificates \
    lsb-release apt-transport-https software-properties-common

# ── 2. Docker Engine + Compose plugin ────────────────────────────────────────
log "2/8 Instalando Docker Engine..."
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

# Permitir acceso al socket sin necesidad de cerrar sesión SSH.
# usermod asigna el grupo, pero las sesiones ya abiertas no lo ven hasta
# reconectar. El override de systemd mantiene el permiso tras reinicios.
mkdir -p /etc/systemd/system/docker.socket.d/
cat > /etc/systemd/system/docker.socket.d/override.conf << 'EOF'
[Socket]
SocketMode=0660
SocketGroup=docker
EOF
systemctl daemon-reload
systemctl restart docker
chmod 660 /var/run/docker.sock
chown root:docker /var/run/docker.sock

# ── 3. Java 25 (Eclipse Temurin) ─────────────────────────────────────────────
log "3/8 Instalando Java 25 (Eclipse Temurin)..."
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

# ── 4. Gradle ────────────────────────────────────────────────────────────────
log "4/8 Instalando Gradle..."
GRADLE_VERSION="9.5.1"
wget -q "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" \
    -O /tmp/gradle.zip
unzip -q /tmp/gradle.zip -d /opt/gradle
ln -sf "/opt/gradle/gradle-${GRADLE_VERSION}/bin/gradle" /usr/local/bin/gradle
rm /tmp/gradle.zip

cat > /etc/profile.d/gradle.sh <<'EOF'
export PATH=/usr/local/bin:$PATH
EOF

gradle --version

# ── 5. Node.js 22 LTS ─────────────────────────────────────────────────────────
log "5/8 Instalando Node.js 20 LTS..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

npm install -g npm@10.8.2

node --version
npm --version

# ── 6. Angular CLI ────────────────────────────────────────────────────────────
log "6/8 Instalando Angular CLI..."
npm install -g @angular/cli@20.1.4

ng version --skip-git 2>/dev/null || true

# ── 7. Gradle wrapper — asegurar permisos de ejecución en el repo ─────────────
log "7/8 Preparando permisos del Gradle wrapper (se aplica si el repo ya está clonado)."
find /home/"${NEXCORE_USER}" -name "gradlew" -exec chmod +x {} \; 2>/dev/null || true

# ── 8. Clonar el repositorio (opcional) ──────────────────────────────────────
if [[ -n "${NEXCORE_REPO}" ]]; then
    log "8/8 Clonando ${NEXCORE_REPO} en ${NEXCORE_DIR}..."
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
    log "8/8 NEXCORE_REPO no definida — omitiendo clonado."
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

# ── Activar grupo docker en sesión actual (ejecución manual) ─────────────────
# Cuando corre vía cloud-init al primer boot, ubuntu no tiene sesión aún y
# usermod es suficiente. Si se ejecutó manualmente, refreshea el grupo ahora.
if [[ -t 1 ]]; then
    log ""
    log "Script ejecutado manualmente. Activando grupo docker en esta sesión..."
    exec newgrp docker
fi

log "Instalación completada."
log "  java   : $(java -version 2>&1 | head -1)"
log "  gradle : $(gradle --version | grep '^Gradle' | head -1)"
log "  node   : $(node --version)"
log "  npm    : $(npm --version)"
log "  ng     : $(ng version --skip-git 2>/dev/null | grep 'Angular CLI' | head -1 || echo 'ok')"
log "  docker : $(docker --version)"
log "  compose: $(docker compose version)"
