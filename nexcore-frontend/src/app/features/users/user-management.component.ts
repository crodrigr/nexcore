import { CommonModule } from '@angular/common';
import { Component, inject, OnInit } from '@angular/core';
import { FormBuilder, FormsModule, ReactiveFormsModule, Validators } from '@angular/forms';
import { TranslocoModule } from '@ngneat/transloco';
import { firstValueFrom, Subject } from 'rxjs';
import { debounceTime, distinctUntilChanged } from 'rxjs/operators';
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
  imports: [CommonModule, FormsModule, ReactiveFormsModule, TranslocoModule],
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
  showToast = false;
  toastMessage = '';
  toastType: 'success' | 'error' = 'success';

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
  readonly invStatusOptions = [
    { value: '', label: 'user.filter.allStatuses' },
    { value: 'PENDING', label: 'user.invitations.statusPENDING' },
    { value: 'ACCEPTED', label: 'user.invitations.statusACCEPTED' },
    { value: 'REVOKED', label: 'user.invitations.statusREVOKED' },
  ];

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
  invSearchTerm = '';
  invStatusFilter = '';
  invSortField: keyof InvitationRecord = 'invitedAt';
  invSortDir: 'asc' | 'desc' = 'desc';
  invPage = 0;
  invSize = 10;

  // ── Roles tab state ───────────────────────────────────────────────────────
  rolesLoading = false;
  rolesSubmitting = false;
  roles: RoleRecord[] = [];
  showCreateRoleModal = false;
  showEditRoleModal = false;
  showDeleteRoleModal = false;
  selectedRole: RoleRecord | null = null;
  deleteRoleError = '';
  roleSearchTerm = '';
  roleSortField: keyof RoleRecord = 'name';
  roleSortDir: 'asc' | 'desc' = 'asc';
  rolePage = 0;
  roleSize = 10;

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
        this.userService.listUsers(page, this.userSize, this.userStatusFilter, this.userSearchTerm, this.userSortField, this.userSortDir)
      );
      const pr = resp as PageResponse<UserRecord>;
      this.users = pr.content || [];
      this.userPage = pr.page ?? page;
      this.userTotalElements = pr.totalElements ?? this.users.length;
      this.userTotalPages = pr.totalPages ?? 1;
    } catch (e: any) {
      this.triggerToast(e?.error?.message || 'user.errors.loadUsers', 'error');
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
        this.triggerToast('user.success.inviteSent');
        await this.loadInvitations();
        this.selectTab('invitations');
      } else {
        this.triggerToast('user.success.userCreated');
        await this.loadUsers(0);
      }
    } catch (e: any) {
      this.triggerToast(e?.error?.message || 'user.errors.createUser', 'error');
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

    const targetId = this.selectedUser.id;
    this.usersSubmitting = true;
    this.clearMessages();
    try {
      const v = this.editUserForm.getRawValue();
      await firstValueFrom(this.userService.updateUser(targetId, {
        fullName: v.fullName,
        phone: v.phone || undefined,
        photoUrl: v.photoUrl || undefined,
      }));
      this.triggerToast('user.success.userUpdated');
      this.showEditUserModal = false;
      this.users = this.users.map(u => u.id === targetId
        ? { ...u, fullName: v.fullName, phone: v.phone || undefined, photoUrl: v.photoUrl || undefined }
        : u);
    } catch (e: any) {
      this.triggerToast(e?.error?.message || 'user.errors.updateUser', 'error');
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
    const targetId = this.selectedUser.id;
    this.usersSubmitting = true;
    this.clearMessages();
    try {
      await firstValueFrom(this.userService.suspendUser(targetId));
      this.triggerToast('user.success.userSuspended');
      this.closeSuspendUserModal();
      this.users = this.users.map(u => u.id === targetId ? { ...u, status: 'SUSPENDED' } : u);
    } catch (e: any) {
      this.triggerToast(e?.error?.message || 'user.errors.suspendUser', 'error');
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
    const targetId = this.selectedUser.id;
    this.usersSubmitting = true;
    this.clearMessages();
    try {
      await firstValueFrom(this.userService.activateUser(targetId));
      this.triggerToast('user.success.userActivated');
      this.closeActivateUserModal();
      this.users = this.users.map(u => u.id === targetId ? { ...u, status: 'ACTIVE' } : u);
    } catch (e: any) {
      this.triggerToast(e?.error?.message || 'user.errors.activateUser', 'error');
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
    const targetId = this.selectedUser.id;
    this.usersSubmitting = true;
    this.clearMessages();
    try {
      await firstValueFrom(this.userService.deleteUser(targetId));
      this.triggerToast('user.success.userDeleted');
      this.closeDeleteUserModal();
      this.users = this.users.filter(u => u.id !== targetId);
      this.userTotalElements = Math.max(0, this.userTotalElements - 1);
    } catch (e: any) {
      this.triggerToast(e?.error?.message || 'user.errors.deleteUser', 'error');
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
    const targetId = this.selectedUser.id;
    this.usersSubmitting = true;
    this.clearMessages();
    try {
      const roles = Array.from(this.selectedRoleIds).map(roleId => ({ roleId, expiresAt: null }));
      await firstValueFrom(this.userService.assignRoles(targetId, { roles }));
      this.triggerToast('user.success.rolesAssigned');
      const updatedRoles = Array.from(this.selectedRoleIds)
        .map(id => this.allRoles.find(r => r.id === id))
        .filter((r): r is RoleRecord => !!r);
      this.closeAssignRolesModal();
      this.users = this.users.map(u => u.id === targetId ? { ...u, roles: updatedRoles } : u);
    } catch (e: any) {
      this.triggerToast(e?.error?.message || 'user.errors.assignRoles', 'error');
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
        this.triggerToast(e?.error?.message || 'user.errors.loadInvitations', 'error');
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
      this.triggerToast('user.success.inviteSent');
      this.showInviteModal = false;
      await this.loadInvitations();
    } catch (e: any) {
      this.triggerToast(e?.error?.message || 'user.errors.invite', 'error');
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
      this.triggerToast('user.success.inviteResent');
      await this.loadInvitations();
    } catch (e: any) {
      this.triggerToast(e?.error?.message || 'user.errors.resendInvitation', 'error');
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
      this.triggerToast('user.success.inviteRevoked');
      this.closeRevokeModal();
      await this.loadInvitations();
    } catch (e: any) {
      this.triggerToast(e?.error?.message || 'user.errors.revokeInvitation', 'error');
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
        this.triggerToast(e?.error?.message || 'user.errors.loadRoles', 'error');
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
      this.triggerToast('user.success.roleCreated');
      this.showCreateRoleModal = false;
      await this.loadRoles();
    } catch (e: any) {
      this.triggerToast(e?.error?.message || 'user.errors.createRole', 'error');
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
      this.triggerToast('user.success.roleUpdated');
      this.showEditRoleModal = false;
      await this.loadRoles();
    } catch (e: any) {
      this.triggerToast(e?.error?.message || 'user.errors.updateRole', 'error');
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
      this.triggerToast('user.success.roleDeleted');
      this.closeDeleteRoleModal();
      await this.loadRoles();
    } catch (e: any) {
      this.deleteRoleError = e?.error?.message || 'user.errors.deleteRole';
    } finally {
      this.rolesSubmitting = false;
    }
  }

  // ── Invitations: filter / sort / page (client-side) ──────────────────────

  get invitationsFiltered(): InvitationRecord[] {
    let list = this.invitations;
    if (this.invStatusFilter) list = list.filter(i => i.status === this.invStatusFilter);
    const term = this.invSearchTerm.trim().toLowerCase();
    if (term) list = list.filter(i => i.email.toLowerCase().includes(term));
    const field = this.invSortField;
    const dir = this.invSortDir;
    return [...list].sort((a, b) => {
      const va = String((a as any)[field] ?? '');
      const vb = String((b as any)[field] ?? '');
      const cmp = va.localeCompare(vb, undefined, { sensitivity: 'base' });
      return dir === 'asc' ? cmp : -cmp;
    });
  }

  get invTotalElements(): number { return this.invitationsFiltered.length; }
  get invTotalPages(): number { return Math.max(1, Math.ceil(this.invTotalElements / this.invSize)); }
  get invPageStart(): number { return this.invTotalElements === 0 ? 0 : this.invPage * this.invSize + 1; }
  get invPageEnd(): number { return Math.min((this.invPage + 1) * this.invSize, this.invTotalElements); }

  get invitationsPaged(): InvitationRecord[] {
    const from = this.invPage * this.invSize;
    return this.invitationsFiltered.slice(from, from + this.invSize);
  }

  isSortedAscInv(field: keyof InvitationRecord): boolean {
    return this.invSortField === field && this.invSortDir === 'asc';
  }

  isSortedDescInv(field: keyof InvitationRecord): boolean {
    return this.invSortField === field && this.invSortDir === 'desc';
  }

  toggleInvSort(field: keyof InvitationRecord): void {
    if (this.invSortField === field) {
      this.invSortDir = this.invSortDir === 'asc' ? 'desc' : 'asc';
    } else {
      this.invSortField = field;
      this.invSortDir = 'asc';
    }
    this.invPage = 0;
  }

  onInvSearchChange(value: string): void {
    this.invSearchTerm = value;
    this.invPage = 0;
  }

  onInvStatusChange(value: string): void {
    this.invStatusFilter = value;
    this.invPage = 0;
  }

  goToInvPage(page: number): void {
    if (page < 0 || page >= this.invTotalPages || page === this.invPage) return;
    this.invPage = page;
  }

  onInvPageSizeChange(val: number | string): void {
    const n = Number(val);
    if (!Number.isFinite(n) || n <= 0 || n === this.invSize) return;
    this.invSize = n;
    this.invPage = 0;
  }

  // ── Roles: filter / sort / page (client-side) ─────────────────────────────

  get rolesFiltered(): RoleRecord[] {
    let list = this.roles;
    const term = this.roleSearchTerm.trim().toLowerCase();
    if (term) list = list.filter(r =>
      r.name.toLowerCase().includes(term) || (r.description ?? '').toLowerCase().includes(term)
    );
    const field = this.roleSortField;
    const dir = this.roleSortDir;
    return [...list].sort((a, b) => {
      const va = (a as any)[field] ?? '';
      const vb = (b as any)[field] ?? '';
      const cmp = typeof va === 'number' && typeof vb === 'number'
        ? va - vb
        : String(va).localeCompare(String(vb), undefined, { sensitivity: 'base' });
      return dir === 'asc' ? cmp : -cmp;
    });
  }

  get roleTotalElements(): number { return this.rolesFiltered.length; }
  get roleTotalPages(): number { return Math.max(1, Math.ceil(this.roleTotalElements / this.roleSize)); }
  get rolePageStart(): number { return this.roleTotalElements === 0 ? 0 : this.rolePage * this.roleSize + 1; }
  get rolePageEnd(): number { return Math.min((this.rolePage + 1) * this.roleSize, this.roleTotalElements); }

  get rolesPaged(): RoleRecord[] {
    const from = this.rolePage * this.roleSize;
    return this.rolesFiltered.slice(from, from + this.roleSize);
  }

  isSortedAscRole(field: keyof RoleRecord): boolean {
    return this.roleSortField === field && this.roleSortDir === 'asc';
  }

  isSortedDescRole(field: keyof RoleRecord): boolean {
    return this.roleSortField === field && this.roleSortDir === 'desc';
  }

  toggleRoleSort(field: keyof RoleRecord): void {
    if (this.roleSortField === field) {
      this.roleSortDir = this.roleSortDir === 'asc' ? 'desc' : 'asc';
    } else {
      this.roleSortField = field;
      this.roleSortDir = 'asc';
    }
    this.rolePage = 0;
  }

  onRoleSearchChange(value: string): void {
    this.roleSearchTerm = value;
    this.rolePage = 0;
  }

  goToRolePage(page: number): void {
    if (page < 0 || page >= this.roleTotalPages || page === this.rolePage) return;
    this.rolePage = page;
  }

  onRolePageSizeChange(val: number | string): void {
    const n = Number(val);
    if (!Number.isFinite(n) || n <= 0 || n === this.roleSize) return;
    this.roleSize = n;
    this.rolePage = 0;
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  private clearMessages(): void {}

  private triggerToast(key: string, type: 'success' | 'error' = 'success'): void {
    this.toastMessage = key;
    this.toastType = type;
    this.showToast = true;
    setTimeout(() => { this.showToast = false; }, 3500);
  }
}
