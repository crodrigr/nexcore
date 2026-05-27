import { Component, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { TranslocoModule } from '@ngneat/transloco';
import { firstValueFrom } from 'rxjs';
import { NavbarComponent } from '../../shared/layout/navbar.component';
import { SidebarComponent } from '../../shared/layout/sidebar.component';
import {
  AccessLevel,
  ComponentPermissionState,
  ElementPermissionState,
  RoleOption,
} from './permissions.models';
import { PermissionManagementService } from './permission-management.service';
import { ComponentAccordionItemComponent } from './component-accordion-item.component';

@Component({
  selector: 'app-permissions-page',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    TranslocoModule,
    NavbarComponent,
    SidebarComponent,
    ComponentAccordionItemComponent,
  ],
  templateUrl: './permissions-page.component.html',
  styleUrls: ['./permissions-page.component.scss']
})
export class PermissionsPageComponent implements OnInit {
  private readonly service = inject(PermissionManagementService);

  // ── Estado de carga ────────────────────────────────────────────
  rolesLoading = false;
  loading = false;
  saving = false;
  errorMessage = '';

  // ── Roles ──────────────────────────────────────────────────────
  roles: RoleOption[] = [];
  selectedRoleId = '';

  // ── Matriz de permisos ─────────────────────────────────────────
  components: ComponentPermissionState[] = [];

  // ── Filtro ─────────────────────────────────────────────────────
  searchTerm = '';

  get filteredComponents(): ComponentPermissionState[] {
    const q = this.searchTerm.toLowerCase().trim();
    if (!q) return this.components;
    return this.components.filter(c =>
      c.name.toLowerCase().includes(q) || c.route.toLowerCase().includes(q)
    );
  }

  // ── Dirty tracking ─────────────────────────────────────────────
  get hasPendingChanges(): boolean {
    return this.components.some(c => c.dirty || c.elements.some(e => e.dirty));
  }

  // ── Toast ──────────────────────────────────────────────────────
  showToast = false;
  toastMessage = '';

  ngOnInit(): void {
    this.loadRoles();
  }

  async loadRoles(): Promise<void> {
    this.rolesLoading = true;
    this.clearMessages();
    try {
      this.roles = await firstValueFrom(this.service.loadRoles());
      if (this.roles.length > 0) {
        this.selectedRoleId = this.roles[0].id;
        await this.loadMatrix();
      }
    } catch (e: any) {
      this.errorMessage = e?.error?.message || 'permissions.errors.loadMatrix';
    } finally {
      this.rolesLoading = false;
    }
  }

  async loadMatrix(): Promise<void> {
    if (!this.selectedRoleId) return;
    this.loading = true;
    this.clearMessages();
    try {
      const matrix = await firstValueFrom(this.service.getPermissionMatrix(this.selectedRoleId));
      this.components = (matrix?.components ?? []).map(c => ({
        ...c,
        elements: (c.elements ?? []).map(e => ({ ...e, dirty: false })) as ElementPermissionState[],
        expanded: false,
        dirty: false,
      }));
    } catch (e: any) {
      this.errorMessage = e?.error?.message || 'permissions.errors.loadMatrix';
    } finally {
      this.loading = false;
    }
  }

  async onRoleChange(roleId: string): Promise<void> {
    this.selectedRoleId = roleId;
    this.searchTerm = '';
    await this.loadMatrix();
  }

  toggleAccordion(componentId: string): void {
    const comp = this.components.find(c => c.componentId === componentId);
    if (comp) comp.expanded = !comp.expanded;
  }

  onComponentAccessChange(event: { componentId: string; level: AccessLevel }): void {
    const comp = this.components.find(c => c.componentId === event.componentId);
    if (!comp) return;
    comp.access = event.level;
    comp.dirty = true;
    comp.elements.forEach(e => {
      if (e.inherited) e.access = event.level;
    });
  }

  onElementAccessChange(event: { componentId: string; elementId: string; level: AccessLevel }): void {
    const comp = this.components.find(c => c.componentId === event.componentId);
    const elem = comp?.elements.find(e => e.elementId === event.elementId);
    if (!elem) return;
    elem.access = event.level;
    elem.dirty = true;
    elem.inherited = false;
  }

  applyViewToAll(): void {
    this.components.forEach(c => {
      c.access = 'view';
      c.dirty = true;
      c.elements.forEach(e => {
        if (e.inherited) e.access = 'view';
      });
    });
  }

  async saveChanges(): Promise<void> {
    if (!this.hasPendingChanges || !this.selectedRoleId) return;
    this.saving = true;
    this.clearMessages();
    try {
      const dirtyComponents = this.components.filter(c => c.dirty);
      const dirtyElements = this.components.flatMap(c =>
        c.elements.filter(e => e.dirty)
      );

      if (dirtyComponents.length > 0) {
        await firstValueFrom(
          this.service.batchUpsertComponents(
            this.selectedRoleId,
            dirtyComponents.map(c => ({ componentId: c.componentId, access: c.access }))
          )
        );
        dirtyComponents.forEach(c => { c.dirty = false; });
      }

      for (const elem of dirtyElements) {
        await firstValueFrom(
          this.service.upsertElement(this.selectedRoleId, elem.elementId, elem.access)
        );
        elem.dirty = false;
      }

      this.triggerToast('permissions.success.updated');
    } catch (e: any) {
      this.errorMessage = e?.error?.message || 'permissions.errors.save';
    } finally {
      this.saving = false;
    }
  }

  private triggerToast(key: string): void {
    this.toastMessage = key;
    this.showToast = true;
    setTimeout(() => { this.showToast = false; }, 3000);
  }

  private clearMessages(): void {
    this.errorMessage = '';
  }
}
