// Proxy del servidor de desarrollo Angular (ng serve).
// Los targets se leen desde las variables de entorno exportadas por el .env raíz.
//   CORE_BASE_URL → destino para /api  (default: http://localhost:8080)
//   AUTH_BASE_URL → destino para /auth (default: http://localhost:8081)

const coreTarget = process.env.CORE_BASE_URL || 'http://localhost:8080';
const authTarget = process.env.AUTH_BASE_URL || 'http://localhost:8081';

module.exports = {
  '/api': {
    target: coreTarget,
    secure: false,
    changeOrigin: true,
    logLevel: 'debug'
  },
  '/auth': {
    target: authTarget,
    secure: false,
    changeOrigin: true,
    logLevel: 'debug'
  }
};
