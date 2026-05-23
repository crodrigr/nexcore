import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { ActivatedRoute } from '@angular/router';
import { AuthService } from '../service/auth.service';
import { ThemeToggleComponent } from '../../../shared/theme/theme-toggle.component';
import { TranslocoModule, TranslocoService } from '@ngneat/transloco';

@Component({
  standalone: true,
  selector: 'app-reset-password',
  imports: [CommonModule, ReactiveFormsModule, RouterModule, ThemeToggleComponent, TranslocoModule],
  templateUrl: './reset-password.component.html',
  styleUrls: ['./reset-password.component.scss']
})
export class ResetPasswordComponent {
  private fb = inject(FormBuilder);
  private authService = inject(AuthService);
  private router = inject(Router);
  private route = inject(ActivatedRoute);
  private transloco = inject(TranslocoService);

  form: FormGroup;
  loading = signal(false);
  error = signal<string | null>(null);
  success = signal(false);
  showCurrentPassword = signal(false);
  showNewPassword = signal(false);
  showConfirmPassword = signal(false);
  tokenMode = signal(false);
  token = signal<string | null>(null);

  constructor() {
    this.form = this.fb.group({
      currentPassword: ['', [Validators.required, Validators.minLength(6)]],
      newPassword: ['', [Validators.required, Validators.minLength(8)]],
      confirmPassword: ['', [Validators.required]]
    });

    // Check query params for token to enable token-based reset flow
    const tokenParam = this.route.snapshot.queryParamMap.get('token');
    if (tokenParam) {
      this.token.set(tokenParam);
      this.tokenMode.set(true);
      // currentPassword not required in token mode
      this.form.get('currentPassword')?.clearValidators();
      this.form.get('currentPassword')?.updateValueAndValidity();
    }
  }

  getFieldError(field: string): string | null {
    const control = this.form.get(field);
    if (!control || !control.touched || !control.errors) return null;
    if (control.errors['required']) return this.transloco.translate('validation.required');
    if (control.errors['minlength']) return this.transloco.translate('validation.minLength', { min: control.errors['minlength'].requiredLength });
    return null;
  }

  async onSubmit(): Promise<void> {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    if (this.form.value.newPassword !== this.form.value.confirmPassword) {
      this.error.set(this.transloco.translate('auth.resetPassword.passwordsMismatch') || 'Passwords do not match');
      return;
    }

    this.loading.set(true);
    this.error.set(null);

    try {
      // Use current user id from AuthService.userProfile — require it for this flow
      const profile = this.authService.userProfile();
      if (this.tokenMode()) {
        // Token-based reset
        const tokenValue = this.token();
        if (!tokenValue) {
          this.error.set(this.transloco.translate('auth.resetPassword.errorGeneric') || 'Invalid token');
          return;
        }
        await this.authService.confirmPasswordReset(tokenValue, this.form.value.newPassword, this.form.value.confirmPassword);
      } else {
        // Authenticated change (requires userId)
        if (!profile || !profile.id) {
          this.error.set(this.transloco.translate('auth.resetPassword.notAuthenticated') || 'User not authenticated');
          this.loading.set(false);
          return;
        }
        const userId = profile.id;
        await this.authService.changePassword(userId, {
          currentPassword: this.form.value.currentPassword,
          newPassword: this.form.value.newPassword
        });
      }

      this.success.set(true);
      // Optional: redirect to dashboard or login
      setTimeout(() => this.router.navigate(['/dashboard']), 1500);
    } catch (err: any) {
      this.error.set(err?.message || this.transloco.translate('auth.resetPassword.errorGeneric'));
    } finally {
      this.loading.set(false);
    }
  }

  toggleShow(field: 'current' | 'new' | 'confirm') {
    if (field === 'current') this.showCurrentPassword.set(!this.showCurrentPassword());
    if (field === 'new') this.showNewPassword.set(!this.showNewPassword());
    if (field === 'confirm') this.showConfirmPassword.set(!this.showConfirmPassword());
  }
}
