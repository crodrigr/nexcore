// Auto-generado por scripts/set-env.js — no editar manualmente.
// Valores configurables desde el .env raíz del proyecto:
//   AUTH_BASE_URL   (vacío = nginx proxy, 'http://host:8081' = directo)
//   CORE_BASE_URL   (vacío = nginx proxy, 'http://host:8080' = directo)
export const environment = {
  production: false,
  authBaseUrl: '',
  coreBaseUrl: '',
  endpoints: {
    login: '/auth/login',
    verifyOtp: '/auth/verify-otp',
    forgotPassword: '/auth/password/reset/request',
    changePassword: '/auth/password',
    confirmReset: '/auth/password/reset/confirm'
  },
  defaultTenantId: '00000000-0000-0000-0000-000000000001'
};
