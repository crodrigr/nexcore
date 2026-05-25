-- Verificación previa
SELECT count(*) AS tenants_a_eliminar
FROM nxc_tenant.tenants
WHERE slug LIKE 'batch-tenant-%';

-- Eliminación
DELETE FROM nxc_tenant.tenants
WHERE slug LIKE 'batch-tenant-%';

COMMIT;

-- Verificación final
SELECT count(*) AS tenants_restantes
FROM nxc_tenant.tenants
WHERE slug LIKE 'batch-tenant-%';