import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { AuthService } from '../../../shared/services/auth.service';
import { ThemeToggleComponent } from '../../../shared/theme/theme-toggle.component';

@Component({
  selector: 'app-forgot-password',
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
      
      await this.authService.forgotPassword({ email });
      
      this.success.set(true);
      
      // Redirect to login after 3 seconds
      setTimeout(() => {
        this.router.navigate(['/auth/login']);
      }, 3000);
      
    } catch (err: any) {
      this.error.set(err.message || 'Error sending instructions');
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
      return 'This field is required';
    }
    
    if (control.errors['email']) {
      return 'Invalid email';
    }
    
    return null;
  }
}
