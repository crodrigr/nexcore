#!/bin/bash
# Script para recrear el schema de base de datos (sin datos de demo)

echo "==========================================="
echo "Recreando schema de base de datos nexcore"
echo "==========================================="
echo "ADVERTENCIA: Esto eliminará TODOS los datos existentes"
echo "Presiona Ctrl+C para cancelar o Enter para continuar..."
read

docker exec -i postgres-db psql -U admin -d nexcore < /home/crodrigr/Documents/Proyectos/nexcore/nexcore-infra/database/schema-nexcore.sql

echo ""
echo "==========================================="
echo "Schema recreado exitosamente"
echo "==========================================="
