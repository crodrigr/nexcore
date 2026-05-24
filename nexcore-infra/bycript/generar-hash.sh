#!/bin/bash
# =============================================================================
# GENERADOR DE HASH BCRYPT - Versión Ultra Simple
# =============================================================================
# Este script genera hashes BCrypt para contraseñas de NexCore
# Usa el contenedor de PostgreSQL que ya tienes corriendo
# =============================================================================

if [ -z "$1" ]; then
    echo "════════════════════════════════════════════════════════════════"
    echo "  GENERADOR DE HASH BCRYPT para NexCore"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "USO:"
    echo "  $0 \"TuContraseña\""
    echo ""
    echo "EJEMPLO:"
    echo "  $0 \"Admin123\""
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    exit 1
fi

PASSWORD="$1"

echo "════════════════════════════════════════════════════════════════"
echo "  Generando hash BCrypt para: $PASSWORD"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Generar hash usando PostgreSQL pgcrypto (crypt con blowfish)
HASH=$(docker exec postgres-db psql -U admin -d nexcore -t -c "SELECT crypt('$PASSWORD', gen_salt('bf', 12));" 2>/dev/null | tr -d ' ')

if [ -z "$HASH" ]; then
    echo "❌ Error: No se pudo generar el hash"
    echo ""
    echo "Verifica que:"
    echo "  1. El contenedor postgres-db esté corriendo"
    echo "  2. La extensión pgcrypto esté instalada"
    echo ""
    echo "Para instalar pgcrypto:"
    echo "  docker exec postgres-db psql -U admin -d nexcore -c 'CREATE EXTENSION IF NOT EXISTS pgcrypto;'"
    echo ""
    exit 1
fi

echo "✅ HASH GENERADO:"
echo ""
echo "$HASH"
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  Copia este hash para usar en tus scripts SQL"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Ejemplo de uso en SQL:"
echo "  UPDATE nxc_tenant.users SET password_hash = '$HASH' WHERE username = 'admin.demo';"
echo ""
