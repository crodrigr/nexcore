import { Injectable } from '@angular/core';
import { HttpInterceptor, HttpRequest, HttpHandler, HttpEvent } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({ providedIn: 'root' })
export class AuthInterceptor implements HttpInterceptor {
  intercept(req: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    try {
      const accessToken = localStorage.getItem('accessToken');
      if (accessToken) {
        const jwtClaims = this.readJwtClaims(accessToken);
        const headers: Record<string, string> = {
          Authorization: `Bearer ${accessToken}`
        };

        const actorId = this.readClaim(jwtClaims, 'sub');
        const tenantId = this.readClaim(jwtClaims, 'tid');
        if (actorId) {
          headers['X-Actor-Id'] = actorId;
        }
        if (tenantId) {
          headers['X-Tenant-Id'] = tenantId;
        }

        const cloned = req.clone({ setHeaders: headers });
        return next.handle(cloned);
      }

      const stored = localStorage.getItem('profile');
      if (stored) {
        const profile = JSON.parse(stored);
        const token = profile?.token;
        if (token) {
          const cloned = req.clone({ setHeaders: { Authorization: `Bearer ${token}` } });
          return next.handle(cloned);
        }
      }
    } catch (error) {
      console.warn('[AuthInterceptor] Failed to resolve auth token from storage', error);
    }
    return next.handle(req);
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
