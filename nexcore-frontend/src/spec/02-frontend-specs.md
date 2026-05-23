# NexCore Frontend — Especificación de Diseño e Implementación
**Versión:** 1.0  
**Fecha:** 2026-05  
**Estado:** En desarrollo activo  
**Para:** Stitch AI & Equipo Frontend

---

## 1. Visión General

El frontend de NexCore es una aplicación Angular 18 construida con **Nx workspace**, diseñada para ser:

- **Multi-tenant**: renderiza UI según permisos dinámicos del tenant
- **Themeable**: soporte nativo de modo **Light** y **Dark** con tokens de diseño
- **Modular**: feature libraries organizadas por dominio
- **Accesible**: WCAG 2.1 AA compliance
- **Responsive**: diseño mobile-first con breakpoints consistentes
- **Mantenible**: arquitectura de estilos centralizada y escalable

### 1.1 Estructura del Proyecto

```
nexcore-frontend/                           # Nx Workspace root
├── apps/
│   └── web/                                # Aplicación principal
│       ├── src/
│       │   ├── app/
│       │   │   ├── app.component.ts        # Root component
│       │   │   ├── app.component.scss
│       │   │   ├── app.config.ts           # App configuration
│       │   │   ├── app.routes.ts           # Routing principal
│       │   │   └── core/                   # Core singleton services
│       │   │       ├── guards/
│       │   │       │   ├── auth.guard.ts
│       │   │       │   └── permission.guard.ts
│       │   │       ├── interceptors/
│       │   │       │   ├── auth.interceptor.ts
│       │   │       │   ├── error.interceptor.ts
│       │   │       │   └── tenant.interceptor.ts
│       │   │       └── services/
│       │   │           ├── auth.service.ts
│       │   │           ├── notification.service.ts
│       │   │           └── websocket.service.ts
│       │   ├── assets/
│       │   │   ├── images/
│       │   │   │   ├── logo-light.svg
│       │   │   │   ├── logo-dark.svg
│       │   │   │   └── favicon.ico
│       │   │   ├── fonts/
│       │   │   │   ├── inter/
│       │   │   │   └── roboto/
│       │   │   └── i18n/
│       │   │       ├── en.json
│       │   │       └── es.json
│       │   ├── environments/
│       │   │   ├── environment.ts
│       │   │   └── environment.prod.ts
│       │   ├── index.html
│       │   ├── main.ts
│       │   └── styles.scss                 # Global styles import
│       ├── project.json
│       └── tsconfig.app.json
│
├── libs/                                   # Shared libraries
│   ├── features/                           # Feature modules
│   │   ├── auth/                           # Módulo de autenticación
│   │   │   ├── src/
│   │   │   │   ├── lib/
│   │   │   │   │   ├── auth.routes.ts      # Rutas del módulo
│   │   │   │   │   ├── login/
│   │   │   │   │   │   ├── login.component.ts
│   │   │   │   │   │   ├── login.component.html
│   │   │   │   │   │   ├── login.component.scss
│   │   │   │   │   │   └── login.component.spec.ts
│   │   │   │   │   ├── forgot-password/
│   │   │   │   │   │   ├── forgot-password.component.ts
│   │   │   │   │   │   ├── forgot-password.component.html
│   │   │   │   │   │   ├── forgot-password.component.scss
│   │   │   │   │   │   └── forgot-password.component.spec.ts
│   │   │   │   │   ├── reset-password/
│   │   │   │   │   │   ├── reset-password.component.ts
│   │   │   │   │   │   ├── reset-password.component.html
│   │   │   │   │   │   ├── reset-password.component.scss
│   │   │   │   │   │   └── reset-password.component.spec.ts
│   │   │   │   │   ├── verify-otp/
│   │   │   │   │   │   ├── verify-otp.component.ts
│   │   │   │   │   │   ├── verify-otp.component.html
│   │   │   │   │   │   ├── verify-otp.component.scss
│   │   │   │   │   │   └── verify-otp.component.spec.ts
│   │   │   │   │   └── index.ts
│   │   │   │   └── index.ts
│   │   │   └── project.json
│   │   │
│   │   ├── dashboard/                      # Dashboard principal
│   │   │   ├── src/
│   │   │   │   ├── lib/
│   │   │   │   │   ├── dashboard.routes.ts
│   │   │   │   │   ├── dashboard.component.ts
│   │   │   │   │   ├── dashboard.component.html
│   │   │   │   │   ├── dashboard.component.scss
│   │   │   │   │   ├── dashboard.component.spec.ts
│   │   │   │   │   ├── widgets/
│   │   │   │   │   │   ├── stats-card/
│   │   │   │   │   │   │   ├── stats-card.component.ts
│   │   │   │   │   │   │   ├── stats-card.component.html
│   │   │   │   │   │   │   └── stats-card.component.scss
│   │   │   │   │   │   ├── chart-widget/
│   │   │   │   │   │   │   ├── chart-widget.component.ts
│   │   │   │   │   │   │   ├── chart-widget.component.html
│   │   │   │   │   │   │   └── chart-widget.component.scss
│   │   │   │   │   │   └── recent-activity/
│   │   │   │   │   │       ├── recent-activity.component.ts
│   │   │   │   │   │       ├── recent-activity.component.html
│   │   │   │   │   │       └── recent-activity.component.scss
│   │   │   │   │   └── index.ts
│   │   │   │   └── index.ts
│   │   │   └── project.json
│   │   │
│   │   ├── tenants/                        # Gestión de tenants
│   │   │   ├── src/
│   │   │   │   ├── lib/
│   │   │   │   │   ├── tenants.routes.ts
│   │   │   │   │   ├── tenant-list/
│   │   │   │   │   │   ├── tenant-list.component.ts
│   │   │   │   │   │   ├── tenant-list.component.html
│   │   │   │   │   │   ├── tenant-list.component.scss
│   │   │   │   │   │   └── tenant-list.component.spec.ts
│   │   │   │   │   ├── tenant-create/
│   │   │   │   │   │   ├── tenant-create.component.ts
│   │   │   │   │   │   ├── tenant-create.component.html
│   │   │   │   │   │   └── tenant-create.component.scss
│   │   │   │   │   ├── tenant-detail/
│   │   │   │   │   │   ├── tenant-detail.component.ts
│   │   │   │   │   │   ├── tenant-detail.component.html
│   │   │   │   │   │   └── tenant-detail.component.scss
│   │   │   │   │   └── index.ts
│   │   │   │   └── index.ts
│   │   │   └── project.json
│   │   │
│   │   ├── menu-config/                    # Configuración de menús
│   │   │   ├── src/
│   │   │   │   ├── lib/
│   │   │   │   │   ├── menu-config.routes.ts
│   │   │   │   │   ├── component-list/
│   │   │   │   │   ├── element-list/
│   │   │   │   │   ├── menu-builder/
│   │   │   │   │   └── role-permissions/
│   │   │   │   └── index.ts
│   │   │   └── project.json
│   │   │
│   │   ├── user-profile/                   # Perfil de usuario
│   │   │   ├── src/
│   │   │   │   ├── lib/
│   │   │   │   │   ├── user-profile.routes.ts
│   │   │   │   │   ├── profile-view/
│   │   │   │   │   │   ├── profile-view.component.ts
│   │   │   │   │   │   ├── profile-view.component.html
│   │   │   │   │   │   ├── profile-view.component.scss
│   │   │   │   │   │   └── profile-view.component.spec.ts
│   │   │   │   │   ├── profile-edit/
│   │   │   │   │   │   ├── profile-edit.component.ts
│   │   │   │   │   │   ├── profile-edit.component.html
│   │   │   │   │   │   └── profile-edit.component.scss
│   │   │   │   │   ├── change-password/
│   │   │   │   │   │   ├── change-password.component.ts
│   │   │   │   │   │   ├── change-password.component.html
│   │   │   │   │   │   └── change-password.component.scss
│   │   │   │   │   └── index.ts
│   │   │   │   └── index.ts
│   │   │   └── project.json
│   │   │
│   │   └── settings/                       # Configuración del sistema
│   │       ├── src/
│   │       │   ├── lib/
│   │       │   │   ├── settings.routes.ts
│   │       │   │   ├── general-settings/
│   │       │   │   ├── notification-settings/
│   │       │   │   └── security-settings/
│   │       │   └── index.ts
│   │       └── project.json
│   │
│   ├── shared/                             # Código compartido
│   │   ├── ui/                             # Componentes de UI reutilizables
│   │   │   ├── src/
│   │   │   │   ├── lib/
│   │   │   │   │   ├── components/
│   │   │   │   │   │   ├── button/
│   │   │   │   │   │   │   ├── button.component.ts
│   │   │   │   │   │   │   ├── button.component.scss
│   │   │   │   │   │   │   ├── button.component.spec.ts
│   │   │   │   │   │   │   ├── button.types.ts
│   │   │   │   │   │   │   └── index.ts
│   │   │   │   │   │   ├── input/
│   │   │   │   │   │   │   ├── input.component.ts
│   │   │   │   │   │   │   ├── input.component.scss
│   │   │   │   │   │   │   └── index.ts
│   │   │   │   │   │   ├── card/
│   │   │   │   │   │   ├── modal/
│   │   │   │   │   │   ├── table/
│   │   │   │   │   │   ├── dropdown/
│   │   │   │   │   │   ├── tabs/
│   │   │   │   │   │   ├── breadcrumb/
│   │   │   │   │   │   ├── badge/
│   │   │   │   │   │   ├── avatar/
│   │   │   │   │   │   ├── skeleton/
│   │   │   │   │   │   ├── alert/
│   │   │   │   │   │   ├── spinner/
│   │   │   │   │   │   └── tooltip/
│   │   │   │   │   ├── layouts/
│   │   │   │   │   │   ├── app-layout/
│   │   │   │   │   │   │   ├── app-layout.component.ts
│   │   │   │   │   │   │   ├── app-layout.component.html
│   │   │   │   │   │   │   ├── app-layout.component.scss
│   │   │   │   │   │   │   └── index.ts
│   │   │   │   │   │   ├── auth-layout/
│   │   │   │   │   │   │   ├── auth-layout.component.ts
│   │   │   │   │   │   │   ├── auth-layout.component.html
│   │   │   │   │   │   │   ├── auth-layout.component.scss
│   │   │   │   │   │   │   └── index.ts
│   │   │   │   │   │   ├── dashboard-layout/
│   │   │   │   │   │   └── empty-layout/
│   │   │   │   │   ├── navigation/
│   │   │   │   │   │   ├── sidebar/
│   │   │   │   │   │   │   ├── sidebar.component.ts
│   │   │   │   │   │   │   ├── sidebar.component.html
│   │   │   │   │   │   │   ├── sidebar.component.scss
│   │   │   │   │   │   │   ├── sidebar-item/
│   │   │   │   │   │   │   │   ├── sidebar-item.component.ts
│   │   │   │   │   │   │   │   ├── sidebar-item.component.html
│   │   │   │   │   │   │   │   └── sidebar-item.component.scss
│   │   │   │   │   │   │   └── index.ts
│   │   │   │   │   │   ├── navbar/
│   │   │   │   │   │   │   ├── navbar.component.ts
│   │   │   │   │   │   │   ├── navbar.component.html
│   │   │   │   │   │   │   ├── navbar.component.scss
│   │   │   │   │   │   │   ├── user-menu/
│   │   │   │   │   │   │   │   ├── user-menu.component.ts
│   │   │   │   │   │   │   │   ├── user-menu.component.html
│   │   │   │   │   │   │   │   └── user-menu.component.scss
│   │   │   │   │   │   │   ├── notifications/
│   │   │   │   │   │   │   │   ├── notifications.component.ts
│   │   │   │   │   │   │   │   ├── notifications.component.html
│   │   │   │   │   │   │   │   └── notifications.component.scss
│   │   │   │   │   │   │   └── index.ts
│   │   │   │   │   │   ├── breadcrumbs/
│   │   │   │   │   │   └── menu/
│   │   │   │   │   ├── theme/
│   │   │   │   │   │   ├── theme.service.ts
│   │   │   │   │   │   ├── theme-toggle/
│   │   │   │   │   │   │   ├── theme-toggle.component.ts
│   │   │   │   │   │   │   ├── theme-toggle.component.scss
│   │   │   │   │   │   │   └── index.ts
│   │   │   │   │   │   └── index.ts
│   │   │   │   │   └── directives/
│   │   │   │   │       ├── has-permission.directive.ts
│   │   │   │   │       ├── click-outside.directive.ts
│   │   │   │   │       └── index.ts
│   │   │   │   ├── styles/                 # Sistema de diseño
│   │   │   │   │   ├── _tokens.scss
│   │   │   │   │   ├── tokens/
│   │   │   │   │   │   ├── _colors.scss
│   │   │   │   │   │   ├── _typography.scss
│   │   │   │   │   │   ├── _spacing.scss
│   │   │   │   │   │   ├── _shadows.scss
│   │   │   │   │   │   ├── _borders.scss
│   │   │   │   │   │   ├── _breakpoints.scss
│   │   │   │   │   │   └── _z-index.scss
│   │   │   │   │   ├── themes/
│   │   │   │   │   │   ├── _light.scss
│   │   │   │   │   │   ├── _dark.scss
│   │   │   │   │   │   └── _theme-base.scss
│   │   │   │   │   ├── _mixins.scss
│   │   │   │   │   ├── _utilities.scss
│   │   │   │   │   └── global.scss
│   │   │   │   └── index.ts
│   │   │   └── project.json
│   │   │
│   │   ├── data-access/                    # Servicios de datos
│   │   │   ├── src/
│   │   │   │   ├── lib/
│   │   │   │   │   ├── auth/
│   │   │   │   │   │   ├── auth.service.ts
│   │   │   │   │   │   ├── auth.store.ts
│   │   │   │   │   │   ├── auth.models.ts
│   │   │   │   │   │   └── index.ts
│   │   │   │   │   ├── tenants/
│   │   │   │   │   │   ├── tenant.service.ts
│   │   │   │   │   │   ├── tenant.store.ts
│   │   │   │   │   │   ├── tenant.models.ts
│   │   │   │   │   │   └── index.ts
│   │   │   │   │   ├── menu/
│   │   │   │   │   │   ├── menu.service.ts
│   │   │   │   │   │   ├── menu.store.ts
│   │   │   │   │   │   ├── menu.models.ts
│   │   │   │   │   │   └── index.ts
│   │   │   │   │   ├── user/
│   │   │   │   │   │   ├── user.service.ts
│   │   │   │   │   │   ├── user.store.ts
│   │   │   │   │   │   ├── user.models.ts
│   │   │   │   │   │   └── index.ts
│   │   │   │   │   └── index.ts
│   │   │   │   └── index.ts
│   │   │   └── project.json
│   │   │
│   │   └── utils/                          # Utilidades compartidas
│   │       ├── src/
│   │       │   ├── lib/
│   │       │   │   ├── validators/
│   │       │   │   │   ├── custom-validators.ts
│   │       │   │   │   └── index.ts
│   │       │   │   ├── helpers/
│   │       │   │   │   ├── date.helpers.ts
│   │       │   │   │   ├── string.helpers.ts
│   │       │   │   │   ├── array.helpers.ts
│   │       │   │   │   └── index.ts
│   │       │   │   ├── constants/
│   │       │   │   │   ├── api.constants.ts
│   │       │   │   │   ├── error.constants.ts
│   │       │   │   │   └── index.ts
│   │       │   │   └── index.ts
│   │       │   └── index.ts
│   │       └── project.json
│   │
│   └── testing/                            # Testing utilities
│       ├── src/
│       │   ├── lib/
│       │   │   ├── mocks/
│       │   │   ├── fixtures/
│       │   │   └── test-helpers.ts
│       │   └── index.ts
│       └── project.json
│
├── .storybook/                             # Storybook configuration
│   ├── main.ts
│   ├── preview.ts
│   └── theme.ts
│
├── tools/                                  # Custom Nx generators and executors
│   ├── generators/
│   └── executors/
│
├── .eslintrc.json                          # ESLint config
├── .prettierrc                             # Prettier config
├── jest.config.ts                          # Jest config
├── nx.json                                 # Nx workspace config
├── package.json
├── tsconfig.base.json                      # Base TypeScript config
└── README.md
```

### 1.2 Stack Tecnológico

| Tecnología | Versión | Propósito |
|---|---|---|
| **Angular** | 18 | Framework principal |
| **Nx** | Latest | Monorepo tooling |
| **TypeScript** | 5.x | Lenguaje |
| **SCSS** | Latest | Preprocessor CSS |
| **CSS Variables** | Native | Design tokens dinámicos |
| **Angular Material** | 18 | Componentes base (opcional) |
| **TailwindCSS** | 3.x | Utility-first CSS (opcional) |
| **RxJS** | 7.x | Reactive programming |
| **NgRx** | Latest | State management |
| **Chart.js** | 4.x | Visualización de datos |

---

## 2. Rutas y Navegación

### 2.1 Estructura de Rutas

```typescript
// apps/web/src/app/app.routes.ts
import { Routes } from '@angular/router';
import { AuthGuard } from './core/guards/auth.guard';
import { PermissionGuard } from './core/guards/permission.guard';

export const routes: Routes = [
  // Ruta raíz - redirect a dashboard o login
  {
    path: '',
    redirectTo: 'dashboard',
    pathMatch: 'full'
  },
  
  // Rutas públicas (sin autenticación)
  {
    path: 'auth',
    loadChildren: () => import('@nexcore/features/auth').then(m => m.AUTH_ROUTES),
    data: { layout: 'auth' }
  },
  
  // Rutas protegidas (requieren autenticación)
  {
    path: '',
    canActivate: [AuthGuard],
    3.1a: { layout: 'app' },
    children: [
      // Dashboard
      {
        path: 'dashboard',
        loadComponent: () => 
          import('@nexcore/features/dashboard').then(m => m.DashboardComponent),
        data: { 
          title: 'Dashboard',
          breadcrumb: 'Dashboard'
        }
      },
      
      // Perfil de usuario
      {
        path: 'profile',
        loadChildren: () => 
          import('@nexcore/features/user-profile').then(m => m.USER_PROFILE_ROUTES),
        data: { 
          title: 'Mi Perfil',
          breadcrumb: 'Perfil'
        }
      },
      
      // Gestión de Tenants (requiere permisos)
      {
        path: 'tenants',
        canActivate: [PermissionGuard],
        data: { 
          permission: { component: 'TENANT', element: 'VIEW' },
          title: 'Tenants',
          breadcrumb: 'Tenants'
        },
        loadChildren: () => 
          import('@nexcore/features/tenants').then(m => m.TENANTS_ROUTES)
      },
      
      // Configuración de Menús (requiere permisos)
      {
        path: 'menu-config',
        canActivate: [PermissionGuard],
        data: { 
          permission: { component: 'MENU', element: 'VIEW' },
          title: 'Configuración de Menús',
          breadcrumb: 'Menús'
        },
        loadChildren: () => 
          import('@nexcore/features/menu-config').then(m => m.MENU_CONFIG_ROUTES)
      },
      
      // Configuración del sistema (requiere permisos)
      {
        path: 'settings',
        canActivate: [PermissionGuard],
        data: { 
          permission: { component: 'SETTINGS', element: 'VIEW' },
          title: 'Configuración',
          breadcrumb: 'Configuración'
        },
        loadChildren: () => 
          import('@nexcore/features/settings').then(m => m.SETTINGS_ROUTES)
      }
    ]
  },
  
  // Ruta 404
  {
    path: '**',
    loadComponent: () => 
      import('./shared/pages/not-found/not-found.component').then(m => m.NotFoundComponent),
    data: { layout: 'empty' }
  }
];
```

### 2.2 Rutas del Módulo Auth

```typescript
// libs/features/auth/src/lib/auth.routes.ts
import { Routes } from '@angular/router';

export const AUTH_ROUTES: Routes = [
  {
    path: '',
    redirectTo: 'login',
    pathMatch: 'full'
  },
  {
    path: 'login',
    loadComponent: () => 
      import('./login/login.component').then(m => m.LoginComponent),
    data: { title: 'Iniciar Sesión' }
  },
  {
    path: 'verify-otp',
    loadComponent: () => 
      import('./verify-otp/verify-otp.component').then(m => m.VerifyOtpComponent),
    data: { title: 'Verificar Código' }
  },
  {
    path: 'forgot-password',
    loadComponent: () => 
      import('./forgot-password/forgot-password.component').then(m => m.ForgotPasswordComponent),
    data: { title: 'Recuperar Contraseña' }
  },
  {
    path: 'reset-password',
    loadComponent: () => 
      import('./reset-password/reset-password.component').then(m => m.ResetPasswordComponent),
    data: { title: 'Restablecer Contraseña' }
  }
];
```
3.2
### 2.3 Rutas del Módulo User Profile

```typescript
// libs/features/user-profile/src/lib/user-profile.routes.ts
import { Routes } from '@angular/router';

export const USER_PROFILE_ROUTES: Routes = [
  {
    path: '',
    loadComponent: () => 
      import('./profile-view/profile-view.component').then(m => m.ProfileViewComponent),
    data: { title: 'Mi Perfil' }
  },
  {
    path: 'edit',
    loadComponent: () => 
      import('./profile-edit/profile-edit.component').then(m => m.ProfileEditComponent),
    data: { title: 'Editar Perfil' }
  },
  {
    path: 'change-password',
    loadComponent: () => 
      import('./change-password/change-password.component').then(m => m.ChangePasswordComponent),
    data: { title: 'Cambiar Contraseña' }
  }
];
```

---

## 3. Sistema de Design Tokens

Los **design tokens** son la capa base del sistema de diseño. Todos los valores de color, tipografía, espaciado, sombras, etc., están centralizados en variables CSS y SCSS.

### 2.1 Estructura de Archivos

```
libs/
└── shared/
    └── ui/
        └── styles/
            ├── _tokens.scss          # Exporta todos los tokens
            ├── tokens/
            │   ├── _colors.scss      # Paleta de colores
            │   ├── _typography.scss  # Fuentes y tamaños
            │   ├── _spacing.scss     # Sistema de espaciado
            │   ├── _shadows.scss     # Elevaciones y sombras
            │   ├── _borders.scss     # Radios y bordes
            │   ├── _breakpoints.scss # Responsive breakpoints
            │   └── _z-index.scss     # Capas de apilamiento
            ├── themes/
            │   ├── _light.scss       # Tema claro
            │   ├── _dark.scss        # Tema oscuro
            │   └── _theme-base.scss  # Base compartida
            ├── _mixins.scss          # Mixins reutilizables
            ├── _utilities.scss       # Clases utilitarias
            └── global.scss           # Importación global
```

### 2.2 Tokens de Color

**Archivo:** `libs/shared/ui/styles/tokens/_colors.scss`

```scss
// ============================================================
// PALETA BASE — Colores primitivos (no usar directamente en componentes)
// =3.3========================================================

// Primarios
$color-primary-50:  #e3f2fd;
$color-primary-100: #bbdefb;
$color-primary-200: #90caf9;
$color-primary-300: #64b5f6;
$color-primary-400: #42a5f5;
$color-primary-500: #2196f3; // Base
$color-primary-600: #1e88e5;
$color-primary-700: #1976d2;
$color-primary-800: #1565c0;
$color-primary-900: #0d47a1;

// Secundarios (Accent)
$color-secondary-50:  #fce4ec;
$color-secondary-100: #f8bbd0;
$color-secondary-200: #f48fb1;
$color-secondary-300: #f06292;
$color-secondary-400: #ec407a;
$color-secondary-500: #e91e63; // Base
$color-secondary-600: #d81b60;
$color-secondary-700: #c2185b;
$color-secondary-800: #ad1457;
$color-secondary-900: #880e4f;

// Neutrales
$color-neutral-0:   #ffffff;
$color-neutral-50:  #fafafa;
$color-neutral-100: #f5f5f5;
$color-neutral-200: #eeeeee;
$color-neutral-300: #e0e0e0;
$color-neutral-400: #bdbdbd;
$color-neutral-500: #9e9e9e;
$color-neutral-600: #757575;
$color-neutral-700: #616161;
$color-neutral-800: #424242;
$color-neutral-900: #212121;
$color-neutral-1000: #000000;

// Estados (Feedback)
$color-success-50:  #e8f5e9;
$color-success-500: #4caf50;
$color-success-700: #388e3c;

$color-warning-50:  #fff3e0;
$color-warning-500: #ff9800;
$color-warning-700: #f57c00;

$color-error-50:  #ffebee;
$color-error-500: #f44336;
$color-error-700: #d32f2f;

$color-info-50:  #e1f5fe;
$color-info-500: #03a9f4;
$color-info-700: #0288d1;

// ============================================================
// TOKENS SEMÁNTICOS — Usar estos en componentes
// ============================================================

// Estos valores se sobrescriben en cada tema (light/dark)
:root {
  // Backgrounds
  --color-bg-primary: #{$color-neutral-0};
  --color-bg-secondary: #{$color-neutral-50};
  --color-bg-tertiary: #{$color-neutral-100};
  --color-bg-elevated: #{$color-neutral-0};
  --color-bg-overlay: rgba(0, 0, 0, 0.5);
  
  // Surfaces (cards, panels)
  --color-surface: #{$color-neutral-0};
  --color-surface-hover: #{$color-neutral-50};
  --color-surface-active: #{$color-neutral-100};
  
  // Textos
  --color-text-primary: #{$color-neutral-900};
  --color-text-secondary: #{$color-neutral-700};
  --color-text-tertiary: #{$color-neutral-600};
  --color-text-disabled: #{$color-neutral-400};
  --color-text-inverse: #{$color-neutral-0};
  
  // Bordes
  --color-border-light: #{$color-neutral-200};
  --color-border-medium: #{$color-neutral-300};
  --color-border-heavy: #{$color-neutral-400};
  
  // Interactivos
  --color-interactive-primary: #{$color-primary-500};
  --color-interactive-primary-hover: #{$color-primary-600};
  --color-interactive-primary-active: #{$color-primary-700};
  --color-interactive-secondary: #{$color-secondary-500};
  
  // Estados
  --color-success: #{$color-success-500};
  --color-warning: #{$color-warning-500};
  --color-error: #{$color-error-500};
  --color-info: #{$color-info-500};
  
  --color-success-bg: #{$color-success-50};
  --color-warning-bg: #{$color-warning-50};
  --color-error-bg: #{$color-error-50};
  --color-info-bg: #{$color-info-50};
}
```

### 2.3 Tokens de Tipografía

**Archivo:** `libs/shared/ui/styles/tokens/_typography.scss`

```scss
// ============================================================
// FUENTES
// ============================================================

$font-family-primary: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', 
                      Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
$font-family-secondary: 'Roboto', sans-serif;
$font-family-mono: 'JetBrains Mono', 'Fira Code', 'Courier New', monospace;

// ============================================================
// ESCALA TIPOGRÁFICA (Mobile-first)
// ============================================================

:root {
  // Tamaños base
  --font-size-xs: 0.75rem;    // 12px
  --font-size-sm: 0.875rem;   // 14px
  --font-size-base: 1rem;     // 16px
  --font-size-lg: 1.125rem;   // 18px
  --font-size-xl: 1.25rem;    // 20px
  --font-size-2xl: 1.5rem;    // 24px
  --font-size-3xl: 1.875rem;  // 30px
  --font-size-4xl: 2.25rem;   // 36px
  --font-size-5xl: 3rem;      // 48px
  
  // Headings
  --font-size-h1: var(--font-size-4xl);
  --font-size-h2: var(--font-size-3xl);
  --font-size-h3: var(--font-size-2xl);
  --font-size-h4: var(--font-size-xl);
  --font-size-h5: var(--font-size-lg);
  --font-size-h6: var(--font-size-base);
  
  // Line heights
  --line-height-tight: 1.25;
  --line-height-normal: 1.5;
  --line-height-relaxed: 1.75;
  
  // Font weights
  --font-weight-light: 300;
  --font-weight-normal: 400;
  --font-weight-medium: 500;
  --font-weight-semibold: 600;
  --font-weight-bold: 700;
  --font-weight-extrabold: 800;
  
  // Letter spacing
  --letter-spacing-tight: -0.025em;
  --letter-spacing-normal: 0;
  --letter-spacing-wide: 0.025em;
}

// Responsive type scale (Desktop)
@media (min-width: 1024px) {
  :root {
    --font-size-h1: 3.5rem;   // 56px
    --font-size-h2: 2.5rem;   // 40px
    --font-size-h3: 2rem;     // 32px
  }
}
```

### 2.4 Tokens de Espaciado

**Archivo:** `libs/shared/ui/styles/tokens/_spacing.scss`

```scss
// ============================================================
// ESCALA DE ESPACIADO (8px base)
// ============================================================

:root {
  --spacing-0: 0;
  --spacing-1: 0.25rem;   // 4px
  --spacing-2: 0.5rem;    // 8px
  --spacing-3: 0.75rem;   // 12px
  --spacing-4: 1rem;      // 16px
  --spacing-5: 1.25rem;   // 20px
  --spacing-6: 1.5rem;    // 24px
  --spacing-8: 2rem;      // 32px
  --spacing-10: 2.5rem;   // 40px
  --spacing-12: 3rem;     // 48px
  --spacing-16: 4rem;     // 64px
  --spacing-20: 5rem;     // 80px
  --spacing-24: 6rem;     // 96px
  --spacing-32: 8rem;     // 128px
  
  // Semantic spacing
  --spacing-xs: var(--spacing-1);
  --spacing-sm: var(--spacing-2);
  --spacing-md: var(--spacing-4);
  --spacing-lg: var(--spacing-6);
  --spacing-xl: var(--spacing-8);
  --spacing-2xl: var(--spacing-12);
  --spacing-3xl: var(--spacing-16);
}
```

### 3.4 Tokens de Sombras

**Archivo:** `libs/shared/ui/styles/tokens/_shadows.scss`

```scss
:root {
  // Elevaciones
  --shadow-sm: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
  --shadow-base: 0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06);
  --shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
  --shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
  --shadow-xl: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
  --shadow-2xl: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
  --shadow-inner: inset 0 2px 4px 0 rgba(0, 0, 0, 0.06);
  
  // Focus ring
  --shadow-focus: 0 0 0 3px rgba(66, 153, 225, 0.5);
  --shadow-focus-error: 0 0 0 3px rgba(245, 101, 101, 0.5);
}
```

### 3.5 Tokens de Bordes

**Archivo:** `libs/shared/ui/styles/tokens/_borders.scss`

```scss
:root {
  // Border widths
  --border-width-0: 0;
  --border-width-1: 1px;
  --border-width-2: 2px;
  --border-width-4: 4px;
  
  // Border radius
  --radius-none: 0;
  --radius-sm: 0.125rem;   // 2px
  --radius-base: 0.25rem;  // 4px
  --radius-md: 0.375rem;   // 6px
  --radius-lg: 0.5rem;     // 8px
  --radius-xl: 0.75rem;    // 12px
  --radius-2xl: 1rem;      // 16px
  --radius-full: 9999px;
}
```

### 3.6 Breakpoints Responsivos

**Archivo:** `libs/shared/ui/styles/tokens/_breakpoints.scss`

```scss
// ============================================================
// BREAKPOINTS (Mobile-first)
// ============================================================

$breakpoint-sm: 640px;   // Phones (landscape)
$breakpoint-md: 768px;   // Tablets
$breakpoint-lg: 1024px;  // Laptops
$breakpoint-xl: 1280px;  // Desktops
$breakpoint-2xl: 1536px; // Large screens

// Mixins para uso en componentes
@mixin respond-to-sm {
  @media (min-width: $breakpoint-sm) { @content; }
}

@mixin respond-to-md {
  @media (min-width: $breakpoint-md) { @content; }
}

@mixin respond-to-lg {
  @media (min-width: $breakpoint-lg) { @content; }
}

@mixin respond-to-xl {
  @media (min-width: $breakpoint-xl) { @content; }
}

@mixin respond-to-2xl {
  @media (min-width: $breakpoint-2xl) { @content; }
}
```

### 3.7 Z-Index Scale

**Archivo:** `libs/shared/ui/styles/tokens/_z-index.scss`

```scss
:root {
  --z-base: 0;
  --z-dropdown: 1000;
  --z-sticky: 1020;
  --z-fixed: 1030;
  --z-modal-backdrop: 1040;
  --z-modal: 1050;
  --z-popover: 1060;
  --z-tooltip: 1070;
  --z-notification: 1080;
}
```

---

## 4. Sistema de Temas (Light / Dark)

### 4.1 Estructura de Temas

Los temas sobrescriben las **CSS custom properties** definidas en `_colors.scss`. El cambio de tema es reactivo mediante el atributo `[data-theme]` en el `<body>`.

**Archivo:** `libs/shared/ui/styles/themes/_light.scss`

```scss
[data-theme='light'] {
  // Backgrounds
  --color-bg-primary: #{$color-neutral-0};
  --color-bg-secondary: #{$color-neutral-50};
  --color-bg-tertiary: #{$color-neutral-100};
  --color-bg-elevated: #{$color-neutral-0};
  --color-bg-overlay: rgba(0, 0, 0, 0.5);
  
  // Surfaces
  --color-surface: #{$color-neutral-0};
  --color-surface-hover: #{$color-neutral-50};
  --color-surface-active: #{$color-neutral-100};
  
  // Texts
  --color-text-primary: #{$color-neutral-900};
  --color-text-secondary: #{$color-neutral-700};
  --color-text-tertiary: #{$color-neutral-600};
  --color-text-disabled: #{$color-neutral-400};
  --color-text-inverse: #{$color-neutral-0};
  
  // Borders
  --color-border-light: #{$color-neutral-200};
  --color-border-medium: #{$color-neutral-300};
  --color-border-heavy: #{$color-neutral-400};
  
  // Shadows (más intensas en light)
  --shadow-sm: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
  --shadow-base: 0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06);
  --shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
  --shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
}
```

**Archivo:** `libs/shared/ui/styles/themes/_dark.scss`

```scss
[data-theme='dark'] {
  // Backgrounds (invertidos)
  --color-bg-primary: #{$color-neutral-900};
  --color-bg-secondary: #{$color-neutral-800};
  --color-bg-tertiary: #{$color-neutral-700};
  --color-bg-elevated: #{$color-neutral-800};
  --color-bg-overlay: rgba(0, 0, 0, 0.7);
  
  // Surfaces
  --color-surface: #{$color-neutral-800};
  --color-surface-hover: #{$color-neutral-700};
  --color-surface-active: #{$color-neutral-600};
  
  // Texts (invertidos)
  --color-text-primary: #{$color-neutral-50};
  --color-text-secondary: #{$color-neutral-300};
  --color-text-tertiary: #{$color-neutral-400};
  --color-text-disabled: #{$color-neutral-600};
  --color-text-inverse: #{$color-neutral-900};
  
  // Borders (más sutiles)
  --color-border-light: #{$color-neutral-700};
  --color-border-medium: #{$color-neutral-600};
  --color-border-heavy: #{$color-neutral-500};
  
  // Shadows (más sutiles en dark)
  --shadow-sm: 0 1px 2px 0 rgba(0, 0, 0, 0.3);
  --shadow-base: 0 1px 3px 0 rgba(0, 0, 0, 0.4), 0 1px 2px 0 rgba(0, 0, 0, 0.3);
  --shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.4), 0 2px 4px -1px rgba(0, 0, 0, 0.3);
  --shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.5), 0 4px 6px -2px rgba(0, 0, 0, 0.4);
  
  // Ajustar colores primarios para mejor contraste
  --color-interactive-primary: #{$color-primary-400};
  --color-interactive-primary-hover: #{$color-primary-300};
  --color-interactive-primary-active: #{$color-primary-200};
}
```

### 4.2 Servicio de Temas (Angular)

**Archivo:** `libs/shared/ui/theme/src/lib/theme.service.ts`

```typescript
import { Injectable, signal, effect } from '@angular/core';
import { DOCUMENT } from '@angular/common';
import { inject } from '@angular/core';

export type Theme = 'light' | 'dark' | 'auto';

@Injectable({
  providedIn: 'root'
})
export class ThemeService {
  private document = inject(DOCUMENT);
  private readonly STORAGE_KEY = 'nexcore-theme';
  
  // Signal reactivo para el tema actual
  theme = signal<Theme>(this.getStoredTheme() || 'auto');
  
  // Computed signal que resuelve el tema efectivo (auto → light/dark según OS)
  effectiveTheme = signal<'light' | 'dark'>('light');
  
  constructor() {
    // Detectar preferencia del sistema
    const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
    
    // Actualizar tema efectivo cuando cambie el signal o la preferencia del OS
    effect(() => {
      const theme = this.theme();
      let effective: 'light' | 'dark';
      
      if (theme === 'auto') {
        effective = mediaQuery.matches ? 'dark' : 'light';
      } else {
        effective = theme;
      }
      
      this.effectiveTheme.set(effective);
      this.applyTheme(effective);
    });
    
    // Escuchar cambios en la preferencia del sistema
    mediaQuery.addEventListener('change', (e) => {
      if (this.theme() === 'auto') {
        const effective = e.matches ? 'dark' : 'light';
        this.effectiveTheme.set(effective);
        this.applyTheme(effective);
      }
    });
  }
  
  setTheme(theme: Theme): void {
    this.theme.set(theme);
    localStorage.setItem(this.STORAGE_KEY, theme);
  }
  
  toggleTheme(): void {
    const current = this.effectiveTheme();
    this.setTheme(current === 'light' ? 'dark' : 'light');
  }
  
  private applyTheme(theme: 'light' | 'dark'): void {
    this.document.body.setAttribute('data-theme', theme);
  }
  
  private getStoredTheme(): Theme | null {
    const stored = localStorage.getItem(this.STORAGE_KEY);
    return stored as Theme | null;
  }
}
```

### 4.3 Componente Toggle de Tema

**Archivo:** `libs/shared/ui/theme/src/lib/theme-toggle/theme-toggle.component.ts`

```typescript
import { Component, inject } from '@angular/core';
import { ThemeService } from '../theme.service';

@Component({
  selector: 'nxc-theme-toggle',
  standalone: true,
  template: `
    <button
      class="theme-toggle"
      [attr.aria-label]="'Toggle theme: ' + effectiveTheme()"
      (click)="toggleTheme()"
    >
      @if (effectiveTheme() === 'light') {
        <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor">
          <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" />
        </svg>
      } @else {
        <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor">
          <circle cx="12" cy="12" r="5" />
          <line x1="12" y1="1" x2="12" y2="3" />
          <line x1="12" y1="21" x2="12" y2="23" />
          <line x1="4.22" y1="4.22" x2="5.64" y2="5.64" />
          <line x1="18.36" y1="18.36" x2="19.78" y2="19.78" />
          <line x1="1" y1="12" x2="3" y2="12" />
          <line x1="21" y1="12" x2="23" y2="12" />
          <line x1="4.22" y1="19.78" x2="5.64" y2="18.36" />
          <line x1="18.36" y1="5.64" x2="19.78" y2="4.22" />
        </svg>
      }
    </button>
  `,
  styles: [`
    .theme-toggle {
      background: var(--color-surface);
      border: 1px solid var(--color-border-light);
      border-radius: var(--radius-md);
      padding: var(--spacing-2);
      cursor: pointer;
      transition: all 0.2s ease;
      
      &:hover {
        background: var(--color-surface-hover);
        border-color: var(--color-border-medium);
      }
      
      &:focus-visible {
        outline: none;
        box-shadow: var(--shadow-focus);
      }
    }
    
    .icon {
      width: 20px;
      height: 20px;
      color: var(--color-text-primary);
      stroke-width: 2;
    }
  `]
})
export class ThemeToggleComponent {
  private themeService = inject(ThemeService);
  
  effectiveTheme = this.themeService.effectiveTheme;
  
  toggleTheme(): void {
    this.themeService.toggleTheme();
  }
}
```

---

## 5. Componentes Principales

### 5.1 Navbar (Barra Superior)

**Archivo:** `libs/shared/ui/navigation/navbar/navbar.component.ts`

```typescript
import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { ThemeToggleComponent } from '../../theme/theme-toggle/theme-toggle.component';
import { UserMenuComponent } from './user-menu/user-menu.component';
import { NotificationsComponent } from './notifications/notifications.component';
import { AuthService } from '@nexcore/data-access/auth';

@Component({
  selector: 'nxc-navbar',
  standalone: true,
  imports: [
    CommonModule,
    RouterModule,
    ThemeToggleComponent,
    UserMenuComponent,
    NotificationsComponent
  ],
  template: `
    <nav class="navbar">
      <div class="navbar-container">
        <!-- Botón menú hamburguesa (móvil) -->
        <button 
          class="menu-toggle"
          (click)="toggleSidebar.emit()"
          aria-label="Toggle menu"
        >
          <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor">
            <line x1="3" y1="12" x2="21" y2="12"></line>
            <line x1="3" y1="6" x2="21" y2="6"></line>
            <line x1="3" y1="18" x2="21" y2="18"></line>
          </svg>
        </button>
        
        <!-- Logo / Breadcrumbs -->
        <div class="navbar-left">
          <h1 class="page-title">{{ pageTitle() }}</h1>
        </div>
        
        <!-- Actions -->
        <div class="navbar-right">
          <!-- Búsqueda global (opcional) -->
          <button class="icon-button" aria-label="Search">
            <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor">
              <circle cx="11" cy="11" r="8"></circle>
              <path d="m21 21-4.35-4.35"></path>
            </svg>
          </button>
          
          <!-- Notificaciones -->
          <nxc-notifications />
          
          <!-- Toggle tema -->
          <nxc-theme-toggle />
          
          <!-- Menú de usuario -->
          <nxc-user-menu />
        </div>
      </div>
    </nav>
  `,
  styles: [`
    .navbar {
      background: var(--color-surface);
      border-bottom: 1px solid var(--color-border-light);
      position: sticky;
      top: 0;
      z-index: var(--z-sticky);
      height: 64px;
    }
    
    .navbar-container {
      display: flex;
      align-items: center;
      justify-content: space-between;
      height: 100%;
      padding: 0 var(--spacing-6);
      gap: var(--spacing-4);
    }
    
    .menu-toggle {
      display: none;
      background: transparent;
      border: none;
      cursor: pointer;
      padding: var(--spacing-2);
      color: var(--color-text-primary);
      
      @media (max-width: 768px) {
        display: flex;
      }
    }
    
    .navbar-left {
      flex: 1;
    }
    
    .page-title {
      font-size: var(--font-size-xl);
      font-weight: var(--font-weight-semibold);
      color: var(--color-text-primary);
      margin: 0;
    }
    
    .navbar-right {
      display: flex;
      align-items: center;
      gap: var(--spacing-3);
    }
    
    .icon-button {
      background: transparent;
      border: none;
      cursor: pointer;
      padding: var(--spacing-2);
      border-radius: var(--radius-md);
      color: var(--color-text-secondary);
      transition: all 0.2s ease;
      
      &:hover {
        background: var(--color-surface-hover);
        color: var(--color-text-primary);
      }
    }
    
    .icon {
      width: 20px;
      height: 20px;
      stroke-width: 2;
    }
  `]6.1
})
export class NavbarComponent {
  private authService = inject(AuthService);
  
  pageTitle = signal('Dashboard');
  toggleSidebar = signal<void>();
}
```

### 5.2 User Menu (Menú de Usuario)

**Archivo:** `libs/shared/ui/navigation/navbar/user-menu/user-menu.component.ts`

```typescript
import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { AuthService } from '@nexcore/data-access/auth';

@Component({
  selector: 'nxc-user-menu',
  standalone: true,
  imports: [CommonModule, RouterModule],
  template: `
    <div class="user-menu" (clickOutside)="isOpen.set(false)">
      <!-- Avatar trigger -->
      <button 
        class="user-avatar"
        (click)="isOpen.update(v => !v)"
        [attr.aria-expanded]="isOpen()"
      >
        @if (user()?.avatar) {
          <img [src]="user()?.avatar" [alt]="user()?.name" />
        } @else {
          <span class="avatar-initials">
            {{ getInitials(user()?.name) }}
          </span>
        }
      </button>
      
      <!-- Dropdown menu -->
      @if (isOpen()) {
        <div class="dropdown-menu">
          <div class="user-info">
            <div class="user-name">{{ user()?.name }}</div>
            <div class="user-email">{{ user()?.email }}</div>
          </div>
          
          <div class="divider"></div>
          
          <nav class="menu-items">
            <a 
              routerLink="/profile" 
     6.1      class="menu-item"
              (click)="isOpen.set(false)"
            >
              <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor">
                <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
                <circle cx="12" cy="7" r="4"></circle>
              </svg>
              <span>Mi Perfil</span>
            </a>
            
            <a 
              routerLink="/profile/change-password" 
              class="menu-item"
              (click)="isOpen.set(false)"
            >
              <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor">
                <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect>
                <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
              </svg>
              <span>Cambiar Contraseña</span>
            </a>
            
            <a 
              routerLink="/settings" 
              class="menu-item"
              (click)="isOpen.set(false)"
            >
              <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor">
                <circle cx="12" cy="12" r="3"></circle>
                <path d="M12 1v6m0 6v6"></path>
              </svg>
              <span>Configuración</span>
            </a>
          </nav>
          
          <div class="divider"></div>
          
          <button class="menu-item logout" (click)="logout()">
            <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor">
              <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path>
              <polyline points="16 17 21 12 16 7"></polyline>
              <line x1="21" y1="12" x2="9" y2="12"></line>
            </svg>
            <span>Cerrar Sesión</span>
          </button>
        </div>
      }
    </div>
  `,
  styles: [`
    .user-menu {
      position: relative;
    }
    
    .user-avatar {
      width: 40px;
      height: 40px;
      border-radius: var(--radius-full);
      border: 2px solid var(--color-border-light);
      background: var(--color-interactive-primary);
      color: var(--color-text-inverse);
      cursor: pointer;
      transition: all 0.2s ease;
      overflow: hidden;
      
      &:hover {
        border-color: var(--color-interactive-primary);
      }
   7. Layouts

### 7   width: 100%;
        height: 100%;
        object-fit: cover;
      }
      
      .avatar-initials {
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: var(--font-weight-semibold);
        font-size: var(--font-size-sm);
      }
    }
    
    .dropdown-menu {
      position: absolute;
      top: calc(100% + var(--spacing-2));
      right: 0;
      min-width: 240px;
      background: var(--color-surface);
      border: 1px solid var(--color-border-light);
      border-radius: var(--radius-lg);
      box-shadow: var(--shadow-lg);
      padding: var(--spacing-2);
      z-index: var(--z-dropdown);
      animation: slideDown 0.2s ease;
    }
    
    @keyframes slideDown {
      from {
        opacity: 0;
        transform: translateY(-10px);
      }
      to {
        opacity: 1;
        transform: translateY(0);
      }
    }
    
    .user-info {
      padding: var(--spacing-3);
    }
    
    .user-name {
      font-weight: var(--font-weight-semibold);
      color: var(--color-text-primary);
      font-size: var(--font-size-sm);
    }
    
    .user-email {
      color: var(--color-text-tertiary);
      font-size: var(--font-size-xs);
      margin-top: var(--spacing-1);
    }
    
    .divider {
      height: 1px;
      background: var(--color-border-light);
      margin: var(--spacing-2) 0;
    }
    
    .menu-items {
      display: flex;
      flex-direction: column;
      gap: var(--spacing-1);
    }
    
    .menu-item {
      display: flex;
      align-items: center;
      gap: var(--spacing-3);
      padding: var(--spacing-3);
      color: var(--color-text-primary);
      text-decoration: none;
      border-radius: var(--radius-md);
      transition: all 0.2s ease;
      font-size: var(--font-size-sm);
      border: none;
      background: transparent;
      cursor: pointer;
      width: 100%;
      text-align: left;
      
      &:hover {
        background: var(--color-surface-hover);
      }
      
      &.logout {
        color: var(--color-error);
      }
    }
    
    .icon {
      width: 18px;
      height: 18px;
      stroke-width: 2;
    }
  `]
})
export class UserMenuComponent {
  private authService = inject(AuthService);
  
  isOpen = signal(false);
  user = this.authService.userProfile;
  
  getInitials(name?: string): string {
    if (!name) return '?';
    return name
      .split(' ')
      .map(n => n[0])
      .join('')
      .toUpperCase()
      .slice(0, 2);
  }
  
  logout(): void {
    this.authService.logout();
  }
}
```8. Guías de Implementación para Stitch AI

### 8.3 Sidebar (Menú Lateral)

**Archivo:** `libs/shared/ui/navigation/sidebar/sidebar.component.ts`

```typescript
import { Component, inject, input, output, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { SidebarItemComponent } from './sidebar-item/sidebar-item.component';
import { MenuService } from '@nexcore/data-access/menu';

expo8t interface MenuItem {
  id: string;
  label: string;
  icon: string;
  route?: string;
  children?: MenuItem[];
  badge?: string;
  badgeType?: 'info' | 'success' | 'warning' | 'error';
}

@Component({
  selector: 'nxc-sidebar',
  standalone: true,
  im8orts: [CommonModule, RouterModule, SidebarItemComponent],
  template: `
    <aside class="sidebar" [class.collapsed]="collapsed()">
      <!-- Logo -->
      <div class="sidebar-header">
        @if (!collapsed()) {
          <img src="/assets/images/logo-full.svg" alt="NexCore" class="logo-full" />
        } @else {
          <img src="/assets/images/logo-mini.svg" alt="NexCore" class="logo-mini" />
        }
      </div>
      
      <!-- Navigation -->
      <nav class="sidebar-nav">
        @for (item of menuItems(); track item.id) {
          <nxc-sidebar-item 
            [item]="item" 
            [collapsed]="collapsed()"
          />
        }
    8 </nav>
      
      <!-- Collapse toggle -->
      <button 
        class="collapse-toggle"
        (click)="toggleCollapse.emit()"
        [attr.aria-label]="collapsed() ? 'Expand sidebar' : 'Collapse sidebar'"
      >
        <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor">
          @if (collapsed()) {
            <polyline points="9 18 15 12 9 6"></polyline>
          } @else {
    8       <polyline points="15 18 9 12 15 6"></polyline>
          }
        </svg>
      </button>
    </aside>
  `,
  styles: [`
    .sidebar {
      display: flex;
      flex-direction: column;
      background: var(--color-surface);
      border-right: 1px solid var(--color-border-light);
      width: 280px;
      height: 100vh;
      position: sticky;
      top: 0;
      transition: width 0.3s ease;
      
      &.collapsed {
        width: 64px;
      }
    }
    
    .sidebar-header {
      display: flex;
      align-items: center;
      justify-content: center;
      height: 64px;
      padding: var(--spacing-4);
      border-bottom: 1px solid var(--color-border-light);
      
      .logo-full,
      .logo-mini {
        max-width: 100%;
        height: auto;
      }
    }
    
    .sidebar-nav {
      flex: 1;
      padding: var(--spacing-4);
      overflow-y: auto;
      
      &::-webkit-scrollbar {
        width: 6px;
      }
      
      &::-webkit-scrollbar-thumb {
   9. Integración con Backend

### 9 }
    }
    
    .collapse-toggle {
      display: flex;
      align-items: center;
      justify-content: center;
      height: 48px;
      border: none;
      border-top: 1px solid var(--color-border-light);
      background: transparent;
      color: var(--color-text-secondary);
      cursor: pointer;
      transition: all 0.2s ease;
      
      &:hover {
        background: var(--color-surface-hover);
        color: var(--color-text-primary);
      }
    }
    
    .icon {
      width: 20px;
      height: 20px;
    9 stroke-width: 2;
    }
    
    @media (max-width: 768px) {
      .sidebar {
        position: fixed;
        left: 0;
        top: 0;
        z-index: var(--z-fixed);
        transform: translateX(-100%);
        
        &.open {
          transform: translateX(0);
        }
      }
    }
  `]
})
export class SidebarComponent {
  private menuService = inject(MenuService);
  
  collapsed = input(false);
  toggleCollapse = output<void>();
  
  menuItems = this.menuService.menuItems;
}
```

### 5.4 Dashboard

**Archivo:** `libs/features/dashboard/src/lib/dashboard.component.ts`

```typescript
import { Component, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { StatsCardComponent } from './widgets/stats-card/stats-card.component';
import { ChartWidgetComponent } from './widgets/chart-widget/chart-widget.component';
import { RecentActivityComponent } from './widgets/recent-activity/recent-activity.component';

@Component({
  selector: 'nxc-dashboard',
  s10. Performance y Optimización

### 10ommonModule,
    StatsCardComponent,
    ChartWidgetComponent,
    RecentActivityComponent
  ],
  template: `
    <div class="dashboard">
      <div class="dashboard-header">
        <h1>Dashboard</h1>
        <p class="subtitle">Bienvenido de vuelta, {{ userName }}</p>
      </div>
      
      <!-- Stats Grid -->
      <div class="stats-grid">
        @for (stat of stats; track stat.id) {
          <nxc-stats-card
            [title]="stat.title"
            [value]="stat.value"
    10       [change]="stat.change"
            [icon]="stat.icon"
            [trend]="stat.trend"
          />
        }
      </div>
      
      <!-- Charts Row -->
      <div class="charts-row">
        <nxc-chart-widget
          title="Usuarios Activos"
          [data]="userActivityData"
          type="line"
    10   />
        
        <nxc-chart-widget
          title="Distribución por Tenant"
          [data]="tenantDistributionData"
          type="pie"
        />
      </div>
      
      <!-- Recent Activity -->
      <nxc-recent-activity />
    </div>
  `,
  styles: [`
    .dashboard {
      max-width: 1400px;
      margin: 0 auto;
      padding: var(--spacing-6);
    }
   11. Testing

### 11 margin-bottom: var(--spacing-8);
      
      h1 {
        font-size: var(--font-size-3xl);
        font-weight: var(--font-weight-bold);
        color: var(--color-text-primary);
        margin: 0 0 var(--spacing-2) 0;
      }
      
      .subtitle {
        color: var(--color-text-secondary);
        font-size: var(--font-size-lg);
        margin: 0;
      }
    }
    
    .stats-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
      gap: var(--spacing-6);
      margin-bottom: var(--spacing-8);
    }
    
    .charts-row {
      display: grid;
    2. Storybook

### 12margin-bottom: var(--spacing-8);
    }
  `]
})
export class DashboardComponent implements OnInit {
  userName = 'Usuario';
  
  stats = [
    {
      id: 1,
      title: 'Total Usuarios',
      value: '1,234',
      change: '+12.5%',
      trend: 'up' as const,
      icon: 'users'
    },
    {
      id: 2,
      title: 'Tenants Activos',
      value: '42',
      change: '+3',
      trend: 'up' as const,
      icon: 'building'
    },
    {
      id: 3,
      title: 'Sesiones Hoy',
      value: '567',
      change: '-2.3%',
      trend: 'down' as const,
      icon: 'activity'
    },
    {
      id: 4,
      title: 'Tasa de Éxito',
      value: '98.5%',
      change: '+0.5%',
      trend: 'up' as const,
      icon: 'check-circle'
    }
  ];
  
  userActivityData = {};
  tenantDistributionData = {};
  
  ngOnInit(): void {
    // Load dashboard data
  }
}
```

---

## 63. Deployment

### 131 Convenciones de Diseño

#### 6.1.1 Botones

```typescript
// libs/shared/ui/components/button/button.component.ts
@Component({
  selector: 'nxc-button',
  standalone: true,
  template: `
    <button 
      [class]="classes"
      [type]="type"
      [disabled]="disabled"
    >
      @if (loading) {
     3  <span class="spinner"></span>
      }
      <ng-content></ng-content>
    </button>
  `,
  styles: [`
    button {
      font-family: var(--font-family-primary);
      font-weight: var(--font-weight-medium);
      border-radius: var(--radius-md);
      transition: all 0.2s ease;
      cursor: pointer;
      border: none;
      
    4 &:focus-visible {
        outline: none;
        box-shadow: var(--shadow-focus);
      }
      
      &:disabled {
        cursor: not-allowed;
        opacity: 0.6;
      }
    }
    
    // Variantes
    .btn-primary {
      background: var(--color-interactive-primary);
      color: var(--color-text-inverse);
      padding: var(--spacing-3) var(--spacing-6);
      
      &:hover:not(:disabled) {
        background: var(--color-interactive-primary-hover);
      }
      
      &:active:not(:disabled) {
        background: var(--color-interactive-primary-active);
      }
    }
    
    .btn-secondary {
    5 background: transparent;
      color: var(--color-text-primary);
      border: 1px solid var(--color-border-medium);
      padding: var(--spacing-3) var(--spacing-6);
      
      &:hover:not(:disabled) {
        background: var(--color-surface-hover);
      }
    }
    
    .btn-ghost {
      background: transparent;
      color: var(--color-text-primary);
      padding: var(--spacing-3) var(--spacing-6);
      
      &:hover:not(:disabled) {
        background: var(--color-surface-hover);
      }
    }
    
    // Tamaños
    .btn-sm { 
      font-size: var(--font-size-sm);
      padding: var(--spacing-2) var(--spacing-4);
    }
    
    .btn-lg { 
      font-size: var(--font-size-lg);
      padding: var(--spacing-4) var(--spacing-8);
    }
  `]
})
export class ButtonComponent {
  @Input() variant: 'primary' | 'secondary' | 'ghost' = 'primary';
  @Input() size: 'sm' | 'md' | 'lg' = 'md';
  @Input() type: 'button' | 'submit' | 'reset' = 'button';
  @Input() disabled = false;
  @Input() loading = false;
  
  get classes(): string {
    return `btn-${this.variant} btn-${this.size}`;
  }
}
```

#### 4.2.2 Cards

```scss
// libs/shared/ui/components/card/card.component.scss
.card {
  background: var(--color-surface);
  border: 1px solid var(--color-border-light);
  border-radius: var(--radius-lg);
  padding: var(--spacing-6);
  box-shadow: var(--shadow-sm);
  transition: all 0.2s ease;
  
  &:hover {
    box-shadow: var(--shadow-md);
  }
  
  &.card-elevated {
    box-shadow: var(--shadow-lg);
  }
  
  &.card-interactive {
    cursor: pointer;
    
    &:hover {
      border-color: var(--color-border-medium);
      box-shadow: var(--shadow-lg);
    }
  }
}

.card-header {
  margin-bottom: var(--spacing-4);
  padding-bottom: var(--spacing-4);
  border-bottom: 1px solid var(--color-border-light);
}

.card-title {
  font-size: var(--font-size-lg);
  font-weight: var(--font-weight-semibold);
  color: var(--color-text-primary);
  margin: 0;
}

.card-body {
  color: var(--color-text-secondary);
}

.card-footer {
  margin-top: var(--spacing-4);
  padding-top: var(--spacing-4);
  border-top: 1px solid var(--color-border-light);
}
```

#### 4.2.3 Inputs

```scss
// libs/shared/ui/components/input/input.component.scss
.input-wrapper {
  display: flex;
  flex-direction: column;
  gap: var(--spacing-2);
}

.input-label {
  font-size: var(--font-size-sm);
  font-weight: var(--font-weight-medium);
  color: var(--color-text-primary);
}

.input-field {
  font-family: var(--font-family-primary);
  font-size: var(--font-size-base);
  padding: var(--spacing-3) var(--spacing-4);
  border: 1px solid var(--color-border-medium);
  border-radius: var(--radius-md);
  background: var(--color-surface);
  color: var(--color-text-primary);
  transition: all 0.2s ease;
  
  &::placeholder {
    color: var(--color-text-tertiary);
  }
  
  &:hover:not(:disabled) {
    border-color: var(--color-border-heavy);
  }
  
  &:focus {
    outline: none;
    border-color: var(--color-interactive-primary);
    box-shadow: var(--shadow-focus);
  }
  
  &:disabled {
    background: var(--color-bg-tertiary);
    color: var(--color-text-disabled);
    cursor: not-allowed;
  }
  
  &.input-error {
    border-color: var(--color-error);
    
    &:focus {
      box-shadow: var(--shadow-focus-error);
    }
  }
}

.input-helper {
  font-size: var(--font-size-xs);
  color: var(--color-text-tertiary);
}

.input-error-message {
  font-size: var(--font-size-xs);
  color: var(--color-error);
}
```

---

## 5. Layouts

### 5.1 App Layout (Dashboard)

```typescript
// libs/shared/ui/layouts/app-layout/app-layout.component.ts
@Component({
  selector: 'nxc-app-layout',
  standalone: true,
  template: `
    <div class="app-layout" [class.sidebar-collapsed]="sidebarCollapsed()">
      <!-- Sidebar -->
      <aside class="sidebar">
        <nxc-sidebar 
          [collapsed]="sidebarCollapsed()" 
          (toggleCollapse)="toggleSidebar()"
        />
      </aside>
      
      <!-- Main content -->
      <div class="main-container">
        <!-- Top navbar -->
        <header class="navbar">
          <nxc-navbar />
        </header>
        
        <!-- Page content -->
        <main class="content">
          <ng-content></ng-content>
        </main>
        
        <!-- Footer -->
        <footer class="footer">
          <nxc-footer />
        </footer>
      </div>
    </div>
  `,
  styles: [`
    .app-layout {
      display: grid;
      grid-template-columns: 280px 1fr;
      min-height: 100vh;
      background: var(--color-bg-primary);
      
      &.sidebar-collapsed {
        grid-template-columns: 64px 1fr;
      }
    }
    
    .sidebar {
      background: var(--color-surface);
      border-right: 1px solid var(--color-border-light);
      position: sticky;
      top: 0;
      height: 100vh;
      overflow-y: auto;
    }
    
    .main-container {
      display: flex;
      flex-direction: column;
      min-height: 100vh;
    }
    
    .navbar {
      background: var(--color-surface);
      border-bottom: 1px solid var(--color-border-light);
      padding: var(--spacing-4) var(--spacing-6);
      position: sticky;
      top: 0;
      z-index: var(--z-sticky);
    }
    
    .content {
      flex: 1;
      padding: var(--spacing-6);
      
      @include respond-to-lg {
        padding: var(--spacing-8);
      }
    }
    
    .footer {
      background: var(--color-surface);
      border-top: 1px solid var(--color-border-light);
      padding: var(--spacing-4) var(--spacing-6);
    }
    
    // Responsive
    @media (max-width: $breakpoint-md) {
      .app-layout {
        grid-template-columns: 1fr;
      }
      
      .sidebar {
        position: fixed;
        left: 0;
        top: 0;
        z-index: var(--z-fixed);
        transform: translateX(-100%);
        transition: transform 0.3s ease;
        
        &.open {
          transform: translateX(0);
        }
      }
    }
  `]
})
export class AppLayoutComponent {
  sidebarCollapsed = signal(false);
  
  toggleSidebar(): void {
    this.sidebarCollapsed.update(v => !v);
  }
}
```

---

## 6. Guías de Implementación para Stitch AI

### 6.1 Principios de Diseño

1. **Mobile-first**: Diseñar primero para móviles, luego escalar a desktop
2. **Accesibilidad**: Mínimo WCAG 2.1 AA
   - Contraste de color >= 4.5:1 para texto normal
   - Focus states visibles
   - Keyboard navigation completa
   - ARIA labels en iconos y botones
3. **Consistencia**: Usar siempre los tokens, nunca valores hardcodeados
4. **Performance**: Lazy loading, code splitting, optimización de assets

### 6.2 Checklist de Componentes

Al crear un nuevo componente, verificar:

- [ ] Usa CSS custom properties (tokens) en lugar de valores hardcoded
- [ ] Funciona en modo light y dark sin ajustes adicionales
- [ ] Es responsive (mobile, tablet, desktop)
- [ ] Tiene estados hover, focus, active, disabled
- [ ] Incluye ARIA attributes apropiados
- [ ] Usa signals de Angular (no RxJS para estado local simple)
- [ ] Está documentado con Storybook
- [ ] Tiene tests unitarios

### 6.3 Convenciones de Naming

```scss
// ❌ MAL - valores hardcoded
.my-component {
  color: #333;
  background: #fff;
  padding: 16px;
  border-radius: 8px;
}

// ✅ BIEN - usa tokens
.my-component {
  color: var(--color-text-primary);
  background: var(--color-surface);
  padding: var(--spacing-4);
  border-radius: var(--radius-lg);
}
```

### 6.4 Estructura de Archivos de Componente

```
button/
├── button.component.ts        # Lógica del componente
├── button.component.scss      # Estilos
├── button.component.spec.ts   # Tests
├── button.component.stories.ts # Storybook
├── button.types.ts            # Types/interfaces
└── index.ts                   # Public API
```

### 6.5 Ejemplo de Componente Completo

```typescript
// button.types.ts
export type ButtonVariant = 'primary' | 'secondary' | 'ghost' | 'danger';
export type ButtonSize = 'sm' | 'md' | 'lg';

export interface ButtonProps {
  variant?: ButtonVariant;
  size?: ButtonSize;
  disabled?: boolean;
  loading?: boolean;
  fullWidth?: boolean;
  type?: 'button' | 'submit' | 'reset';
}
```

```typescript
// button.component.ts
import { Component, Input, computed, signal } from '@angular/core';
import { ButtonProps } from './button.types';

@Component({
  selector: 'nxc-button',
  standalone: true,
  templateUrl: './button.component.html',
  styleUrl: './button.component.scss'
})
export class ButtonComponent implements ButtonProps {
  @Input() variant: ButtonProps['variant'] = 'primary';
  @Input() size: ButtonProps['size'] = 'md';
  @Input() disabled = false;
  @Input() loading = false;
  @Input() fullWidth = false;
  @Input() type: ButtonProps['type'] = 'button';
  
  classes = computed(() => [
    'nxc-button',
    `nxc-button--${this.variant}`,
    `nxc-button--${this.size}`,
    this.fullWidth ? 'nxc-button--full-width' : '',
    this.loading ? 'nxc-button--loading' : ''
  ].filter(Boolean).join(' '));
}
```

---

## 7. Integración con Backend

### 7.1 Permisos Dinámicos (Module Menu)

La UI se renderiza según los permisos del usuario:

```typescript
// libs/shared/data-access/auth/src/lib/auth.service.ts
@Injectable({ providedIn: 'root' })
export class AuthService {
  private http = inject(HttpClient);
  
  userProfile$ = signal<UserProfile | null>(null);
  permissions$ = computed(() => this.userProfile$()?.permissions || []);
  
  hasPermission(componentCode: string, elementCode: string): boolean {
    const permissions = this.permissions$();
    return permissions.some(p => 
      p.component === componentCode && 
      p.element === elementCode && 
      p.enabled
    );
  }
}
```

### 7.2 Directiva de Permisos

```typescript
// libs/shared/ui/directives/has-permission.directive.ts
@Directive({
  selector: '[nxcHasPermission]',
  standalone: true
})
export class HasPermissionDirective implements OnInit {
  @Input() nxcHasPermission!: { component: string; element: string };
  
  private authService = inject(AuthService);
  private viewContainer = inject(ViewContainerRef);
  private templateRef = inject(TemplateRef);
  
  ngOnInit(): void {
    const { component, element } = this.nxcHasPermission;
    const hasPermission = this.authService.hasPermission(component, element);
    
    if (hasPermission) {
      this.viewContainer.createEmbeddedView(this.templateRef);
    } else {
      this.viewContainer.clear();
    }
  }
}
```

Uso:

```html
<button 
  *nxcHasPermission="{ component: 'TENANT', element: 'BTN_CREATE' }"
  (click)="createTenant()"
>
  Create Tenant
</button>
```

---

## 8. Performance y Optimización

### 8.1 Lazy Loading

```typescript
// app.routes.ts
export const routes: Routes = [
  {
    path: 'tenants',
    loadComponent: () => 
      import('./features/tenants/tenants.component').then(m => m.TenantsComponent)
  },
  {
    path: 'menu',
    loadChildren: () => 
      import('./features/menu/menu.routes').then(m => m.MENU_ROUTES)
  }
];
```

### 8.2 OnPush Change Detection

Todos los componentes deben usar `OnPush`:

```typescript
@Component({
  selector: 'nxc-card',
  changeDetection: ChangeDetectionStrategy.OnPush,
  // ...
})
export class CardComponent {}
```

### 8.3 Track By Functions

```typescript
@Component({
  template: `
    @for (item of items; track trackById($index, item)) {
      <div>{{ item.name }}</div>
    }
  `
})
export class ListComponent {
  trackById(index: number, item: any): string {
    return item.id;
  }
}
```

---

## 9. Testing

### 9.1 Unit Tests

```typescript
// button.component.spec.ts
describe('ButtonComponent', () => {
  it('should render primary variant by default', () => {
    const fixture = TestBed.createComponent(ButtonComponent);
    const button = fixture.nativeElement.querySelector('button');
    
    expect(button.classList.contains('nxc-button--primary')).toBe(true);
  });
  
  it('should apply disabled state', () => {
    const fixture = TestBed.createComponent(ButtonComponent);
    fixture.componentInstance.disabled = true;
    fixture.detectChanges();
    
    const button = fixture.nativeElement.querySelector('button');
    expect(button.disabled).toBe(true);
  });
});
```

---

## 10. Storybook

### 10.1 Story Example

```typescript
// button.component.stories.ts
import type { Meta, StoryObj } from '@storybook/angular';
import { ButtonComponent } from './button.component';

const meta: Meta<ButtonComponent> = {
  component: ButtonComponent,
  title: 'UI/Button',
  tags: ['autodocs'],
  argTypes: {
    variant: {
      control: 'select',
      options: ['primary', 'secondary', 'ghost', 'danger']
    },
    size: {
      control: 'select',
      options: ['sm', 'md', 'lg']
    }
  }
};

export default meta;
type Story = StoryObj<ButtonComponent>;

export const Primary: Story = {
  args: {
    variant: 'primary',
    size: 'md'
  },
  render: (args) => ({
    props: args,
    template: `<nxc-button [variant]="variant" [size]="size">Click me</nxc-button>`
  })
};

export const AllVariants: Story = {
  render: () => ({
    template: `
      <div style="display: flex; gap: 1rem;">
        <nxc-button variant="primary">Primary</nxc-button>
        <nxc-button variant="secondary">Secondary</nxc-button>
        <nxc-button variant="ghost">Ghost</nxc-button>
        <nxc-button variant="danger">Danger</nxc-button>
      </div>
    `
  })
};
```

---

## 11. Deployment

### 11.1 Build para Producción

```bash
# Build con optimizaciones
nx build frontend --configuration=production

# Output
dist/apps/frontend/
├── index.html
├── main.[hash].js
├── polyfills.[hash].js
├── runtime.[hash].js
├── styles.[hash].css
└── assets/
```

### 11.2 Variables de Entorno

```typescript
// environment.prod.ts
export const environment = {
  production: true,
  apiUrl: 'https://api.nexcore.com',
  authUrl: 'https://auth.nexcore.com',
  wsUrl: 'wss://notifications.nexcore.com'
};
```

---

## 12. Resumen de Comandos Nx

```bash
# Generar nuevo componente
nx g @nx/angular:component --name=my-component --project=shared-ui

# Generar nueva librería
nx g @nx/angular:library --name=shared-data-access

# Servir aplicación
nx serve frontend

# Build
nx build frontend

# Tests
nx test shared-ui

# Lint
nx lint frontend

# Storybook
nx storybook shared-ui
```

---

## 13. Referencias

- **Design System:** Material Design 3, Tailwind CSS
- **Accessibility:** WCAG 2.1 Guidelines
- **Angular:** [Angular.dev](https://angular.dev)
- **Nx:** [Nx.dev](https://nx.dev)
- **CSS Variables:** [MDN Web Docs](https://developer.mozilla.org/en-US/docs/Web/CSS/Using_CSS_custom_properties)

---

**Fin del documento**
