import { Injectable, inject } from '@angular/core';
import { HttpInterceptor, HttpRequest, HttpHandler, HttpEvent, HttpErrorResponse } from '@angular/common/http';
import { Observable, throwError } from 'rxjs';
import { catchError } from 'rxjs/operators';
import { Router } from '@angular/router';

@Injectable({ providedIn: 'root' })
export class AuthInterceptor implements HttpInterceptor {
  private readonly router = inject(Router);

  intercept(req: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    const clonedReq = this.attachToken(req);
    return next.handle(clonedReq).pipe(
      catchError((error: HttpErrorResponse) => {
        // 401: token expirado o inválido en el servidor
        // 403: permisos revocados en caliente
        // No aplicar en rutas de auth (login, otp, etc.) para evitar loops
        if ((error.status === 401 || error.status === 403) && !req.url.includes('/auth/')) {
          this.clearSessionAndRedirect();
        }
        return throwError(() => error);
      })
    );
  }

  private attachToken(req: HttpRequest<any>): HttpRequest<any> {
    try {
      const accessToken = localStorage.getItem('accessToken');
      if (accessToken) {
        const jwtClaims = this.readJwtClaims(accessToken);
        const headers: Record<string, string> = {
          Authorization: `Bearer ${accessToken}`
        };

        const actorId = this.readClaim(jwtClaims, 'sub');
        const tenantId = this.readClaim(jwtClaims, 'tid');
        if (actorId) headers['X-Actor-Id'] = actorId;
        if (tenantId) headers['X-Tenant-Id'] = tenantId;

        return req.clone({ setHeaders: headers });
      }

      const stored = localStorage.getItem('profile');
      if (stored) {
        const profile = JSON.parse(stored);
        const token = profile?.token;
        if (token) {
          return req.clone({ setHeaders: { Authorization: `Bearer ${token}` } });
        }
      }
    } catch (error) {
      console.warn('[AuthInterceptor] Failed to resolve auth token from storage', error);
    }
    return req;
  }

  private clearSessionAndRedirect(): void {
    localStorage.removeItem('accessToken');
    localStorage.removeItem('refreshToken');
    localStorage.removeItem('profile');
    this.router.navigate(['/auth/login']);
  }

  private readJwtClaims(token: string): Record<string, unknown> | null {
    const parts = token.split('.');
    if (parts.length < 2) {
      return null;
    }

    const payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
    const normalizedPayload = payload.padEnd(payload.length + ((4 - (payload.length % 4)) % 4), '=');
    const decodedPayload = atob(normalizedPayload);
    return JSON.parse(decodedPayload) as Record<string, unknown>;
  }

  private readClaim(claims: Record<string, unknown> | null, claimName: string): string | null {
    const value = claims?.[claimName];
    return typeof value === 'string' && value.length > 0 ? value : null;
  }
}
