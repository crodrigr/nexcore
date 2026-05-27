import { CommonModule } from '@angular/common';
import { Component, inject, OnInit } from '@angular/core';
import { FormBuilder, FormsModule, ReactiveFormsModule, Validators } from '@angular/forms';
import { TranslocoModule } from '@ngneat/transloco';
import { firstValueFrom, Subject } from 'rxjs';
import { debounceTime, distinctUntilChanged } from 'rxjs/operators';
import { NavbarComponent } from '../../shared/layout/navbar.component';
import { SidebarComponent } from '../../shared/layout/sidebar.component';
import {
  UserService,
  UserRecord,
  RoleRecord,
  InvitationRecord,
} from './user.service';
import { PageResponse } from '../tenants/tenant.service';

type ActiveTab = 'users' | 'invitations' | 'roles';

@Component({
  selector: 'app-user-management',
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule, NavbarComponent, SidebarComponent, TranslocoModule],
  templateUrl: './user-management.component.html',
  styleUrls: ['./user-management.component.scss']
})
export class UserManagementComponent implements OnInit {
  private readonly userService = inject(UserService);
  private readonly fb = inject(FormBuilder);
  private readonly searchSubject = new Subject<string>();

  // ── Tab ───────────────────────────────────────────────────────────────────
  activeTab: ActiveTab = 'users';

  // ── Feedback ──────────────────────────────────────────────────────────────
  errorMessage = '';
  successMessage = '';

  // ── Users tab state ───────────────────────────────────────────────────────
  usersLoading = false;
  usersRefreshing = false;
  usersSubmitting = false;
  users: UserRecord[] = [];
  userSearchTerm = '';
  userStatusFilter = '';
  userPage = 0;
  userSize = 10;
  userTotalElements = 0;
  userTotalPages = 1;
  userSortField: keyof UserRecord = 'fullName';
  userSortDir: 'asc' | 'desc' = 'asc';

  showCreateUserModal = false;
  showEditUserModal = false;
  showSuspendUserModal = false;
  showActivateUserModal = false;
  showDeleteUserModal = false;
  showAssignRolesModal = false;
  selectedUser: UserRecord | null = null;
  allRoles: RoleRecord[] = [];
  selectedRoleIds: Set<string> = new Set();

  readonly userStatusOptions = [
    { value: '', label: 'user.filter.allStatuses' },
    { value: 'ACTIVE', label: 'user.status.active' },
    { value: 'PENDING_ACTIVATION', label: 'user.status.pending' },
    { value: 'SUSPENDED', label: 'user.status.suspended' },
    { value: 'BLOCKED', label: 'user.status.blocked' },
  ];
  readonly pageSizeOptions = [5, 10, 20, 50];

  readonly createUserForm = this.fb.nonNullable.group({
    email: ['', [Validators.required, Validators.email]],
    username: ['', [Validators.required, Validators.minLength(3), Validators.pattern(/^[a-z0-9.\-]+$/)]],
    fullName: ['', [Validators.required, Validators.minLength(3)]],
    phone: [''],
    sendInvite: [false],
  });

  readonly editUserForm = this.fb.nonNullable.group({
    fullName: ['', [Validators.required, Validators.minLength(3)]],
    phone: [''],
    photoUrl: [''],
  });

  // ── Invitations tab state ─────────────────────────────────────────────────
  invitationsLoading = false;
  invitationsSubmitting = false;
  invitations: InvitationRecord[] = [];
  showInviteModal = false;
  showRevokeModal = false;
  selectedInvitation: InvitationRecord | null = null;

  readonly inviteForm = this.fb.nonNullable.group({
    email: ['', [Validators.required, Validators.email]],
  });
  inviteRoleIds: Set<string> = new Set();

  // ── Roles tab state ───────────────────────────────────────────────────────
  rolesLoading = false;
  rolesSubmitting = false;
  roles: RoleRecord[] = [];
  showCreateRoleModal = false;
  showEditRoleModal = false;
  showDeleteRoleModal = false;
  selectedRole: RoleRecord | null = null;
  deleteRoleError = '';

  readonly createRoleForm = this.fb.nonNullable.group({
    name: ['', [Validators.required, Validators.minLength(3)]],
    description: [''],
    isDefault: [false],
  });

  readonly editRoleForm = this.fb.nonNullable.group({
    name: ['', [Validators.required, Validators.minLength(3)]],
    description: [''],
    isDefault: [false],
  });

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  ngOnInit(): void {
    this.searchSubject.pipe(debounceTime(300), distinctUntilChanged()).subscribe(() => {
      this.loadUsers(0);
    });
    this.loadUsers();
    this.loadRoles().then(() => this.loadInvitations());
  }

  // ── Tab navigation ────────────────────────────────────────────────────────

  selectTab(tab: ActiveTab): void {
    this.activeTab = tab;
    this.clearMessages();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  get userPageStart(): number {
    return this.userTotalElements === 0 ? 0 : this.userPage * this.userSize + 1;
  }

  get userPageEnd(): number {
    return Math.min((this.userPage + 1) * this.userSize, this.userTotalElements);
  }

  isSortedAsc(field: keyof UserRecord): boolean {
    return this.userSortField === field && this.userSortDir === 'asc';
  }

  isSortedDesc(field: keyof UserRecord): boolean {
    return this.userSortField === field && this.userSortDir === 'desc';
  }

  toggleSort(field: keyof UserRecord): void {
    if (this.userSortField === field) {
      this.userSortDir = this.userSortDir === 'asc' ? 'desc' : 'asc';
    } else {
      this.userSortField = field;
      this.userSortDir = 'asc';
    }
    this.loadUsers(0);
  }

  userStatusClass(status: string | undefined): string {
    const s = (status || '').toUpperCase();
    if (s === 'ACTIVE') return 'status-active';
    if (s === 'SUSPENDED') return 'status-suspended';
    if (s === 'BLOCKED') return 'status-blocked';
    return 'status-pending';
  }

  invitationStatusClass(status: string | undefined): string {
    const s = (status || '').toUpperCase();
    if (s === 'ACCEPTED') return 'status-active';
    if (s === 'REVOKED') return 'status-blocked';
    return 'status-pending';
  }

  userInitials(user: UserRecord): string {
    const parts = (user.fullName || user.username || '').trim().split(/\s+/);
    if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase();
    return (parts[0] || 'U').substring(0, 2).toUpperCase();
  }

  avatarClass(user: UserRecord): string {
    const classes = ['ua-blue', 'ua-purple', 'ua-green', 'ua-orange', 'ua-teal'];
    let hash = 0;
    for (const ch of user.username || user.id || '') hash += ch.charCodeAt(0);
    return classes[hash % classes.length];
  }

  isSystemRole(role: RoleRecord): boolean {
    return !!role.isSystemRole || ['TENANT_ADMIN', 'EDITOR', 'VIEWER', 'SUPER_ADMIN'].includes(role.name);
  }

  // ── Users: load + pagination ──────────────────────────────────────────────

  async loadUsers(page = this.userPage): Promise<void> {
    const isInitial = this.users.length === 0;
    if (isInitial) this.usersLoading = true;
    else this.usersRefreshing = true;
    this.clearMessages();
    try {
      const resp = await firstValueFrom(
        this.userService.listUsers(page, this.userSize, this.userStatusFilter, this.userSearchTerm)
      );
      const pr = resp as PageResponse<UserRecord>;
      this.users = pr.content || [];
      this.userPage = pr.page ?? page;
      this.userTotalElements = pr.totalElements ?? this.users.length;
      this.userTotalPages = pr.totalPages ?? 1;
    } catch (e: any) {
      this.errorMessage = e?.error?.message || 'user.errors.loadUsers';
    } finally {
      this.usersLoading = false;
      this.usersRefreshing = false;
    }
  }

  onUserSearchChange(value: string): void {
    this.userSearchTerm = value;
    this.searchSubject.next(value);
  }

  onUserStatusChange(value: string): void {
    this.userStatusFilter = value;
    this.loadUsers(0);
  }

  async goToUserPage(page: number): Promise<void> {
    if (page < 0 || page >= this.userTotalPages || page === this.userPage) return;
    await this.loadUsers(page);
  }

  async onUserPageSizeChange(val: number | string): Promise<void> {
    const n = Number(val);
    if (!Number.isFinite(n) || n <= 0 || n === this.userSize) return;
    this.userSize = n;
    await this.loadUsers(0);
  }

  // ── Users: create ─────────────────────────────────────────────────────────

  openCreateUserModal(): void {
    this.createUserForm.reset({ email: '', username: '', fullName: '', phone: '', sendInvite: false });
    this.selectedRoleIds = new Set();
    this.showCreateUserModal = true;
    this.clearMessages();
  }

  closeCreateUserModal(): void {
    this.showCreateUserModal = false;
  }

  async submitCreateUser(): Promise<void> {
    this.createUserForm.markAllAsTouched();
    if (this.createUserForm.invalid) return;

    this.usersSubmitting = true;
    this.clearMessages();
    try {
      const v = this.createUserForm.getRawValue();
      await firstValueFrom(this.userService.createUser({
        email: v.email,
        username: v.username,
        fullName: v.fullName,
        phone: v.phone || undefined,
        roleIds: Array.from(this.selectedRoleIds),
        sendInvite: v.sendInvite,
      }));
      this.showCreateUserModal = false;
      if (v.sendInvite) {
        this.successMessage = 'user.success.inviteSent';
        await this.loadInvitations();
        this.selectTab('invitations');
      } else {
        this.successMessage = 'user.success.userCreated';
        await this.loadUsers(0);
      }
    } catch (e: any) {
      this.errorMessage = e?.error?.message || 'user.errors.createUser';
    } finally {
      this.usersSubmitting = false;
    }
  }

  // ── Users: edit ───────────────────────────────────────────────────────────

  openEditUserModal(user: UserRecord): void {
    this.selectedUser = user;
    this.editUserForm.reset({
      fullName: user.fullName || '',
      phone: user.phone || '',
      photoUrl: user.photoUrl || '',
    });
    this.showEditUserModal = true;
    this.clearMessages();
  }

  closeEditUserModal(): void {
    this.showEditUserModal = false;
    this.selectedUser = null;
  }

  async submitEditUser(): Promise<void> {
    this.editUserForm.markAllAsTouched();
    if (this.editUserForm.invalid || !this.selectedUser) return;

    this.usersSubmitting = true;
    this.clearMessages();
    try {
      const v = this.editUserForm.getRawValue();
      await firstValueFrom(this.userService.updateUser(this.selectedUser.id, {
        fullName: v.fullName,
        phone: v.phone || undefined,
        photoUrl: v.photoUrl || undefined,
      }));
      this.successMessage = 'user.success.userUpdated';
      this.showEditUserModal = false;
      await this.loadUsers(this.userPage);
    } catch (e: any) {
      this.errorMessage = e?.error?.message || 'user.errors.updateUser';
    } finally {
      this.usersSubmitting = false;
    }
  }

  // ── Users: suspend ────────────────────────────────────────────────────────

  openSuspendUserModal(user: UserRecord): void {
    this.selectedUser = user;
    this.showSuspendUserModal = true;
    this.clearMessages();
  }

  closeSuspendUserModal(): void {
    this.showSuspendUserModal = false;
    this.selectedUser = null;
  }

  async confirmSuspendUser(): Promise<void> {
    if (!this.selectedUser) return;
    this.usersSubmitting = true;
    this.clearMessages();
    try {
      await firstValueFrom(this.userService.suspendUser(this.selectedUser.id));
      this.successMessage = 'user.success.userSuspended';
      this.closeSuspendUserModal();
      await this.loadUsers(this.userPage);
    } catch (e: any) {
      this.errorMessage = e?.error?.message || 'user.errors.suspendUser';
    } finally {
      this.usersSubmitting = false;
    }
  }

  // ── Users: activate ───────────────────────────────────────────────────────

  openActivateUserModal(user: UserRecord): void {
    this.selectedUser = user;
    this.showActivateUserModal = true;
    this.clearMessages();
  }

  closeActivateUserModal(): void {
    this.showActivateUserModal = false;
    this.selectedUser = null;
  }

  async confirmActivateUser(): Promise<void> {
    if (!this.selectedUser) return;
    this.usersSubmitting = true;
    this.clearMessages();
    try {
      await firstValueFrom(this.userService.activateUser(this.selectedUser.id));
      this.successMessage = 'user.success.userActivated';
      this.closeActivateUserModal();
      await this.loadUsers(this.userPage);
    } catch (e: any) {
      this.errorMessage = e?.error?.message || 'user.errors.activateUser';
    } finally {
      this.usersSubmitting = false;
    }
  }

  // ── Users: delete ─────────────────────────────────────────────────────────

  openDeleteUserModal(user: UserRecord): void {
    this.selectedUser = user;
    this.showDeleteUserModal = true;
    this.clearMessages();
  }

  closeDeleteUserModal(): void {
    this.showDeleteUserModal = false;
    this.selectedUser = null;
  }

  async confirmDeleteUser(): Promise<void> {
    if (!this.selectedUser) return;
    this.usersSubmitting = true;
    this.clearMessages();
    try {
      await firstValueFrom(this.userService.deleteUser(this.selectedUser.id));
      this.successMessage = 'user.success.userDeleted';
      this.closeDeleteUserModal();
      await this.loadUsers(this.userPage);
    } catch (e: any) {
      this.errorMessage = e?.error?.message || 'user.errors.deleteUser';
    } finally {
      this.usersSubmitting = false;
    }
  }

  // ── Users: assign roles ───────────────────────────────────────────────────

  openAssignRolesModal(user: UserRecord): void {
    this.selectedUser = user;
    this.selectedRoleIds = new Set((user.roles || []).map(r => r.id));
    this.showAssignRolesModal = true;
    this.clearMessages();
  }

  closeAssignRolesModal(): void {
    this.showAssignRolesModal = false;
    this.selectedUser = null;
    this.selectedRoleIds = new Set();
  }

  toggleRoleSelection(roleId: string): void {
    if (this.selectedRoleIds.has(roleId)) {
      this.selectedRoleIds.delete(roleId);
    } else {
      this.selectedRoleIds.add(roleId);
    }
  }

  isRoleSelected(roleId: string): boolean {
    return this.selectedRoleIds.has(roleId);
  }

  async confirmAssignRoles(): Promise<void> {
    if (!this.selectedUser) return;
    this.usersSubmitting = true;
    this.clearMessages();
    try {
      const assignments = Array.from(this.selectedRoleIds).map(roleId => ({ roleId, expiresAt: null }));
      await firstValueFrom(this.userService.assignRoles(this.selectedUser.id, { assignments }));
      this.successMessage = 'user.success.rolesAssigned';
      this.closeAssignRolesModal();
      await this.loadUsers(this.userPage);
    } catch (e: any) {
      this.errorMessage = e?.error?.message || 'user.errors.assignRoles';
    } finally {
      this.usersSubmitting = false;
    }
  }

  // ── Invitations: load ─────────────────────────────────────────────────────

  async loadInvitations(): Promise<void> {
    this.invitationsLoading = true;
    try {
      const raw = await firstValueFrom(this.userService.listInvitations());
      this.invitations = raw.map(inv => {
        let status: 'PENDING' | 'ACCEPTED' | 'REVOKED' = 'PENDING';
        if (inv.revoked) status = 'REVOKED';
        else if (inv.acceptedAt) status = 'ACCEPTED';
        return {
          ...inv,
          roles: (inv.roleIds || [])
            .map(id => this.allRoles.find(r => r.id === id))
            .filter((r): r is RoleRecord => !!r),
          status,
        };
      });
    } catch (e: any) {
      if (this.activeTab === 'invitations') {
        this.errorMessage = e?.error?.message || 'user.errors.loadInvitations';
      }
    } finally {
      this.invitationsLoading = false;
    }
  }

  // ── Invitations: invite ───────────────────────────────────────────────────

  openInviteModal(): void {
    this.inviteForm.reset({ email: '' });
    this.inviteRoleIds = new Set();
    this.showInviteModal = true;
    this.clearMessages();
  }

  closeInviteModal(): void {
    this.showInviteModal = false;
  }

  toggleInviteRole(roleId: string): void {
    if (this.inviteRoleIds.has(roleId)) {
      this.inviteRoleIds.delete(roleId);
    } else {
      this.inviteRoleIds.add(roleId);
    }
  }

  isInviteRoleSelected(roleId: string): boolean {
    return this.inviteRoleIds.has(roleId);
  }

  async submitInvite(): Promise<void> {
    this.inviteForm.markAllAsTouched();
    if (this.inviteForm.invalid) return;

    this.invitationsSubmitting = true;
    this.clearMessages();
    try {
      const v = this.inviteForm.getRawValue();
      await firstValueFrom(this.userService.invite({
        email: v.email,
        roleIds: Array.from(this.inviteRoleIds),
      }));
      this.successMessage = 'user.success.inviteSent';
      this.showInviteModal = false;
      await this.loadInvitations();
    } catch (e: any) {
      this.errorMessage = e?.error?.message || 'user.errors.invite';
    } finally {
      this.invitationsSubmitting = false;
    }
  }

  // ── Invitations: revoke ───────────────────────────────────────────────────

  async resendInvitation(invitation: InvitationRecord): Promise<void> {
    this.invitationsSubmitting = true;
    this.clearMessages();
    try {
      await firstValueFrom(this.userService.resendInvitation(invitation.id));
      this.successMessage = 'user.success.inviteResent';
      await this.loadInvitations();
    } catch (e: any) {
      this.errorMessage = e?.error?.message || 'user.errors.resendInvitation';
    } finally {
      this.invitationsSubmitting = false;
    }
  }

  openRevokeModal(invitation: InvitationRecord): void {
    this.selectedInvitation = invitation;
    this.showRevokeModal = true;
    this.clearMessages();
  }

  closeRevokeModal(): void {
    this.showRevokeModal = false;
    this.selectedInvitation = null;
  }

  async confirmRevoke(): Promise<void> {
    if (!this.selectedInvitation) return;
    this.invitationsSubmitting = true;
    this.clearMessages();
    try {
      await firstValueFrom(this.userService.revokeInvitation(this.selectedInvitation.id));
      this.successMessage = 'user.success.inviteRevoked';
      this.closeRevokeModal();
      await this.loadInvitations();
    } catch (e: any) {
      this.errorMessage = e?.error?.message || 'user.errors.revokeInvitation';
    } finally {
      this.invitationsSubmitting = false;
    }
  }

  // ── Roles: load ───────────────────────────────────────────────────────────

  async loadRoles(): Promise<void> {
    this.rolesLoading = true;
    try {
      this.roles = await firstValueFrom(this.userService.listRoles());
      this.allRoles = this.roles;
    } catch (e: any) {
      if (this.activeTab === 'roles') {
        this.errorMessage = e?.error?.message || 'user.errors.loadRoles';
      }
    } finally {
      this.rolesLoading = false;
    }
  }

  // ── Roles: create ─────────────────────────────────────────────────────────

  openCreateRoleModal(): void {
    this.createRoleForm.reset({ name: '', description: '', isDefault: false });
    this.showCreateRoleModal = true;
    this.clearMessages();
  }

  closeCreateRoleModal(): void {
    this.showCreateRoleModal = false;
  }

  async submitCreateRole(): Promise<void> {
    this.createRoleForm.markAllAsTouched();
    if (this.createRoleForm.invalid) return;

    this.rolesSubmitting = true;
    this.clearMessages();
    try {
      const v = this.createRoleForm.getRawValue();
      await firstValueFrom(this.userService.createRole({
        name: v.name.toUpperCase(),
        description: v.description || undefined,
        isDefault: v.isDefault,
      }));
      this.successMessage = 'user.success.roleCreated';
      this.showCreateRoleModal = false;
      await this.loadRoles();
    } catch (e: any) {
      this.errorMessage = e?.error?.message || 'user.errors.createRole';
    } finally {
      this.rolesSubmitting = false;
    }
  }

  // ── Roles: edit ───────────────────────────────────────────────────────────

  openEditRoleModal(role: RoleRecord): void {
    if (this.isSystemRole(role)) return;
    this.selectedRole = role;
    this.editRoleForm.reset({
      name: role.name || '',
      description: role.description || '',
      isDefault: role.isDefault ?? false,
    });
    this.showEditRoleModal = true;
    this.clearMessages();
  }

  closeEditRoleModal(): void {
    this.showEditRoleModal = false;
    this.selectedRole = null;
  }

  async submitEditRole(): Promise<void> {
    this.editRoleForm.markAllAsTouched();
    if (this.editRoleForm.invalid || !this.selectedRole) return;

    this.rolesSubmitting = true;
    this.clearMessages();
    try {
      const v = this.editRoleForm.getRawValue();
      await firstValueFrom(this.userService.updateRole(this.selectedRole.id, {
        name: v.name.toUpperCase(),
        description: v.description || undefined,
        isDefault: v.isDefault,
      }));
      this.successMessage = 'user.success.roleUpdated';
      this.showEditRoleModal = false;
      await this.loadRoles();
    } catch (e: any) {
      this.errorMessage = e?.error?.message || 'user.errors.updateRole';
    } finally {
      this.rolesSubmitting = false;
    }
  }

  // ── Roles: delete ─────────────────────────────────────────────────────────

  openDeleteRoleModal(role: RoleRecord): void {
    if (this.isSystemRole(role)) return;
    this.selectedRole = role;
    this.deleteRoleError = '';
    this.showDeleteRoleModal = true;
    this.clearMessages();
  }

  closeDeleteRoleModal(): void {
    this.showDeleteRoleModal = false;
    this.selectedRole = null;
    this.deleteRoleError = '';
  }

  async confirmDeleteRole(): Promise<void> {
    if (!this.selectedRole) return;
    this.rolesSubmitting = true;
    this.deleteRoleError = '';
    try {
      await firstValueFrom(this.userService.deleteRole(this.selectedRole.id));
      this.successMessage = 'user.success.roleDeleted';
      this.closeDeleteRoleModal();
      await this.loadRoles();
    } catch (e: any) {
      this.deleteRoleError = e?.error?.message || 'user.errors.deleteRole';
    } finally {
      this.rolesSubmitting = false;
    }
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  private clearMessages(): void {
    this.errorMessage = '';
    this.successMessage = '';
  }
}
