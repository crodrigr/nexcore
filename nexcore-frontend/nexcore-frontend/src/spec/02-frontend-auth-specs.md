# NexCore Frontend — Especificación del Módulo de Autenticación
**Versión:** 1.0  
**Fecha:** 2026-05-22  
**Estado:** En desarrollo activo  
**Módulo:** Auth (Login & Password Recovery)  
**Fase Actual:** Frontend UI/UX (Sin integración backend)

---

## 1. Visión General

El módulo de autenticación de NexCore proporciona las pantallas y flujos necesarios para:
- **Login con 2FA**: Autenticación multi-tenant con verificación OTP por email
- **Recuperar Contraseña**: Flujo completo de recuperación y restablecimiento
- **Temas Light/Dark**: Soporte nativo de cambio de tema en todas las pantallas

### 1.1 Alcance de la Fase Actual

> **⚠️ IMPORTANTE**: Esta especificación cubre únicamente la **implementación del frontend** (UI/UX) sin integración con servicios backend.

**Objetivo de esta fase:**
- 🎨 Establecer el **sistema de diseño** y estilos visuales
- 🧩 Implementar **componentes de UI** completamente funcionales
- 🎭 Configurar el **sistema de temas** light/dark
- 📱 Validar **responsive design** y accesibilidad
- 🔄 Simular flujos con **datos mock** (sin llamadas HTTP reales)

**Implementación futura (Fase 2):**
- 🔌 Integración con backend (nexcore-auth-service)
- 🌐 HTTP Interceptors y manejo de tokens JWT
- 🔐 Autenticación real y guards
- 📧 Envío real de OTP por email

### 1.2 Objetivos del Módulo

- ✅ Interfaz limpia y moderna con branding consistente
- ✅ Responsive design (mobile-first)
- ✅ Validación de formularios en tiempo real
- ✅ Feedback visual claro (loading, errors, success)
- ✅ Accesibilidad WCAG 2.1 AA
- ✅ Soporte completo de temas light/dark
- ✅ **Simulación de flujos con datos mock** (Fase 1)

---

## 2. Estructura de Archivos

```
libs/features/auth/
├── src/
│   ├── lib/
│   │   ├── auth.routes.ts                    # Rutas del módulo
│   │   │
│   │   ├── login/                            # Pantalla de login
│   │   │   ├── login.component.ts
│   │   │   ├── login.component.html
│   │   │   ├── login.component.scss
│   │   │   └── login.component.spec.ts
│   │   │
│   │   ├── verify-otp/                       # Verificación 2FA
│   │   │   ├── verify-otp.component.ts
│   │   │   ├── verify-otp.component.html
│   │   │   ├── verify-otp.component.scss
│   │   │   └── verify-otp.component.spec.ts
│   │   │
│   │   ├── forgot-password/                  # Solicitar reset
│   │   │   ├── forgot-password.component.ts
│   │   │   ├── forgot-password.component.html
│   │   │   ├── forgot-password.component.scss
│   │   │   └── forgot-password.component.spec.ts
│   │   │
│   │   ├── reset-password/                   # Cambiar contraseña
│   │   │   ├── reset-password.component.ts
│   │   │   ├── reset-password.component.html
│   │   │   ├── reset-password.component.scss
│   │   │   └── reset-password.component.spec.ts
│   │   │
│   │   └── index.ts                          # Public API
│   │
│   └── index.ts
│
└── project.json
```

---

## 3. Rutas del Módulo

**Archivo:** `libs/features/auth/src/lib/auth.routes.ts`

```typescript
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

---

## 4. Pantalla de Login

### 4.1 Diseño UI

**Wireframe (Mobile & Desktop)**

```
┌──────────────────────────────────────────┐
│                                          │
│          [Logo NexCore]                  │
│                                          │
│          Iniciar Sesión                  │
│          Bienvenido de vuelta            │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │ Tenant ID                          │ │
│  │ [Dropdown: Sistema / Demo]         │ │
│  └────────────────────────────────────┘ │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │ Usuario                            │ │
│  │ [Input: super.admin]               │ │
│  └────────────────────────────────────┘ │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │ Contraseña                         │ │
│  │ [Input: ••••••••] [👁]             │ │
│  └────────────────────────────────────┘ │
│                                          │
│  [x] Recordarme                          │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │      INICIAR SESIÓN                │ │
│  └────────────────────────────────────┘ │
│                                          │
│  ¿Olvidaste tu contraseña?              │
│                                          │
│                                  [🌙/☀] │
└──────────────────────────────────────────┘
```

### 4.2 Implementación

**Archivo:** `libs/features/auth/src/lib/login/login.component.ts`

```typescript
import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { AuthService } from '@nexcore/data-access/auth';
import { ThemeToggleComponent } from '@nexcore/shared/ui/theme';

interface Tenant {
  id: string;
  name: string;
}

@Component({
  selector: 'nxc-login',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    RouterModule,
    ThemeToggleComponent
  ],
  templateUrl: './login.component.html',
  styleUrl: './login.component.scss'
})
export class LoginComponent {
  private fb = inject(FormBuilder);
  private authService = inject(AuthService);
  private router = inject(Router);
  
  loginForm: FormGroup;
  loading = signal(false);
  error = signal<string | null>(null);
  showPassword = signal(false);
  
  tenants: Tenant[] = [
    { id: '00000000-0000-0000-0000-000000000001', name: 'Sistema' },
    { id: '00000000-0000-0000-0001-000000000001', name: 'Demo' }
  ];
  
  constructor() {
    this.loginForm = this.fb.group({
      tenantId: ['00000000-0000-0000-0000-000000000001', Validators.required],
      username: ['', [Validators.required, Validators.minLength(3)]],
      password: ['', [Validators.required, Validators.minLength(6)]],
      rememberMe: [false]
    });
  }
  
  togglePasswordVisibility(): void {
    this.showPassword.update(v => !v);
  }
  
  async onSubmit(): Promise<void> {
    if (this.loginForm.invalid) {
      this.loginForm.markAllAsTouched();
      return;
    }
    
    this.loading.set(true);
    this.error.set(null);
    
    try {
      const { tenantId, username, password } = this.loginForm.value;
      
      // ============================================================
      // MOCK: Simulación de login (sin llamadas reales al backend)
      // ============================================================
      
      // Simular delay de red (300ms)
      await new Promise(resolve => setTimeout(resolve, 300));
      
      // Credenciales válidas para demostración
      const validCredentials = [
        { username: 'super.admin', password: 'NexCore@2026!' },
        { username: 'admin', password: 'admin123' },
        { username: 'demo', password: 'demo123' }
      ];
      
      const isValidCredential = validCredentials.some(
        cred => cred.username === username && cred.password === password
      );
      
      if (!isValidCredential) {
        throw new Error('Credenciales inválidas');
      }
      
      // Simular respuesta del backend
      const mockResponse = {
        challengeToken: 'mock-challenge-token-' + Date.now(),
        message: 'Código OTP enviado a tu email'
      };
      
      // Guardar challenge token y redirigir a OTP
      sessionStorage.setItem('challengeToken', mockResponse.challengeToken);
      sessionStorage.setItem('mockUsername', username);
      
      this.router.navigate(['/auth/verify-otp']);
      
      // ============================================================
      // PRODUCCIÓN: Descomentar cuando se integre con backend
      // ============================================================
      // const response = await this.authService.login({
      //   tenantId,
      //   username,
      //   password
      // });
      // sessionStorage.setItem('challengeToken', response.challengeToken);
      // this.router.navigate(['/auth/verify-otp']);
      
    } catch (err: any) {
      this.error.set(err.message || 'Error al iniciar sesión');
    } finally {
      this.loading.set(false);
    }
  }
  
  getFieldError(field: string): string | null {
    const control = this.loginForm.get(field);
    
    if (!control || !control.touched || !control.errors) {
      return null;
    }
    
    if (control.errors['required']) {
      return 'Este campo es requerido';
    }
    
    if (control.errors['minlength']) {
      const minLength = control.errors['minlength'].requiredLength;
      return `Mínimo ${minLength} caracteres`;
    }
    
    return null;
  }
}
```

**Archivo:** `libs/features/auth/src/lib/login/login.component.html`

```html
<div class="login-container">
  <div class="login-card">
    <!-- Header -->
    <div class="login-header">
      <img src="/assets/images/logo-light.svg" alt="NexCore" class="logo" />
      <h1 class="title">Iniciar Sesión</h1>
      <p class="subtitle">Bienvenido de vuelta</p>
    </div>
    
    <!-- Theme Toggle -->
    <div class="theme-toggle-wrapper">
      <nxc-theme-toggle />
    </div>
    
    <!-- Form -->
    <form [formGroup]="loginForm" (ngSubmit)="onSubmit()" class="login-form">
      <!-- Error Alert -->
      @if (error()) {
        <div class="alert alert-error">
          <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor">
            <circle cx="12" cy="12" r="10"></circle>
            <line x1="12" y1="8" x2="12" y2="12"></line>
            <line x1="12" y1="16" x2="12.01" y2="16"></line>
          </svg>
          <span>{{ error() }}</span>
        </div>
      }
      
      <!-- Tenant Select -->
      <div class="form-field">
        <label for="tenantId" class="form-label">Tenant</label>
        <select
          id="tenantId"
          formControlName="tenantId"
          class="form-select"
          [class.form-field-error]="getFieldError('tenantId')"
        >
          @for (tenant of tenants; track tenant.id) {
            <option [value]="tenant.id">{{ tenant.name }}</option>
          }
        </select>
        @if (getFieldError('tenantId')) {
          <span class="form-error">{{ getFieldError('tenantId') }}</span>
        }
      </div>
      
      <!-- Username Input -->
      <div class="form-field">
        <label for="username" class="form-label">Usuario</label>
        <input
          type="text"
          id="username"
          formControlName="username"
          placeholder="Ingresa tu usuario"
          class="form-input"
          [class.form-field-error]="getFieldError('username')"
          autocomplete="username"
        />
        @if (getFieldError('username')) {
          <span class="form-error">{{ getFieldError('username') }}</span>
        }
      </div>
      
      <!-- Password Input -->
      <div class="form-field">
        <label for="password" class="form-label">Contraseña</label>
        <div class="input-with-icon">
          <input
            [type]="showPassword() ? 'text' : 'password'"
            id="password"
            formControlName="password"
            placeholder="Ingresa tu contraseña"
            class="form-input"
            [class.form-field-error]="getFieldError('password')"
            autocomplete="current-password"
          />
          <button
            type="button"
            class="icon-button"
            (click)="togglePasswordVisibility()"
            [attr.aria-label]="showPassword() ? 'Ocultar contraseña' : 'Mostrar contraseña'"
          >
            @if (showPassword()) {
              <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor">
                <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"></path>
                <line x1="1" y1="1" x2="23" y2="23"></line>
              </svg>
            } @else {
              <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor">
                <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
                <circle cx="12" cy="12" r="3"></circle>
              </svg>
            }
          </button>
        </div>
        @if (getFieldError('password')) {
          <span class="form-error">{{ getFieldError('password') }}</span>
        }
      </div>
      
      <!-- Remember Me -->
      <div class="form-checkbox">
        <input
          type="checkbox"
          id="rememberMe"
          formControlName="rememberMe"
          class="checkbox"
        />
        <label for="rememberMe" class="checkbox-label">Recordarme</label>
      </div>
      
      <!-- Submit Button -->
      <button
        type="submit"
        class="btn-primary btn-block"
        [disabled]="loading()"
      >
        @if (loading()) {
          <span class="spinner"></span>
          <span>Iniciando sesión...</span>
        } @else {
          <span>Iniciar Sesión</span>
        }
      </button>
      
      <!-- Forgot Password Link -->
      <div class="form-footer">
        <a routerLink="/auth/forgot-password" class="link">
          ¿Olvidaste tu contraseña?
        </a>
      </div>
    </form>
  </div>
</div>
```

**Archivo:** `libs/features/auth/src/lib/login/login.component.scss`

```scss
.login-container {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--color-bg-primary);
  padding: var(--spacing-6);
}

.login-card {
  width: 100%;
  max-width: 440px;
  background: var(--color-surface);
  border: 1px solid var(--color-border-light);
  border-radius: var(--radius-xl);
  box-shadow: var(--shadow-lg);
  padding: var(--spacing-8);
  position: relative;
}

.login-header {
  text-align: center;
  margin-bottom: var(--spacing-8);
  
  .logo {
    height: 48px;
    margin-bottom: var(--spacing-4);
  }
  
  .title {
    font-size: var(--font-size-3xl);
    font-weight: var(--font-weight-bold);
    color: var(--color-text-primary);
    margin: 0 0 var(--spacing-2) 0;
  }
  
  .subtitle {
    font-size: var(--font-size-base);
    color: var(--color-text-secondary);
    margin: 0;
  }
}

.theme-toggle-wrapper {
  position: absolute;
  top: var(--spacing-4);
  right: var(--spacing-4);
}

.login-form {
  display: flex;
  flex-direction: column;
  gap: var(--spacing-5);
}

.form-field {
  display: flex;
  flex-direction: column;
  gap: var(--spacing-2);
}

.form-label {
  font-size: var(--font-size-sm);
  font-weight: var(--font-weight-medium);
  color: var(--color-text-primary);
}

.form-input,
.form-select {
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
  
  &.form-field-error {
    border-color: var(--color-error);
    
    &:focus {
      box-shadow: var(--shadow-focus-error);
    }
  }
}

.input-with-icon {
  position: relative;
  
  .form-input {
    padding-right: 48px;
  }
  
  .icon-button {
    position: absolute;
    right: var(--spacing-2);
    top: 50%;
    transform: translateY(-50%);
    background: transparent;
    border: none;
    cursor: pointer;
    padding: var(--spacing-2);
    color: var(--color-text-tertiary);
    border-radius: var(--radius-md);
    transition: all 0.2s ease;
    
    &:hover {
      background: var(--color-surface-hover);
      color: var(--color-text-primary);
    }
    
    .icon {
      width: 20px;
      height: 20px;
      stroke-width: 2;
    }
  }
}

.form-error {
  font-size: var(--font-size-xs);
  color: var(--color-error);
}

.form-checkbox {
  display: flex;
  align-items: center;
  gap: var(--spacing-2);
  
  .checkbox {
    width: 18px;
    height: 18px;
    cursor: pointer;
  }
  
  .checkbox-label {
    font-size: var(--font-size-sm);
    color: var(--color-text-secondary);
    cursor: pointer;
  }
}

.btn-primary {
  font-family: var(--font-family-primary);
  font-size: var(--font-size-base);
  font-weight: var(--font-weight-medium);
  padding: var(--spacing-4) var(--spacing-6);
  background: var(--color-interactive-primary);
  color: var(--color-text-inverse);
  border: none;
  border-radius: var(--radius-md);
  cursor: pointer;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: var(--spacing-2);
  
  &:hover:not(:disabled) {
    background: var(--color-interactive-primary-hover);
  }
  
  &:active:not(:disabled) {
    background: var(--color-interactive-primary-active);
  }
  
  &:focus-visible {
    outline: none;
    box-shadow: var(--shadow-focus);
  }
  
  &:disabled {
    cursor: not-allowed;
    opacity: 0.6;
  }
}

.btn-block {
  width: 100%;
}

.spinner {
  width: 18px;
  height: 18px;
  border: 2px solid rgba(255, 255, 255, 0.3);
  border-top-color: white;
  border-radius: 50%;
  animation: spin 0.6s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.form-footer {
  text-align: center;
  margin-top: var(--spacing-2);
  
  .link {
    color: var(--color-interactive-primary);
    text-decoration: none;
    font-size: var(--font-size-sm);
    font-weight: var(--font-weight-medium);
    transition: color 0.2s ease;
    
    &:hover {
      color: var(--color-interactive-primary-hover);
      text-decoration: underline;
    }
  }
}

.alert {
  display: flex;
  align-items: center;
  gap: var(--spacing-3);
  padding: var(--spacing-4);
  border-radius: var(--radius-md);
  font-size: var(--font-size-sm);
  
  .icon {
    width: 20px;
    height: 20px;
    stroke-width: 2;
    flex-shrink: 0;
  }
  
  &.alert-error {
    background: var(--color-error-bg);
    color: var(--color-error);
    border: 1px solid var(--color-error);
  }
}

// Responsive
@media (max-width: 480px) {
  .login-container {
    padding: var(--spacing-4);
  }
  
  .login-card {
    padding: var(--spacing-6);
  }
  
  .login-header {
    .title {
      font-size: var(--font-size-2xl);
    }
  }
}
```

---

## 5. Pantalla de Recuperar Contraseña

### 5.1 Diseño UI

**Wireframe**

```
┌──────────────────────────────────────────┐
│                                          │
│          [Logo NexCore]                  │
│                                          │
│       Recuperar Contraseña               │
│       Ingresa tu email y te enviaremos   │
│       instrucciones para restablecer     │
│       tu contraseña.                     │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │ Email                              │ │
│  │ [Input: user@example.com]          │ │
│  └────────────────────────────────────┘ │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │      ENVIAR INSTRUCCIONES          │ │
│  └────────────────────────────────────┘ │
│                                          │
│  Volver a Iniciar Sesión                │
│                                          │
│                                  [🌙/☀] │
└──────────────────────────────────────────┘
```

### 5.2 Implementación

**Archivo:** `libs/features/auth/src/lib/forgot-password/forgot-password.component.ts`

```typescript
import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { AuthService } from '@nexcore/data-access/auth';
import { ThemeToggleComponent } from '@nexcore/shared/ui/theme';

@Component({
  selector: 'nxc-forgot-password',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    RouterModule,
    ThemeToggleComponent
  ],
  templateUrl: './forgot-password.component.html',
  styleUrl: './forgot-password.component.scss'
})
export class ForgotPasswordComponent {
  private fb = inject(FormBuilder);
  private authService = inject(AuthService);
  private router = inject(Router);
  
  forgotForm: FormGroup;
  loading = signal(false);
  error = signal<string | null>(null);
  success = signal(false);
  
  constructor() {
    this.forgotForm = this.fb.group({
      email: ['', [Validators.required, Validators.email]]
    });
  }
  
  async onSubmit(): Promise<void> {
    if (this.forgotForm.invalid) {
      this.forgotForm.markAllAsTouched();
      return;
    }
    
    this.loading.set(true);
    this.error.set(null);
    
    try {
      const { email } = this.forgotForm.value;
      
      // ============================================================
      // MOCK: Simulación de envío de email (sin backend real)
      // ============================================================
      
      // Simular delay de red (500ms)
      await new Promise(resolve => setTimeout(resolve, 500));
      
      // Validar formato de email (ya validado por el formulario)
      // En producción, el backend verificaría si el email existe
      
      console.log('📧 [MOCK] Email de recuperación enviado a:', email);
      
      this.success.set(true);
      
      // Redirigir al login después de 3 segundos
      setTimeout(() => {
        this.router.navigate(['/auth/login']);
      }, 3000);
      
      // ============================================================
      // PRODUCCIÓN: Descomentar cuando se integre con backend
      // ============================================================
      // await this.authService.forgotPassword({ email });
      // this.success.set(true);
      
    } catch (err: any) {
      this.error.set(err.message || 'Error al enviar instrucciones');
    } finally {
      this.loading.set(false);
    }
  }
  
  getFieldError(field: string): string | null {
    const control = this.forgotForm.get(field);
    
    if (!control || !control.touched || !control.errors) {
      return null;
    }
    
    if (control.errors['required']) {
      return 'Este campo es requerido';
    }
    
    if (control.errors['email']) {
      return 'Email inválido';
    }
    
    return null;
  }
}
```

**Archivo:** `libs/features/auth/src/lib/forgot-password/forgot-password.component.html`

```html
<div class="forgot-container">
  <div class="forgot-card">
    <!-- Header -->
    <div class="forgot-header">
      <img src="/assets/images/logo-light.svg" alt="NexCore" class="logo" />
      <h1 class="title">Recuperar Contraseña</h1>
      <p class="subtitle">
        Ingresa tu email y te enviaremos instrucciones para restablecer tu contraseña
      </p>
    </div>
    
    <!-- Theme Toggle -->
    <div class="theme-toggle-wrapper">
      <nxc-theme-toggle />
    </div>
    
    <!-- Success State -->
    @if (success()) {
      <div class="alert alert-success">
        <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor">
          <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
          <polyline points="22 4 12 14.01 9 11.01"></polyline>
        </svg>
        <div>
          <div class="alert-title">¡Instrucciones enviadas!</div>
          <div class="alert-message">
            Revisa tu correo electrónico. Serás redirigido al login en unos segundos...
          </div>
        </div>
      </div>
    }
    
    <!-- Form (hide on success) -->
    @if (!success()) {
      <form [formGroup]="forgotForm" (ngSubmit)="onSubmit()" class="forgot-form">
        <!-- Error Alert -->
        @if (error()) {
          <div class="alert alert-error">
            <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor">
              <circle cx="12" cy="12" r="10"></circle>
              <line x1="12" y1="8" x2="12" y2="12"></line>
              <line x1="12" y1="16" x2="12.01" y2="16"></line>
            </svg>
            <span>{{ error() }}</span>
          </div>
        }
        
        <!-- Email Input -->
        <div class="form-field">
          <label for="email" class="form-label">Email</label>
          <input
            type="email"
            id="email"
            formControlName="email"
            placeholder="tu@email.com"
            class="form-input"
            [class.form-field-error]="getFieldError('email')"
            autocomplete="email"
          />
          @if (getFieldError('email')) {
            <span class="form-error">{{ getFieldError('email') }}</span>
          }
        </div>
        
        <!-- Submit Button -->
        <button
          type="submit"
          class="btn-primary btn-block"
          [disabled]="loading()"
        >
          @if (loading()) {
            <span class="spinner"></span>
            <span>Enviando...</span>
          } @else {
            <span>Enviar Instrucciones</span>
          }
        </button>
        
        <!-- Back to Login Link -->
        <div class="form-footer">
          <a routerLink="/auth/login" class="link">
            Volver a Iniciar Sesión
          </a>
        </div>
      </form>
    }
  </div>
</div>
```

**Archivo:** `libs/features/auth/src/lib/forgot-password/forgot-password.component.scss`

```scss
// Reutilizar estilos del login
@import '../login/login.component.scss';

.forgot-container {
  @extend .login-container;
}

.forgot-card {
  @extend .login-card;
}

.forgot-header {
  @extend .login-header;
}

.forgot-form {
  @extend .login-form;
}

.alert {
  display: flex;
  align-items: flex-start;
  gap: var(--spacing-3);
  padding: var(--spacing-4);
  border-radius: var(--radius-md);
  font-size: var(--font-size-sm);
  margin-bottom: var(--spacing-6);
  
  .icon {
    width: 24px;
    height: 24px;
    stroke-width: 2;
    flex-shrink: 0;
    margin-top: 2px;
  }
  
  &.alert-error {
    background: var(--color-error-bg);
    color: var(--color-error);
    border: 1px solid var(--color-error);
  }
  
  &.alert-success {
    background: var(--color-success-bg);
    color: var(--color-success);
    border: 1px solid var(--color-success);
  }
  
  .alert-title {
    font-weight: var(--font-weight-semibold);
    margin-bottom: var(--spacing-1);
  }
  
  .alert-message {
    font-size: var(--font-size-xs);
    opacity: 0.9;
  }
}
```

---

## 5.3 Pantalla de Verificar OTP

### 5.3.1 Diseño UI

**Wireframe**

```
┌──────────────────────────────────────────┐
│                                          │
│          [Logo NexCore]                  │
│                                          │
│       Verificar Código OTP               │
│       Ingresa el código de 6 dígitos    │
│       enviado a tu email                 │
│                                          │
│  ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐   │
│  │ 1 │ │ 2 │ │ 3 │ │ 4 │ │ 5 │ │ 6 │   │
│  └───┘ └───┘ └───┘ └───┘ └───┘ └───┘   │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │      VERIFICAR                     │ │
│  └────────────────────────────────────┘ │
│                                          │
│  ¿No recibiste el código?               │
│  Reenviar código (30s)                  │
│                                          │
│  Volver a Iniciar Sesión                │
│                                          │
│                                  [🌙/☀] │
└──────────────────────────────────────────┘
```

### 5.3.2 Implementación

**Archivo:** `libs/features/auth/src/lib/verify-otp/verify-otp.component.ts`

```typescript
import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { AuthService } from '@nexcore/data-access/auth';
import { ThemeToggleComponent } from '@nexcore/shared/ui/theme';

@Component({
  selector: 'nxc-verify-otp',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    RouterModule,
    ThemeToggleComponent
  ],
  templateUrl: './verify-otp.component.html',
  styleUrl: './verify-otp.component.scss'
})
export class VerifyOtpComponent {
  private fb = inject(FormBuilder);
  private authService = inject(AuthService);
  private router = inject(Router);
  
  otpForm: FormGroup;
  loading = signal(false);
  error = signal<string | null>(null);
  resendTimer = signal(30);
  canResend = signal(false);
  
  constructor() {
    // Verificar que existe challenge token
    const challengeToken = sessionStorage.getItem('challengeToken');
    if (!challengeToken) {
      this.router.navigate(['/auth/login']);
      return;
    }
    
    this.otpForm = this.fb.group({
      digit1: ['', [Validators.required, Validators.pattern(/^\d$/)]],
      digit2: ['', [Validators.required, Validators.pattern(/^\d$/)]],
      digit3: ['', [Validators.required, Validators.pattern(/^\d$/)]],
      digit4: ['', [Validators.required, Validators.pattern(/^\d$/)]],
      digit5: ['', [Validators.required, Validators.pattern(/^\d$/)]],
      digit6: ['', [Validators.required, Validators.pattern(/^\d$/)]]
    });
    
    this.startResendTimer();
  }
  
  startResendTimer(): void {
    this.canResend.set(false);
    this.resendTimer.set(30);
    
    const interval = setInterval(() => {
      const current = this.resendTimer();
      if (current <= 1) {
        clearInterval(interval);
        this.canResend.set(true);
      } else {
        this.resendTimer.set(current - 1);
      }
    }, 1000);
  }
  
  onDigitInput(event: Event, index: number): void {
    const input = event.target as HTMLInputElement;
    const value = input.value;
    
    // Auto-avanzar al siguiente campo
    if (value.length === 1 && index < 6) {
      const nextInput = input.parentElement?.parentElement
        ?.querySelector(`#digit${index + 1}`) as HTMLInputElement;
      nextInput?.focus();
    }
  }
  
  onDigitKeyDown(event: KeyboardEvent, index: number): void {
    const input = event.target as HTMLInputElement;
    
    // Retroceder al campo anterior con Backspace
    if (event.key === 'Backspace' && !input.value && index > 1) {
      const prevInput = input.parentElement?.parentElement
        ?.querySelector(`#digit${index - 1}`) as HTMLInputElement;
      prevInput?.focus();
    }
  }
  
  async onSubmit(): Promise<void> {
    if (this.otpForm.invalid) {
      this.otpForm.markAllAsTouched();
      return;
    }
    
    this.loading.set(true);
    this.error.set(null);
    
    try {
      const challengeToken = sessionStorage.getItem('challengeToken')!;
      
      const otpCode = Object.values(this.otpForm.value).join('');
      
      // ============================================================
      // MOCK: Simulación de verificación OTP (sin backend real)
      // ============================================================
      
      // Simular delay de red (400ms)
      await new Promise(resolve => setTimeout(resolve, 400));
      
      // En esta fase, cualquier código de 6 dígitos es válido
      if (otpCode.length !== 6) {
        throw new Error('Código OTP inválido');
      }
      
      console.log('✅ [MOCK] OTP verificado:', otpCode);
      
      // Simular respuesta de sesión
      const mockSession = {
        accessToken: 'mock-access-token-' + Date.now(),
        refreshToken: 'mock-refresh-token-' + Date.now(),
        expiresIn: 3600,
        profile: {
          id: 'mock-user-id',
          username: sessionStorage.getItem('mockUsername') || 'super.admin',
          email: 'admin@nexcore.com',
          name: 'Administrador',
          avatar: '/assets/images/default-avatar.png',
          tenantId: '00000000-0000-0000-0000-000000000001',
          tenantName: 'Sistema'
        }
      };
      
      // Guardar sesión mock
      localStorage.setItem('accessToken', mockSession.accessToken);
      localStorage.setItem('refreshToken', mockSession.refreshToken);
      
      // Limpiar challenge token
      sessionStorage.removeItem('challengeToken');
      sessionStorage.removeItem('mockUsername');
      
      // Redirigir al dashboard
      this.router.navigate(['/dashboard']);
      
      // ============================================================
      // PRODUCCIÓN: Descomentar cuando se integre con backend
      // ============================================================
      // const response = await this.authService.verifyOtp({
      //   challengeToken,
      //   otpCode
      // });
      // sessionStorage.removeItem('challengeToken');
      // this.router.navigate(['/dashboard']);
      
    } catch (err: any) {
      this.error.set(err.message || 'Código OTP inválido');
    } finally {
      this.loading.set(false);
    }
  }
  
  async resendCode(): Promise<void> {
    if (!this.canResend()) return;
    
    this.loading.set(true);
    this.error.set(null);
    
    try {
      // ============================================================
      // MOCK: Simular reenvío de código
      // ============================================================
      
      await new Promise(resolve => setTimeout(resolve, 300));
      
      console.log('📧 [MOCK] Código OTP reenviado');
      
      // Reiniciar timer
      this.startResendTimer();
      
      // Limpiar formulario
      this.otpForm.reset();
      
      // Focus en primer input
      setTimeout(() => {
        const firstInput = document.querySelector('#digit1') as HTMLInputElement;
        firstInput?.focus();
      }, 100);
      
      // ============================================================
      // PRODUCCIÓN: Descomentar cuando se integre con backend
      // ============================================================
      // await this.authService.resendOtp({
      //   challengeToken: sessionStorage.getItem('challengeToken')!
      // });
      
    } catch (err: any) {
      this.error.set(err.message || 'Error al reenviar código');
    } finally {
      this.loading.set(false);
    }
  }
}
```

**Archivo:** `libs/features/auth/src/lib/verify-otp/verify-otp.component.html`

```html
<div class="otp-container">
  <div class="otp-card">
    <!-- Header -->
    <div class="otp-header">
      <img src="/assets/images/logo-light.svg" alt="NexCore" class="logo" />
      <h1 class="title">Verificar Código OTP</h1>
      <p class="subtitle">
        Ingresa el código de 6 dígitos enviado a tu email
      </p>
    </div>
    
    <!-- Theme Toggle -->
    <div class="theme-toggle-wrapper">
      <nxc-theme-toggle />
    </div>
    
    <!-- Form -->
    <form [formGroup]="otpForm" (ngSubmit)="onSubmit()" class="otp-form">
      <!-- Error Alert -->
      @if (error()) {
        <div class="alert alert-error">
          <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor">
            <circle cx="12" cy="12" r="10"></circle>
            <line x1="12" y1="8" x2="12" y2="12"></line>
            <line x1="12" y1="16" x2="12.01" y2="16"></line>
          </svg>
          <span>{{ error() }}</span>
        </div>
      }
      
      <!-- OTP Input Fields -->
      <div class="otp-inputs">
        @for (i of [1, 2, 3, 4, 5, 6]; track i) {
          <input
            type="text"
            [id]="'digit' + i"
            [formControlName]="'digit' + i"
            class="otp-digit"
            maxlength="1"
            inputmode="numeric"
            pattern="[0-9]"
            (input)="onDigitInput($event, i)"
            (keydown)="onDigitKeyDown($event, i)"
            [attr.aria-label]="'Dígito ' + i"
          />
        }
      </div>
      
      <!-- Submit Button -->
      <button
        type="submit"
        class="btn-primary btn-block"
        [disabled]="loading() || otpForm.invalid"
      >
        @if (loading()) {
          <span class="spinner"></span>
          <span>Verificando...</span>
        } @else {
          <span>Verificar</span>
        }
      </button>
      
      <!-- Resend Code -->
      <div class="form-footer">
        <p class="footer-text">¿No recibiste el código?</p>
        @if (canResend()) {
          <button
            type="button"
            class="link-button"
            (click)="resendCode()"
            [disabled]="loading()"
          >
            Reenviar código
          </button>
        } @else {
          <span class="timer-text">
            Reenviar código en {{ resendTimer() }}s
          </span>
        }
      </div>
      
      <!-- Back to Login -->
      <div class="form-footer">
        <a routerLink="/auth/login" class="link">
          Volver a Iniciar Sesión
        </a>
      </div>
    </form>
  </div>
</div>
```

**Archivo:** `libs/features/auth/src/lib/verify-otp/verify-otp.component.scss`

```scss
// Reutilizar estilos base del login
@import '../login/login.component.scss';

.otp-container {
  @extend .login-container;
}

.otp-card {
  @extend .login-card;
}

.otp-header {
  @extend .login-header;
}

.otp-form {
  @extend .login-form;
}

// Estilos específicos de OTP
.otp-inputs {
  display: flex;
  gap: var(--spacing-3);
  justify-content: center;
  margin: var(--spacing-6) 0;
}

.otp-digit {
  width: 56px;
  height: 64px;
  font-family: var(--font-family-mono);
  font-size: var(--font-size-2xl);
  font-weight: var(--font-weight-bold);
  text-align: center;
  border: 2px solid var(--color-border-medium);
  border-radius: var(--radius-lg);
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
  
  &:invalid {
    border-color: var(--color-error);
  }
}

.footer-text {
  font-size: var(--font-size-sm);
  color: var(--color-text-secondary);
  margin: 0 0 var(--spacing-2) 0;
  text-align: center;
}

.link-button {
  background: transparent;
  border: none;
  color: var(--color-interactive-primary);
  font-size: var(--font-size-sm);
  font-weight: var(--font-weight-medium);
  cursor: pointer;
  padding: 0;
  text-decoration: none;
  transition: color 0.2s ease;
  
  &:hover:not(:disabled) {
    color: var(--color-interactive-primary-hover);
    text-decoration: underline;
  }
  
  &:disabled {
    cursor: not-allowed;
    opacity: 0.5;
  }
}

.timer-text {
  font-size: var(--font-size-sm);
  color: var(--color-text-tertiary);
  font-style: italic;
}

// Responsive
@media (max-width: 480px) {
  .otp-inputs {
    gap: var(--spacing-2);
  }
  
  .otp-digit {
    width: 44px;
    height: 52px;
    font-size: var(--font-size-xl);
  }
}
```

---

## 6. Sistema de Temas Light/Dark

### 6.1 Servicio de Temas

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

### 6.2 Componente Theme Toggle

**Archivo:** `libs/shared/ui/theme/src/lib/theme-toggle/theme-toggle.component.ts`

```typescript
import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ThemeService } from '../theme.service';

@Component({
  selector: 'nxc-theme-toggle',
  standalone: true,
  imports: [CommonModule],
  template: `
    <button
      class="theme-toggle"
      [attr.aria-label]="'Cambiar tema: ' + effectiveTheme()"
      (click)="toggleTheme()"
    >
      @if (effectiveTheme() === 'light') {
        <!-- Icono de Luna (modo oscuro disponible) -->
        <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor">
          <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" />
        </svg>
      } @else {
        <!-- Icono de Sol (modo claro disponible) -->
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
      display: flex;
      align-items: center;
      justify-content: center;
      
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

### 6.3 Tokens de Tema

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
  
  // Shadows
  --shadow-sm: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
  --shadow-base: 0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06);
  --shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
  --shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
  --shadow-focus: 0 0 0 3px rgba(66, 153, 225, 0.5);
  --shadow-focus-error: 0 0 0 3px rgba(245, 101, 101, 0.5);
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
  --shadow-focus: 0 0 0 3px rgba(66, 153, 225, 0.4);
  --shadow-focus-error: 0 0 0 3px rgba(245, 101, 101, 0.4);
  
  // Ajustar colores primarios para mejor contraste
  --color-interactive-primary: #{$color-primary-400};
  --color-interactive-primary-hover: #{$color-primary-300};
  --color-interactive-primary-active: #{$color-primary-200};
}
```

---

## 7. Integración del Sistema de Temas

### 7.1 Importar Tokens en Global Styles

**Archivo:** `apps/web/src/styles.scss`

```scss
// Importar tokens de colores
@import '../../../libs/shared/ui/styles/tokens/colors';
@import '../../../libs/shared/ui/styles/tokens/typography';
@import '../../../libs/shared/ui/styles/tokens/spacing';
@import '../../../libs/shared/ui/styles/tokens/shadows';
@import '../../../libs/shared/ui/styles/tokens/borders';
@import '../../../libs/shared/ui/styles/tokens/breakpoints';
@import '../../../libs/shared/ui/styles/tokens/z-index';

// Importar temas
@import '../../../libs/shared/ui/styles/themes/light';
@import '../../../libs/shared/ui/styles/themes/dark';

// Reset básico
* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

html, body {
  height: 100%;
  font-family: var(--font-family-primary);
  font-size: var(--font-size-base);
  line-height: var(--line-height-normal);
  color: var(--color-text-primary);
  background: var(--color-bg-primary);
  transition: background-color 0.3s ease, color 0.3s ease;
}

// Smooth transitions para cambio de tema
body[data-theme] {
  transition: background-color 0.3s ease, color 0.3s ease;
  
  * {
    transition: background-color 0.3s ease, 
                border-color 0.3s ease, 
                color 0.3s ease,
                box-shadow 0.3s ease;
  }
}
```

### 7.2 Inicializar Tema en App Component

**Archivo:** `apps/web/src/app/app.component.ts`

```typescript
import { Component, inject, OnInit } from '@angular/core';
import { RouterModule } from '@angular/router';
import { ThemeService } from '@nexcore/shared/ui/theme';

@Component({
  standalone: true,
  imports: [RouterModule],
  selector: 'app-root',
  template: `<router-outlet></router-outlet>`,
  styleUrl: './app.component.scss'
})
export class AppComponent implements OnInit {
  private themeService = inject(ThemeService);
  
  ngOnInit(): void {
    // El servicio ya aplica el tema automáticamente en su constructor
    console.log('Tema actual:', this.themeService.effectiveTheme());
  }
}
```

---

## 8. Servicio de Autenticación (Mock)

> **Nota:** Este servicio usa datos mock para simular las respuestas del backend.  
> En la Fase 2 se implementarán las llamadas HTTP reales a nexcore-auth-service.

**Archivo:** `libs/shared/data-access/auth/src/lib/auth.service.ts`

```typescript
import { Injectable, inject, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { firstValueFrom } from 'rxjs';
// import { environment } from '@env/environment'; // Comentado temporalmente

export interface LoginRequest {
  tenantId: string;
  username: string;
  password: string;
}

export interface LoginResponse {
  challengeToken: string;
  message: string;
}

export interface VerifyOtpRequest {
  challengeToken: string;
  otpCode: string;
}

export interface SessionResponse {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
  profile: UserProfile;
}

export interface UserProfile {
  id: string;
  username: string;
  email: string;
  name: string;
  avatar?: string;
  tenantId: string;
  tenantName: string;
}

export interface ForgotPasswordRequest {
  email: string;
}

export interface ResetPasswordRequest {
  token: string;
  newPassword: string;
}

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private http = inject(HttpClient);
  private router = inject(Router);
  
  // Comentado para fase 1 (solo frontend)
  // private readonly API_URL = environment.authUrl;
  
  // State signals
  userProfile = signal<UserProfile | null>(null);
  isAuthenticated = signal(false);
  
  constructor() {
    this.loadSessionFromStorage();
  }
  
  // ============================================================
  // MÉTODOS MOCK (Fase 1 - Solo Frontend)
  // ============================================================
  
  async login(request: LoginRequest): Promise<LoginResponse> {
    // Simular delay de red
    await new Promise(resolve => setTimeout(resolve, 300));
    
    // Mock: Simular respuesta exitosa
    return {
      challengeToken: 'mock-challenge-' + Date.now(),
      message: 'Código OTP enviado'
    };
    
    // PRODUCCIÓN: Descomentar para integración real
    // const url = `${this.API_URL}/auth/login`;
    // return firstValueFrom(this.http.post<LoginResponse>(url, request));
  }
  
  async verifyOtp(request: VerifyOtpRequest): Promise<SessionResponse> {
    // Simular delay de red
    await new Promise(resolve => setTimeout(resolve, 400));
    
    // Mock: Simular sesión exitosa
    const mockResponse: SessionResponse = {
      accessToken: 'mock-access-token-' + Date.now(),
      refreshToken: 'mock-refresh-token-' + Date.now(),
      expiresIn: 3600,
      profile: {
        id: 'mock-user-id',
        username: 'super.admin',
        email: 'admin@nexcore.com',
        name: 'Administrador',
        avatar: '/assets/images/default-avatar.png',
        tenantId: '00000000-0000-0000-0000-000000000001',
        tenantName: 'Sistema'
      }
    };
    
    this.saveSession(mockResponse);
    return mockResponse;
    
    // PRODUCCIÓN: Descomentar para integración real
    // const url = `${this.API_URL}/auth/verify-otp`;
    // const response = await firstValueFrom(
    //   this.http.post<SessionResponse>(url, request)
    // );
    // this.saveSession(response);
    // return response;
  }
  
  async forgotPassword(request: ForgotPasswordRequest): Promise<void> {
    // Simular delay de red
    await new Promise(resolve => setTimeout(resolve, 500));
    
    console.log('📧 [MOCK] Email enviado a:', request.email);
    
    // PRODUCCIÓN: Descomentar para integración real
    // const url = `${this.API_URL}/auth/forgot-password`;
    // return firstValueFrom(this.http.post<void>(url, request));
  }
  
  async resetPassword(request: ResetPasswordRequest): Promise<void> {
    // Simular delay de red
    await new Promise(resolve => setTimeout(resolve, 400));
    
    console.log('🔐 [MOCK] Contraseña restablecida');
    
    // PRODUCCIÓN: Descomentar para integración real
    // const url = `${this.API_URL}/auth/reset-password`;
    // return firstValueFrom(this.http.post<void>(url, request));
  }
  
  async refreshToken(): Promise<SessionResponse> {
    const refreshToken = localStorage.getItem('refreshToken');
    
    if (!refreshToken) {
      throw new Error('No refresh token available');
    }
    
    // Simular delay de red
    await new Promise(resolve => setTimeout(resolve, 200));
    
    // Mock: Simular refresh exitoso
    const mockResponse: SessionResponse = {
      accessToken: 'mock-access-token-refreshed-' + Date.now(),
      refreshToken: 'mock-refresh-token-refreshed-' + Date.now(),
      expiresIn: 3600,
      profile: this.userProfile()!
    };
    
    this.saveSession(mockResponse);
    return mockResponse;
    
    // PRODUCCIÓN: Descomentar para integración real
    // const url = `${this.API_URL}/auth/refresh`;
    // const response = await firstValueFrom(
    //   this.http.post<SessionResponse>(url, { refreshToken })
    // );
    // this.saveSession(response);
    // return response;
  }
  
  logout(): void {
    localStorage.removeItem('accessToken');
    localStorage.removeItem('refreshToken');
    sessionStorage.clear();
    
    this.userProfile.set(null);
    this.isAuthenticated.set(false);
    
    this.router.navigate(['/auth/login']);
  }
  
  private saveSession(response: SessionResponse): void {
    localStorage.setItem('accessToken', response.accessToken);
    localStorage.setItem('refreshToken', response.refreshToken);
    
    this.userProfile.set(response.profile);
    this.isAuthenticated.set(true);
  }
  
  private loadSessionFromStorage(): void {
    const accessToken = localStorage.getItem('accessToken');
    
    if (accessToken) {
      // Validar token y cargar perfil
      this.isAuthenticated.set(true);
      // TODO: Implementar validación de token y carga de perfil
    }
  }
}
```

---

## 9. Testing

### 9.1 Test del Login Component

**Archivo:** `libs/features/auth/src/lib/login/login.component.spec.ts`

```typescript
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { ReactiveFormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { of, throwError } from 'rxjs';
import { LoginComponent } from './login.component';
import { AuthService } from '@nexcore/data-access/auth';
import { ThemeToggleComponent } from '@nexcore/shared/ui/theme';

describe('LoginComponent', () => {
  let component: LoginComponent;
  let fixture: ComponentFixture<LoginComponent>;
  let mockAuthService: jasmine.SpyObj<AuthService>;
  let mockRouter: jasmine.SpyObj<Router>;
  
  beforeEach(async () => {
    mockAuthService = jasmine.createSpyObj('AuthService', ['login']);
    mockRouter = jasmine.createSpyObj('Router', ['navigate']);
    
    await TestBed.configureTestingModule({
      imports: [
        LoginComponent,
        ReactiveFormsModule,
        ThemeToggleComponent
      ],
      providers: [
        { provide: AuthService, useValue: mockAuthService },
        { provide: Router, useValue: mockRouter }
      ]
    }).compileComponents();
    
    fixture = TestBed.createComponent(LoginComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });
  
  it('should create', () => {
    expect(component).toBeTruthy();
  });
  
  it('should have invalid form when empty', () => {
    expect(component.loginForm.valid).toBeFalsy();
  });
  
  it('should validate required fields', () => {
    const usernameControl = component.loginForm.get('username');
    const passwordControl = component.loginForm.get('password');
    
    usernameControl?.markAsTouched();
    passwordControl?.markAsTouched();
    
    expect(component.getFieldError('username')).toBe('Este campo es requerido');
    expect(component.getFieldError('password')).toBe('Este campo es requerido');
  });
  
  it('should call authService.login on valid form submission', async () => {
    const mockResponse = {
      challengeToken: 'mock-token',
      message: 'OTP sent'
    };
    
    mockAuthService.login.and.returnValue(Promise.resolve(mockResponse));
    
    component.loginForm.patchValue({
      tenantId: '00000000-0000-0000-0000-000000000001',
      username: 'testuser',
      password: 'password123'
    });
    
    await component.onSubmit();
    
    expect(mockAuthService.login).toHaveBeenCalledWith({
      tenantId: '00000000-0000-0000-0000-000000000001',
      username: 'testuser',
      password: 'password123'
    });
    
    expect(mockRouter.navigate).toHaveBeenCalledWith(['/auth/verify-otp']);
  });
  
  it('should show error message on login failure', async () => {
    const errorMessage = 'Credenciales inválidas';
    mockAuthService.login.and.returnValue(
      Promise.reject({ error: { message: errorMessage } })
    );
    
    component.loginForm.patchValue({
      tenantId: '00000000-0000-0000-0000-000000000001',
      username: 'testuser',
      password: 'wrongpassword'
    });
    
    await component.onSubmit();
    
    expect(component.error()).toBe(errorMessage);
  });
  
  it('should toggle password visibility', () => {
    expect(component.showPassword()).toBeFalsy();
    
    component.togglePasswordVisibility();
    expect(component.showPassword()).toBeTruthy();
    
    component.togglePasswordVisibility();
    expect(component.showPassword()).toBeFalsy();
  });
});
```

---

## 10. Comandos de Desarrollo

### 10.1 Generar Componentes

```bash
# Generar componente de login
nx g @nx/angular:component --name=login --project=features-auth --standalone

# Generar componente de forgot-password
nx g @nx/angular:component --name=forgot-password --project=features-auth --standalone

# Generar servicio de autenticación
nx g @nx/angular:service --name=auth --project=shared-data-access-auth

# Generar servicio de temas
nx g @nx/angular:service --name=theme --project=shared-ui-theme
```

### 10.2 Ejecutar Aplicación

```bash
# Servir aplicación en desarrollo
nx serve web

# Servir con hot reload
nx serve web --hmr

# Build para producción
nx build web --configuration=production
```

### 10.3 Testing

```bash
# Ejecutar tests del módulo auth
nx test features-auth

# Ejecutar tests con cobertura
nx test features-auth --coverage

# Ejecutar tests en modo watch
nx test features-auth --watch
```

---

## 11. Fases de Implementación

### 📍 FASE 1: Frontend UI/UX (ACTUAL)

**Objetivo:** Establecer el diseño, estilos y componentes visuales sin integración backend.

#### 1.1 Setup Base
- [ ] Crear librería `features/auth`
- [ ] Crear librería `shared/ui/theme`
- [ ] Crear librería `shared/data-access/auth` (con mocks)
- [ ] Configurar tokens de diseño en `shared/ui/styles`
- [ ] Implementar ThemeService con localStorage
- [ ] Implementar ThemeToggleComponent

#### 1.2 Componentes de Login
- [ ] Implementar LoginComponent con diseño completo
- [ ] Implementar formulario reactivo con validación
- [ ] Integrar con AuthService (usando mocks)
- [ ] Implementar feedback visual (loading, errors)
- [ ] Agregar toggle de contraseña
- [ ] Probar flujo simulado con credenciales mock

#### 1.3 Componentes de Recuperación
- [ ] Implementar ForgotPasswordComponent
- [ ] Implementar formulario de email con validación
- [ ] Implementar VerifyOtpComponent (UI completa)
- [ ] Implementar ResetPasswordComponent
- [ ] Probar flujos simulados con delays

#### 1.4 Sistema de Temas
- [ ] Crear tokens SCSS para light theme
- [ ] Crear tokens SCSS para dark theme
- [ ] Implementar transiciones suaves entre temas
- [ ] Probar cambio de tema en todas las pantallas
- [ ] Verificar contraste de colores (WCAG 2.1 AA)
- [ ] Implementar persistencia de preferencia en localStorage

#### 1.5 Testing UI
- [ ] Tests unitarios de componentes (estructura)
- [ ] Tests de validación de formularios
- [ ] Tests de accesibilidad (a11y)
- [ ] Pruebas manuales en diferentes dispositivos

---

### 🔌 FASE 2: Integración Backend (FUTURO)

**Objetivo:** Conectar con nexcore-auth-service y nexcore-core para autenticación real.

#### 2.1 Configuración HTTP
- [ ] Configurar HttpClient y environments
- [ ] Implementar HTTP Interceptors para tokens JWT
- [ ] Implementar refresh token automático
- [ ] Manejo de errores HTTP centralizados

#### 2.2 Servicios Reales
- [ ] Reemplazar métodos mock en AuthService por llamadas HTTP
- [ ] Implementar AuthGuard para proteger rutas
- [ ] Implementar PermissionGuard para permisos
- [ ] Implementar token storage seguro

#### 2.3 Integración Completa
- [ ] Conectar login con POST /auth/login
- [ ] Conectar verify-otp con POST /auth/verify-otp
- [ ] Conectar forgot-password con POST /auth/forgot-password
- [ ] Conectar reset-password con POST /auth/reset-password
- [ ] Implementar refresh token flow
- [ ] Cargar perfil desde /api/v1/me/profile

#### 2.4 Testing Integración
- [ ] Tests de integración con backend mock (MSW)
- [ ] Tests E2E con Cypress/Playwright
- [ ] Tests de seguridad (OWASP)
- [ ] Load testing (opcional)

---

## 12. Datos Mock para Pruebas

### 12.1 Credenciales Válidas (Login)

Para probar el flujo de login en esta fase, usar cualquiera de estas credenciales:

```typescript
const validCredentials = [
  { 
    tenantId: '00000000-0000-0000-0000-000000000001',
    username: 'super.admin', 
    password: 'NexCore@2026!' 
  },
  { 
    tenantId: '00000000-0000-0000-0000-000000000001',
    username: 'admin', 
    password: 'admin123' 
  },
  { 
    tenantId: '00000000-0000-0000-0001-000000000001',
    username: 'demo', 
    password: 'demo123' 
  }
];
```

### 12.2 Código OTP Mock

En la pantalla de Verify OTP, cualquier código de 6 dígitos será aceptado:
- `123456` ✅
- `000000` ✅
- `999999` ✅

### 12.3 Email para Recuperación

Cualquier email con formato válido será aceptado:
- `usuario@example.com` ✅
- `test@nexcore.com` ✅

---

## 13. Notas Finales

### 13.1 Consideraciones de UX
- Todos los inputs tienen placeholders descriptivos
- Feedback inmediato en validación de formularios
- Estados de loading visibles durante operaciones asíncronas
- Mensajes de error claros y accionables
- Transiciones suaves en cambio de tema

### 13.2 Accesibilidad
- Etiquetas `aria-label` en todos los botones de iconos
- Contraste de colores >= 4.5:1 (WCAG 2.1 AA)
- Navegación por teclado completa
- Focus states visibles
- Atributos `autocomplete` en inputs

### 13.3 Performance
- Componentes standalone para lazy loading
- Signals para reactividad eficiente
- OnPush change detection
- Transiciones CSS optimizadas

---

## 14. Resumen del Alcance Actual

### ✅ Lo que INCLUYE esta fase (Frontend UI/UX)

1. **Diseño Visual Completo**
   - Sistema de diseño con tokens (colores, tipografía, espaciado)
   - Temas light/dark funcionales con persistencia
   - Componentes responsive (mobile-first)
   - Animaciones y transiciones suaves

2. **Componentes Funcionales**
   - LoginComponent con validación completa
   - ForgotPasswordComponent con flujo simulado
   - VerifyOtpComponent con inputs de 6 dígitos
   - ResetPasswordComponent (opcional en esta fase)
   - ThemeToggleComponent con iconos dinámicos

3. **Lógica de Presentación**
   - Validación de formularios reactivos
   - Estados de loading/error/success
   - Navegación entre pantallas
   - Feedback visual inmediato
   - Manejo de eventos de UI

4. **Simulación de Flujos**
   - Login con credenciales mock
   - Verificación OTP con cualquier código de 6 dígitos
   - Recuperación de contraseña simulada
   - Delays de red simulados (300-500ms)
   - Transiciones entre pantallas

### ❌ Lo que NO INCLUYE esta fase

1. **Integración Backend**
   - ❌ Llamadas HTTP reales a nexcore-auth-service
   - ❌ Manejo de tokens JWT reales
   - ❌ Envío de emails OTP reales
   - ❌ Validación de credenciales contra base de datos

2. **Seguridad**
   - ❌ HTTP Interceptors para tokens
   - ❌ Refresh token automático
   - ❌ AuthGuards para proteger rutas
   - ❌ Encriptación de datos sensibles

3. **Funcionalidades Avanzadas**
   - ❌ Recuperación de contraseña real
   - ❌ Cambio de contraseña desde perfil
   - ❌ Historial de intentos de login
   - ❌ Bloqueo por intentos fallidos

### 🎯 Objetivo de esta Fase

> **Establecer una base sólida de UI/UX** que permita:
> - Validar el diseño con stakeholders
> - Probar la experiencia de usuario
> - Iterar rápidamente en los estilos
> - Documentar patrones visuales reutilizables
> - Preparar el terreno para la integración backend

### ➡️ Próximos Pasos (Fase 2)

Una vez aprobado el diseño y los estilos:
1. Configurar HttpClient y environments
2. Implementar servicios reales con llamadas HTTP
3. Agregar interceptors y guards
4. Conectar con nexcore-auth-service (puerto 8081)
5. Probar flujo completo end-to-end
6. Agregar tests de integración

---

**Fin del documento**
