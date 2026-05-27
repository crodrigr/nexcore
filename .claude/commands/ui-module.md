# NexCore — Guía de diseño de módulos UI

Cuando el usuario pida crear o ajustar una interfaz de módulo (feature page), sigue
**exactamente** estos patrones establecidos en los módulos `tenants` y `users`.
Nunca inventes estructuras nuevas; extiende las existentes.

---

## 1. Estructura HTML de página

```html
<app-navbar></app-navbar>

<div class="page-wrap module-shell">
  <div class="layout module-layout">
    <app-sidebar></app-sidebar>

    <main class="content module-content">

      <!-- Cabecera -->
      <header class="page-header module-header">
        <div class="module-title-group">
          <h1 class="module-title">{{ 'module.header.title' | transloco }}</h1>
          <p class="subtitle module-subtitle">{{ 'module.header.subtitle' | transloco }}</p>
        </div>
      </header>

      <!-- Tabs (si aplica) -->
      <div class="tabs"> ... </div>

      <!-- Toolbar (búsqueda + filtros + paginador + acciones) -->
      <section class="card module-card toolbar module-toolbar"> ... </section>

      <!-- Tabla -->
      <section class="card module-card table-card"> ... </section>

    </main>
  </div>
</div>

<!-- Modales al final del template -->

<!-- Toast (siempre al final, fuera del page-wrap) -->
<div class="toast-container" *ngIf="showToast">
  <div class="toast" [class.toast-success]="toastType === 'success'" [class.toast-error]="toastType === 'error'">
    <span class="toast-icon">{{ toastType === 'success' ? '✓' : '✕' }}</span>
    <span>{{ toastMessage | transloco }}</span>
  </div>
</div>
```

---

## 2. Toolbar

```html
<section class="card module-card toolbar module-toolbar">
  <!-- Izquierda: búsqueda -->
  <div class="search-block">
    <label for="search">{{ 'module.search.label' | transloco }}</label>
    <input id="search" type="text" [placeholder]="'module.search.placeholder' | transloco"
           [value]="searchTerm" (input)="onSearchChange($any($event.target).value)" />
  </div>

  <!-- Derecha: filtro + paginador + botones acción -->
  <div class="toolbar-actions module-toolbar-actions">
    <!-- Filtro de estado -->
    <div class="filter-block">
      <label>{{ 'module.filter.status' | transloco }}</label>
      <select [ngModel]="statusFilter" [ngModelOptions]="{standalone:true}" (ngModelChange)="onStatusChange($event)">
        <option *ngFor="let opt of statusOptions" [value]="opt.value">{{ opt.label | transloco }}</option>
      </select>
    </div>

    <!-- Paginador -->
    <div class="toolbar-pager" *ngIf="!loading">
      <div class="pager-left">
        <span class="pager-meta">{{ 'module.pager.range' | transloco:{start,end,total} }}</span>
        <select class="page-size-select" [ngModel]="pageSize" [ngModelOptions]="{standalone:true}"
                (ngModelChange)="onPageSizeChange($event)">
          <option *ngFor="let s of pageSizeOptions" [ngValue]="s">{{ s }}</option>
        </select>
      </div>
      <div class="pager-controls">
        <button class="pager-btn" [disabled]="page===0" (click)="goToPage(0)">&laquo;</button>
        <button class="pager-btn" [disabled]="page===0" (click)="goToPage(page-1)">&lsaquo;</button>
        <button class="pager-btn" [disabled]="page>=totalPages-1" (click)="goToPage(page+1)">&rsaquo;</button>
        <button class="pager-btn" [disabled]="page>=totalPages-1" (click)="goToPage(totalPages-1)">&raquo;</button>
      </div>
    </div>

    <!-- Botones de acción principales -->
    <button class="btn btn-primary" type="button" (click)="openCreateModal()">
      {{ 'module.actions.create' | transloco }}
    </button>
  </div>
</section>
```

**Regla de altura:** los botones `.btn` dentro de `.toolbar-actions` deben recibir la clase
`.toolbar-actions > .btn` (ya definida en SCSS) para igualar la altura del paginador (44 px,
border-radius 12 px).

---

## 3. Tabla

```html
<section class="card module-card table-card">
  <div class="loading" *ngIf="loading">{{ 'module.list.loading' | transloco }}</div>

  <ng-container *ngIf="!loading">
    <!-- Estado vacío -->
    <div class="empty" *ngIf="!items.length">
      <!-- SVG ilustrativo + mensaje + CTA -->
    </div>

    <div class="table-wrap" *ngIf="items.length" [class.refreshing]="refreshing">
      <table>
        <thead>
          <tr>
            <!-- Columna ordenable -->
            <th>
              <button class="sort-btn" type="button" (click)="toggleSort('field')">
                {{ 'module.table.field' | transloco }}
                <span class="sort-indicator" [class.asc]="isSortedAsc('field')" [class.desc]="isSortedDesc('field')">
                  <span class="sort-chevron up">▲</span>
                  <span class="sort-chevron down">▼</span>
                </span>
              </button>
            </th>
            <!-- Columna normal -->
            <th>{{ 'module.table.other' | transloco }}</th>
          </tr>
        </thead>
        <tbody>
          <tr *ngFor="let item of items">
            <!-- Celda de usuario / entidad con avatar -->
            <td>
              <div class="user-cell">
                <div class="user-avatar" [ngClass]="avatarClass(item)">{{ initials(item) }}</div>
                <div class="user-meta">
                  <div class="user-name">{{ item.name }}</div>
                  <div class="user-email">{{ item.email }}</div>
                </div>
              </div>
            </td>

            <!-- Chip de estado -->
            <td>
              <span class="status-chip" [ngClass]="statusClass(item.status)">{{ item.status }}</span>
            </td>

            <!-- Chips de roles -->
            <td>
              <div class="role-chips">
                <span *ngFor="let role of item.roles" class="role-chip" [class.system]="isSystem(role)">
                  {{ role.name }}
                </span>
                <span *ngIf="!item.roles?.length" class="role-chip-empty">—</span>
              </div>
            </td>

            <!-- Fecha -->
            <td class="date-cell">{{ item.createdAt | date:'yyyy-MM-dd HH:mm' }}</td>

            <!-- Acciones -->
            <td>
              <div class="actions">
                <button class="btn btn-secondary btn-sm" type="button" (click)="openEdit(item)">
                  {{ 'module.actions.edit' | transloco }}
                </button>
                <button class="btn btn-danger btn-sm" type="button" (click)="openDelete(item)">
                  {{ 'module.actions.delete' | transloco }}
                </button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </ng-container>
</section>
```

---

## 4. Botones — reglas y variantes

| Clase | Uso | Altura |
|---|---|---|
| `btn btn-primary` | Acción principal (crear, guardar, confirmar) | 36 px (44 px en toolbar) |
| `btn btn-secondary` | Acción neutra (editar, cancelar, reenviar) | 36 px (44 px en toolbar) |
| `btn btn-danger` | Acción destructiva (eliminar, suspender, revocar) | 36 px |
| `btn btn-success` | Acción afirmativa (activar) | 36 px |
| `btn btn-ghost` | Acción de bajo énfasis (eliminar soft) | 36 px |
| `btn-sm` | Botones dentro de tabla (`actions`) | 32 px |
| `btn-fixed` | Botón de tabla con ancho mínimo estable (ej. Resend) | min-width 88 px |

**Spinner en botones de submit / acción asíncrona:**
```html
<button class="btn btn-primary" [disabled]="submitting">
  <span *ngIf="submitting" class="btn-spinner"></span>
  {{ submitting ? ('module.actions.saving' | transloco) : ('module.actions.save' | transloco) }}
</button>
```
Para botones pequeños de tabla con acción rápida (ej. Resend) no cambiar el texto,
solo mostrar el spinner, y usar `btn-fixed` para evitar cambio de tamaño.

**Igualdad de altura entre btn-secondary y btn-danger:** el `.btn` base lleva
`box-sizing: border-box` para que el `border: 1px solid` del secondary no añada altura extra.

---

## 5. Modales

### Modal simple (confirmación / eliminación)
```html
<div class="modal-backdrop" *ngIf="showModal">
  <section class="modal">
    <header class="modal-header [danger-header]">
      <h2>{{ 'module.modal.title' | transloco }}</h2>
      <!-- sin botón cerrar en modales destructivos -->
    </header>
    <div class="modal-body">
      <p>{{ 'module.modal.message' | transloco }} <strong>{{ selectedItem?.name }}</strong>.</p>
      <p class="modal-warning">{{ 'module.modal.warning' | transloco }}</p>
    </div>
    <footer class="modal-actions">
      <button class="btn btn-secondary" (click)="closeModal()">{{ 'shared.actions.cancel' | transloco }}</button>
      <button class="btn btn-danger" [disabled]="submitting" (click)="confirm()">
        <span *ngIf="submitting" class="btn-spinner"></span>
        {{ submitting ? ('module.actions.deleting' | transloco) : ('module.actions.delete' | transloco) }}
      </button>
    </footer>
  </section>
</div>
```

### Modal de formulario (crear / editar)
```html
<div class="modal-backdrop" *ngIf="showFormModal">
  <section class="modal modal-lg user-form-shell">
    <header class="modal-header user-topbar">
      <div class="user-head">
        <h2>{{ 'module.form.title' | transloco }}</h2>
        <p>{{ 'module.form.description' | transloco }}</p>
      </div>
      <button class="icon-btn" type="button" (click)="closeFormModal()">✕</button>
    </header>

    <form [formGroup]="form" (ngSubmit)="submitForm()" class="user-form-body">
      <!-- Sección de campos -->
      <section class="user-form-card">
        <header class="user-section-head">
          <div class="section-icon blue">IC</div>
          <div>
            <h3>{{ 'module.sections.basic.title' | transloco }}</h3>
            <p>{{ 'module.sections.basic.description' | transloco }}</p>
          </div>
        </header>
        <div class="field-grid two-col">  <!-- o one-col -->
          <label>{{ 'module.fields.name' | transloco }} *
            <input formControlName="name" [placeholder]="'module.placeholders.name' | transloco" />
            <small class="error" *ngIf="form.controls.name.touched && form.controls.name.invalid">
              {{ 'module.validation.name' | transloco }}
            </small>
          </label>
        </div>
      </section>

      <!-- Toggle (boolean field) -->
      <section class="user-form-card">
        <div class="toggle-row">
          <div class="toggle-info">
            <div class="toggle-label">{{ 'module.fields.toggle' | transloco }}</div>
            <div class="toggle-desc">{{ 'module.fields.toggleHint' | transloco }}</div>
          </div>
          <label class="toggle">
            <input type="checkbox" formControlName="toggle" />
            <span class="toggle-track"></span>
            <span class="toggle-thumb"></span>
          </label>
        </div>
      </section>

      <div class="user-form-footer-gap" aria-hidden="true"></div>
      <footer class="user-form-footer">
        <div class="footer-actions">
          <button type="button" class="btn btn-secondary" (click)="closeFormModal()">
            {{ 'shared.actions.cancel' | transloco }}
          </button>
          <button type="submit" class="btn btn-primary" [disabled]="submitting">
            <span *ngIf="submitting" class="btn-spinner"></span>
            {{ submitting ? ('module.actions.saving' | transloco) : ('module.actions.save' | transloco) }}
          </button>
        </div>
      </footer>
    </form>
  </section>
</div>
```

---

## 6. i18n — estructura de claves

Todo texto usa `transloco`. Estructura de claves en `es.json` / `en.json`:

```json
"module": {
  "header":      { "title": "...", "subtitle": "..." },
  "tabs":        { "tab1": "...", "tab2": "..." },
  "search":      { "label": "...", "placeholder": "..." },
  "filter":      { "status": "...", "allStatuses": "Todos" },
  "pager":       { "range": "{{start}}–{{end}} de {{total}}" },
  "list":        { "loading": "...", "empty": "..." },
  "table":       { "col1": "...", "col2": "...", "actions": "Acciones" },
  "status":      { "ACTIVE": "ACTIVO", "SUSPENDED": "SUSPENDIDO" },
  "actions": {
    "create": "Crear", "creating": "Creando...",
    "save": "Guardar", "saving": "Guardando...",
    "edit": "Editar", "delete": "Eliminar", "deleting": "Eliminando...",
    "suspend": "Suspender", "suspending": "Suspendiendo...",
    "activate": "Activar", "activating": "Activando...",
    "cancel": "Cancelar"
  },
  "sections":    { "basic": { "title": "...", "description": "..." } },
  "fields":      { "name": "Nombre", "email": "Correo" },
  "placeholders":{ "name": "ej. Mi empresa" },
  "validation":  { "name": "El nombre es requerido (mín. 3 caracteres)." },
  "errors": {
    "loadItems": "...", "createItem": "...", "updateItem": "...", "deleteItem": "..."
  },
  "success": {
    "itemCreated": "...", "itemUpdated": "...", "itemDeleted": "..."
  }
}
```

**Regla:** añadir SIEMPRE las claves en `es.json` y `en.json` en paralelo.
Para chips de estado con clave dinámica usar: `('module.status.' + item.status) | transloco`.

---

## 7. TypeScript — Component patterns

```typescript
@Component({ standalone: true, ... })
export class ModuleComponent implements OnInit {

  // ── Estado de carga ────────────────────────────────
  loading = false;
  refreshing = false;
  submitting = false;

  // ── Toast ──────────────────────────────────────────
  showToast = false;
  toastMessage = '';
  toastType: 'success' | 'error' = 'success';

  // ── Datos ─────────────────────────────────────────
  items: ItemRecord[] = [];
  selectedItem: ItemRecord | null = null;

  // ── Paginación ─────────────────────────────────────
  page = 0;
  pageSize = 10;
  totalElements = 0;
  totalPages = 0;
  pageSizeOptions = [10, 25, 50];

  // ── Búsqueda y filtros ─────────────────────────────
  searchTerm = '';
  statusFilter = '';
  private searchSubject = new Subject<string>();

  // ── Modales ────────────────────────────────────────
  showCreateModal = false;
  showEditModal = false;
  showDeleteModal = false;

  // ── Formularios ────────────────────────────────────
  createForm = this.fb.nonNullable.group({ name: ['', [Validators.required, Validators.minLength(3)]] });

  ngOnInit(): void {
    this.searchSubject.pipe(debounceTime(300), distinctUntilChanged())
      .subscribe(() => { this.page = 0; this.loadItems(); });
    this.loadItems();
  }

  private triggerToast(key: string, type: 'success' | 'error' = 'success'): void {
    this.toastMessage = key;
    this.toastType = type;
    this.showToast = true;
    setTimeout(() => { this.showToast = false; }, 3500);
  }

  async loadItems(): Promise<void> {
    this.loading = true;
    try {
      const res = await firstValueFrom(this.service.list(this.page, this.pageSize, this.searchTerm, this.statusFilter));
      this.items = res.content;
      this.totalElements = res.totalElements;
      this.totalPages = res.totalPages;
    } catch (e: any) {
      this.triggerToast(e?.error?.message || 'module.errors.loadItems', 'error');
    } finally {
      this.loading = false;
    }
  }

  async submitCreate(): Promise<void> {
    this.createForm.markAllAsTouched();
    if (this.createForm.invalid) return;
    this.submitting = true;
    try {
      await firstValueFrom(this.service.create(this.createForm.getRawValue()));
      this.triggerToast('module.success.itemCreated');
      this.closeCreateModal();
      await this.loadItems();
    } catch (e: any) {
      this.triggerToast(e?.error?.message || 'module.errors.createItem', 'error');
    } finally {
      this.submitting = false;
    }
  }

  // Paginación
  get pageStart(): number { return this.totalElements === 0 ? 0 : this.page * this.pageSize + 1; }
  get pageEnd(): number   { return Math.min((this.page + 1) * this.pageSize, this.totalElements); }

  goToPage(p: number): void { this.page = p; this.loadItems(); }
  onPageSizeChange(s: number): void { this.pageSize = s; this.page = 0; this.loadItems(); }
  onSearchChange(v: string): void { this.searchTerm = v; this.searchSubject.next(v); }
  onStatusChange(v: string): void { this.statusFilter = v; this.page = 0; this.loadItems(); }
}
```

---

## 8. Service pattern (Angular)

```typescript
export interface ItemRecord {
  id: string;
  tenantId?: string;
  name: string;
  status: 'ACTIVE' | 'SUSPENDED';
  createdAt?: string;
}

@Injectable({ providedIn: 'root' })
export class ModuleService {
  private readonly baseUrl = `${environment.apiUrl}/api/v1`;

  constructor(private http: HttpClient) {}

  list(page: number, size: number, search?: string, status?: string): Observable<PageResponse<ItemRecord>> {
    let params = new HttpParams().set('page', page).set('size', size);
    if (search) params = params.set('search', search);
    if (status) params = params.set('status', status);
    return this.http.get<PageResponse<ItemRecord>>(`${this.baseUrl}/items`, { params });
  }

  create(payload: CreateItemRequest): Observable<ItemRecord> {
    return this.http.post<ItemRecord>(`${this.baseUrl}/items`, payload);
  }

  update(id: string, payload: UpdateItemRequest): Observable<ItemRecord> {
    return this.http.patch<ItemRecord>(`${this.baseUrl}/items/${id}`, payload);
  }

  delete(id: string): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/items/${id}`);
  }
}
```

---

## 9. SCSS — Variables y convenciones

Usar **siempre** variables CSS del design system. Nunca colores hardcodeados excepto
para estados de danger/success sin variable disponible.

```scss
// Fondo y superficies
var(--color-bg-primary)        // fondo principal
var(--color-bg-secondary)      // fondo de cards, inputs
var(--color-surface)           // superficies elevadas

// Texto
var(--color-text-primary)
var(--color-text-secondary)    // subtítulos, meta
var(--color-text-inverse)      // texto sobre fondos oscuros (botón primary)

// Bordes
var(--color-border-light)
var(--color-border-medium)

// Interacción
var(--color-interactive-primary)   // botón primary, focus ring
```

**Chips de estado:**
```scss
.status-chip {
  display: inline-flex; align-items: center;
  padding: 3px 10px; border-radius: 20px; font-size: .75rem; font-weight: 700;
  letter-spacing: .04em;
  &.active     { background: rgba(34,197,94,.15);  color: #15803d; }
  &.pending    { background: rgba(234,179,8,.15);  color: #92400e; }
  &.suspended  { background: rgba(239,68,68,.12);  color: #b91c1c; }
}
```

**Chips de roles:**
```scss
.role-chip {
  display: inline-block; padding: 2px 8px; border-radius: 6px; font-size: .72rem;
  font-weight: 600; background: var(--color-bg-secondary);
  border: 1px solid var(--color-border-light); color: var(--color-text-secondary);
  &.system { border-color: var(--color-interactive-primary); color: var(--color-interactive-primary); }
}
```

---

## 10. Toast — estilos SCSS

Agregar al final del archivo `.component.scss` del módulo:

```scss
// ── Toast ─────────────────────────────────────────────────────────────────────
.toast-container {
  position: fixed;
  bottom: 28px;
  right: 28px;
  z-index: 9999;
}

.toast {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 13px 20px;
  border-radius: 10px;
  font-size: .875rem;
  font-weight: 500;
  box-shadow: 0 4px 20px rgba(0,0,0,.14);
  animation: toast-slide-in .2s ease-out;

  &.toast-success { background: #10b981; color: #fff; }
  &.toast-error   { background: #ef4444; color: #fff; }
}

.toast-icon { font-size: 1.1rem; }

@keyframes toast-slide-in {
  from { opacity: 0; transform: translateY(16px); }
  to   { opacity: 1; transform: translateY(0); }
}
```

---

## 11. Reglas generales

1. **Un archivo por módulo**: `module.component.ts`, `module.component.html`, `module.component.scss`.
2. **standalone: true** en todos los componentes.
3. **No `ngModel` en formularios reactivos**; usar `formControlName`.
4. **`firstValueFrom`** para convertir Observables en promesas dentro de métodos `async`.
5. **`debounceTime(300) + distinctUntilChanged()`** en campos de búsqueda.
6. **Modales y toast al final del template**, fuera del `<main>`.
7. **`triggerToast(key, type?)`** para notificar éxito (`'success'`, default) o error (`'error'`); auto-dismiss a 3.5 s. Nunca usar `errorMessage`/`successMessage` en la parte superior.
8. **El tab activo** controla qué sección cargar; solo mostrar errores del tab activo.
9. **`loadRoles().then(() => loadInvitations())`** cuando una lista depende de un catálogo.
10. **`box-sizing: border-box`** en `.btn` para que border no rompa alturas.
