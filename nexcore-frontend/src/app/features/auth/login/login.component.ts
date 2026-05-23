import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { AuthService } from '../service/auth.service';
import { ThemeToggleComponent } from '../../../shared/theme/theme-toggle.component';
import { TranslocoModule, TranslocoService } from '@ngneat/transloco';

interface Tenant {
  id: string;
  name: string;
}

@Component({
  standalone: true,
  selector: 'app-login',
  imports: [
    CommonModule,
    ReactiveFormsModule,
    RouterModule,
    ThemeToggleComponent,
    TranslocoModule
  ],
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.scss']
})
export class LoginComponent {
  private fb = inject(FormBuilder);
  private authService = inject(AuthService);
  private router = inject(Router);
  private transloco = inject(TranslocoService);
  
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

    // Persist selected tenantId to sessionStorage so other auth flows (forgot password)
    // can reuse the tenant selected in the login form.
    if (typeof window !== 'undefined') {
      const current = sessionStorage.getItem('tenantId');
      if (current) {
        this.loginForm.get('tenantId')?.setValue(current);
      }
    }

    this.loginForm.get('tenantId')?.valueChanges.subscribe((tid: string) => {
      if (typeof window !== 'undefined') {
        sessionStorage.setItem('tenantId', tid);
      }
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
        // Ensure tenantId is persisted for flows like forgot-password
        sessionStorage.setItem('tenantId', tenantId);
      }
      
      this.router.navigate(['/auth/verify-otp']);
      
    } catch (err: any) {
      this.error.set(err.message || this.transloco.translate('auth.login.errorGeneric'));
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
      return this.transloco.translate('validation.required');
    }
    
    if (control.errors['minlength']) {
      const minLength = control.errors['minlength'].requiredLength;
      return this.transloco.translate('validation.minLength', { min: minLength });
    }
    
    return null;
  }
}
