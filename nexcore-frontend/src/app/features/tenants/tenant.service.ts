import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface Tenant {
  id: string;
  slug: string;
  name: string;
  legalName?: string;
  taxId?: string;
  plan: string;
  mode: string;
  status: string;
  timezone: string;
  locale: string;
  dateFormat?: string;
  currency?: string;
  mfaRequired?: boolean;
  sessionTimeoutMinutes?: number;
  maxLoginAttempts?: number;
  passwordMinLength?: number;
  passwordRequiresUpper?: boolean;
  passwordRequiresSpecial?: boolean;
  createdAt?: string;
  updatedAt?: string;
}

export interface TenantCreateRequest {
  slug: string;
  name: string;
  legalName: string;
  taxId: string;
  plan: string;
  mode: string;
  timezone: string;
  locale: string;
  dateFormat: string;
  currency: string;
}

export interface TenantUpdateRequest {
  name?: string;
  legalName?: string;
  timezone?: string;
  locale?: string;
  mfaRequired?: boolean;
  sessionTimeoutMinutes?: number;
  maxLoginAttempts?: number;
  passwordMinLength?: number;
  passwordRequiresUpper?: boolean;
  passwordRequiresSpecial?: boolean;
}

export interface PageResponse<T> {
  content: T[];
  page: number;
  size: number;
  totalElements: number;
  totalPages: number;
  last: boolean;
}

@Injectable({
  providedIn: 'root'
})
export class TenantService {
  private readonly http = inject(HttpClient);
  private readonly baseUrl = `${environment.coreBaseUrl}/api/v1/tenants`;

  list(page: number, size: number): Observable<PageResponse<Tenant> | Tenant[]> {
    const params = new HttpParams().set('page', page).set('size', size);
    return this.http.get<PageResponse<Tenant> | Tenant[]>(this.baseUrl, { params });
  }

  create(payload: TenantCreateRequest): Observable<Tenant> {
    return this.http.post<Tenant>(this.baseUrl, payload);
  }

  update(id: string, payload: TenantUpdateRequest, isSuperAdmin = false): Observable<Tenant> {
    const headers = new HttpHeaders({
      'X-Actor-Super-Admin': String(isSuperAdmin)
    });

    return this.http.patch<Tenant>(`${this.baseUrl}/${id}`, payload, { headers });
  }

  suspend(id: string): Observable<void> {
    return this.http.post<void>(`${this.baseUrl}/${id}/suspend`, null);
  }

  activate(id: string): Observable<void> {
    return this.http.post<void>(`${this.baseUrl}/${id}/activate`, null);
  }
}
