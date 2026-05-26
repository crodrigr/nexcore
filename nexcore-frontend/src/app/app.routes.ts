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
    path: 'tenants',
    loadComponent: () =>
      import('./features/tenants/tenant-management.component').then(m => m.TenantManagementComponent),
    title: 'Tenant Management'
  },
  {
    path: 'tenant-management',
    redirectTo: 'tenants',
    pathMatch: 'full'
  },
  {
    path: 'identity-access',
    redirectTo: 'tenants',
    pathMatch: 'full'
  },
  {
    path: 'reset-password',
    loadComponent: () =>
      import('./features/auth/reset-password/reset-password.component').then(m => m.ResetPasswordComponent),
    title: 'Reset Password'
  },
  {
    path: 'auth',
    children: [
      {
        path: 'login',
        loadComponent: () => 
          import('./features/auth/login/login.component').then(m => m.LoginComponent),
        title: 'Sign In'
      },
      {
        path: 'verify-otp',
        loadComponent: () => 
          import('./features/auth/verify-otp/verify-otp.component').then(m => m.VerifyOtpComponent),
        title: 'Verify OTP'
      },
      {
        path: 'forgot-password',
        loadComponent: () => 
          import('./features/auth/forgot-password/forgot-password.component').then(m => m.ForgotPasswordComponent),
        title: 'Reset Password'
      },
      {
        path: 'reset-password',
        loadComponent: () =>
          import('./features/auth/reset-password/reset-password.component').then(m => m.ResetPasswordComponent),
        title: 'Change Password'
      },
      {
        path: '',
        redirectTo: 'login',
        pathMatch: 'full'
      }
    ]
  },
  {
    path: 'crm',
    loadChildren: () => import('./features/crm/crm.module').then(m => m.CrmModule),
    title: 'CRM'
  }
];
