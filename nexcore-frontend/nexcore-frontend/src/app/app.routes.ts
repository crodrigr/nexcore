import { Routes } from '@angular/router';

export const routes: Routes = [
  {
    path: '',
    redirectTo: 'auth/login',
    pathMatch: 'full'
  },
  {
    path: 'dashboard',
    loadComponent: () =>
      import('./features/dashboard/dashboard.component').then(m => m.DashboardComponent),
    title: 'Dashboard'
  },
  {
    path: 'auth',
    children: [
      {
        path: 'login',
        loadComponent: () => 
          import('./features/auth/login/login.component').then(m => m.LoginComponent),
        title: 'Iniciar Sesión'
      },
      {
        path: 'verify-otp',
        loadComponent: () => 
          import('./features/auth/verify-otp/verify-otp.component').then(m => m.VerifyOtpComponent),
        title: 'Verificar Código'
      },
      {
        path: 'forgot-password',
        loadComponent: () => 
          import('./features/auth/forgot-password/forgot-password.component').then(m => m.ForgotPasswordComponent),
        title: 'Recuperar Contraseña'
      },
      {
        path: '',
        redirectTo: 'login',
        pathMatch: 'full'
      }
    ]
  }
];
