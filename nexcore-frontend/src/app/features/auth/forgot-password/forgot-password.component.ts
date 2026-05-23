import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { AuthService } from '../../../shared/services/auth.service';
import { ThemeToggleComponent } from '../../../shared/theme/theme-toggle.component';
import { TranslocoModule, TranslocoService } from '@ngneat/transloco';

@Component({
  standalone: true,
  selector: 'app-forgot-password',
  imports: [
    CommonModule,
    ReactiveFormsModule,
    RouterModule,
    ThemeToggleComponent,
    TranslocoModule
  ],
  templateUrl: './forgot-password.component.html',
  styleUrl: './forgot-password.component.scss'
})
export class ForgotPasswordComponent {
  private fb = inject(FormBuilder);
  private authService = inject(AuthService);
  private router = inject(Router);
  private transloco = inject(TranslocoService);
  
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
      
      await this.authService.forgotPassword({ email });
      
      this.success.set(true);
      
      // Redirect to login after 3 seconds
      setTimeout(() => {
        this.router.navigate(['/auth/login']);
      }, 3000);
      
    } catch (err: any) {
      this.error.set(err.message || this.transloco.translate('auth.forgotPassword.errorGeneric'));
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
      return this.transloco.translate('validation.required');
    }
    
    if (control.errors['email']) {
      return this.transloco.translate('validation.invalidEmail');
    }
    
    return null;
  }
}
