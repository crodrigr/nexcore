# 🎯 Sistema de Menús, Roles y Permisos - NexCore

## 📋 Resumen

El sistema de menús y permisos de NexCore permite configurar dinámicamente qué opciones de navegación y funcionalidades están disponibles para cada usuario según sus roles asignados. El sistema opera en dos niveles:

1. **Menús**: Controlan la navegación y opciones visibles en la interfaz
2. **Permisos**: Controlan el acceso a componentes y elementos específicos dentro de las páginas

---

## 🧭 Sistema de Menús

### Estructura de un Menú

Cada menú tiene la siguiente estructura:

```typescript
interface MenuItem {
  id: string;              // UUID único del menú
  name: string;            // Identificador técnico (ej: "Dashboard")
  title: string;           // Texto visible (ej: "Panel Principal")
  icon: string;            // Nombre del ícono
  icon_type: string;       // Librería de íconos (tabler, material, etc.)
  route: string | null;    // Ruta de navegación (ej: "/graphics")
  location: string;        // Ubicación donde se muestra el menú
  item_type: string;       // Tipo: ITEM (enlace) o GROUP (grupo de menús)
  access: AccessType;      // Nivel de acceso: execute, view, hidden
  order_index: number;     // Orden de visualización
  children: MenuItem[];    // Submenús (solo para type: GROUP)
}
```

### 📍 Ubicaciones de Menús (location)

Los menús se pueden ubicar en diferentes áreas de la interfaz:

| Location | Descripción | Uso Típico |
|----------|-------------|------------|
| **navbar** | Barra de navegación principal | Menús principales de la aplicación |
| **header-dropdown** | Menú desplegable del header | Opciones de perfil y administración |
| **sidebar** | Barra lateral (si existe) | Navegación secundaria |
| **footer** | Pie de página | Enlaces secundarios o legales |

**Ejemplo del perfil super.admin:**

```json
{
  "name": "Dashboard",
  "title": "Panel Principal",
  "icon": "layout-dashboard",
  "icon_type": "tabler",
  "route": "/graphics",
  "location": "navbar",          ← Se muestra en la barra de navegación
  "item_type": "ITEM",
  "access": "execute",
  "order_index": 10
}
```

### 🔤 Tipos de Ítems (item_type)

#### ITEM
Menú individual que navega a una ruta específica.

```json
{
  "name": "Alerts",
  "title": "Alertas",
  "route": "/alerts",
  "location": "navbar",
  "item_type": "ITEM",           ← Enlace directo
  "children": []
}
```

#### GROUP
Grupo que contiene submenús. No tiene ruta propia.

```json
{
  "name": "ProfileMenu",
  "title": "Perfil",
  "route": null,                 ← Sin ruta
  "location": "header-dropdown",
  "item_type": "GROUP",          ← Agrupa otros menús
  "children": [
    {
      "name": "Profile",
      "title": "Mi Perfil",
      "route": "/profile"
    },
    {
      "name": "Settings",
      "title": "Configuración",
      "route": "/admin/settings"
    }
  ]
}
```

### 🔄 Carga de Menús

Los menús se cargan automáticamente cuando el usuario inicia sesión:

```typescript
// 1. Usuario hace login
this.authService.login(credentials).subscribe();

// 2. Backend responde con el perfil completo (incluye menus)
{
  "user": { ... },
  "menus": [ ... ],      ← Menús asignados al usuario
  "permissions": [ ... ],
  "token": "..."
}

// 3. ProfileService guarda los menús
this.profileService.setProfile(profileData);

// 4. Los componentes de UI consumen los menús
this.profileService.menus$.subscribe(menus => {
  this.navbarMenus = menus.filter(m => m.location === 'navbar');
  this.headerMenus = menus.filter(m => m.location === 'header-dropdown');
});
```

**Componentes que consumen menús:**
- `navbar.component.ts` - Muestra menús con `location: 'navbar'`
- `header.component.ts` - Muestra menús con `location: 'header-dropdown'`
- `sidebar.component.ts` - Muestra menús con `location: 'sidebar'`

### 🎯 Niveles de Acceso en Menús

| Access | Comportamiento | Caso de Uso |
|--------|----------------|-------------|
| **execute** | Menú visible y clickeable | Acceso completo |
| **view** | Menú visible pero deshabilitado | Informativo, sin acceso |
| **hidden** | Menú no se muestra | Sin acceso |

**Ejemplo:**

```typescript
// Filtrar solo menús con acceso 'execute' o 'view'
this.visibleMenus = this.allMenus.filter(menu => 
  menu.access === 'execute' || menu.access === 'view'
);

// En el template
<a *ngFor="let menu of visibleMenus"
   [routerLink]="menu.route"
   [class.disabled]="menu.access === 'view'">  ← Deshabilitado si es 'view'
  {{ menu.title }}
</a>
```

---

## 🔐 Sistema de Permisos

Los permisos controlan el acceso a **componentes** y **elementos** dentro de cada página.

### Estructura de Permisos

```typescript
interface Permission {
  component: string;         // Identificador del componente (ej: "alerts")
  route: string;             // Ruta asociada (ej: "/alerts")
  access: AccessType;        // Nivel de acceso general del componente
  elements: PermissionElement[];  // Permisos de elementos específicos
}

interface PermissionElement {
  element_key: string;       // Identificador único del elemento (ej: "btn-create")
  access: AccessType;        // Nivel de acceso: execute, view, hidden
}
```

### 🎯 Niveles de Acceso

| Access | Descripción | Ejemplo |
|--------|-------------|---------|
| **execute** | Puede ver y ejecutar acciones | Usuario puede ver la página y hacer clic en botones |
| **view** | Solo puede ver, sin ejecutar | Usuario ve la página pero botones deshabilitados |
| **hidden** | No puede acceder | Usuario es redirigido si intenta acceder |

### 📦 Componentes

Un **componente** representa una página o módulo completo de la aplicación.

**Ejemplo del perfil super.admin:**

```json
{
  "component": "alerts",         ← Componente de alertas
  "route": "/alerts",            ← Ruta asociada
  "access": "execute",           ← Acceso completo al componente
  "elements": [
    {
      "element_key": "searchInput",
      "access": "hidden"         ← Barra de búsqueda oculta
    },
    {
      "element_key": "columnsMenuBtn",
      "access": "hidden"         ← Botón de columnas oculto
    }
  ]
}
```

### 🧩 Elementos de Componentes

Los **elementos** son partes específicas dentro de un componente (botones, inputs, secciones, etc.).

#### Convención de Nombres

```typescript
// Formato: [tipo]-[acción]-[contexto]
"btn-create-user"        // Botón para crear usuario
"searchInput"            // Input de búsqueda
"paginator"              // Paginador de tabla
"tab-roles"              // Pestaña de roles
"columnsMenuBtn"         // Botón de menú de columnas
```

#### Tipos Comunes de Elementos

| Prefijo | Descripción | Ejemplo |
|---------|-------------|---------|
| **btn-** | Botones | `btn-create`, `btn-edit`, `btn-delete` |
| **input-** | Campos de entrada | `searchInput`, `input-email` |
| **tab-** | Pestañas | `tab-roles`, `tab-permissions` |
| **section-** | Secciones de página | `section-stats`, `section-details` |
| **[componente]** | Componentes Angular | `app-alert-groups[groupSelected]` |

**Ejemplo del componente user-management:**

```json
{
  "component": "user-management",
  "route": "/admin/users",
  "access": "execute",
  "elements": [
    {
      "element_key": "btn-create-user",
      "access": "hidden"           ← No puede crear usuarios
    },
    {
      "element_key": "btn-edit-user",
      "access": "hidden"           ← No puede editar usuarios
    },
    {
      "element_key": "btn-delete-user",
      "access": "hidden"           ← No puede eliminar usuarios
    },
    {
      "element_key": "searchInput",
      "access": "hidden"           ← Sin barra de búsqueda
    },
    {
      "element_key": "paginator",
      "access": "hidden"           ← Sin paginador
    },
    {
      "element_key": "tab-roles",
      "access": "hidden"           ← No ve la pestaña de roles
    }
  ]
}
```

### 🔄 Aplicación de Permisos

Los permisos se aplican en tres niveles:

#### 1. **Nivel de Ruta (Route Guard)**

Valida si el usuario puede acceder a la página completa.

```typescript
// permission.guard.ts
export const permissionGuard: CanActivateFn = async (route) => {
  const permissionService = inject(PermissionService);
  const componentName = route.data?.['component'];
  
  // Verificar si el usuario tiene permiso para el componente
  const hasAccess = await permissionService.canAccessRoute(componentName);
  
  if (!hasAccess) {
    router.navigate(['/dashboard']);  // Redirigir si no tiene acceso
    return false;
  }
  
  return true;
};
```

**Configuración en rutas:**

```typescript
// app.routes.ts
{
  path: 'alerts',
  component: AlertsComponent,
  canActivate: [permissionGuard],  ← Guard de permisos
  data: { component: 'alerts' }    ← Nombre del componente a validar
}
```

#### 2. **Nivel de Componente**

Controla la visibilidad de elementos dentro de la página.

```typescript
// alerts.component.ts
export class AlertsComponent implements OnInit {
  canSearch$: Observable<boolean>;
  canExportData$: Observable<boolean>;
  canViewColumns$: Observable<boolean>;

  constructor(private permissionService: PermissionService) {
    // Preguntar al servicio por cada elemento
    this.canSearch$ = this.permissionService.canExecute$('alerts', 'searchInput');
    this.canExportData$ = this.permissionService.canExecute$('alerts', 'btn-export');
    this.canViewColumns$ = this.permissionService.canExecute$('alerts', 'columnsMenuBtn');
  }
}
```

#### 3. **Nivel de Template**

Muestra/oculta elementos en el HTML según los permisos.

```html
<!-- alerts.component.html -->

<!-- Input de búsqueda (solo si tiene permiso) -->
<input *ngIf="canSearch$ | async"
       type="text"
       placeholder="Buscar alertas..."
       [(ngModel)]="searchTerm">

<!-- Botón de exportar (solo si tiene permiso) -->
<button *ngIf="canExportData$ | async"
        (click)="exportData()">
  <mat-icon>download</mat-icon>
  Exportar
</button>

<!-- Menú de columnas (solo si tiene permiso) -->
<button *ngIf="canViewColumns$ | async"
        [matMenuTriggerFor]="columnsMenu">
  <mat-icon>view_column</mat-icon>
  Columnas
</button>
```

### 🛠️ PermissionService

Servicio central para validar permisos.

```typescript
@Injectable({ providedIn: 'root' })
export class PermissionService {
  
  /**
   * Verifica si el usuario puede VER un componente
   */
  canView$(component: string): Observable<boolean> {
    return this.getAccess$(component).pipe(
      map(access => access === 'view' || access === 'execute')
    );
  }

  /**
   * Verifica si el usuario puede EJECUTAR acciones en un componente
   */
  canExecute$(component: string): Observable<boolean> {
    return this.getAccess$(component).pipe(
      map(access => access === 'execute')
    );
  }

  /**
   * Verifica si el usuario puede EJECUTAR un elemento específico
   */
  canExecute$(component: string, elementKey: string): Observable<boolean> {
    return this.getAccess$(component, elementKey).pipe(
      map(access => access === 'execute')
    );
  }

  /**
   * Verifica si el usuario puede acceder a una RUTA
   */
  async canAccessRoute(component: string): Promise<boolean> {
    const permission = this.userPermissions.find(p => p.component === component);
    
    if (!permission) {
      return false;  // No tiene permiso del componente
    }
    
    // Puede acceder si tiene 'view' o 'execute'
    return permission.access === 'view' || permission.access === 'execute';
  }
}
```

---

## 🔗 Integración: Menús + Permisos

### Relación entre Menús y Permisos

Los **menús** y **permisos** trabajan juntos pero son independientes:

| Concepto | Función | Ejemplo |
|----------|---------|---------|
| **Menú** | Controla si el enlace aparece en la navegación | Mostrar/ocultar "Alertas" en navbar |
| **Permiso** | Controla si el usuario puede acceder a la ruta y qué puede hacer | Permitir entrar a `/alerts` y ver botones |

**Flujo completo:**

```
1. Usuario hace login
   ↓
2. Backend responde con perfil (menus + permissions)
   ↓
3. ProfileService guarda menus y permissions
   ↓
4. Navbar consume menus y muestra enlaces según 'location' y 'access'
   ↓
5. Usuario hace clic en "Alertas"
   ↓
6. permissionGuard valida si tiene permiso del componente 'alerts'
   ↓
7. Si tiene permiso 'execute' o 'view', permite acceso
   ↓
8. Componente AlertsComponent carga
   ↓
9. Componente pregunta a PermissionService por cada elemento
   ↓
10. Template muestra/oculta elementos según permisos
```

### Ejemplo Completo: Dashboard

**1. Menú en navbar:**

```json
{
  "name": "Dashboard",
  "title": "Panel Principal",
  "route": "/graphics",
  "location": "navbar",
  "access": "execute"        ← Menú visible y clickeable
}
```

**2. Permiso del componente:**

```json
{
  "component": "dashboard",
  "route": "/graphics",
  "access": "execute",       ← Puede acceder a la página
  "elements": [
    {
      "element_key": "filterButton",
      "access": "hidden"     ← Botón de filtros oculto
    },
    {
      "element_key": "refreshButton",
      "access": "hidden"     ← Botón de refrescar oculto
    },
    {
      "element_key": "cityFilterSelect#cityFilter",
      "access": "hidden"     ← Filtro de ciudad oculto
    }
  ]
}
```

**3. Ruta protegida:**

```typescript
{
  path: 'graphics',
  component: DashboardComponent,
  canActivate: [permissionGuard],
  data: { component: 'dashboard' }
}
```

**4. Componente:**

```typescript
export class DashboardComponent implements OnInit {
  canFilter$: Observable<boolean>;
  canRefresh$: Observable<boolean>;

  constructor(private permissionService: PermissionService) {
    this.canFilter$ = this.permissionService.canExecute$('dashboard', 'filterButton');
    this.canRefresh$ = this.permissionService.canExecute$('dashboard', 'refreshButton');
  }
}
```

**5. Template:**

```html
<div class="dashboard-header">
  <h1>Panel Principal</h1>
  
  <!-- Botón de filtros (oculto para este rol) -->
  <button *ngIf="canFilter$ | async" (click)="openFilters()">
    <mat-icon>filter_list</mat-icon>
    Filtros
  </button>
  
  <!-- Botón de refrescar (oculto para este rol) -->
  <button *ngIf="canRefresh$ | async" (click)="refresh()">
    <mat-icon>refresh</mat-icon>
    Actualizar
  </button>
</div>

<!-- El dashboard se muestra siempre (porque tiene access: 'execute') -->
<div class="dashboard-content">
  <app-widget-stats></app-widget-stats>
  <app-chart-overview></app-chart-overview>
</div>
```

**Resultado:**
- ✅ Usuario ve el menú "Dashboard" en navbar
- ✅ Usuario puede hacer clic y acceder a `/graphics`
- ✅ Usuario ve el contenido del dashboard
- ❌ Usuario NO ve el botón de filtros
- ❌ Usuario NO ve el botón de refrescar

---

## 🎨 Ejemplo Visual: Perfil super.admin

### Navbar (location: navbar)

```
┌──────────────────────────────────────────────────────────┐
│  🏠 Dashboard  │  🔔 Alertas  │  ⚠️ Incidentes  │  📡 Traps │
└──────────────────────────────────────────────────────────┘
```

Todos tienen `access: "execute"` y `location: "navbar"`.

### Header Dropdown (location: header-dropdown)

```
┌────────────────────────┐
│  👤 Perfil             │  ← GROUP (sin ruta)
│  ├─ Mi Perfil          │  ← ITEM (route: /profile)
│  ├─ Configuración      │  ← ITEM (route: /admin/settings)
│  └─ Cerrar Sesión      │  ← ITEM (route: /auth/login)
│                        │
│  🛡️ Administración     │  ← GROUP con access: "hidden"
│  (No se muestra)       │     (solo visible si access: execute)
└────────────────────────┘
```

**Nota:** El grupo "Administración" tiene `access: "hidden"`, por lo que aunque esté en el perfil, no se muestra en la UI.

---

## 📊 Diferencias Clave

### Menús vs Permisos

| Aspecto | Menús | Permisos |
|---------|-------|----------|
| **Propósito** | Navegación | Control de acceso |
| **Ubicación** | Navbar, header, sidebar | Dentro de páginas |
| **Granularidad** | Página completa | Componente + Elementos |
| **Validación** | En UI (navbar, header) | En Guard + Componente |
| **Independencia** | Pueden existir sin permisos | Requieren ruta asociada |

### Access en Menús vs Permisos

| Access | En Menús | En Permisos |
|--------|----------|-------------|
| **execute** | Menú clickeable | Puede acceder y usar elementos |
| **view** | Menú visible pero deshabilitado | Puede ver pero no ejecutar |
| **hidden** | Menú no se muestra | No puede acceder |

---

## 🚀 Buenas Prácticas

### 1. **Nomenclatura de Componentes**

```typescript
// ✅ BIEN: Nombre descriptivo y único
component: "user-management"
component: "role-management"
component: "audit-viewer"

// ❌ MAL: Nombres genéricos o ambiguos
component: "users"
component: "admin"
component: "page1"
```

### 2. **Nomenclatura de Elementos**

```typescript
// ✅ BIEN: Prefijo + acción + contexto
element_key: "btn-create-user"
element_key: "btn-delete-role"
element_key: "searchInput"
element_key: "tab-permissions"

// ❌ MAL: Sin contexto
element_key: "button1"
element_key: "input"
element_key: "div"
```

### 3. **Uso de Observables**

```typescript
// ✅ BIEN: Observable con async pipe
canEdit$: Observable<boolean>;

constructor(private permissionService: PermissionService) {
  this.canEdit$ = this.permissionService.canExecute$('users', 'btn-edit');
}

// En template
<button *ngIf="canEdit$ | async" (click)="edit()">Editar</button>

// ❌ MAL: Suscripción manual sin unsubscribe
canEdit: boolean = false;

ngOnInit() {
  this.permissionService.canExecute$('users', 'btn-edit').subscribe(can => {
    this.canEdit = can;  // Memory leak si no se unsubscribe
  });
}
```

### 4. **Configuración de Rutas**

```typescript
// ✅ BIEN: Con guard y data
{
  path: 'users',
  component: UserManagementComponent,
  canActivate: [permissionGuard],
  data: { component: 'user-management' }
}

// ❌ MAL: Sin protección
{
  path: 'users',
  component: UserManagementComponent
}
```

### 5. **Validación en Componentes**

```typescript
// ✅ BIEN: Validar permisos antes de acciones importantes
async deleteUser(userId: string) {
  const canDelete = await firstValueFrom(
    this.permissionService.canExecute$('users', 'btn-delete')
  );
  
  if (!canDelete) {
    this.showMessage('No tienes permiso para eliminar usuarios', 'error');
    return;
  }
  
  // Proceder con la eliminación
  this.userService.deleteUser(userId).subscribe(...);
}

// ❌ MAL: Asumir que el permiso existe
async deleteUser(userId: string) {
  this.userService.deleteUser(userId).subscribe(...);  // Sin validar
}
```

---

## 🐛 Debugging

### Logs Útiles

```typescript
// En ProfileService
console.log('[ProfileService] Menús cargados:', menus.length);
console.log('[ProfileService] Permisos cargados:', permissions.length);

// En PermissionService
console.log('[PermissionService] Validando acceso a:', component);
console.log('[PermissionService] Permiso encontrado:', permission);

// En Componentes
console.log('[UserManagement] canCreate:', await firstValueFrom(this.canCreate$));
console.log('[UserManagement] canEdit:', await firstValueFrom(this.canEdit$));
```

### Verificación en Consola del Navegador

```javascript
// Ver perfil completo
JSON.parse(localStorage.getItem('profile'))

// Ver solo menús
JSON.parse(localStorage.getItem('profile')).menus

// Ver solo permisos
JSON.parse(localStorage.getItem('profile')).permissions

// Filtrar menús por ubicación
JSON.parse(localStorage.getItem('profile')).menus.filter(m => m.location === 'navbar')
```

---

## 📚 Resumen

### Menús
- ✅ Controlan la **navegación** de la aplicación
- ✅ Se ubican en diferentes áreas: `navbar`, `header-dropdown`, `sidebar`, `footer`
- ✅ Pueden ser `ITEM` (enlace directo) o `GROUP` (agrupación)
- ✅ Tienen niveles de acceso: `execute`, `view`, `hidden`
- ✅ Se cargan automáticamente al hacer login

### Permisos
- ✅ Controlan el **acceso** a componentes y elementos
- ✅ Operan a nivel de **componente** (página completa) y **elemento** (botones, inputs)
- ✅ Tienen niveles de acceso: `execute`, `view`, `hidden`
- ✅ Se validan con **Guards** (rutas), **Servicios** (lógica) y **Directivas** (UI)
- ✅ Se aplican dinámicamente con `*ngIf` y Observables

### Integración
- ✅ Los **menús** controlan QUÉ se muestra en la navegación
- ✅ Los **permisos** controlan QUÉ puede hacer el usuario dentro de cada página
- ✅ Ambos se reciben del backend al hacer login
- ✅ Se guardan en `ProfileService` y se consumen reactivamente

---

**Fecha:** 23 de mayo de 2026  
**Proyecto:** NexCore  
**Autor:** GitHub Copilot  
**Versión:** 1.0
