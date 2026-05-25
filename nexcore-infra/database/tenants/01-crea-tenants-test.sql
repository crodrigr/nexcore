WITH seed AS (
  SELECT
    gs AS n,
    format('batch-tenant-%s', lpad(gs::text, 2, '0')) AS slug_value
  FROM generate_series(1, 20) AS gs
)
INSERT INTO nxc_tenant.tenants (
  slug,
  name,
  legal_name,
  tax_id,
  plan,
  mode,
  status,
  active,
  timezone,
  locale,
  date_format,
  currency,
  mfa_required,
  session_timeout_minutes,
  max_login_attempts,
  password_min_length,
  password_requires_upper,
  password_requires_special,
  audit_retention_days,
  created_at,
  updated_at,
  version
)
SELECT
  s.slug_value,
  format('Batch Tenant %s', lpad(s.n::text, 2, '0')),
  format('Batch Tenant %s S.A.S.', lpad(s.n::text, 2, '0')),
  format('900100%03s-%s', s.n::text, (s.n % 9) + 1),
  CASE
    WHEN s.n <= 5 THEN 'FREE'::nxc_tenant.tenant_plan
    WHEN s.n <= 10 THEN 'STARTER'::nxc_tenant.tenant_plan
    WHEN s.n <= 15 THEN 'PROFESSIONAL'::nxc_tenant.tenant_plan
    ELSE 'ENTERPRISE'::nxc_tenant.tenant_plan
  END,
  CASE
    WHEN s.n % 3 = 1 THEN 'SAAS_SHARED'::nxc_tenant.tenant_mode
    WHEN s.n % 3 = 2 THEN 'SAAS_DEDICATED'::nxc_tenant.tenant_mode
    ELSE 'ON_PREMISE'::nxc_tenant.tenant_mode
  END,
  CASE
    WHEN s.n % 4 = 0 THEN 'TRIAL'::nxc_tenant.tenant_status
    ELSE 'ACTIVE'::nxc_tenant.tenant_status
  END,
  TRUE,
  'America/Bogota',
  'es-CO',
  'DD/MM/YYYY',
  'COP',
  FALSE,
  480,
  5,
  8,
  TRUE,
  FALSE,
  90,
  NOW(),
  NOW(),
  0
FROM seed s
WHERE NOT EXISTS (
  SELECT 1
  FROM nxc_tenant.tenants t
  WHERE t.slug = s.slug_value
    AND t.deleted_at IS NULL
);

COMMIT;

-- Verificación
SELECT id, slug, name, status, plan, mode
FROM nxc_tenant.tenants
WHERE slug LIKE 'batch-tenant-%'
  AND deleted_at IS NULL
ORDER BY slug;