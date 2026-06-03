const fs   = require('fs');
const path = require('path');

const authBaseUrl = process.env.AUTH_BASE_URL  ?? 'http://localhost:8081';
const coreBaseUrl = process.env.CORE_BASE_URL  ?? '';

const content = `// Auto-generado por scripts/set-env.js — no editar manualmente.
// Valores configurables desde el .env raíz del proyecto:
//   AUTH_BASE_URL   (vacío = nginx proxy, 'http://host:8081' = directo)
//   CORE_BASE_URL   (vacío = nginx proxy, 'http://host:8080' = directo)
export const environment = {
  production: false,
  authBaseUrl: '${authBaseUrl}',
  coreBaseUrl: '${coreBaseUrl}',
  endpoints: {
    login: '/auth/login',
    verifyOtp: '/auth/verify-otp',
    forgotPassword: '/auth/password/reset/request',
    changePassword: '/auth/password',
    confirmReset: '/auth/password/reset/confirm'
  },
  defaultTenantId: '00000000-0000-0000-0000-000000000001'
};
`;

const target = path.resolve(__dirname, '../src/environments/environment.ts');
fs.writeFileSync(target, content, 'utf-8');
console.log(`[set-env] authBaseUrl="${authBaseUrl}" coreBaseUrl="${coreBaseUrl}"`);
