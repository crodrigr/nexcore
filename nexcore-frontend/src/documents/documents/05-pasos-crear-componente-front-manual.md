# 05 - Cómo Crear un Componente Frontend Manualmente — NexCore

> **Para quién es este documento:** Para cualquier persona que necesite agregar una nueva página/módulo al frontend de NexCore **sin usar el agente de IA**. No se asume conocimiento previo de Angular ni de la estructura del proyecto. Cada sección tiene código listo para copiar y pegar.

---

## Contexto: qué es NexCore Frontend

NexCore Frontend es una aplicación Angular 17 (standalone components). Cada "módulo" de la aplicación es una carpeta dentro de `src/app/features/`. El layout (sidebar + navbar) es compartido y ya está listo — tú solo tienes que crear la página interna.

### Estructura que ya existe (no tocar)

```
src/
├── app/
│   ├── app.routes.ts              ← Aquí registras la ruta de tu nuevo módulo
│   ├── features/                  ← Aquí van tus archivos
│   │   ├── dashboard/
│   │   ├── tenants/
│   │   ├── users/
│   │   └── (tu-nuevo-modulo/)     ← Lo crearás aquí
│   └── shared/
│       ├── layout/                ← Sidebar, Navbar, LayoutShell (NO modificar)
│       └── services/              ← Servicios compartidos (NO modificar)
├── assets/
│   └── i18n/
│       ├── en.json                ← Traducciones en inglés (agregar tus textos)
│       └── es.json                ← Traducciones en español (agregar tus textos)
└── styles.scss                    ← Estilos globales con clases reutilizables
```

---

## Resumen de pasos (lista rápida)

| # | Qué hacer | Archivo |
|---|-----------|---------|
| **1** | Crear la carpeta del módulo | `src/app/features/proyectos/` |
| **2** | Crear el servicio HTTP | `proyectos.service.ts` |
| **3** | Crear el componente TypeScript | `proyectos.component.ts` |
| **4** | Crear el template HTML | `proyectos.component.html` |
| **5** | Crear los estilos locales | `proyectos.component.scss` |
| **6** | Registrar la ruta | `src/app/app.routes.ts` |
| **7** | Agregar las traducciones | `src/assets/i18n/en.json` y `es.json` |
| **8** | Registrar menú + permisos en BD | Script SQL (ver doc 04) |

---

## Ejemplo práctico: Módulo "Proyectos"

Crearemos una página que lista proyectos con búsqueda, paginación, y botón de crear. Al terminar los 8 pasos tendrás una página funcional integrada con el sidebar y el navbar.

---

## Paso 1 — Crear la carpeta

Crea la carpeta manualmente o con terminal:

```bash
mkdir -p src/app/features/proyectos
```

Dentro de esa carpeta irán 4 archivos:
- `proyectos.service.ts`
- `proyectos.component.ts`
- `proyectos.component.html`
- `proyectos.component.scss`

---

## Paso 2 — Crear el servicio HTTP

El servicio se comunica con el backend. Crea el archivo:

**`src/app/features/proyectos/proyectos.service.ts`**

```typescript
import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

// ── Modelos de datos ──────────────────────────────────────────
export interface Proyecto {
  id: string;
  nombre: string;
  descripcion: string;
  estado: string;       // ACTIVO | INACTIVO | ARCHIVADO
  presupuesto: number;
  fechaInicio: string;  // ISO 8601: "2026-05-01"
  createdAt?: string;
  updatedAt?: string;
}

export interface ProyectoCreateRequest {
  nombre: string;
  descripcion: string;
  estado: string;
  presupuesto: number;
  fechaInicio: string;
}

export interface ProyectoUpdateRequest {
  nombre?: string;
  descripcion?: string;
  estado?: string;
  presupuesto?: number;
}

// Estructura de respuesta paginada del backend
export interface PageResponse<T> {
  content: T[];
  totalElements: number;
  totalPages: number;
  number: number;
  size: number;
}

// ── Servicio ──────────────────────────────────────────────────
@Injectable({ providedIn: 'root' })
export class ProyectosService {
  private readonly http = inject(HttpClient);

  // Cambia esta URL por la de tu API real
  private readonly baseUrl = `${environment.coreBaseUrl}/api/v1/proyectos`;

  private headers(): HttpHeaders {
    const token = localStorage.getItem('access_token') ?? '';
    return new HttpHeaders({ Authorization: `Bearer ${token}` });
  }

  getAll(page = 0, size = 10, search = ''): Observable<PageResponse<Proyecto>> {
    let params = new HttpParams()
      .set('page', page)
      .set('size', size);
    if (search.trim()) {
      params = params.set('search', search.trim());
    }
    return this.http.get<PageResponse<Proyecto>>(this.baseUrl, {
      headers: this.headers(),
      params
    });
  }

  getById(id: string): Observable<Proyecto> {
    return this.http.get<Proyecto>(`${this.baseUrl}/${id}`, {
      headers: this.headers()
    });
  }

  create(data: ProyectoCreateRequest): Observable<Proyecto> {
    return this.http.post<Proyecto>(this.baseUrl, data, {
      headers: this.headers()
    });
  }

  update(id: string, data: ProyectoUpdateRequest): Observable<Proyecto> {
    return this.http.put<Proyecto>(`${this.baseUrl}/${id}`, data, {
      headers: this.headers()
    });
  }

  delete(id: string): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/${id}`, {
      headers: this.headers()
    });
  }
}
```

**¿Qué hace este archivo?**
- Define las interfaces TypeScript (los "tipos" de datos que vienen del backend).
- Define el servicio con los métodos CRUD: `getAll`, `getById`, `create`, `update`, `delete`.
- El token JWT se lee automáticamente del `localStorage`.
- `environment.coreBaseUrl` viene de `src/environments/environment.ts`.

---

## Paso 3 — Crear el componente TypeScript

Este es el cerebro de tu página. Maneja el estado (datos, cargando, errores) y llama al servicio.

**`src/app/features/proyectos/proyectos.component.ts`**

```typescript
import { CommonModule } from '@angular/common';
import { Component, HostListener, OnInit, inject } from '@angular/core';
import { FormBuilder, FormsModule, ReactiveFormsModule, Validators } from '@angular/forms';
import { TranslocoModule } from '@ngneat/transloco';
import { firstValueFrom } from 'rxjs';
import {
  Proyecto,
  ProyectoCreateRequest,
  ProyectosService,
  PageResponse
} from './proyectos.service';

@Component({
  selector: 'app-proyectos',
  standalone: true,
  // Importa los módulos que el template va a usar
  imports: [CommonModule, FormsModule, ReactiveFormsModule, TranslocoModule],
  templateUrl: './proyectos.component.html',
  styleUrls: ['./proyectos.component.scss']
})
export class ProyectosComponent implements OnInit {
  // ── Inyección de dependencias ──────────────────────────────
  private readonly proyectosService = inject(ProyectosService);
  private readonly fb = inject(FormBuilder);

  // ── Estado de la lista ─────────────────────────────────────
  proyectos: Proyecto[] = [];
  loading = false;
  errorMessage = '';
  successMessage = '';

  // ── Búsqueda y paginación ──────────────────────────────────
  searchTerm = '';
  page = 0;
  size = 10;
  totalElements = 0;
  totalPages = 1;

  // ── Modal crear proyecto ───────────────────────────────────
  showCreateModal = false;
  submitting = false;

  createForm = this.fb.group({
    nombre:      ['', [Validators.required, Validators.minLength(3)]],
    descripcion: ['', Validators.required],
    estado:      ['ACTIVO', Validators.required],
    presupuesto: [0, [Validators.required, Validators.min(0)]],
    fechaInicio: ['', Validators.required]
  });

  // ── Ciclo de vida ──────────────────────────────────────────
  ngOnInit(): void {
    this.loadProyectos();
  }

  // ── Carga de datos ─────────────────────────────────────────
  async loadProyectos(): Promise<void> {
    this.loading = true;
    this.errorMessage = '';
    try {
      const res = await firstValueFrom(
        this.proyectosService.getAll(this.page, this.size, this.searchTerm)
      );
      this.proyectos = res.content;
      this.totalElements = res.totalElements;
      this.totalPages = res.totalPages;
    } catch (err: any) {
      this.errorMessage = err?.error?.message ?? 'Error al cargar proyectos';
    } finally {
      this.loading = false;
    }
  }

  // ── Búsqueda ───────────────────────────────────────────────
  onSearchChange(value: string): void {
    this.searchTerm = value;
    this.page = 0;
    this.loadProyectos();
  }

  // ── Paginación ─────────────────────────────────────────────
  prevPage(): void {
    if (this.page > 0) { this.page--; this.loadProyectos(); }
  }

  nextPage(): void {
    if (this.page < this.totalPages - 1) { this.page++; this.loadProyectos(); }
  }

  get pageStart(): number { return this.page * this.size + 1; }
  get pageEnd(): number   { return Math.min((this.page + 1) * this.size, this.totalElements); }

  // ── Modal: Crear proyecto ──────────────────────────────────
  openCreateModal(): void {
    this.createForm.reset({ estado: 'ACTIVO', presupuesto: 0 });
    this.submitting = false;
    this.showCreateModal = true;
  }

  closeCreateModal(): void {
    this.showCreateModal = false;
  }

  async submitCreate(): Promise<void> {
    if (this.createForm.invalid || this.submitting) return;
    this.submitting = true;
    this.errorMessage = '';
    try {
      const payload = this.createForm.value as ProyectoCreateRequest;
      await firstValueFrom(this.proyectosService.create(payload));
      this.successMessage = 'Proyecto creado correctamente';
      this.closeCreateModal();
      this.page = 0;
      await this.loadProyectos();
      setTimeout(() => this.successMessage = '', 4000);
    } catch (err: any) {
      this.errorMessage = err?.error?.message ?? 'Error al crear el proyecto';
    } finally {
      this.submitting = false;
    }
  }

  // ── Eliminar ───────────────────────────────────────────────
  async deleteProyecto(proyecto: Proyecto): Promise<void> {
    if (!confirm(`¿Eliminar "${proyecto.nombre}"?`)) return;
    try {
      await firstValueFrom(this.proyectosService.delete(proyecto.id));
      this.successMessage = 'Proyecto eliminado';
      await this.loadProyectos();
      setTimeout(() => this.successMessage = '', 4000);
    } catch (err: any) {
      this.errorMessage = err?.error?.message ?? 'Error al eliminar';
    }
  }

  // ── Cierra modal al hacer clic fuera ──────────────────────
  @HostListener('document:keydown.escape')
  onEscape(): void {
    this.closeCreateModal();
  }
}
```

**Puntos clave:**
- `standalone: true` — No necesita un NgModule. Es el patrón moderno de Angular 17.
- `imports: [CommonModule, ...]` — Todo lo que uses en el HTML (`*ngIf`, `*ngFor`, pipes, formularios) debe estar aquí.
- `inject()` — Forma moderna de inyectar dependencias (sin constructor).
- `firstValueFrom()` — Convierte un Observable del servicio a una Promesa para usar `await`.
- `@HostListener('document:keydown.escape')` — Cierra el modal al presionar Escape.

---

## Paso 4 — Crear el template HTML

Este es el archivo más largo. Contiene la estructura visual de la página.

**`src/app/features/proyectos/proyectos.component.html`**

```html
<!-- ─────────────────────────────────────────────────────────────
  CONTENEDOR PRINCIPAL
  Nota: <main class="content"> aplica el padding y margin-left
  desde styles.scss global, dejando espacio para el sidebar.
  Las clases "module-*" vienen de styles.scss y son reutilizables.
──────────────────────────────────────────────────────────────── -->
<main class="content">

  <!-- ── Cabecera de página ── -->
  <header class="module-header">
    <div class="module-title-group">
      <h1 class="module-title">{{ 'proyectos.header.title' | transloco }}</h1>
      <p class="module-subtitle">{{ 'proyectos.header.subtitle' | transloco }}</p>
    </div>
    <button class="btn-primary" type="button" (click)="openCreateModal()">
      + {{ 'proyectos.actions.create' | transloco }}
    </button>
  </header>

  <!-- ── Mensajes de éxito / error ── -->
  <section class="module-feedback" *ngIf="errorMessage || successMessage">
    <div class="module-alert error" *ngIf="errorMessage">{{ errorMessage }}</div>
    <div class="module-alert success" *ngIf="successMessage">{{ successMessage }}</div>
  </section>

  <!-- ── Barra de herramientas: búsqueda + paginación ── -->
  <section class="module-card module-toolbar">
    <div class="search-block">
      <label for="proj-search">{{ 'proyectos.search.label' | transloco }}</label>
      <input
        id="proj-search"
        type="text"
        [placeholder]="'proyectos.search.placeholder' | transloco"
        [value]="searchTerm"
        (input)="onSearchChange($any($event.target).value)"
      />
    </div>
    <div class="module-toolbar-actions">
      <div class="pager-info" *ngIf="!loading && totalElements > 0">
        {{ pageStart }}–{{ pageEnd }} de {{ totalElements }}
        <button class="pager-btn" [disabled]="page === 0" (click)="prevPage()">‹</button>
        <button class="pager-btn" [disabled]="page >= totalPages - 1" (click)="nextPage()">›</button>
      </div>
    </div>
  </section>

  <!-- ── Tabla de proyectos ── -->
  <section class="module-card">

    <!-- Estado: cargando -->
    <div class="loading-row" *ngIf="loading">Cargando...</div>

    <!-- Estado: sin resultados -->
    <div class="empty-row" *ngIf="!loading && proyectos.length === 0">
      {{ 'proyectos.empty' | transloco }}
    </div>

    <!-- Tabla real -->
    <div class="table-responsive" *ngIf="!loading && proyectos.length > 0">
      <table class="data-table">
        <thead>
          <tr>
            <th>{{ 'proyectos.table.nombre' | transloco }}</th>
            <th>{{ 'proyectos.table.descripcion' | transloco }}</th>
            <th>{{ 'proyectos.table.estado' | transloco }}</th>
            <th>{{ 'proyectos.table.presupuesto' | transloco }}</th>
            <th>{{ 'proyectos.table.fechaInicio' | transloco }}</th>
            <th>{{ 'proyectos.table.acciones' | transloco }}</th>
          </tr>
        </thead>
        <tbody>
          <tr *ngFor="let proyecto of proyectos">
            <td class="cell-nombre">{{ proyecto.nombre }}</td>
            <td class="cell-desc">{{ proyecto.descripcion }}</td>
            <td>
              <span class="badge" [class]="proyecto.estado | lowercase">
                {{ proyecto.estado }}
              </span>
            </td>
            <td>{{ proyecto.presupuesto | number:'1.0-0' }}</td>
            <td>{{ proyecto.fechaInicio }}</td>
            <td class="cell-actions">
              <button class="btn-icon btn-danger"
                      type="button"
                      title="Eliminar"
                      (click)="deleteProyecto(proyecto)">
                ✕
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

  </section>

</main>

<!-- ─────────────────────────────────────────────────────────────
  MODAL: Crear Proyecto
  Nota: los modales van FUERA de <main> para evitar que el
  padding/margin del contenido los desplace.
──────────────────────────────────────────────────────────────── -->
<div class="modal-backdrop" *ngIf="showCreateModal" (click)="closeCreateModal()">
  <section class="modal" (click)="$event.stopPropagation()">

    <header class="modal-header">
      <h2>{{ 'proyectos.create.title' | transloco }}</h2>
      <button class="btn-icon" type="button" (click)="closeCreateModal()">✕</button>
    </header>

    <form [formGroup]="createForm" (ngSubmit)="submitCreate()" class="modal-body">

      <div class="form-group">
        <label for="nombre">{{ 'proyectos.fields.nombre' | transloco }} *</label>
        <input id="nombre" type="text" formControlName="nombre" />
        <span class="field-error"
              *ngIf="createForm.get('nombre')?.invalid && createForm.get('nombre')?.touched">
          Requerido, mínimo 3 caracteres
        </span>
      </div>

      <div class="form-group">
        <label for="descripcion">{{ 'proyectos.fields.descripcion' | transloco }} *</label>
        <textarea id="descripcion" rows="3" formControlName="descripcion"></textarea>
      </div>

      <div class="form-row">
        <div class="form-group">
          <label for="estado">{{ 'proyectos.fields.estado' | transloco }}</label>
          <select id="estado" formControlName="estado">
            <option value="ACTIVO">Activo</option>
            <option value="INACTIVO">Inactivo</option>
            <option value="ARCHIVADO">Archivado</option>
          </select>
        </div>

        <div class="form-group">
          <label for="presupuesto">{{ 'proyectos.fields.presupuesto' | transloco }}</label>
          <input id="presupuesto" type="number" formControlName="presupuesto" min="0" />
        </div>
      </div>

      <div class="form-group">
        <label for="fechaInicio">{{ 'proyectos.fields.fechaInicio' | transloco }} *</label>
        <input id="fechaInicio" type="date" formControlName="fechaInicio" />
      </div>

      <footer class="modal-footer">
        <button type="button" class="btn-secondary" (click)="closeCreateModal()">
          {{ 'proyectos.actions.cancel' | transloco }}
        </button>
        <button type="submit" class="btn-primary"
                [disabled]="createForm.invalid || submitting">
          {{ submitting ? 'Guardando...' : ('proyectos.actions.save' | transloco) }}
        </button>
      </footer>

    </form>
  </section>
</div>
```

**Puntos clave del HTML:**
- `<main class="content">` — Esta clase es esencial. Está definida en `styles.scss` y aplica el `margin-left: 247px` que deja espacio para el sidebar fijo. Sin ella, el contenido quedaría debajo del sidebar.
- `module-*` — Las clases `module-header`, `module-card`, `module-feedback`, etc., son utilidades globales definidas en `styles.scss`. Úsalas en lugar de crear tus propias clases para estos contenedores comunes.
- `*ngIf` / `*ngFor` — Directivas de Angular para condicional y bucles. Vienen del `CommonModule`.
- `formGroup` / `formControlName` — Parte de `ReactiveFormsModule`. Conectan el HTML al formulario definido en el `.ts`.
- `'clave' | transloco` — Pipe de internacionalización. La clave debe existir en `en.json` / `es.json`.
- El modal va **fuera del** `<main>` — así el `padding` del contenido no lo afecta.

---

## Paso 5 — Crear los estilos locales

Los estilos locales solo aplican a este componente. Gracias al encapsulamiento de Angular, no afectan otros componentes aunque uses el mismo nombre de clase.

**`src/app/features/proyectos/proyectos.component.scss`**

```scss
// ── Tabla de datos ─────────────────────────────────────────────
.table-responsive {
  overflow-x: auto;
}

.data-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.88rem;

  th {
    text-align: left;
    padding: 10px 14px;
    font-weight: 600;
    color: var(--color-text-secondary);
    border-bottom: 2px solid var(--color-border-light);
    white-space: nowrap;
  }

  td {
    padding: 10px 14px;
    border-bottom: 1px solid var(--color-border-light);
    vertical-align: middle;
    color: var(--color-text-primary);
  }

  tbody tr:hover {
    background: var(--color-bg-hover, rgba(0,0,0,0.03));
  }
}

.cell-nombre {
  font-weight: 600;
  min-width: 140px;
}

.cell-desc {
  color: var(--color-text-secondary);
  max-width: 260px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.cell-actions {
  text-align: right;
  white-space: nowrap;
}

// ── Badges de estado ───────────────────────────────────────────
.badge {
  display: inline-block;
  padding: 3px 10px;
  border-radius: 20px;
  font-size: 0.78rem;
  font-weight: 600;
  letter-spacing: 0.02em;

  &.activo   { background: rgba(76,175,80,0.12); color: #2e7d32; }
  &.inactivo { background: rgba(158,158,158,0.15); color: #616161; }
  &.archivado { background: rgba(255,152,0,0.12); color: #e65100; }
}

// ── Búsqueda ───────────────────────────────────────────────────
.search-block {
  display: flex;
  flex-direction: column;
  gap: 4px;

  label {
    font-size: 0.82rem;
    color: var(--color-text-secondary);
  }

  input {
    padding: 7px 12px;
    border: 1px solid var(--color-border-light);
    border-radius: 8px;
    background: var(--color-bg-primary);
    color: var(--color-text-primary);
    font-size: 0.9rem;
    outline: none;
    min-width: 240px;

    &:focus {
      border-color: var(--color-interactive-primary);
    }
  }
}

// ── Paginador ──────────────────────────────────────────────────
.pager-info {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 0.85rem;
  color: var(--color-text-secondary);
}

.pager-btn {
  width: 28px;
  height: 28px;
  border: 1px solid var(--color-border-light);
  border-radius: 6px;
  background: var(--color-bg-primary);
  color: var(--color-text-primary);
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;

  &:disabled { opacity: 0.35; cursor: default; }
  &:not(:disabled):hover { background: var(--color-bg-hover, #f0f0f0); }
}

// ── Botones de la página ───────────────────────────────────────
.btn-primary {
  padding: 8px 18px;
  background: var(--color-interactive-primary);
  color: #fff;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  font-size: 0.9rem;
  cursor: pointer;
  white-space: nowrap;

  &:hover { background: var(--color-interactive-primary-hover, #1565c0); }
  &:disabled { opacity: 0.5; cursor: default; }
}

.btn-secondary {
  padding: 8px 18px;
  background: transparent;
  color: var(--color-text-primary);
  border: 1px solid var(--color-border-light);
  border-radius: 8px;
  font-weight: 500;
  font-size: 0.9rem;
  cursor: pointer;

  &:hover { background: var(--color-bg-hover, rgba(0,0,0,0.04)); }
}

.btn-icon {
  width: 30px;
  height: 30px;
  border: none;
  border-radius: 6px;
  background: transparent;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-size: 0.8rem;

  &.btn-danger {
    color: #c62828;
    &:hover { background: rgba(198,40,40,0.1); }
  }
}

// ── Estados vacío / cargando ───────────────────────────────────
.loading-row,
.empty-row {
  padding: 40px;
  text-align: center;
  color: var(--color-text-secondary);
  font-size: 0.9rem;
}

// ── Modal ──────────────────────────────────────────────────────
.modal-backdrop {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.45);
  z-index: 1000;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
}

.modal {
  background: var(--color-surface);
  border-radius: 14px;
  width: 100%;
  max-width: 540px;
  box-shadow: 0 20px 60px rgba(0,0,0,0.25);
  overflow: hidden;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 18px 22px;
  border-bottom: 1px solid var(--color-border-light);

  h2 {
    margin: 0;
    font-size: 1.1rem;
    font-weight: 700;
    color: var(--color-text-primary);
  }
}

.modal-body {
  padding: 22px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  padding-top: 8px;
}

// ── Formulario ─────────────────────────────────────────────────
.form-group {
  display: flex;
  flex-direction: column;
  gap: 6px;

  label {
    font-size: 0.83rem;
    font-weight: 600;
    color: var(--color-text-secondary);
  }

  input, textarea, select {
    padding: 9px 12px;
    border: 1px solid var(--color-border-light);
    border-radius: 8px;
    background: var(--color-bg-primary);
    color: var(--color-text-primary);
    font-size: 0.9rem;
    outline: none;
    font-family: inherit;

    &:focus {
      border-color: var(--color-interactive-primary);
      box-shadow: 0 0 0 3px rgba(33, 150, 243, 0.12);
    }
  }

  textarea { resize: vertical; }
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 14px;
}

.field-error {
  font-size: 0.78rem;
  color: #c62828;
}
```

**Puntos clave de los estilos:**
- Usamos `var(--color-*)` en lugar de colores fijos. Estas variables CSS vienen del sistema de temas claro/oscuro y se definen en `src/styles/themes/_light.scss` y `_dark.scss`. Al usarlas, tu componente cambia automáticamente cuando el usuario cambia el tema.
- Las clases `module-*` (`module-card`, `module-header`, etc.) **no** se definen aquí. Ya están en `styles.scss` global. Solo define en este archivo lo que es específico de Proyectos.

### Referencia: variables CSS disponibles

| Variable | Uso |
|----------|-----|
| `--color-text-primary` | Texto principal |
| `--color-text-secondary` | Texto secundario / labels |
| `--color-bg-primary` | Fondo de la página |
| `--color-surface` | Fondo de cards / modales |
| `--color-border-light` | Bordes suaves |
| `--color-interactive-primary` | Azul de acción (botones, links) |
| `--shadow-sm` | Sombra suave para cards |
| `--navbar-height` | Altura del navbar (64px) |

---

## Paso 6 — Registrar la ruta

Abre `src/app/app.routes.ts` y agrega la ruta de Proyectos dentro del bloque `children` del `LayoutShellComponent`:

```typescript
// src/app/app.routes.ts
import { Routes } from '@angular/router';
import { LayoutShellComponent } from './shared/layout/layout-shell.component';

export const routes: Routes = [
  {
    path: '',
    redirectTo: 'auth/login',
    pathMatch: 'full'
  },
  {
    path: '',
    component: LayoutShellComponent,
    children: [
      {
        path: 'dashboard',
        loadComponent: () =>
          import('./features/dashboard/dashboard.component').then(m => m.DashboardComponent),
        title: 'Dashboard'
      },
      {
        path: 'tenants',
        loadComponent: () =>
          import('./features/tenants/tenant-management.component').then(m => m.TenantManagementComponent),
        title: 'Tenant Management'
      },
      {
        path: 'users',
        loadComponent: () =>
          import('./features/users/user-management.component').then(m => m.UserManagementComponent),
        title: 'Usuarios & Roles'
      },
      {
        path: 'permissions',
        loadComponent: () =>
          import('./features/permissions/permissions-page.component').then(m => m.PermissionsPageComponent),
        title: 'Permisos de Componentes'
      },

      // ── AGREGAR AQUÍ tu nuevo módulo ────────────────────────
      {
        path: 'proyectos',
        loadComponent: () =>
          import('./features/proyectos/proyectos.component').then(m => m.ProyectosComponent),
        title: 'Proyectos'
      },
      // ────────────────────────────────────────────────────────

      {
        path: 'crm',
        loadChildren: () => import('./features/crm/crm.module').then(m => m.CrmModule),
        title: 'CRM'
      },
      {
        path: 'tenant-management',
        redirectTo: 'tenants',
        pathMatch: 'full'
      },
    ]
  },
  // ... rutas de auth (no tocar)
];
```

**¿Qué hace esto?**
- `path: 'proyectos'` — La URL de tu página será `http://localhost:4200/proyectos`.
- `loadComponent: () => import(...)` — Carga el componente de forma "lazy" (solo cuando el usuario navega a esa ruta). Esto mejora el tiempo de carga inicial.
- Estar dentro de `LayoutShellComponent` children hace que automáticamente tenga el sidebar y el navbar.
- `title: 'Proyectos'` — El título que aparece en la pestaña del navegador.

**Regla:** Toda ruta que deba mostrar el sidebar/navbar debe ir dentro de `children` del `LayoutShellComponent`. Las rutas de autenticación van por fuera (como `auth/login`).

---

## Paso 7 — Agregar las traducciones

Las traducciones permiten que la aplicación muestre textos en inglés o español según la preferencia del usuario. El pipe `| transloco` busca la clave en el archivo JSON del idioma activo.

### 7.1 Inglés — `src/assets/i18n/en.json`

Abre el archivo y agrega la sección `proyectos` al objeto JSON existente:

```json
{
  "navbar": { ... },
  "dashboard": { ... },

  "proyectos": {
    "header": {
      "title": "Projects",
      "subtitle": "Manage your organization's projects"
    },
    "search": {
      "label": "Search",
      "placeholder": "Search by name..."
    },
    "table": {
      "nombre": "Name",
      "descripcion": "Description",
      "estado": "Status",
      "presupuesto": "Budget",
      "fechaInicio": "Start Date",
      "acciones": "Actions"
    },
    "fields": {
      "nombre": "Name",
      "descripcion": "Description",
      "estado": "Status",
      "presupuesto": "Budget",
      "fechaInicio": "Start Date"
    },
    "actions": {
      "create": "New Project",
      "save": "Save",
      "cancel": "Cancel",
      "delete": "Delete"
    },
    "create": {
      "title": "Create Project"
    },
    "empty": "No projects found."
  }
}
```

### 7.2 Español — `src/assets/i18n/es.json`

Agrega la misma estructura con textos en español:

```json
{
  "proyectos": {
    "header": {
      "title": "Proyectos",
      "subtitle": "Gestiona los proyectos de tu organización"
    },
    "search": {
      "label": "Buscar",
      "placeholder": "Buscar por nombre..."
    },
    "table": {
      "nombre": "Nombre",
      "descripcion": "Descripción",
      "estado": "Estado",
      "presupuesto": "Presupuesto",
      "fechaInicio": "Fecha inicio",
      "acciones": "Acciones"
    },
    "fields": {
      "nombre": "Nombre",
      "descripcion": "Descripción",
      "estado": "Estado",
      "presupuesto": "Presupuesto",
      "fechaInicio": "Fecha de inicio"
    },
    "actions": {
      "create": "Nuevo Proyecto",
      "save": "Guardar",
      "cancel": "Cancelar",
      "delete": "Eliminar"
    },
    "create": {
      "title": "Crear Proyecto"
    },
    "empty": "No se encontraron proyectos."
  }
}
```

**Regla:** Siempre agrega la misma clave en **los dos archivos** (`en.json` y `es.json`). Si falta en uno, el pipe mostrará la clave cruda (ej. `"proyectos.header.title"`) en ese idioma.

---

## Paso 8 — Registrar menú y permisos en la base de datos

Para que la página aparezca en el **sidebar**, debes registrar el menú en la base de datos. Esto se hace con scripts SQL, documentados en detalle en `04-componentes-web-permisos.md`.

### Resumen rápido para Proyectos como ítem simple en el sidebar:

```sql
-- Reemplazar los valores de las variables según tu entorno
DO $$ DECLARE
  v_tenant_id   UUID := '00000000-0000-0000-0000-000000000002';
  v_created_by  UUID := '00000000-0000-0000-0001-000000000001';

  v_module_key  TEXT := 'proyectos';
  v_comp_name   TEXT := 'Proyectos';
  v_comp_route  TEXT := '/proyectos';
  v_comp_desc   TEXT := 'Módulo de gestión de proyectos';
  v_is_system   BOOLEAN := FALSE;

  v_menu_name       TEXT    := 'Proyectos';
  v_menu_title      TEXT    := 'Proyectos';
  v_menu_icon       TEXT    := 'folder';      -- ícono Lucide
  v_menu_icon_type  TEXT    := 'tabler';
  v_menu_route      TEXT    := '/proyectos';
  v_menu_location   TEXT    := 'sidebar';
  v_menu_order      INTEGER := 40;
  v_default_access  TEXT    := 'HIDDEN';

  v_role_name   TEXT := 'ADMIN';
  v_comp_access TEXT := 'EXECUTE';

  v_comp_id UUID;
  v_role_id UUID;
BEGIN
  -- Crear componente
  INSERT INTO nxc_menu.components
    (tenant_id, module_key, name, route, description, is_system, created_by, created_at, updated_at, version)
  VALUES
    (v_tenant_id, v_module_key, v_comp_name, v_comp_route, v_comp_desc, v_is_system, v_created_by, NOW(), NOW(), 0)
  ON CONFLICT DO NOTHING
  RETURNING id INTO v_comp_id;

  IF v_comp_id IS NULL THEN
    SELECT id INTO v_comp_id FROM nxc_menu.components
    WHERE module_key = v_module_key AND tenant_id = v_tenant_id AND deleted_at IS NULL;
  END IF;

  -- Crear ítem de menú
  INSERT INTO nxc_menu.menu_items
    (tenant_id, component_id, parent_id, name, title, icon, icon_type,
     route, location, item_type, order_index, is_visible, is_system,
     default_access, created_by, created_at, updated_at, version)
  VALUES
    (v_tenant_id, v_comp_id, NULL, v_menu_name, v_menu_title, v_menu_icon, v_menu_icon_type,
     v_menu_route, v_menu_location, 'ITEM', v_menu_order, TRUE, FALSE,
     v_default_access::nxc_menu.access_level, v_created_by, NOW(), NOW(), 0);

  -- Asignar permiso al rol
  SELECT id INTO v_role_id FROM nxc_tenant.roles
  WHERE name = v_role_name AND tenant_id = v_tenant_id AND deleted_at IS NULL;

  INSERT INTO nxc_menu.component_permissions
    (tenant_id, role_id, component_id, access, created_by, created_at, updated_at)
  VALUES
    (v_tenant_id, v_role_id, v_comp_id, v_comp_access::nxc_menu.access_level, v_created_by, NOW(), NOW())
  ON CONFLICT (tenant_id, role_id, component_id) DO UPDATE
    SET access = EXCLUDED.access, updated_at = NOW();

  RAISE NOTICE 'Proyectos registrado en el menú';
END $$;
```

Ver el documento `04-componentes-web-permisos.md` para scripts más avanzados (con hijos, elementos de permisos granulares, rollback).

---

## Verificación final

Después de completar los 8 pasos, ejecuta:

```bash
ng serve
```

Y navega a `http://localhost:4200/proyectos`. Deberías ver tu página con el sidebar y navbar funcionando.

### Lista de verificación

- [ ] La carpeta `src/app/features/proyectos/` existe con los 4 archivos
- [ ] El componente tiene `standalone: true` y los módulos correctos en `imports`
- [ ] El HTML empieza con `<main class="content">`
- [ ] La ruta está registrada en `app.routes.ts` dentro de `LayoutShellComponent children`
- [ ] Las claves de traducción están en `en.json` **y** `es.json`
- [ ] El script SQL del menú fue ejecutado en la base de datos
- [ ] `ng serve` compila sin errores

---

## Errores comunes y solución

| Error | Causa | Solución |
|-------|-------|----------|
| `NG0303: Can't bind to 'formGroup'` | Falta `ReactiveFormsModule` en imports | Agregar `ReactiveFormsModule` al array `imports` del componente |
| `NG0304: 'app-xxx' is not a known element` | Componente no importado | Agregar el componente al array `imports` o verificar el selector |
| `NG5002: Unexpected closing tag` | Tags `</div>` extras en el HTML | Revisar que cada `<div>` que abres lo cierres exactamente una vez |
| La página carga pero sin sidebar/navbar | La ruta no está dentro de `LayoutShellComponent children` | Mover la ruta al bloque correcto en `app.routes.ts` |
| El contenido queda debajo del sidebar | Falta `class="content"` en `<main>` | Agregar `<main class="content">` como wrapper raíz del template |
| Las traducciones muestran la clave cruda | La clave no existe en el JSON del idioma activo | Agregar la clave en `en.json` y/o `es.json` |
| `Cannot GET /proyectos` al refrescar | Problema de configuración del servidor de desarrollo | Con `ng serve` no pasa. En producción: configurar el servidor para redirigir a `index.html` |

---

## Referencia rápida: estructura mínima de un componente

Si necesitas un componente más sencillo (solo mostrar información, sin formulario), esta es la estructura mínima:

**`.ts` mínimo:**
```typescript
import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { TranslocoModule } from '@ngneat/transloco';

@Component({
  selector: 'app-mi-modulo',
  standalone: true,
  imports: [CommonModule, TranslocoModule],
  templateUrl: './mi-modulo.component.html',
  styleUrls: ['./mi-modulo.component.scss']
})
export class MiModuloComponent {}
```

**`.html` mínimo:**
```html
<main class="content">
  <header class="module-header">
    <div class="module-title-group">
      <h1 class="module-title">Mi Módulo</h1>
      <p class="module-subtitle">Descripción corta</p>
    </div>
  </header>

  <section class="module-card">
    Contenido aquí
  </section>
</main>
```

**`.scss` mínimo:**
```scss
// Solo estilos específicos del componente.
// Las clases module-* ya vienen de styles.scss global.
```

**Ruta mínima en `app.routes.ts`:**
```typescript
{
  path: 'mi-modulo',
  loadComponent: () =>
    import('./features/mi-modulo/mi-modulo.component').then(m => m.MiModuloComponent),
  title: 'Mi Módulo'
}
```

---

**Fecha:** Mayo 2026
**Proyecto:** NexCore Frontend
**Angular:** 17 (Standalone Components)
