// Environment configuration (development)
export const environment = {
  production: false,
  authBaseUrl: 'http://localhost:8081',
  coreBaseUrl: '',
  endpoints: {
    login: '/auth/login',
    verifyOtp: '/auth/verify-otp',
    // Endpoint according to Postman collection
    forgotPassword: '/auth/password/reset/request',
    changePassword: '/auth/password',
    confirmReset: '/auth/password/reset/confirm'
  }
  ,
  // Default tenant used for unauthenticated flows (can be overridden)
  defaultTenantId: '00000000-0000-0000-0000-000000000001'
};
