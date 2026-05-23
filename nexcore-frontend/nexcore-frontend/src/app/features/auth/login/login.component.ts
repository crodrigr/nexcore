import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { AuthService } from '../../../shared/services/auth.service';
import { ThemeToggleComponent } from '../../../shared/theme/theme-toggle.component';

interface Tenant {
  id: string;
  name: string;
}

@Component({
  selector: 'app-login',
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
      
      const response = await this.authService.login({
        tenantId,
        username,
        password
      });
      
      // Guardar challenge token y redirigir a OTP
      if (typeof window !== 'undefined') {
        sessionStorage.setItem('challengeToken', response.challengeToken);
        sessionStorage.setItem('mockUsername', username);
      }
      
      this.router.navigate(['/auth/verify-otp']);
      
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
