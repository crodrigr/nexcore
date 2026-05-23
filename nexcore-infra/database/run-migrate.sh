#!/bin/bash
# Script para ejecutar el schema y migración de base de datos

echo "==========================================="
echo "Recreando schema de base de datos nexcore"
echo "==========================================="
docker exec -i postgres-db psql -U admin -d nexcore < /home/crodrigr/Documents/Proyectos/nexcore/nexcore-infra/database/schema-nexcore.sql

echo ""
echo "==========================================="
echo "Ejecutando migración de datos iniciales"
echo "==========================================="
docker exec -i postgres-db psql -U admin -d nexcore < /home/crodrigr/Documents/Proyectos/nexcore/nexcore-infra/database/02-migrate-base.sql

echo ""
echo "==========================================="
echo "¡Proceso completado!"
echo "==========================================="
