import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AbstractControl, FormBuilder, ReactiveFormsModule, ValidationErrors, Validators } from '@angular/forms';
import { Router, ActivatedRoute, RouterModule } from '@angular/router';
import { firstValueFrom } from 'rxjs';
import { TranslocoModule } from '@ngneat/transloco';
import { UserService } from '../../users/user.service';
import { ThemeToggleComponent } from '../../../shared/theme/theme-toggle.component';

@Component({
  standalone: true,
  selector: 'app-accept-invitation',
  imports: [CommonModule, ReactiveFormsModule, RouterModule, TranslocoModule, ThemeToggleComponent],
  templateUrl: './accept-invitation.component.html',
  styleUrls: ['./accept-invitation.component.scss']
})
export class AcceptInvitationComponent implements OnInit {
  private fb     = inject(FormBuilder);
  private route  = inject(ActivatedRoute);
  private router = inject(Router);
  private userService = inject(UserService);

  token    = '';
  submitting = false;
  submitted  = false;
  errorMsg   = '';
  showPassword = false;

  readonly form = this.fb.nonNullable.group({
    fullName:        ['', [Validators.required, Validators.minLength(2)]],
    username:        ['', [Validators.required, Validators.minLength(3),
                           Validators.pattern(/^[a-zA-Z0-9._-]{3,100}$/)]],
    password:        ['', [Validators.required, Validators.minLength(8)]],
    confirmPassword: ['', [Validators.required]],
  }, {
    validators: (group: AbstractControl): ValidationErrors | null => {
      const pwd  = group.get('password')?.value;
      const conf = group.get('confirmPassword')?.value;
      return pwd === conf ? null : { mismatch: true };
    }
  });

  ngOnInit(): void {
    this.token = this.route.snapshot.queryParamMap.get('token') ?? '';
    if (!this.token) this.errorMsg = 'invitation.invalidLink';
  }

  togglePassword(): void { this.showPassword = !this.showPassword; }

  async submit(): Promise<void> {
    this.form.markAllAsTouched();
    if (this.form.invalid || !this.token) return;

    this.submitting = true;
    this.errorMsg   = '';
    const v = this.form.getRawValue();
    try {
      await firstValueFrom(this.userService.acceptInvitation({
        token:    this.token,
        fullName: v.fullName,
        username: v.username,
        password: v.password,
      }));
      this.submitted = true;
      setTimeout(() => this.router.navigate(['/auth/login']), 3000);
    } catch (e: any) {
      this.errorMsg = e?.error?.message || 'invitation.errorGeneric';
    } finally {
      this.submitting = false;
    }
  }

}
