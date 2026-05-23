import { Injectable, signal, inject } from '@angular/core';
import { Router } from '@angular/router';

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
  
  async login(request: LoginRequest): Promise<LoginResponse> {
    // Simular delay de red
    await new Promise(resolve => setTimeout(resolve, 300));
    
    // Credenciales válidas para demostración
    const validCredentials = [
      { username: 'super.admin', password: 'NexCore@2026!' },
      { username: 'admin', password: 'admin123' },
      { username: 'demo', password: 'demo123' }
    ];
    
    const isValidCredential = validCredentials.some(
      cred => cred.username === request.username && cred.password === request.password
    );
    
    if (!isValidCredential) {
      throw new Error('Credenciales inválidas');
    }
    
    // Mock: Simular respuesta exitosa
    return {
      challengeToken: 'mock-challenge-' + Date.now(),
      message: 'Código OTP enviado'
    };
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
  }
  
  async forgotPassword(request: ForgotPasswordRequest): Promise<void> {
    // Simular delay de red
    await new Promise(resolve => setTimeout(resolve, 500));
    
    console.log('📧 [MOCK] Email enviado a:', request.email);
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
