import { inject } from '@angular/core';
import { CanActivateChildFn, Router } from '@angular/router';

interface StoredPermission {
  route: string | null;
  access: string;
}

interface StoredMenuItem {
  route: string | null;
  access: string;
  children?: StoredMenuItem[];
}

interface StoredProfile {
  permissions: StoredPermission[];
  menus: StoredMenuItem[];
}

// Extrae recursivamente todas las rutas execute de menus[] incluyendo hijos
function flattenMenuRoutes(menus: StoredMenuItem[]): string[] {
  const routes: string[] = [];
  for (const menu of menus ?? []) {
    if (menu.route && menu.access === 'execute') {
      routes.push(menu.route);
    }
    if (menu.children?.length) {
      routes.push(...flattenMenuRoutes(menu.children));
    }
  }
  return routes;
}

export const permissionGuard: CanActivateChildFn = (_childRoute, state) => {
  const router = inject(Router);

  const stored = localStorage.getItem('profile');
  if (!stored) return router.createUrlTree(['/auth/login']);

  try {
    const profile: StoredProfile = JSON.parse(stored);

    // Fuente 1: permissions[] con route explícita y access execute
    const fromPermissions = (profile.permissions ?? [])
      .filter((p): p is StoredPermission & { route: string } => !!p.route && p.access === 'execute')
      .map(p => p.route);

    // Fuente 2: menus[] aplanado recursivamente (incluye hijos como /users, /permissions)
    const fromMenus = flattenMenuRoutes(profile.menus ?? []);

    // Unión sin duplicados
    const allowedRoutes = [...new Set([...fromPermissions, ...fromMenus])];

    const targetPath = state.url.split('?')[0].split('#')[0];

    const isAllowed = allowedRoutes.some(
      route => targetPath === route || targetPath.startsWith(route + '/')
    );

    if (isAllowed) return true;

    const hasDashboard = allowedRoutes.includes('/dashboard');
    return router.createUrlTree([hasDashboard ? '/dashboard' : '/auth/login']);
  } catch {
    return router.createUrlTree(['/auth/login']);
  }
};
