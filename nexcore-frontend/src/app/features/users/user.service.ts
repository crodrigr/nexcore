import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { PageResponse } from '../tenants/tenant.service';

// ── Domain interfaces ──────────────────────────────────────────────────────

export interface UserRecord {
  id: string;
  tenantId: string;
  username: string;
  email: string;
  fullName: string;
  phone?: string;
  photoUrl?: string;
  status: 'PENDING_ACTIVATION' | 'ACTIVE' | 'SUSPENDED' | 'BLOCKED' | 'DELETED';
  isTenantAdmin?: boolean;
  roles?: RoleRecord[];
  createdAt?: string;
  updatedAt?: string;
  lastLoginAt?: string;
}

export interface UserCreateRequest {
  email: string;
  username: string;
  fullName: string;
  phone?: string;
  roleIds: string[];
  sendInvite: boolean;
}

export interface UserUpdateRequest {
  fullName?: string;
  phone?: string;
  photoUrl?: string;
}

export interface RoleAssignment {
  roleId: string;
  expiresAt: string | null;
}

export interface AssignRolesRequest {
  roles: RoleAssignment[];
}

// ── Role interfaces ────────────────────────────────────────────────────────

export interface RoleRecord {
  id: string;
  tenantId?: string;
  name: string;
  description?: string;
  isSystemRole?: boolean;
  isDefault?: boolean;
  activeUsersCount?: number;
  createdAt?: string;
  updatedAt?: string;
}

export interface RoleCreateRequest {
  name: string;
  description?: string;
  isDefault: boolean;
}

export interface RoleUpdateRequest {
  name?: string;
  description?: string;
  isDefault?: boolean;
}

// ── Invitation interfaces ──────────────────────────────────────────────────

export interface InvitationRecord {
  id: string;
  tenantId?: string;
  email: string;
  roleIds: string[];
  revoked: boolean;
  roles?: RoleRecord[];
  status: 'PENDING' | 'ACCEPTED' | 'REVOKED';
  invitedAt?: string;
  expiresAt?: string;
  acceptedAt?: string;
}

export interface InviteRequest {
  email: string;
  roleIds: string[];
}

export interface AcceptInvitationRequest {
  token: string;
  username: string;
  fullName: string;
  password: string;
}

// ── Service ────────────────────────────────────────────────────────────────

@Injectable({ providedIn: 'root' })
export class UserService {
  private readonly http = inject(HttpClient);
  private readonly usersUrl = `${environment.coreBaseUrl}/api/v1/users`;
  private readonly rolesUrl = `${environment.coreBaseUrl}/api/v1/roles`;

  // ── Users ────────────────────────────────────────────────────────────────

  listUsers(
    page: number,
    size: number,
    status?: string,
    search?: string,
    sortField?: string,
    sortDir?: string
  ): Observable<PageResponse<UserRecord>> {
    let params = new HttpParams().set('page', page).set('size', size);
    if (status) params = params.set('status', status);
    if (search?.trim()) params = params.set('search', search.trim());
    if (sortField) params = params.set('sort', sortField);
    if (sortDir) params = params.set('dir', sortDir);
    return this.http.get<PageResponse<UserRecord>>(this.usersUrl, { params });
  }

  getUser(userId: string): Observable<UserRecord> {
    return this.http.get<UserRecord>(`${this.usersUrl}/${userId}`);
  }

  createUser(payload: UserCreateRequest): Observable<UserRecord> {
    return this.http.post<UserRecord>(this.usersUrl, payload);
  }

  updateUser(
    userId: string,
    payload: UserUpdateRequest,
    isTenantAdmin = false
  ): Observable<UserRecord> {
    const headers = new HttpHeaders({ 'X-Is-Tenant-Admin': String(isTenantAdmin) });
    return this.http.patch<UserRecord>(`${this.usersUrl}/${userId}`, payload, { headers });
  }

  suspendUser(userId: string): Observable<void> {
    return this.http.post<void>(`${this.usersUrl}/${userId}/suspend`, null);
  }

  activateUser(userId: string): Observable<void> {
    return this.http.post<void>(`${this.usersUrl}/${userId}/activate`, null);
  }

  deleteUser(userId: string): Observable<void> {
    return this.http.delete<void>(`${this.usersUrl}/${userId}`);
  }

  assignRoles(userId: string, payload: AssignRolesRequest): Observable<void> {
    return this.http.put<void>(`${this.usersUrl}/${userId}/roles`, payload);
  }

  // ── Invitations ──────────────────────────────────────────────────────────

  acceptInvitation(payload: AcceptInvitationRequest): Observable<UserRecord> {
    return this.http.post<UserRecord>(`${this.usersUrl}/invitations/accept`, payload);
  }

  invite(payload: InviteRequest): Observable<void> {
    return this.http.post<void>(`${this.usersUrl}/invite`, payload);
  }

  listInvitations(): Observable<InvitationRecord[]> {
    return this.http.get<InvitationRecord[]>(`${this.usersUrl}/invitations`);
  }

  revokeInvitation(invitationId: string): Observable<void> {
    return this.http.post<void>(
      `${this.usersUrl}/invitations/${invitationId}/revoke`,
      null
    );
  }

  resendInvitation(invitationId: string): Observable<InvitationRecord> {
    return this.http.post<InvitationRecord>(
      `${this.usersUrl}/invitations/${invitationId}/resend`,
      null
    );
  }

  // ── Roles ────────────────────────────────────────────────────────────────

  listRoles(): Observable<RoleRecord[]> {
    return this.http.get<RoleRecord[]>(this.rolesUrl);
  }

  createRole(payload: RoleCreateRequest): Observable<RoleRecord> {
    return this.http.post<RoleRecord>(this.rolesUrl, payload);
  }

  updateRole(roleId: string, payload: RoleUpdateRequest): Observable<RoleRecord> {
    return this.http.patch<RoleRecord>(`${this.rolesUrl}/${roleId}`, payload);
  }

  deleteRole(roleId: string): Observable<void> {
    return this.http.delete<void>(`${this.rolesUrl}/${roleId}`);
  }
}
