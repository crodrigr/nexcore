# NexCore Frontend — Especificación Módulo Permisos de Componentes
**Versión:** 1.0  
**Fecha:** 2026-05-27  
**Estado:** Propuesto para implementación

---

## 1. Objetivo

Definir los requisitos funcionales, de experiencia de usuario y criterios de aceptación del módulo **Permisos de Componentes** para el frontend NexCore, basado en el diseño de referencia (`modulo-permisos-componentes.png`) y en los servicios API del módulo `module-menu`.

El módulo permite a un TENANT_ADMIN gestionar los permisos de acceso que tiene un rol sobre cada componente del sistema (pantallas, secciones) y sobre sus elementos individuales (botones, campos, tabs). El resultado determina qué elementos de la UI puede ver o ejecutar cada usuario según su rol.

---

## 2. Alcance

Este documento cubre la pantalla de gestión de permisos organizada en torno a un selector de rol:

1. Selector de rol activo (dropdown SELECTED ROLE)
2. Lista de componentes en acordeón con selector de nivel de acceso por componente
3. Tabla de elementos por componente expandido con selector de nivel de acceso por elemento
4. Acciones de guardado: individual (por componente/elemento) y lote (Apply VIEW to all)

La implementación se divide en dos fases:

- **Fase 1:** Construcción del módulo con datos mock para validar el funcionamiento de la UI y la interacción de los controles.
- **Fase 2:** Integración real con los endpoints del backend.

---

## 3. Restricciones de diseño

1. No se debe modificar el header global (`app-navbar`).
2. No se debe modificar el sidebar global (`app-sidebar`).
3. La implementación debe adaptarse al layout existente: `.page-wrap > .layout > .content`.
4. El look and feel sigue el sistema de estilos establecido (tokens CSS, clases BEM de los módulos existentes).
5. Componentes visuales reutilizados deben mantener su comportamiento sin clases nuevas que rompan coherencia:
   - `.card`, `.toolbar`, `.btn`, `.status-chip`, `.modal-backdrop`, `.modal`
6. Los tres niveles de acceso se representan siempre con los mismos colores semánticos:
   - `HIDDEN` → gris (apagado, sin acceso)
   - `VIEW` → azul (acceso de solo lectura)
   - `EXECUTE` → verde (acceso completo)

Referencias visuales:
1. [nexcore-frontend/src/documents/nexcore_frontend_specification_ligth/modulo-permisos-componentes.png](nexcore-frontend/src/documents/nexcore_frontend_specification_ligth/modulo-permisos-componentes.png)

API base de referencia:
1. [nexcore-infra/postman/nexcore-collection.json](nexcore-infra/postman/nexcore-collection.json)

---

## 4. Roles y permisos

| Operación | Rol mínimo requerido |
|---|---|
| Ver la pantalla de permisos | TENANT_ADMIN |
| Seleccionar un rol activo | TENANT_ADMIN |
| Cambiar nivel de acceso a un componente | TENANT_ADMIN |
| Cambiar nivel de acceso a un elemento | TENANT_ADMIN |
| Aplicar nivel en lote a todos los componentes | TENANT_ADMIN |
| Acceso completo al módulo | SUPER_ADMIN (bypass total) |

Todos los requests deben incluir `X-Tenant-Id` y `X-Actor-Id` en los headers.

---

## 5. Niveles de acceso

Los tres niveles forman una jerarquía ordinal:

| Nivel | Valor | Significado |
|---|---|---|
| `HIDDEN` | 0 | El componente/elemento no es visible para el rol |
| `VIEW` | 1 | El componente/elemento es visible pero no ejecutable |
| `EXECUTE` | 2 | El componente/elemento es visible y ejecutable |

**Herencia:** cuando un elemento no tiene permiso explícito asignado, hereda el nivel del componente padre. En este caso el badge de estado muestra `Inherited`. Si el elemento tiene un permiso propio distinto al del componente, el badge muestra `Overridden`.

---

## 6. Estructura de pantalla

```
┌─────────────────────────────────────────────────────────────────┐
│ [app-navbar]                                                     │
├────────────┬────────────────────────────────────────────────────┤
│            │  Permisos de Componentes                            │
│ [sidebar]  │  Gestiona el acceso por rol a cada componente       │
│            │                                                     │
│  Dashboard │  ┌──────────────────────────────────────────────┐  │
│  Tenants   │  │ SELECTED ROLE  [EDITOR            ▼]         │  │
│  Users     │  └──────────────────────────────────────────────┘  │
│  Roles ●   │                                                     │
│            │  ┌─ Toolbar ─────────────────────────────────────┐ │
│            │  │ [🔍 Filter components...]  [Apply VIEW to all] │ │
│            │  │                            [Save Changes    ]  │ │
│            │  └───────────────────────────────────────────────┘ │
│            │                                                     │
│            │  ┌─ Acordeón ────────────────────────────────────┐ │
│            │  │ ▼ User Management    /admin/users              │ │
│            │  │   [HIDDEN] [VIEW] [EXECUTE]                    │ │
│            │  │   ┌─ Tabla elementos ────────────────────────┐ │ │
│            │  │   │ KEY | LABEL | TYPE | ACCESS | STATUS     │ │ │
│            │  │   │ btn-delete-user | Delete User | BUTTON   │ │ │
│            │  │   │  [HIDDEN][VIEW][EXECUTE]  [Inherited]    │ │ │
│            │  │   └──────────────────────────────────────────┘ │ │
│            │  │                                                  │ │
│            │  │ ► Tenant Billing      /admin/tenants/billing   │ │
│            │  │   [HIDDEN] [VIEW] [EXECUTE]                    │ │
│            │  │                                                  │ │
│            │  │ ► Security Logs       /admin/logs/security     │ │
│            │  │   [HIDDEN] [VIEW] [EXECUTE]                    │ │
│            │  └───────────────────────────────────────────────┘ │
│            │                                                     │
│            │  [Toast: Permissions updated successfully ✓]        │
└────────────┴────────────────────────────────────────────────────┘
```

---

## 7. Fase 1 — Construcción con datos mock

### 7.1 Objetivo de la Fase 1

Construir la pantalla completa con datos de prueba hardcodeados para validar:
- La interacción del selector de nivel de acceso (pills segmentadas HIDDEN/VIEW/EXECUTE)
- El comportamiento del acordeón (expandir/colapsar componentes)
- La lógica visual de herencia (`Inherited` / `Overridden`)
- El flujo de `Apply VIEW to all` y `Save Changes`
- La apariencia del toast de confirmación

No se realizan llamadas HTTP reales en Fase 1.

### 7.2 Mock data

#### Roles disponibles

```typescript
export const MOCK_ROLES: RoleOption[] = [
  { id: '00000000-0000-0000-0000-000000000001', name: 'TENANT_ADMIN' },
  { id: '00000000-0000-0000-0000-000000000010', name: 'EDITOR' },
  { id: '00000000-0000-0000-0000-000000000020', name: 'VIEWER' },
];
```

#### Matriz de permisos (respuesta mock de `GET /roles/{roleId}`)

```typescript
export const MOCK_PERMISSION_MATRIX: RolePermissionMatrixResponse = {
  roleId: '00000000-0000-0000-0000-000000000010',
  roleName: 'EDITOR',
  tenantId: '00000000-0000-0000-0000-000000000100',
  components: [
    {
      componentId: 'aaa00000-0000-0000-0000-000000000001',
      moduleKey: 'user-management',
      name: 'User Management',
      route: '/admin/users',
      access: 'view',
      elements: [
        {
          elementId: 'eee00000-0000-0000-0000-000000000001',
          elementKey: 'btn-delete-user',
          label: 'Delete User',
          elementType: 'BUTTON',
          access: 'hidden',
          inherited: true,
        },
        {
          elementId: 'eee00000-0000-0000-0000-000000000002',
          elementKey: 'field-user-email',
          label: 'Email Address',
          elementType: 'FIELD',
          access: 'view',
          inherited: false,
        },
        {
          elementId: 'eee00000-0000-0000-0000-000000000003',
          elementKey: 'tab-activity-log',
          label: 'Activity Log',
          elementType: 'TAB',
          access: 'execute',
          inherited: true,
        },
      ],
    },
    {
      componentId: 'aaa00000-0000-0000-0000-000000000002',
      moduleKey: 'tenant-billing',
      name: 'Tenant Billing',
      route: '/admin/tenants/billing',
      access: 'hidden',
      elements: [],
    },
    {
      componentId: 'aaa00000-0000-0000-0000-000000000003',
      moduleKey: 'security-logs',
      name: 'Security Logs',
      route: '/admin/logs/security',
      access: 'execute',
      elements: [
        {
          elementId: 'eee00000-0000-0000-0000-000000000010',
          elementKey: 'btn-export-logs',
          label: 'Export Logs',
          elementType: 'BUTTON',
          access: 'execute',
          inherited: true,
        },
      ],
    },
  ],
};
```

### 7.3 Modelos TypeScript

```typescript
export type AccessLevel = 'hidden' | 'view' | 'execute';

export interface RoleOption {
  id: string;
  name: string;
}

export interface RoleElementPermission {
  elementId: string;
  elementKey: string;
  label: string;
  elementType: 'BUTTON' | 'FIELD' | 'TAB' | string;
  access: AccessLevel;
  inherited: boolean;
}

export interface RoleComponentPermission {
  componentId: string;
  moduleKey: string;
  name: string;
  route: string;
  access: AccessLevel;
  elements: RoleElementPermission[];
}

export interface RolePermissionMatrixResponse {
  roleId: string;
  roleName: string;
  tenantId: string;
  components: RoleComponentPermission[];
}

// Estado local del editor (copia mutable de la matriz)
export interface ComponentPermissionState extends RoleComponentPermission {
  expanded: boolean;
  dirty: boolean;
}

export interface ElementPermissionState extends RoleElementPermission {
  dirty: boolean;
}
```

### 7.4 Comportamiento mock en Fase 1

| Acción | Comportamiento mock |
|---|---|
| Cambiar rol en dropdown | Cargar la matriz mock correspondiente al rol (o la misma si solo hay una) |
| Expandir/colapsar acordeón | Toggle visual sin request |
| Cambiar acceso de componente | Actualizar estado local; marcar como `dirty`; recalcular herencia en elementos |
| Cambiar acceso de elemento | Actualizar estado local; marcar como `dirty`; cambiar badge a `Overridden` |
| Apply VIEW to all | Poner todos los componentes a `view` en estado local; marcar todos `dirty` |
| Save Changes | Simular delay 800ms → mostrar toast de éxito → limpiar `dirty` |
| Filtrar componentes | Filtrar la lista en memoria por `name` o `route` |

---

## 8. Componentes Angular

### 8.1 Componente principal: `PermissionsPageComponent`

Archivo: `permissions-page.component.ts / .html / .scss`

Responsabilidades:
- Contiene el selector de rol (`RoleSelectorComponent`)
- Gestiona la matriz de permisos en estado local
- Propaga cambios individuales y en lote
- Coordina el toast de notificación
- En Fase 2: inyecta `PermissionService` para llamadas HTTP

Estado del componente:

```typescript
@Component({ standalone: true, ... })
export class PermissionsPageComponent implements OnInit {

  // ── Estado de carga ────────────────────────────────
  loading = false;
  saving = false;
  errorMessage = '';

  // ── Rol activo ─────────────────────────────────────
  roles: RoleOption[] = MOCK_ROLES;  // Fase 2: cargado via RoleService
  selectedRoleId = MOCK_ROLES[1].id;

  // ── Matriz de permisos (estado editable local) ─────
  components: ComponentPermissionState[] = [];

  // ── Filtro de búsqueda ─────────────────────────────
  searchTerm = '';
  get filteredComponents(): ComponentPermissionState[] {
    const q = this.searchTerm.toLowerCase();
    if (!q) return this.components;
    return this.components.filter(c =>
      c.name.toLowerCase().includes(q) || c.route.toLowerCase().includes(q)
    );
  }

  // ── Dirty tracking ─────────────────────────────────
  get hasPendingChanges(): boolean {
    return this.components.some(c => c.dirty || c.elements.some((e: any) => e.dirty));
  }

  // ── Toast ──────────────────────────────────────────
  showToast = false;
  toastMessage = '';

  ngOnInit(): void {
    this.loadMatrix();
  }

  loadMatrix(): void {
    this.loading = true;
    // Fase 1: usar mock
    const matrix = MOCK_PERMISSION_MATRIX;
    this.components = matrix.components.map(c => ({
      ...c,
      elements: c.elements.map(e => ({ ...e, dirty: false })),
      expanded: false,
      dirty: false,
    }));
    this.loading = false;
  }

  onRoleChange(roleId: string): void {
    this.selectedRoleId = roleId;
    this.loadMatrix();
  }

  toggleAccordion(componentId: string): void {
    const comp = this.components.find(c => c.componentId === componentId);
    if (comp) comp.expanded = !comp.expanded;
  }

  onComponentAccessChange(componentId: string, level: AccessLevel): void {
    const comp = this.components.find(c => c.componentId === componentId);
    if (!comp) return;
    comp.access = level;
    comp.dirty = true;
    // Recalcular herencia: los elementos con inherited=true adoptan el nuevo nivel
    comp.elements.forEach((e: any) => {
      if (e.inherited) e.access = level;
    });
  }

  onElementAccessChange(componentId: string, elementId: string, level: AccessLevel): void {
    const comp = this.components.find(c => c.componentId === componentId);
    const elem = comp?.elements.find((e: any) => e.elementId === elementId);
    if (!elem) return;
    elem.access = level;
    elem.dirty = true;
    elem.inherited = false;
  }

  applyViewToAll(): void {
    this.components.forEach(c => {
      c.access = 'view';
      c.dirty = true;
    });
  }

  async saveChanges(): Promise<void> {
    this.saving = true;
    this.clearMessages();
    try {
      // Fase 1: simular delay
      await new Promise(r => setTimeout(r, 800));
      this.components.forEach(c => {
        c.dirty = false;
        c.elements.forEach((e: any) => e.dirty = false);
      });
      this.showSuccessToast('permissions.success.updated');
    } catch (e: any) {
      this.errorMessage = e?.error?.message || 'permissions.errors.save';
    } finally {
      this.saving = false;
    }
  }

  private showSuccessToast(key: string): void {
    this.toastMessage = key;
    this.showToast = true;
    setTimeout(() => { this.showToast = false; }, 3000);
  }

  private clearMessages(): void { this.errorMessage = ''; }
}
```

### 8.2 Selector de rol: `RoleSelectorComponent`

```typescript
@Component({
  selector: 'app-role-selector',
  standalone: true,
  template: `
    <div class="role-selector-block">
      <label class="role-selector-label">{{ 'permissions.roleSelector.label' | transloco }}</label>
      <select class="role-selector-select"
              [ngModel]="selectedRoleId"
              [ngModelOptions]="{standalone: true}"
              (ngModelChange)="roleChange.emit($event)">
        <option *ngFor="let r of roles" [value]="r.id">{{ r.name }}</option>
      </select>
    </div>
  `
})
export class RoleSelectorComponent {
  @Input() roles: RoleOption[] = [];
  @Input() selectedRoleId = '';
  @Output() roleChange = new EventEmitter<string>();
}
```

### 8.3 Acordeón de componente: `ComponentAccordionItemComponent`

```typescript
@Component({
  selector: 'app-component-accordion-item',
  standalone: true,
  ...
})
export class ComponentAccordionItemComponent {
  @Input() component!: ComponentPermissionState;
  @Output() accessChange = new EventEmitter<{ componentId: string; level: AccessLevel }>();
  @Output() elementAccessChange = new EventEmitter<{ componentId: string; elementId: string; level: AccessLevel }>();
  @Output() toggleExpand = new EventEmitter<string>();

  onAccessClick(level: AccessLevel): void {
    this.accessChange.emit({ componentId: this.component.componentId, level });
  }

  onElementClick(elementId: string, level: AccessLevel): void {
    this.elementAccessChange.emit({ componentId: this.component.componentId, elementId, level });
  }
}
```

Template del acordeón:

```html
<div class="accordion-item" [class.expanded]="component.expanded" [class.dirty]="component.dirty">

  <!-- Header del acordeón -->
  <div class="accordion-header" (click)="toggleExpand.emit(component.componentId)">
    <div class="accordion-arrow">{{ component.expanded ? '▼' : '►' }}</div>
    <div class="accordion-info">
      <span class="accordion-name">{{ component.name }}</span>
      <span class="accordion-route">{{ component.route }}</span>
    </div>
    <app-access-level-pill
      [value]="component.access"
      (levelChange)="onAccessClick($event)"
      (click)="$event.stopPropagation()">
    </app-access-level-pill>
  </div>

  <!-- Tabla de elementos (solo visible si expandido) -->
  <div class="accordion-body" *ngIf="component.expanded">
    <div class="empty-elements" *ngIf="!component.elements.length">
      {{ 'permissions.elements.empty' | transloco }}
    </div>
    <table class="elements-table" *ngIf="component.elements.length">
      <thead>
        <tr>
          <th>{{ 'permissions.table.elementKey' | transloco }}</th>
          <th>{{ 'permissions.table.label' | transloco }}</th>
          <th>{{ 'permissions.table.type' | transloco }}</th>
          <th>{{ 'permissions.table.accessLevel' | transloco }}</th>
          <th>{{ 'permissions.table.status' | transloco }}</th>
        </tr>
      </thead>
      <tbody>
        <tr *ngFor="let elem of component.elements" [class.dirty]="elem.dirty">
          <td class="elem-key">{{ elem.elementKey }}</td>
          <td>{{ elem.label }}</td>
          <td>
            <span class="elem-type-badge" [ngClass]="elem.elementType.toLowerCase()">
              {{ elem.elementType }}
            </span>
          </td>
          <td>
            <app-access-level-pill
              [value]="elem.access"
              (levelChange)="onElementClick(elem.elementId, $event)">
            </app-access-level-pill>
          </td>
          <td>
            <span class="inherit-badge" [class.inherited]="elem.inherited" [class.overridden]="!elem.inherited">
              {{ (elem.inherited ? 'permissions.badge.inherited' : 'permissions.badge.overridden') | transloco }}
            </span>
          </td>
        </tr>
      </tbody>
    </table>
  </div>

</div>
```

### 8.4 Pills de nivel de acceso: `AccessLevelPillComponent`

```typescript
@Component({
  selector: 'app-access-level-pill',
  standalone: true,
  template: `
    <div class="access-pills">
      <button *ngFor="let level of levels"
              class="access-pill"
              [class.active]="value === level"
              [ngClass]="level"
              type="button"
              (click)="levelChange.emit(level)">
        {{ level.toUpperCase() }}
      </button>
    </div>
  `
})
export class AccessLevelPillComponent {
  @Input() value: AccessLevel = 'hidden';
  @Output() levelChange = new EventEmitter<AccessLevel>();
  readonly levels: AccessLevel[] = ['hidden', 'view', 'execute'];
}
```

---

## 9. Template principal `PermissionsPageComponent`

```html
<app-navbar></app-navbar>

<div class="page-wrap module-shell">
  <div class="layout module-layout">
    <app-sidebar></app-sidebar>

    <main class="content module-content">

      <!-- Cabecera -->
      <header class="page-header module-header">
        <div class="module-title-group">
          <h1 class="module-title">{{ 'permissions.header.title' | transloco }}</h1>
          <p class="subtitle module-subtitle">{{ 'permissions.header.subtitle' | transloco }}</p>
        </div>
      </header>

      <!-- Feedback global -->
      <section class="feedback module-feedback" *ngIf="errorMessage">
        <div class="alert module-alert error">{{ errorMessage }}</div>
      </section>

      <!-- Selector de rol -->
      <section class="card module-card role-selector-card">
        <app-role-selector
          [roles]="roles"
          [selectedRoleId]="selectedRoleId"
          (roleChange)="onRoleChange($event)">
        </app-role-selector>
      </section>

      <!-- Toolbar: búsqueda + acciones lote -->
      <section class="card module-card toolbar module-toolbar">
        <div class="search-block">
          <label for="compSearch">{{ 'permissions.search.label' | transloco }}</label>
          <input id="compSearch" type="text"
                 [placeholder]="'permissions.search.placeholder' | transloco"
                 [value]="searchTerm"
                 (input)="searchTerm = $any($event.target).value" />
        </div>
        <div class="toolbar-actions module-toolbar-actions">
          <button class="btn btn-secondary" type="button"
                  (click)="applyViewToAll()"
                  [disabled]="saving">
            {{ 'permissions.actions.applyViewAll' | transloco }}
          </button>
          <button class="btn btn-primary" type="button"
                  (click)="saveChanges()"
                  [disabled]="saving || !hasPendingChanges">
            <span *ngIf="saving" class="btn-spinner"></span>
            {{ saving ? ('permissions.actions.saving' | transloco) : ('permissions.actions.save' | transloco) }}
          </button>
        </div>
      </section>

      <!-- Lista de componentes en acordeón -->
      <section class="card module-card accordion-card">
        <div class="loading" *ngIf="loading">{{ 'permissions.list.loading' | transloco }}</div>

        <ng-container *ngIf="!loading">
          <div class="empty" *ngIf="!filteredComponents.length">
            {{ 'permissions.list.empty' | transloco }}
          </div>

          <div class="accordion-list" *ngIf="filteredComponents.length">
            <app-component-accordion-item
              *ngFor="let comp of filteredComponents"
              [component]="comp"
              (toggleExpand)="toggleAccordion($event)"
              (accessChange)="onComponentAccessChange($event.componentId, $event.level)"
              (elementAccessChange)="onElementAccessChange($event.componentId, $event.elementId, $event.level)">
            </app-component-accordion-item>
          </div>
        </ng-container>
      </section>

    </main>
  </div>
</div>

<!-- Toast de éxito -->
<div class="toast-container" *ngIf="showToast">
  <div class="toast toast-success">
    <span class="toast-icon">✓</span>
    <span>{{ toastMessage | transloco }}</span>
  </div>
</div>
```

---

## 10. SCSS — Estilos específicos del módulo

```scss
// ── Selector de rol ────────────────────────────────────────────
.role-selector-card {
  display: flex;
  align-items: center;
  padding: 16px 20px;
  gap: 16px;
}

.role-selector-block {
  display: flex;
  align-items: center;
  gap: 12px;

  .role-selector-label {
    font-size: .75rem;
    font-weight: 700;
    letter-spacing: .08em;
    text-transform: uppercase;
    color: var(--color-text-secondary);
  }

  .role-selector-select {
    padding: 8px 12px;
    border-radius: 8px;
    border: 1px solid var(--color-border-medium);
    background: var(--color-bg-secondary);
    font-weight: 600;
    min-width: 180px;
  }
}

// ── Acordeón ───────────────────────────────────────────────────
.accordion-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.accordion-item {
  border: 1px solid var(--color-border-light);
  border-radius: 10px;
  overflow: hidden;
  transition: border-color .15s;

  &.dirty { border-color: var(--color-interactive-primary); }

  &.expanded .accordion-header { border-bottom: 1px solid var(--color-border-light); }
}

.accordion-header {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 14px 16px;
  background: var(--color-bg-secondary);
  cursor: pointer;
  user-select: none;

  &:hover { background: var(--color-surface); }
}

.accordion-arrow { font-size: .8rem; color: var(--color-text-secondary); width: 16px; }

.accordion-info {
  flex: 1;
  min-width: 0;

  .accordion-name { display: block; font-weight: 600; font-size: .875rem; }
  .accordion-route { display: block; font-size: .75rem; color: var(--color-text-secondary); }
}

.accordion-body { padding: 0; }

// ── Tabla de elementos ─────────────────────────────────────────
.elements-table {
  width: 100%;
  border-collapse: collapse;

  thead th {
    padding: 10px 16px;
    font-size: .72rem;
    font-weight: 700;
    letter-spacing: .05em;
    text-transform: uppercase;
    color: var(--color-text-secondary);
    text-align: left;
    border-bottom: 1px solid var(--color-border-light);
  }

  tbody tr {
    border-bottom: 1px solid var(--color-border-light);
    &:last-child { border-bottom: none; }
    &:hover { background: var(--color-bg-secondary); }
    &.dirty { background: rgba(var(--color-interactive-primary-rgb), .04); }
  }

  td { padding: 10px 16px; font-size: .85rem; }
}

.elem-key { font-family: monospace; font-size: .78rem; color: var(--color-text-secondary); }

.elem-type-badge {
  display: inline-block;
  padding: 2px 8px;
  border-radius: 4px;
  font-size: .7rem;
  font-weight: 700;
  text-transform: uppercase;

  &.button  { background: rgba(139, 92, 246, .12); color: #6d28d9; }
  &.field   { background: rgba(59, 130, 246, .12);  color: #1d4ed8; }
  &.tab     { background: rgba(16, 185, 129, .12);  color: #065f46; }
}

// ── Pills de nivel de acceso ───────────────────────────────────
.access-pills {
  display: inline-flex;
  border: 1px solid var(--color-border-light);
  border-radius: 8px;
  overflow: hidden;
}

.access-pill {
  padding: 5px 12px;
  font-size: .72rem;
  font-weight: 700;
  letter-spacing: .04em;
  background: var(--color-bg-secondary);
  border: none;
  cursor: pointer;
  transition: background .12s, color .12s;

  &:not(:last-child) { border-right: 1px solid var(--color-border-light); }

  &:hover { filter: brightness(.95); }

  &.active {
    &.hidden  { background: #6b7280; color: #fff; }
    &.view    { background: var(--color-interactive-primary); color: #fff; }
    &.execute { background: #10b981; color: #fff; }
  }

  &:not(.active) { color: var(--color-text-secondary); }
}

// ── Badges Inherited / Overridden ──────────────────────────────
.inherit-badge {
  display: inline-block;
  padding: 2px 8px;
  border-radius: 6px;
  font-size: .7rem;
  font-weight: 600;

  &.inherited  { background: rgba(107,114,128,.12); color: #6b7280; }
  &.overridden { background: rgba(59,130,246,.12);  color: #1d4ed8; }
}

// ── Toast ──────────────────────────────────────────────────────
.toast-container {
  position: fixed;
  bottom: 24px;
  right: 24px;
  z-index: 9999;
}

.toast {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 12px 20px;
  border-radius: 10px;
  font-size: .875rem;
  font-weight: 500;
  box-shadow: 0 4px 16px rgba(0,0,0,.12);
  animation: toast-in .2s ease-out;

  &.toast-success { background: #10b981; color: #fff; }
  .toast-icon { font-size: 1rem; }
}

@keyframes toast-in {
  from { opacity: 0; transform: translateY(12px); }
  to   { opacity: 1; transform: translateY(0); }
}
```

---

## 11. i18n — Claves de traducción

Estructura en `es.json` / `en.json`:

```json
"permissions": {
  "header": {
    "title": "Permisos de Componentes",
    "subtitle": "Gestiona el acceso por rol a cada componente y sus elementos"
  },
  "roleSelector": {
    "label": "ROL SELECCIONADO"
  },
  "search": {
    "label": "Buscar componente",
    "placeholder": "Filtrar componentes..."
  },
  "actions": {
    "applyViewAll": "Aplicar VIEW a todos",
    "save": "Guardar Cambios",
    "saving": "Guardando..."
  },
  "list": {
    "loading": "Cargando componentes...",
    "empty": "No se encontraron componentes."
  },
  "elements": {
    "empty": "Este componente no tiene elementos registrados."
  },
  "table": {
    "elementKey": "Element Key",
    "label": "Label",
    "type": "Type",
    "accessLevel": "Access Level",
    "status": "Status"
  },
  "badge": {
    "inherited": "Inherited",
    "overridden": "Overridden"
  },
  "success": {
    "updated": "Permissions updated successfully"
  },
  "errors": {
    "loadMatrix": "Error al cargar la matriz de permisos.",
    "save": "Error al guardar los cambios. Intente nuevamente."
  }
}
```

---

## 12. Fase 2 — Integración con backend

### 12.1 Servicio Angular: `PermissionService`

```typescript
@Injectable({ providedIn: 'root' })
export class PermissionService {
  private readonly baseUrl = `${environment.apiUrl}/api/v1/menu`;

  constructor(private http: HttpClient) {}

  getPermissionMatrix(tenantId: string, roleId: string): Observable<RolePermissionMatrixResponse> {
    return this.http.get<RolePermissionMatrixResponse>(
      `${this.baseUrl}/permissions/roles/${roleId}`,
      { headers: { 'X-Tenant-Id': tenantId } }
    );
  }

  upsertComponentPermission(
    tenantId: string, actorId: string,
    roleId: string, componentId: string,
    access: string
  ): Observable<ComponentPermissionResultResponse> {
    return this.http.put<ComponentPermissionResultResponse>(
      `${this.baseUrl}/permissions/roles/${roleId}/components/${componentId}`,
      { access },
      { headers: { 'X-Tenant-Id': tenantId, 'X-Actor-Id': actorId } }
    );
  }

  batchUpsertComponentPermissions(
    tenantId: string, actorId: string,
    roleId: string,
    permissions: Array<{ componentId: string; access: string }>
  ): Observable<ComponentPermissionResultResponse[]> {
    return this.http.put<ComponentPermissionResultResponse[]>(
      `${this.baseUrl}/permissions/roles/${roleId}/components/batch`,
      { permissions },
      { headers: { 'X-Tenant-Id': tenantId, 'X-Actor-Id': actorId } }
    );
  }

  upsertElementPermission(
    tenantId: string, actorId: string,
    roleId: string, elementId: string,
    access: string
  ): Observable<ElementPermissionResultResponse> {
    return this.http.put<ElementPermissionResultResponse>(
      `${this.baseUrl}/permissions/roles/${roleId}/elements/${elementId}`,
      { access },
      { headers: { 'X-Tenant-Id': tenantId, 'X-Actor-Id': actorId } }
    );
  }
}

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
```

### 12.2 `ComponentService`

```typescript
@Injectable({ providedIn: 'root' })
export class ComponentService {
  private readonly baseUrl = `${environment.apiUrl}/api/v1/menu`;

  constructor(private http: HttpClient) {}

  listComponents(
    tenantId: string,
    search?: string, isSystem?: boolean,
    page = 0, size = 20
  ): Observable<PageResponse<ComponentSummaryResponse>> {
    let params = new HttpParams().set('page', page).set('size', size);
    if (search) params = params.set('search', search);
    if (isSystem != null) params = params.set('isSystem', isSystem);
    return this.http.get<PageResponse<ComponentSummaryResponse>>(
      `${this.baseUrl}/components`, { params, headers: { 'X-Tenant-Id': tenantId } }
    );
  }
}
```

### 12.3 Cambios en `PermissionsPageComponent` para Fase 2

Reemplazar el cuerpo de `loadMatrix()` por:

```typescript
async loadMatrix(): Promise<void> {
  this.loading = true;
  this.clearMessages();
  try {
    const matrix = await firstValueFrom(
      this.permissionService.getPermissionMatrix(this.tenantId, this.selectedRoleId)
    );
    this.components = matrix.components.map(c => ({
      ...c,
      elements: c.elements.map(e => ({ ...e, dirty: false })),
      expanded: false,
      dirty: false,
    }));
  } catch (e: any) {
    this.errorMessage = e?.error?.message || 'permissions.errors.loadMatrix';
  } finally {
    this.loading = false;
  }
}
```

Reemplazar `saveChanges()` por guardado real con lote + elementos:

```typescript
async saveChanges(): Promise<void> {
  this.saving = true;
  this.clearMessages();
  try {
    const dirtyComponents = this.components.filter(c => c.dirty);
    const dirtyElements = this.components.flatMap(c =>
      c.elements.filter((e: any) => e.dirty).map((e: any) => ({ ...e, componentId: c.componentId }))
    );

    // Batch para componentes sucios
    if (dirtyComponents.length > 0) {
      await firstValueFrom(
        this.permissionService.batchUpsertComponentPermissions(
          this.tenantId, this.actorId, this.selectedRoleId,
          dirtyComponents.map(c => ({ componentId: c.componentId, access: c.access }))
        )
      );
    }

    // Individual para elementos sucios
    for (const elem of dirtyElements) {
      await firstValueFrom(
        this.permissionService.upsertElementPermission(
          this.tenantId, this.actorId,
          this.selectedRoleId, elem.elementId, elem.access
        )
      );
    }

    this.components.forEach(c => {
      c.dirty = false;
      c.elements.forEach((e: any) => e.dirty = false);
    });
    this.showSuccessToast('permissions.success.updated');
  } catch (e: any) {
    this.errorMessage = e?.error?.message || 'permissions.errors.save';
  } finally {
    this.saving = false;
  }
}
```

---

## 13. Trazabilidad API → Pantallas

| Pantalla / Acción | Endpoint | Fase |
|---|---|---|
| Cargar lista de roles (selector) | `GET /api/v1/roles` | 2 |
| Cargar matriz de permisos del rol | `GET /api/v1/menu/permissions/roles/{roleId}` | 2 |
| Guardar nivel de acceso (componente individual) | `PUT /api/v1/menu/permissions/roles/{roleId}/components/{componentId}` | 2 |
| Guardar nivel de acceso (lote Apply VIEW to all) | `PUT /api/v1/menu/permissions/roles/{roleId}/components/batch` | 2 |
| Guardar nivel de acceso (elemento individual) | `PUT /api/v1/menu/permissions/roles/{roleId}/elements/{elementId}` | 2 |
| Listar componentes (búsqueda avanzada) | `GET /api/v1/menu/components` | 2 (opcional) |
| Ver detalle de componente | `GET /api/v1/menu/components/{componentId}` | 2 (opcional) |

---

## 14. Estados y manejo de errores

| Estado | Comportamiento |
|---|---|
| Loading matriz | Spinner o texto de carga en lugar del acordeón |
| Empty state (sin componentes) | Ilustración + mensaje "No hay componentes registrados" |
| Empty elements (componente sin elementos) | Mensaje dentro del acordeón expandido |
| Dirty (cambios pendientes) | Borde azul en acordeón + botón Save habilitado |
| Saving | Botón Save con spinner + disabled; botón Apply deshabilitado |
| Éxito de guardado | Toast verde (3s auto-dismiss) en esquina inferior derecha |
| Error de API (carga) | Alerta `error` en zona feedback + mensaje descriptivo |
| Error de API (guardado) | Alerta `error` en zona feedback; cambios no se limpian |
| Error 422 (componentes inválidos) | Mensaje mapeado desde código `NXC-PRM-0002` |
| Error 404 (rol no encontrado) | Mensaje mapeado desde código `NXC-PRM-0001` |

---

## 15. Criterios de aceptación globales del módulo

### Fase 1

1. La pantalla carga con datos mock y muestra la lista de componentes en acordeón.
2. Al hacer clic en un componente el acordeón se expande mostrando la tabla de elementos.
3. Al hacer clic en una pill (HIDDEN / VIEW / EXECUTE) en el header del componente, el nivel cambia visualmente y el acordeón muestra borde azul (dirty).
4. Los elementos con `inherited: true` actualizan su acceso al mismo nivel cuando cambia el componente padre.
5. Al hacer clic en una pill de un elemento, el badge cambia de `Inherited` a `Overridden` y el nivel se actualiza.
6. El botón **Guardar Cambios** está deshabilitado cuando no hay cambios pendientes.
7. Al hacer clic en **Apply VIEW to all**, todos los componentes pasan a nivel `view` y el botón Guardar se habilita.
8. Al hacer clic en **Guardar Cambios**, aparece el spinner, luego el toast de éxito, y los bordes de dirty desaparecen.
9. El campo de filtro filtra la lista de componentes por nombre o ruta en tiempo real.
10. El selector de rol permite cambiar el rol activo y recarga la matriz mock.

### Fase 2

11. Al cargar la pantalla se consume `GET /api/v1/menu/permissions/roles/{roleId}` con `X-Tenant-Id` correcto.
12. Al guardar componentes dirty se ejecuta el endpoint batch con todos los cambios en una sola llamada.
13. Al guardar elementos dirty se ejecutan los PUTs individuales secuencialmente.
14. Si el backend retorna error `NXC-PRM-0002`, se muestra el mensaje de negocio descriptivo.
15. Los headers `X-Tenant-Id` y `X-Actor-Id` se envían en todos los requests de escritura.

---

## 16. Fuera de alcance

1. Implementación o modificación de endpoints backend.
2. Rediseño de header, sidebar o sistema de navegación global.
3. Creación o edición de componentes del sistema (eso es responsabilidad de seeds/scripts en backend).
4. Gestión de permisos entre tenants (cada tenant gestiona solo sus propios permisos).
5. Auditoría o historial de cambios de permisos.
6. Bulk import de configuraciones de permisos desde CSV u otro formato externo.
