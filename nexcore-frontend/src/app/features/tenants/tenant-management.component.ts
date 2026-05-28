import { CommonModule } from '@angular/common';
import { Component, HostListener, inject } from '@angular/core';
import { FormBuilder, FormsModule, ReactiveFormsModule, Validators } from '@angular/forms';
import { TranslocoModule } from '@ngneat/transloco';
import { firstValueFrom } from 'rxjs';
import {
  Tenant,
  TenantCreateRequest,
  TenantService,
  TenantUpdateRequest,
  PageResponse
} from './tenant.service';

@Component({
  selector: 'app-tenant-management',
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule, TranslocoModule],
  templateUrl: './tenant-management.component.html',
  styleUrls: ['./tenant-management.component.scss']
})
export class TenantManagementComponent {
  private readonly tenantService = inject(TenantService);
  private readonly fb = inject(FormBuilder);

  loading = false;
  submitting = false;
  errorMessage = '';
  successMessage = '';

  tenants: Tenant[] = [];
  allTenants: Tenant[] = [];
  useClientPagination = false;
  searchTerm = '';

  page = 0;
  size = 10;
  totalElements = 0;
  totalPages = 1;

  sortField: keyof Tenant = 'name';
  sortDirection: 'asc' | 'desc' = 'asc';

  showCreateModal = false;
  showEditModal = false;
  showUpdateConfirmModal = false;
  showSuspendModal = false;
  showActivateModal = false;

  selectedTenant: Tenant | null = null;
  updateImpactSummary: string[] = [];
  suspendConfirmText = '';

  readonly planOptions = ['FREE', 'STARTER', 'PROFESSIONAL', 'ENTERPRISE'];
  readonly modeOptions = ['SAAS_SHARED', 'SAAS_DEDICATED', 'ON_PREMISE'];
  readonly pageSizeOptions = [5,10, 20, 50, 100];

  readonly createForm = this.fb.nonNullable.group({
    slug: ['', [Validators.required, Validators.pattern(/^[a-z0-9]+(-[a-z0-9]+)*$/)]],
    name: ['', [Validators.required, Validators.minLength(2)]],
    legalName: ['', [Validators.required, Validators.minLength(2)]],
    taxId: ['', [Validators.required, Validators.minLength(3)]],
    plan: ['STARTER', Validators.required],
    mode: ['SAAS_SHARED', Validators.required],
    timezone: ['America/Bogota', Validators.required],
    locale: ['es-CO', Validators.required],
    dateFormat: ['DD/MM/YYYY', Validators.required],
    currency: ['COP', Validators.required]
  });

  readonly updateForm = this.fb.nonNullable.group({
    name: ['', [Validators.required, Validators.minLength(2)]],
    legalName: ['', [Validators.required, Validators.minLength(2)]],
    timezone: ['', Validators.required],
    locale: ['', Validators.required],
    mfaRequired: [false],
    sessionTimeoutMinutes: [480, [Validators.required, Validators.min(1)]],
    maxLoginAttempts: [5, [Validators.required, Validators.min(1)]],
    passwordMinLength: [8, [Validators.required, Validators.min(6)]],
    passwordRequiresUpper: [true],
    passwordRequiresSpecial: [false]
  });

  constructor() {
    this.loadTenants();
  }

  @HostListener('window:beforeunload', ['$event'])
  beforeUnload(event: BeforeUnloadEvent): void {
    if (this.showCreateModal && this.createForm.dirty) {
      event.preventDefault();
      event.returnValue = '';
    }
  }

  get filteredTenants(): Tenant[] {
    if (this.useClientPagination) {
      return this.tenants;
    }

    const term = this.searchTerm.trim().toLowerCase();
    if (term.length === 0) {
      return this.tenants;
    }

    return this.tenants.filter(tenant => this.matchesSearch(tenant, term));
  }

  get canSuspend(): boolean {
    if (!this.selectedTenant) {
      return false;
    }

    const status = this.selectedTenant.status?.toUpperCase();
    return status === 'ACTIVE' || status === 'TRIAL' || status === 'PROVISIONING';
  }

  get canActivate(): boolean {
    return this.selectedTenant?.status?.toUpperCase() === 'SUSPENDED';
  }

  get pageStart(): number {
    if (this.totalElements === 0) {
      return 0;
    }
    return this.page * this.size + 1;
  }

  get pageEnd(): number {
    if (this.totalElements === 0) {
      return 0;
    }
    return Math.min((this.page + 1) * this.size, this.totalElements);
  }

  async loadTenants(page = this.page): Promise<void> {
    this.loading = true;
    this.errorMessage = '';

    try {
      const response = await firstValueFrom(this.tenantService.list(page, this.size));

      if (Array.isArray(response)) {
        this.useClientPagination = true;
        this.allTenants = response;
        this.applyClientPagination(page);
      } else {
        this.useClientPagination = false;
        this.allTenants = [];
        const pageResponse = response as PageResponse<Tenant>;
        this.tenants = this.applySorting(pageResponse.content || []);
        this.page = pageResponse.page ?? page;
        this.size = pageResponse.size ?? this.size;
        this.totalElements = pageResponse.totalElements ?? this.tenants.length;
        this.totalPages = pageResponse.totalPages ?? 1;
      }
    } catch (error: any) {
      this.errorMessage = error?.error?.message || 'No fue posible cargar los tenants.';
    } finally {
      this.loading = false;
    }
  }

  onSearchChange(value: string): void {
    this.searchTerm = value;
    if (this.useClientPagination) {
      this.applyClientPagination(0);
    }
  }

  async goToPage(nextPage: number): Promise<void> {
    if (nextPage < 0 || nextPage >= this.totalPages || nextPage === this.page) {
      return;
    }

    if (this.useClientPagination) {
      this.applyClientPagination(nextPage);
      return;
    }

    await this.loadTenants(nextPage);
  }

  async toggleSort(field: keyof Tenant): Promise<void> {
    if (this.sortField === field) {
      this.sortDirection = this.sortDirection === 'asc' ? 'desc' : 'asc';
    } else {
      this.sortField = field;
      this.sortDirection = 'asc';
    }

    if (this.useClientPagination) {
      this.applyClientPagination(this.page);
      return;
    }

    this.tenants = this.applySorting(this.tenants);
  }

  isSortedAsc(field: keyof Tenant): boolean {
    return this.sortField === field && this.sortDirection === 'asc';
  }

  isSortedDesc(field: keyof Tenant): boolean {
    return this.sortField === field && this.sortDirection === 'desc';
  }

  async goToFirstPage(): Promise<void> {
    await this.goToPage(0);
  }

  async goToLastPage(): Promise<void> {
    await this.goToPage(Math.max(this.totalPages - 1, 0));
  }

  async onPageSizeChange(value: number | string): Promise<void> {
    const nextSize = Number(value);
    if (!Number.isFinite(nextSize) || nextSize <= 0 || nextSize === this.size) {
      return;
    }

    this.size = nextSize;
    if (this.useClientPagination) {
      this.applyClientPagination(0);
      return;
    }

    await this.loadTenants(0);
  }

  private applyClientPagination(targetPage: number): void {
    const term = this.searchTerm.trim().toLowerCase();
    const source = term.length === 0
      ? this.allTenants
      : this.allTenants.filter(tenant => this.matchesSearch(tenant, term));

    const sortedSource = this.applySorting(source);

    this.totalElements = sortedSource.length;
    this.totalPages = Math.max(1, Math.ceil(this.totalElements / this.size));
    this.page = Math.min(Math.max(targetPage, 0), this.totalPages - 1);

    const start = this.page * this.size;
    this.tenants = sortedSource.slice(start, start + this.size);
  }

  private matchesSearch(tenant: Tenant, term: string): boolean {
    const id = (tenant.id || '').toLowerCase();
    const name = (tenant.name || '').toLowerCase();
    const slug = (tenant.slug || '').toLowerCase();
    return id.includes(term) || name.includes(term) || slug.includes(term);
  }

  private applySorting(items: Tenant[]): Tenant[] {
    const dir = this.sortDirection === 'asc' ? 1 : -1;
    const field = this.sortField;

    return [...items].sort((a, b) => {
      const av = this.normalizeSortValue(a[field]);
      const bv = this.normalizeSortValue(b[field]);

      if (av < bv) {
        return -1 * dir;
      }
      if (av > bv) {
        return 1 * dir;
      }
      return 0;
    });
  }

  private normalizeSortValue(value: unknown): string | number {
    if (value === null || value === undefined) {
      return '';
    }

    if (typeof value === 'number') {
      return value;
    }

    if (typeof value === 'string') {
      const asDate = Date.parse(value);
      if (!Number.isNaN(asDate) && /\d{4}-\d{2}-\d{2}/.test(value)) {
        return asDate;
      }
      return value.toLowerCase();
    }

    return '';
  }

  openCreateModal(): void {
    this.createForm.reset({
      slug: '',
      name: '',
      legalName: '',
      taxId: '',
      plan: 'STARTER',
      mode: 'SAAS_SHARED',
      timezone: 'America/Bogota',
      locale: 'es-CO',
      dateFormat: 'DD/MM/YYYY',
      currency: 'COP'
    });
    this.showCreateModal = true;
    this.clearMessages();
  }

  closeCreateModal(force = false): void {
    if (!force && this.createForm.dirty) {
      const confirmed = window.confirm('Tienes cambios sin guardar. Deseas cerrar el formulario?');
      if (!confirmed) {
        return;
      }
    }

    this.showCreateModal = false;
  }

  async submitCreate(): Promise<void> {
    this.createForm.markAllAsTouched();
    if (this.createForm.invalid) {
      return;
    }

    this.submitting = true;
    this.clearMessages();

    try {
      const payload = this.createForm.getRawValue() as TenantCreateRequest;
      await firstValueFrom(this.tenantService.create(payload));
      this.successMessage = 'Tenant creado correctamente.';
      this.showCreateModal = false;
      await this.loadTenants(0);
    } catch (error: any) {
      this.errorMessage = error?.error?.message || 'No fue posible crear el tenant.';
    } finally {
      this.submitting = false;
    }
  }

  openEditModal(tenant: Tenant): void {
    this.selectedTenant = tenant;
    this.updateForm.reset({
      name: tenant.name || '',
      legalName: tenant.legalName || '',
      timezone: tenant.timezone || 'America/Bogota',
      locale: tenant.locale || 'es-CO',
      mfaRequired: Boolean(tenant.mfaRequired),
      sessionTimeoutMinutes: tenant.sessionTimeoutMinutes ?? 480,
      maxLoginAttempts: tenant.maxLoginAttempts ?? 5,
      passwordMinLength: tenant.passwordMinLength ?? 8,
      passwordRequiresUpper: tenant.passwordRequiresUpper ?? true,
      passwordRequiresSpecial: tenant.passwordRequiresSpecial ?? false
    });

    this.showEditModal = true;
    this.showUpdateConfirmModal = false;
    this.updateImpactSummary = [];
    this.clearMessages();
  }

  closeEditModal(): void {
    this.showEditModal = false;
    this.showUpdateConfirmModal = false;
    this.selectedTenant = null;
    this.updateImpactSummary = [];
  }

  requestUpdateConfirmation(): void {
    this.updateForm.markAllAsTouched();
    if (this.updateForm.invalid) {
      return;
    }

    if (!this.selectedTenant) {
      return;
    }

    const changed: string[] = [];
    const current = this.selectedTenant;
    const next = this.updateForm.getRawValue();

    if (next.mfaRequired !== Boolean(current.mfaRequired)) {
      changed.push('MFA requerido puede afectar el inicio de sesion de usuarios.');
    }
    if ((next.sessionTimeoutMinutes ?? 0) !== (current.sessionTimeoutMinutes ?? 480)) {
      changed.push('Cambio de session timeout impacta sesiones activas.');
    }
    if ((next.maxLoginAttempts ?? 0) !== (current.maxLoginAttempts ?? 5)) {
      changed.push('Cambio de maximo de intentos de login puede bloquear usuarios antes/despues.');
    }
    if ((next.passwordMinLength ?? 0) !== (current.passwordMinLength ?? 8)) {
      changed.push('Cambio de longitud minima de password aplica a futuras validaciones.');
    }

    this.updateImpactSummary = changed;
    this.showUpdateConfirmModal = true;
  }

  async confirmUpdate(): Promise<void> {
    if (!this.selectedTenant) {
      return;
    }

    this.submitting = true;
    this.clearMessages();

    try {
      const payload = this.updateForm.getRawValue() as TenantUpdateRequest;
      await firstValueFrom(this.tenantService.update(this.selectedTenant.id, payload, false));
      this.successMessage = 'Tenant actualizado correctamente.';
      this.closeEditModal();
      await this.loadTenants(this.page);
    } catch (error: any) {
      this.errorMessage = error?.error?.message || 'No fue posible actualizar el tenant.';
      this.showUpdateConfirmModal = false;
    } finally {
      this.submitting = false;
    }
  }

  openSuspendModal(tenant: Tenant): void {
    this.selectedTenant = tenant;
    this.suspendConfirmText = '';
    this.showSuspendModal = true;
    this.clearMessages();
  }

  closeSuspendModal(): void {
    this.showSuspendModal = false;
    this.selectedTenant = null;
    this.suspendConfirmText = '';
  }

  async confirmSuspend(): Promise<void> {
    if (!this.selectedTenant || this.suspendConfirmText !== 'SUSPEND') {
      return;
    }

    this.submitting = true;
    this.clearMessages();

    try {
      await firstValueFrom(this.tenantService.suspend(this.selectedTenant.id));
      this.successMessage = 'Tenant suspendido correctamente.';
      this.closeSuspendModal();
      await this.loadTenants(this.page);
    } catch (error: any) {
      this.errorMessage = error?.error?.message || 'No fue posible suspender el tenant.';
    } finally {
      this.submitting = false;
    }
  }

  openActivateModal(tenant: Tenant): void {
    this.selectedTenant = tenant;
    this.showActivateModal = true;
    this.clearMessages();
  }

  closeActivateModal(): void {
    this.showActivateModal = false;
    this.selectedTenant = null;
  }

  async confirmActivate(): Promise<void> {
    if (!this.selectedTenant) {
      return;
    }

    this.submitting = true;
    this.clearMessages();

    try {
      await firstValueFrom(this.tenantService.activate(this.selectedTenant.id));
      this.successMessage = 'Tenant activado correctamente.';
      this.closeActivateModal();
      await this.loadTenants(this.page);
    } catch (error: any) {
      this.errorMessage = error?.error?.message || 'No fue posible activar el tenant.';
    } finally {
      this.submitting = false;
    }
  }

  statusClass(status: string | undefined): string {
    const normalized = (status || '').toUpperCase();
    if (normalized === 'ACTIVE') {
      return 'status-active';
    }
    if (normalized === 'SUSPENDED') {
      return 'status-suspended';
    }
    return 'status-provisioning';
  }

  private clearMessages(): void {
    this.errorMessage = '';
    this.successMessage = '';
  }
}
