import { Injectable, signal, inject } from '@angular/core';
import { Router } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';
import { environment } from '../../../../environments/environment';

export interface LoginRequest {
  tenantId: string;
  username: string;
  password: string;
}

export interface LoginResponse {
  challengeToken: string;
  message: string;
  expiresIn?: number;
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

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private router = inject(Router);
  
  // State signals
  userProfile = signal<UserProfile | null>(null);
  isAuthenticated = signal(false);
  
  constructor() {
    this.loadSessionFromStorage();
  }
  
  // ============================================================
  // MÉTODOS MOCK (Fase 1 - Solo Frontend)
  // ============================================================
  
  private http = inject(HttpClient);

  async login(request: LoginRequest): Promise<LoginResponse> {
    const url = `${environment.authBaseUrl}${environment.endpoints.login}`;
    try {
      const res = await firstValueFrom(this.http.post<LoginResponse>(url, request));
      return res;
    } catch (err: any) {
      const msg = err?.error?.message || err.message || 'Login failed';
      throw new Error(msg);
    }
  }
  
  async verifyOtp(request: VerifyOtpRequest): Promise<SessionResponse> {
    const url = `${environment.authBaseUrl}${environment.endpoints.verifyOtp}`;
    try {
      // Backend expects { challengeToken, code }
      const payload = { challengeToken: request.challengeToken, code: request.otpCode };
      const res = await firstValueFrom(this.http.post<any>(url, payload));
      // Map backend response to SessionResponse
      const session: SessionResponse = {
        accessToken: res.token || res.accessToken,
        refreshToken: res.refreshToken,
        expiresIn: res.expiresIn,
        profile: res.profile
      };
      this.saveSession(session);
      return session;
    } catch (err: any) {
      const msg = err?.error?.message || err.message || 'OTP verification failed';
      throw new Error(msg);
    }
  }
  
  async forgotPassword(request: ForgotPasswordRequest): Promise<void> {
    const url = `${environment.authBaseUrl}${environment.endpoints.forgotPassword}`;
    try {
      const payload = {
        tenantId: (request as any).tenantId || environment.defaultTenantId,
        email: request.email
      };
      await firstValueFrom(this.http.post(url, payload));
    } catch (err: any) {
      const msg = err?.error?.message || err.message || 'Password reset request failed';
      throw new Error(msg);
    }
  }

  async changePassword(userId: string, payload: { currentPassword: string; newPassword: string }): Promise<void> {
    const url = `${environment.authBaseUrl}${environment.endpoints.changePassword}`;
    try {
      const params = userId ? `?userId=${encodeURIComponent(userId)}` : '';
      const headers: any = {};
      if (typeof window !== 'undefined') {
        const token = localStorage.getItem('accessToken');
        if (token) headers['Authorization'] = `Bearer ${token}`;
      }
      await firstValueFrom(this.http.put(`${url}${params}`, payload, { headers }));
    } catch (err: any) {
      const msg = err?.error?.message || err.message || 'Change password failed';
      throw new Error(msg);
    }
  }

  async confirmPasswordReset(token: string, newPassword: string, confirmPassword: string): Promise<void> {
    const url = `${environment.authBaseUrl}${environment.endpoints.confirmReset}`;
    try {
      const payload = { token, newPassword, confirmPassword };
      await firstValueFrom(this.http.post(url, payload));
    } catch (err: any) {
      const msg = err?.error?.message || err.message || 'Password reset confirmation failed';
      throw new Error(msg);
    }
  }
  
  logout(): void {
    if (typeof window !== 'undefined') {
      localStorage.removeItem('accessToken');
      localStorage.removeItem('refreshToken');
      sessionStorage.clear();
    }
    
    this.userProfile.set(null);
    this.isAuthenticated.set(false);
    
    this.router.navigate(['/auth/login']);
  }
  
  private saveSession(response: SessionResponse): void {
    if (typeof window !== 'undefined') {
      localStorage.setItem('accessToken', response.accessToken);
      localStorage.setItem('refreshToken', response.refreshToken);
    }
    
    this.userProfile.set(response.profile);
    this.isAuthenticated.set(true);
  }
  
  private loadSessionFromStorage(): void {
    if (typeof window !== 'undefined') {
      const accessToken = localStorage.getItem('accessToken');
      
      if (accessToken) {
        this.isAuthenticated.set(true);
        // TODO: Implementar validación de token y carga de perfil en Fase 2
      }
    }
  }
}
