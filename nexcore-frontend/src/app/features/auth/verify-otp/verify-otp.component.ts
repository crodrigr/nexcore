import { Component, inject, signal, PLATFORM_ID } from '@angular/core';
import { CommonModule, isPlatformBrowser } from '@angular/common';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { AuthService } from '../service/auth.service';
import { ThemeToggleComponent } from '../../../shared/theme/theme-toggle.component';
import { TranslocoModule, TranslocoService } from '@ngneat/transloco';

@Component({
  selector: 'app-verify-otp',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    RouterModule,
    ThemeToggleComponent
    ,TranslocoModule
  ],
  templateUrl: './verify-otp.component.html',
  styleUrls: ['./verify-otp.component.scss']
})
export class VerifyOtpComponent {
  private fb = inject(FormBuilder);
  private authService = inject(AuthService);
  private router = inject(Router);
  private platformId = inject(PLATFORM_ID);
  private transloco = inject(TranslocoService);
  
  otpForm!: FormGroup;
  loading = signal(false);
  error = signal<string | null>(null);
  resendTimer = signal(30);
  canResend = signal(false);
  
  constructor() {
    // Verify that a challenge token exists
    if (isPlatformBrowser(this.platformId)) {
      const challengeToken = sessionStorage.getItem('challengeToken');
      if (!challengeToken) {
        this.router.navigate(['/auth/login']);
        return;
      }
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
    
    // Auto-advance to the next field
    if (value.length === 1 && index < 6 && isPlatformBrowser(this.platformId)) {
      const nextInput = document.querySelector(`#digit${index + 1}`) as HTMLInputElement;
      nextInput?.focus();
    }
  }
  
  onDigitKeyDown(event: KeyboardEvent, index: number): void {
    const input = event.target as HTMLInputElement;
    
    // Move focus to previous field on Backspace
    if (event.key === 'Backspace' && !input.value && index > 1 && isPlatformBrowser(this.platformId)) {
      const prevInput = document.querySelector(`#digit${index - 1}`) as HTMLInputElement;
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
      let challengeToken = '';
      if (isPlatformBrowser(this.platformId)) {
        challengeToken = sessionStorage.getItem('challengeToken') || '';
      }
      
      const otpCode = Object.values(this.otpForm.value).join('');
      
      console.log('OTP submit:', otpCode, 'challengeToken=', challengeToken);
      await this.authService.verifyOtp({
        challengeToken,
        otpCode
      });
      console.log('OTP verification succeeded');
      
      // Clear challenge token
      if (isPlatformBrowser(this.platformId)) {
        sessionStorage.removeItem('challengeToken');
        sessionStorage.removeItem('mockUsername');
      }
      
      // Redirect to dashboard after successful verification
      await this.router.navigateByUrl('/dashboard');
      
    } catch (err: any) {
      this.error.set(err.message || this.transloco.translate('auth.verifyOtp.errorInvalid'));
    } finally {
      this.loading.set(false);
    }
  }
  
  async resendCode(): Promise<void> {
    if (!this.canResend()) return;
    
    this.loading.set(true);
    this.error.set(null);
    
    try {
      console.log('📧 [MOCK] OTP code resent');
      
      // Reset timer
      this.startResendTimer();
      
      // Limpiar formulario
      this.otpForm.reset();
      
      // Focus on first input
      if (isPlatformBrowser(this.platformId)) {
        setTimeout(() => {
          const firstInput = document.querySelector('#digit1') as HTMLInputElement;
          firstInput?.focus();
        }, 100);
      }
      
    } catch (err: any) {
      this.error.set(err.message || this.transloco.translate('auth.verifyOtp.errorResend'));
    } finally {
      this.loading.set(false);
    }
  }
}
