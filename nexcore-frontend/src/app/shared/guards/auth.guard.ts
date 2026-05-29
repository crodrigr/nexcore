import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';

function isTokenValid(token: string): boolean {
  try {
    const parts = token.split('.');
    if (parts.length < 2) return false;
    const payload = parts[1].replace(/-/g, '+').replace(/_/g, '/');
    const padded = payload.padEnd(payload.length + ((4 - (payload.length % 4)) % 4), '=');
    const claims = JSON.parse(atob(padded)) as Record<string, unknown>;
    const exp = claims['exp'];
    if (typeof exp !== 'number') return true; // sin exp → aceptar
    return Date.now() / 1000 < exp;
  } catch {
    return false;
  }
}

export const authGuard: CanActivateFn = () => {
  const router = inject(Router);
  const token = localStorage.getItem('accessToken');

  if (token && isTokenValid(token)) {
    return true;
  }

  // Limpiar sesión corrupta o expirada
  localStorage.removeItem('accessToken');
  localStorage.removeItem('refreshToken');
  localStorage.removeItem('profile');

  return router.createUrlTree(['/auth/login']);
};
