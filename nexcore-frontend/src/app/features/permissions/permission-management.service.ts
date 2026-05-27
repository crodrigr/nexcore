import { HttpClient } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { environment } from '../../../environments/environment';
import { UserService } from '../users/user.service';
import { AccessLevel, RoleOption, RolePermissionMatrixResponse } from './permissions.models';

export interface ComponentPermissionResultResponse {
  componentId: string;
  moduleKey: string;
  access: AccessLevel;
  updatedAt: string;
}

export interface ElementPermissionResultResponse {
  elementId: string;
  elementKey: string;
  access: AccessLevel;
  inherited: boolean;
  updatedAt: string;
}

export interface BatchComponentPermissionItem {
  componentId: string;
  access: string;
}

@Injectable({ providedIn: 'root' })
export class PermissionManagementService {
  private readonly http = inject(HttpClient);
  private readonly userService = inject(UserService);
  private readonly baseUrl = `${environment.coreBaseUrl}/api/v1/menu`;

  loadRoles(): Observable<RoleOption[]> {
    return this.userService.listRoles().pipe(
      map(roles => (Array.isArray(roles) ? roles : []).map(r => ({ id: r.id, name: r.name })))
    );
  }

  getPermissionMatrix(roleId: string): Observable<RolePermissionMatrixResponse> {
    return this.http.get<RolePermissionMatrixResponse>(
      `${this.baseUrl}/permissions/roles/${roleId}`
    );
  }

  batchUpsertComponents(
    roleId: string,
    permissions: BatchComponentPermissionItem[]
  ): Observable<ComponentPermissionResultResponse[]> {
    return this.http.put<ComponentPermissionResultResponse[]>(
      `${this.baseUrl}/permissions/roles/${roleId}/components/batch`,
      { permissions: permissions.map(p => ({ ...p, access: p.access.toUpperCase() })) }
    );
  }

  upsertElement(
    roleId: string,
    elementId: string,
    access: string
  ): Observable<ElementPermissionResultResponse> {
    return this.http.put<ElementPermissionResultResponse>(
      `${this.baseUrl}/permissions/roles/${roleId}/elements/${elementId}`,
      { access: access.toUpperCase() }
    );
  }
}
