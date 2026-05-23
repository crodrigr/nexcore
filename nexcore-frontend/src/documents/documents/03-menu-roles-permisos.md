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
| **profile** | Menú desplegable del perfil | Opciones de perfil y administración |
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
  "id": "37bbc70f-6d2d-463a-8714-ded61c4d0596",
  "name": "ProfileMenu",
  "title": "Perfil",
  "icon": "user-circle",
  "icon_type": "tabler",
  "route": null,                 ← Sin ruta
  "location": "profile",
  "item_type": "GROUP",          ← Agrupa otros menús
  "access": "execute",
  "order_index": 50,
  "children": [
    {
      "id": "d0fca44e-9948-4d0c-895b-24d5050f967f",
      "name": "Profile",
      "title": "Mi Perfil",
      "icon": "user",
      "icon_type": "tabler",
      "route": "/profile",
      "location": "profile",
      "item_type": "ITEM",
      "access": "execute",
      "order_index": 10
    },
    {
      "id": "ef6859b4-4e05-4f57-8e0f-096004207940",
      "name": "Settings",
      "title": "Configuración",
      "icon": "settings",
      "icon_type": "tabler",
      "route": "/admin/settings",
      "location": "profile",
      "item_type": "ITEM",
      "access": "execute",
      "order_index": 20
    },
    {
      "id": "49e50200-30b6-464f-8a8e-14579d8e77d6",
      "name": "Logout",
      "title": "Cerrar Sesión",
      "icon": "logout",
      "icon_type": "tabler",
      "route": "/auth/login",
      "location": "profile",
      "item_type": "ITEM",
      "access": "execute",
      "order_index": 30
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
  this.profileMenus = menus.filter(m => m.location === 'profile');
});
```

**Componentes que consumen menús:**
- `navbar.component.ts` - Muestra menús con `location: 'navbar'`
- `header.component.ts` - Muestra menús con `location: 'profile'`
- `sidebar.component.ts` - Muestra menús con `location: 'sidebar'`

### 📄 Ejemplo Real: Respuesta del Backend (super.admin)

Cuando el usuario `super.admin` hace login, el backend retorna el siguiente perfil completo:

```json
{
  "user": {
    "iduser": "00000000-0000-0000-0001-000000000001",
    "username": "super.admin",
    "name": "Super Administrador NexCore",
    "email": "super.admin@nexcore.io",
    "phone": null,
    "photo": null,
    "roles": ["SUPER_ADMIN", "VIEWER"]
  },
  "menus": [
    {
      "id": "4337a18f-c20d-422e-a828-db3fb3d45a7c",
      "name": "Dashboard",
      "title": "Panel Principal",
      "icon": "layout-dashboard",
      "icon_type": "tabler",
      "route": "/graphics",
      "location": "navbar",
      "item_type": "ITEM",
      "access": "execute",
      "order_index": 10,
      "children": []
    },
    {
      "id": "02b1f6cc-c4e3-49da-98ec-f7c2118ba9d0",
      "name": "Alerts",
      "title": "Alertas",
      "icon": "bell",
      "icon_type": "tabler",
      "route": "/alerts",
      "location": "navbar",
      "item_type": "ITEM",
      "access": "execute",
      "order_index": 20,
      "children": []
    },
    {
      "id": "4681f5bd-c718-48f1-9b42-b14a5e1f1ad0",
      "name": "Incidents",
      "title": "Incidentes",
      "icon": "alert-circle",
      "icon_type": "tabler",
      "route": "/incidents",
      "location": "navbar",
      "item_type": "ITEM",
      "access": "execute",
      "order_index": 30,
      "children": []
    },
    {
      "id": "1ea0d8eb-bbf9-4953-81fc-26e82d0c0521",
      "name": "Traps",
      "title": "Traps SNMP",
      "icon": "radar",
      "icon_type": "tabler",
      "route": "/traps",
      "location": "navbar",
      "item_type": "ITEM",
      "access": "execute",
      "order_index": 40,
      "children": []
    },
    {
      "id": "37bbc70f-6d2d-463a-8714-ded61c4d0596",
      "name": "ProfileMenu",
      "title": "Perfil",
      "icon": "user-circle",
      "icon_type": "tabler",
      "route": null,
      "location": "profile",
      "item_type": "GROUP",
      "access": "execute",
      "order_index": 50,
      "children": [
        {
          "id": "d0fca44e-9948-4d0c-895b-24d5050f967f",
          "name": "Profile",
          "title": "Mi Perfil",
          "icon": "user",
          "icon_type": "tabler",
          "route": "/profile",
          "location": "profile",
          "item_type": "ITEM",
          "access": "execute",
          "order_index": 10,
          "children": []
        },
        {
          "id": "ef6859b4-4e05-4f57-8e0f-096004207940",
          "name": "Settings",
          "title": "Configuración",
          "icon": "settings",
          "icon_type": "tabler",
          "route": "/admin/settings",
          "location": "profile",
          "item_type": "ITEM",
          "access": "execute",
          "order_index": 20,
          "children": []
        },
        {
          "id": "49e50200-30b6-464f-8a8e-14579d8e77d6",
          "name": "Logout",
          "title": "Cerrar Sesión",
          "icon": "logout",
          "icon_type": "tabler",
          "route": "/auth/login",
          "location": "profile",
          "item_type": "ITEM",
          "access": "execute",
          "order_index": 30,
          "children": []
        }
      ]
    },
    {
      "id": "aaeee5e3-71d9-49a9-a3c6-5383b2952420",
      "name": "Administration",
      "title": "Administración",
      "icon": "shield",
      "icon_type": "tabler",
      "route": null,
      "location": "profile",
      "item_type": "GROUP",
      "access": "hidden",
      "order_index": 60,
      "children": [
        {
          "id": "c644bf4b-412a-4051-95f2-a89d2ca4c637",
          "name": "Users",
          "title": "Usuarios",
          "icon": "users",
          "icon_type": "tabler",
          "route": "/admin/users",
          "location": "profile",
          "item_type": "ITEM",
          "access": "execute",
          "order_index": 10,
          "children": []
        },
        {
          "id": "f27b26a3-067c-4683-a0bf-de5ad843e9ca",
          "name": "Roles",
          "title": "Roles",
          "icon": "lock",
          "icon_type": "tabler",
          "route": "/admin/roles",
          "location": "profile",
          "item_type": "ITEM",
          "access": "execute",
          "order_index": 20,
          "children": []
        },
        {
          "id": "33483115-e90e-4fb3-abee-4632899e4fa8",
          "name": "Menus",
          "title": "Menús",
          "icon": "layout-navbar",
          "icon_type": "tabler",
          "route": "/admin/menus",
          "location": "profile",
          "item_type": "ITEM",
          "access": "execute",
          "order_index": 30,
          "children": []
        },
        {
          "id": "75f7f9fb-ceea-4cd6-9075-7fde5ba2deb9",
          "name": "Audit",
          "title": "Auditoría",
          "icon": "history",
          "icon_type": "tabler",
          "route": "/admin/audit",
          "location": "profile",
          "item_type": "ITEM",
          "access": "execute",
          "order_index": 40,
          "children": []
        }
      ]
    }
  ],
  "permissions": [
    {
      "component": "dashboard",
      "route": "/graphics",
      "access": "execute",
      "elements": [
        {
          "element_key": "filterButton",
          "access": "hidden"
        },
        {
          "element_key": "refreshButton",
          "access": "hidden"
        },
        {
          "element_key": "cityFilterSelect#cityFilter",
          "access": "hidden"
        },
        {
          "element_key": "hostFilterSelect#hostFilter",
          "access": "hidden"
        },
        {
          "element_key": "timeFilterSelect#timeFilter",
          "access": "hidden"
        }
      ]
    },
    {
      "component": "alerts",
      "route": "/alerts",
      "access": "execute",
      "elements": [
        {
          "element_key": "searchInput",
          "access": "hidden"
        },
        {
          "element_key": "columnsMenuBtn",
          "access": "hidden"
        },
        {
          "element_key": "paginator",
          "access": "hidden"
        },
        {
          "element_key": "resetColumnsBtn",
          "access": "hidden"
        },
        {
          "element_key": "toggleColumnItem",
          "access": "hidden"
        }
      ]
    },
    {
      "component": "incidents",
      "route": "/incidents",
      "access": "execute",
      "elements": [
        {
          "element_key": "app-alert-groups[groupSelected]",
          "access": "hidden"
        },
        {
          "element_key": "app-incident-detail[incidentUpdated]",
          "access": "hidden"
        }
      ]
    },
    {
      "component": "traps",
      "route": "/traps",
      "access": "execute",
      "elements": [
        {
          "element_key": "searchInput",
          "access": "hidden"
        },
        {
          "element_key": "columnsMenuBtn",
          "access": "hidden"
        },
        {
          "element_key": "paginator",
          "access": "hidden"
        },
        {
          "element_key": "matSortHeader",
          "access": "hidden"
        },
        {
          "element_key": "resetColumnsBtn",
          "access": "hidden"
        },
        {
          "element_key": "rowClickToggle",
          "access": "hidden"
        },
        {
          "element_key": "toggleColumnItem",
          "access": "hidden"
        }
      ]
    },
    {
      "component": "auth",
      "route": "/auth",
      "access": "execute",
      "elements": [
        {
          "element_key": "loginButton",
          "access": "hidden"
        },
        {
          "element_key": "togglePasswordButton",
          "access": "hidden"
        },
        {
          "element_key": "goBackButton",
          "access": "hidden"
        },
        {
          "element_key": "resendCodeButton",
          "access": "hidden"
        }
      ]
    },
    {
      "component": "user-management",
      "route": "/admin/users",
      "access": "execute",
      "elements": [
        {
          "element_key": "btn-create-user",
          "access": "hidden"
        },
        {
          "element_key": "btn-edit-user",
          "access": "hidden"
        },
        {
          "element_key": "btn-delete-user",
          "access": "hidden"
        },
        {
          "element_key": "btn-invite-user",
          "access": "hidden"
        },
        {
          "element_key": "btn-suspend-user",
          "access": "hidden"
        },
        {
          "element_key": "searchInput",
          "access": "hidden"
        },
        {
          "element_key": "paginator",
          "access": "hidden"
        },
        {
          "element_key": "tab-roles",
          "access": "hidden"
        }
      ]
    },
    {
      "component": "role-management",
      "route": "/admin/roles",
      "access": "execute",
      "elements": [
        {
          "element_key": "btn-create-role",
          "access": "hidden"
        },
        {
          "element_key": "btn-edit-role",
          "access": "hidden"
        },
        {
          "element_key": "btn-delete-role",
          "access": "hidden"
        },
        {
          "element_key": "btn-assign-role",
          "access": "hidden"
        }
      ]
    },
    {
      "component": "menu-management",
      "route": "/admin/menus",
      "access": "execute",
      "elements": []
    },
    {
      "component": "audit-viewer",
      "route": "/admin/audit",
      "access": "execute",
      "elements": []
    },
    {
      "component": "tenant-settings",
      "route": "/admin/settings",
      "access": "execute",
      "elements": []
    }
  ],
  "token": null
}
```

**Análisis de esta respuesta:**

- **6 menús principales**: 4 en navbar (Dashboard, Alertas, Incidentes, Traps) + 2 grupos en profile (Perfil, Administración)
- **Grupo "Perfil"**: `access: "execute"` → Se muestra con 3 opciones
- **Grupo "Administración"**: `access: "hidden"` → NO se muestra en la UI
- **10 componentes con permisos**: Cada uno con diferentes elementos ocultos o habilitados

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

### Profile Dropdown (location: profile)

```
┌────────────────────────┐
│  👤 Perfil             │  ← GROUP (sin ruta, access: execute)
│  ├─ Mi Perfil          │  ← ITEM (route: /profile)
│  ├─ Configuración      │  ← ITEM (route: /admin/settings)
│  └─ Cerrar Sesión      │  ← ITEM (route: /auth/login)
│                        │
│  🛡️ Administración     │  ← GROUP con access: "hidden"
│  (No se muestra)       │     (solo visible si access: execute)
│  ├─ Usuarios           │  ← ITEM (route: /admin/users)
│  ├─ Roles              │  ← ITEM (route: /admin/roles)
│  ├─ Menús              │  ← ITEM (route: /admin/menus)
│  └─ Auditoría          │  ← ITEM (route: /admin/audit)
└────────────────────────┘
```

**Nota:** El grupo "Administración" tiene `access: "hidden"`, por lo que aunque esté en el perfil, no se muestra en la UI para roles sin privilegios administrativos.

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

## 🎓 Guía Paso a Paso: Cómo Implementar Menús y Permisos

Esta sección explica de forma clara y práctica cómo agregar menús y permisos a un nuevo componente en NexCore.

---

### 📝 Escenario: Crear un nuevo módulo "Reportes"

Vamos a crear un módulo completo de reportes con su menú, permisos y elementos controlados.

---

### 🗂️ PASO 1: Crear el Componente en la Base de Datos

#### 1.1. Crear el Componente

```sql
-- Tabla: nxc_config.components
-- Registrar el componente principal
INSERT INTO nxc_config.components (
    id,
    component_key,
    component_name,
    description,
    is_active,
    created_at,
    created_by
) VALUES (
    gen_random_uuid(),
    'reports',                    -- ← Identificador único del componente
    'Reportes',                   -- ← Nombre descriptivo
    'Módulo de generación y visualización de reportes',
    true,
    NOW(),
    '00000000-0000-0000-0001-000000000001'  -- Super Admin
);
```

#### 1.2. Crear los Elementos del Componente

```sql
-- Tabla: nxc_config.component_elements
-- Definir los elementos que se pueden controlar dentro del componente
INSERT INTO nxc_config.component_elements (
    id,
    component_id,
    element_key,
    element_name,
    description,
    is_active
) VALUES 
-- Botones
(gen_random_uuid(), 
 (SELECT id FROM nxc_config.components WHERE component_key = 'reports'),
 'btn-create-report',          -- ← ID del botón de crear
 'Botón Crear Reporte',
 'Permite crear un nuevo reporte',
 true),

(gen_random_uuid(),
 (SELECT id FROM nxc_config.components WHERE component_key = 'reports'),
 'btn-export-pdf',             -- ← ID del botón de exportar PDF
 'Botón Exportar PDF',
 'Permite exportar reporte a PDF',
 true),

(gen_random_uuid(),
 (SELECT id FROM nxc_config.components WHERE component_key = 'reports'),
 'btn-export-excel',           -- ← ID del botón de exportar Excel
 'Botón Exportar Excel',
 'Permite exportar reporte a Excel',
 true),

-- Inputs y filtros
(gen_random_uuid(),
 (SELECT id FROM nxc_config.components WHERE component_key = 'reports'),
 'searchInput',                -- ← ID del input de búsqueda
 'Input de Búsqueda',
 'Permite buscar reportes',
 true),

(gen_random_uuid(),
 (SELECT id FROM nxc_config.components WHERE component_key = 'reports'),
 'dateRangeFilter',            -- ← ID del filtro de fechas
 'Filtro de Rango de Fechas',
 'Permite filtrar por rango de fechas',
 true),

-- Secciones
(gen_random_uuid(),
 (SELECT id FROM nxc_config.components WHERE component_key = 'reports'),
 'section-charts',             -- ← ID de la sección de gráficos
 'Sección de Gráficos',
 'Muestra gráficos estadísticos',
 true);
```

---

### 🎯 PASO 2: Crear el Menú

#### 2.1. Crear el Item de Menú

```sql
-- Tabla: nxc_menu.menu_items
-- Crear el menú que aparecerá en la navegación
INSERT INTO nxc_menu.menu_items (
    id,
    tenant_id,
    parent_id,                    -- NULL = menú de nivel superior
    name,
    title,
    icon,
    icon_type,
    route,
    location,
    item_type,
    order_index,
    is_active
) VALUES (
    gen_random_uuid(),
    '00000000-0000-0000-0000-000000000001',  -- Tenant sistema
    NULL,                         -- Sin padre (nivel superior)
    'Reports',                    -- ← Identificador técnico
    'Reportes',                   -- ← Texto visible en la UI
    'file-analytics',             -- ← Icono de Tabler Icons
    'tabler',
    '/reports',                   -- ← Ruta de navegación
    'navbar',                     -- ← Ubicación: aparece en navbar principal
    'ITEM',                       -- ← Tipo: enlace directo
    50,                           -- ← Orden de visualización
    true
);
```

#### 2.2. Alternativa: Crear Menú dentro de un Grupo

Si quieres que aparezca en el dropdown de perfil:

```sql
INSERT INTO nxc_menu.menu_items (
    id,
    tenant_id,
    parent_id,                    -- ← Asignar al grupo "ProfileMenu"
    name,
    title,
    icon,
    icon_type,
    route,
    location,
    item_type,
    order_index,
    is_active
) VALUES (
    gen_random_uuid(),
    '00000000-0000-0000-0000-000000000001',
    (SELECT id FROM nxc_menu.menu_items WHERE name = 'ProfileMenu'),  -- ← Hijo de ProfileMenu
    'Reports',
    'Mis Reportes',
    'file-analytics',
    'tabler',
    '/reports',
    'profile',                    -- ← Ubicación: dropdown de perfil
    'ITEM',
    35,
    true
);
```

---

### 🔐 PASO 3: Asignar Permisos al Rol

#### 3.1. Dar acceso al componente completo

```sql
-- Tabla: nxc_menu.role_component_permissions
-- Dar permiso de acceso al componente para un rol específico
INSERT INTO nxc_menu.role_component_permissions (
    id,
    tenant_id,
    role_id,
    component_id,
    access_level,
    created_at,
    created_by
) VALUES (
    gen_random_uuid(),
    '00000000-0000-0000-0000-000000000001',
    (SELECT id FROM nxc_tenant.roles WHERE role_name = 'TENANT_ADMIN'),  -- ← Rol
    (SELECT id FROM nxc_config.components WHERE component_key = 'reports'),  -- ← Componente
    'EXECUTE',                    -- ← Nivel de acceso: execute, view, hidden
    NOW(),
    '00000000-0000-0000-0001-000000000001'
);
```

**Niveles de acceso:**
- `EXECUTE`: Puede acceder y ejecutar todas las acciones
- `VIEW`: Solo puede ver, sin ejecutar acciones
- `HIDDEN`: No puede acceder al componente

#### 3.2. Dar permisos a elementos específicos

```sql
-- Tabla: nxc_menu.role_element_permissions
-- Controlar qué elementos (botones, inputs) puede usar el rol
INSERT INTO nxc_menu.role_element_permissions (
    id,
    tenant_id,
    role_id,
    element_id,
    access_level,
    created_at,
    created_by
) VALUES 
-- Puede crear reportes
(gen_random_uuid(),
 '00000000-0000-0000-0000-000000000001',
 (SELECT id FROM nxc_tenant.roles WHERE role_name = 'TENANT_ADMIN'),
 (SELECT id FROM nxc_config.component_elements WHERE element_key = 'btn-create-report'),
 'EXECUTE',                       -- ← Botón visible y clickeable
 NOW(),
 '00000000-0000-0000-0001-000000000001'),

-- Puede exportar a PDF
(gen_random_uuid(),
 '00000000-0000-0000-0000-000000000001',
 (SELECT id FROM nxc_tenant.roles WHERE role_name = 'TENANT_ADMIN'),
 (SELECT id FROM nxc_config.component_elements WHERE element_key = 'btn-export-pdf'),
 'EXECUTE',
 NOW(),
 '00000000-0000-0000-0001-000000000001'),

-- NO puede exportar a Excel
(gen_random_uuid(),
 '00000000-0000-0000-0000-000000000001',
 (SELECT id FROM nxc_tenant.roles WHERE role_name = 'TENANT_ADMIN'),
 (SELECT id FROM nxc_config.component_elements WHERE element_key = 'btn-export-excel'),
 'HIDDEN',                        -- ← Botón oculto
 NOW(),
 '00000000-0000-0000-0001-000000000001'),

-- Puede buscar
(gen_random_uuid(),
 '00000000-0000-0000-0000-000000000001',
 (SELECT id FROM nxc_tenant.roles WHERE role_name = 'TENANT_ADMIN'),
 (SELECT id FROM nxc_config.component_elements WHERE element_key = 'searchInput'),
 'EXECUTE',
 NOW(),
 '00000000-0000-0000-0001-000000000001'),

-- Puede filtrar por fechas
(gen_random_uuid(),
 '00000000-0000-0000-0000-000000000001',
 (SELECT id FROM nxc_tenant.roles WHERE role_name = 'TENANT_ADMIN'),
 (SELECT id FROM nxc_config.component_elements WHERE element_key = 'dateRangeFilter'),
 'EXECUTE',
 NOW(),
 '00000000-0000-0000-0001-000000000001'),

-- Puede ver gráficos
(gen_random_uuid(),
 '00000000-0000-0000-0000-000000000001',
 (SELECT id FROM nxc_tenant.roles WHERE role_name = 'TENANT_ADMIN'),
 (SELECT id FROM nxc_config.component_elements WHERE element_key = 'section-charts'),
 'VIEW',                          -- ← Solo ver, no interactuar
 NOW(),
 '00000000-0000-0000-0001-000000000001');
```

#### 3.3. Asignar el menú al rol

```sql
-- Tabla: nxc_menu.role_menu_items
-- Asignar el menú al rol para que aparezca en la UI
INSERT INTO nxc_menu.role_menu_items (
    id,
    tenant_id,
    role_id,
    menu_item_id,
    access_level,
    created_at,
    created_by
) VALUES (
    gen_random_uuid(),
    '00000000-0000-0000-0000-000000000001',
    (SELECT id FROM nxc_tenant.roles WHERE role_name = 'TENANT_ADMIN'),
    (SELECT id FROM nxc_menu.menu_items WHERE name = 'Reports'),
    'EXECUTE',                    -- ← Menú visible y clickeable
    NOW(),
    '00000000-0000-0000-0001-000000000001'
);
```

---

### 🎨 PASO 4: Implementar en el Frontend (Angular)

#### 4.1. Crear el Componente

```bash
ng generate component features/reports
```

#### 4.2. Configurar la Ruta con Protección

```typescript
// app.routes.ts
import { ReportsComponent } from './features/reports/reports.component';
import { permissionGuard } from './core/guards/permission.guard';

export const routes: Routes = [
  // ... otras rutas
  {
    path: 'reports',
    component: ReportsComponent,
    canActivate: [permissionGuard],      // ← Guard de permisos
    data: { component: 'reports' }       // ← Nombre del componente a validar
  }
];
```

#### 4.3. Implementar el Componente TypeScript

```typescript
// reports.component.ts
import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Observable, firstValueFrom } from 'rxjs';
import { PermissionService } from '@core/services/permission.service';

@Component({
  selector: 'app-reports',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './reports.component.html',
  styleUrls: ['./reports.component.scss']
})
export class ReportsComponent implements OnInit {
  
  // Observables para controlar permisos de elementos
  canCreate$: Observable<boolean>;
  canExportPDF$: Observable<boolean>;
  canExportExcel$: Observable<boolean>;
  canSearch$: Observable<boolean>;
  canFilterDate$: Observable<boolean>;
  canViewCharts$: Observable<boolean>;

  // Propiedades del componente
  searchTerm: string = '';
  reports: any[] = [];
  displayedColumns: string[] = ['name', 'date'];

  constructor(private permissionService: PermissionService) {
    // Inicializar permisos de elementos
    this.canCreate$ = this.permissionService.canExecute$('reports', 'btn-create-report');
    this.canExportPDF$ = this.permissionService.canExecute$('reports', 'btn-export-pdf');
    this.canExportExcel$ = this.permissionService.canExecute$('reports', 'btn-export-excel');
    this.canSearch$ = this.permissionService.canExecute$('reports', 'searchInput');
    this.canFilterDate$ = this.permissionService.canExecute$('reports', 'dateRangeFilter');
    this.canViewCharts$ = this.permissionService.canView$('reports', 'section-charts');
  }

  ngOnInit(): void {
    this.loadReports();
  }

  async createReport() {
    // Validar permiso antes de ejecutar acción crítica
    const canCreate = await firstValueFrom(this.canCreate$);
    if (!canCreate) {
      this.showError('No tienes permiso para crear reportes');
      return;
    }
    
    // Lógica para crear reporte
    console.log('Creando reporte...');
  }

  async exportPDF() {
    const canExport = await firstValueFrom(this.canExportPDF$);
    if (!canExport) {
      this.showError('No tienes permiso para exportar a PDF');
      return;
    }
    
    console.log('Exportando a PDF...');
  }

  async exportExcel() {
    const canExport = await firstValueFrom(this.canExportExcel$);
    if (!canExport) {
      this.showError('No tienes permiso para exportar a Excel');
      return;
    }
    
    console.log('Exportando a Excel...');
  }

  loadReports() {
    // Lógica para cargar reportes
  }

  showError(message: string) {
    // Mostrar mensaje de error
  }
}
```

#### 4.4. Implementar el Template HTML

```html
<!-- reports.component.html -->
<div class="reports-container">
  
  <!-- Header con título y acciones -->
  <div class="reports-header">
    <h1>Reportes</h1>
    
    <div class="actions">
      <!-- Botón Crear (solo si tiene permiso) -->
      <button *ngIf="canCreate$ | async"
              class="btn btn-primary"
              (click)="createReport()">
        <mat-icon>add</mat-icon>
        Crear Reporte
      </button>

      <!-- Botón Exportar PDF (solo si tiene permiso) -->
      <button *ngIf="canExportPDF$ | async"
              class="btn btn-secondary"
              (click)="exportPDF()">
        <mat-icon>picture_as_pdf</mat-icon>
        Exportar PDF
      </button>

      <!-- Botón Exportar Excel (solo si tiene permiso) -->
      <button *ngIf="canExportExcel$ | async"
              class="btn btn-secondary"
              (click)="exportExcel()">
        <mat-icon>table_chart</mat-icon>
        Exportar Excel
      </button>
    </div>
  </div>

  <!-- Filtros (solo si tiene permiso) -->
  <div class="reports-filters" *ngIf="(canSearch$ | async) || (canFilterDate$ | async)">
    
    <!-- Input de búsqueda -->
    <input *ngIf="canSearch$ | async"
           type="text"
           placeholder="Buscar reportes..."
           class="search-input"
           [(ngModel)]="searchTerm">

    <!-- Filtro de rango de fechas -->
    <mat-date-range-input *ngIf="canFilterDate$ | async">
      <input matStartDate placeholder="Fecha inicio">
      <input matEndDate placeholder="Fecha fin">
    </mat-date-range-input>
  </div>

  <!-- Lista de reportes -->
  <div class="reports-list">
    <table mat-table [dataSource]="reports">
      <!-- Columnas de la tabla -->
      <ng-container matColumnDef="name">
        <th mat-header-cell *matHeaderCellDef>Nombre</th>
        <td mat-cell *matCellDef="let report">{{ report.name }}</td>
      </ng-container>

      <ng-container matColumnDef="date">
        <th mat-header-cell *matHeaderCellDef>Fecha</th>
        <td mat-cell *matCellDef="let report">{{ report.date | date }}</td>
      </ng-container>

      <tr mat-header-row *matHeaderRowDef="displayedColumns"></tr>
      <tr mat-row *matRowDef="let row; columns: displayedColumns;"></tr>
    </table>
  </div>

  <!-- Sección de gráficos (solo si tiene permiso VIEW o EXECUTE) -->
  <div class="reports-charts" *ngIf="canViewCharts$ | async">
    <h2>Estadísticas</h2>
    <app-chart-stats></app-chart-stats>
  </div>

</div>
```

---

### 🔄 PASO 5: Verificar el Flujo Completo

#### 5.1. Backend: Verificar que se retorna en el perfil

Después de hacer login, el endpoint `/api/profile` debe retornar:

```json
{
  "user": { ... },
  "menus": [
    {
      "id": "...",
      "name": "Reports",
      "title": "Reportes",
      "route": "/reports",
      "location": "navbar",
      "item_type": "ITEM",
      "access": "execute"
    }
  ],
  "permissions": [
    {
      "component": "reports",
      "route": "/reports",
      "access": "execute",
      "elements": [
        {
          "element_key": "btn-create-report",
          "access": "execute"
        },
        {
          "element_key": "btn-export-pdf",
          "access": "execute"
        },
        {
          "element_key": "btn-export-excel",
          "access": "hidden"
        },
        {
          "element_key": "searchInput",
          "access": "execute"
        },
        {
          "element_key": "dateRangeFilter",
          "access": "execute"
        },
        {
          "element_key": "section-charts",
          "access": "view"
        }
      ]
    }
  ]
}
```

#### 5.2. Frontend: Verificar en navegador

1. **Hacer login** como usuario con rol TENANT_ADMIN
2. **Verificar en navbar**: Debe aparecer el menú "Reportes"
3. **Hacer clic** en "Reportes"
4. **Verificar elementos visibles:**
   - ✅ Botón "Crear Reporte" → visible
   - ✅ Botón "Exportar PDF" → visible
   - ❌ Botón "Exportar Excel" → oculto (access: hidden)
   - ✅ Input de búsqueda → visible
   - ✅ Filtro de fechas → visible
   - ✅ Sección de gráficos → visible (pero sin interacción, solo VIEW)

#### 5.3. Consola del navegador: Verificar localStorage

```javascript
// Ver perfil completo
JSON.parse(localStorage.getItem('profile'))

// Ver el menú de reportes
JSON.parse(localStorage.getItem('profile')).menus.find(m => m.name === 'Reports')

// Ver permisos de reportes
JSON.parse(localStorage.getItem('profile')).permissions.find(p => p.component === 'reports')
```

---

### ✅ Checklist Completo

#### Base de Datos
- [ ] ✅ Componente creado en `nxc_config.components`
- [ ] ✅ Elementos creados en `nxc_config.component_elements`
- [ ] ✅ Menú creado en `nxc_menu.menu_items`
- [ ] ✅ Permiso de componente asignado en `nxc_menu.role_component_permissions`
- [ ] ✅ Permisos de elementos asignados en `nxc_menu.role_element_permissions`
- [ ] ✅ Menú asignado al rol en `nxc_menu.role_menu_items`

#### Backend
- [ ] ✅ Endpoint `/api/profile` retorna el menú
- [ ] ✅ Endpoint `/api/profile` retorna los permisos

#### Frontend
- [ ] ✅ Componente Angular creado
- [ ] ✅ Ruta configurada con `permissionGuard`
- [ ] ✅ Permisos de elementos inicializados en constructor
- [ ] ✅ Template usa `*ngIf` con Observables
- [ ] ✅ Validación de permisos en métodos críticos

#### Verificación
- [ ] ✅ Menú aparece en navbar/profile
- [ ] ✅ Clic en menú navega a la ruta correcta
- [ ] ✅ Elementos con `access: execute` son visibles y funcionales
- [ ] ✅ Elementos con `access: hidden` están ocultos
- [ ] ✅ Elementos con `access: view` son visibles pero deshabilitados

---

### 🎯 Resultado Final

**Para el rol TENANT_ADMIN:**

```
┌─────────────────────────────────────────────────────┐
│  Navbar                                             │
│  Dashboard │ Alertas │ Incidentes │ Traps │ Reportes │
└─────────────────────────────────────────────────────┘

Página de Reportes:
┌─────────────────────────────────────────────────────┐
│  📊 Reportes                                        │
│  [+ Crear Reporte] [📄 Exportar PDF]                │  ← Exportar Excel oculto
├─────────────────────────────────────────────────────┤
│  🔍 [Buscar...]  📅 [Fecha inicio - Fecha fin]      │
├─────────────────────────────────────────────────────┤
│  Tabla de reportes...                               │
├─────────────────────────────────────────────────────┤
│  📈 Estadísticas (solo visualización)               │  ← access: VIEW
└─────────────────────────────────────────────────────┘
```

---

### 📊 Diagrama de Flujo Completo

```
┌──────────────────────────────────────────────────────────────────┐
│                        BASE DE DATOS                              │
├──────────────────────────────────────────────────────────────────┤
│  1. nxc_config.components                                        │
│     └─ 'reports' component                                       │
│                                                                  │
│  2. nxc_config.component_elements                                │
│     ├─ 'btn-create-report'                                       │
│     ├─ 'btn-export-pdf'                                          │
│     ├─ 'btn-export-excel'                                        │
│     ├─ 'searchInput'                                             │
│     ├─ 'dateRangeFilter'                                         │
│     └─ 'section-charts'                                          │
│                                                                  │
│  3. nxc_menu.menu_items                                          │
│     └─ 'Reports' menu (navbar)                                   │
│                                                                  │
│  4. nxc_menu.role_menu_items                                     │
│     └─ TENANT_ADMIN → 'Reports' menu [EXECUTE]                  │
│                                                                  │
│  5. nxc_menu.role_component_permissions                          │
│     └─ TENANT_ADMIN → 'reports' component [EXECUTE]             │
│                                                                  │
│  6. nxc_menu.role_element_permissions                            │
│     ├─ TENANT_ADMIN → 'btn-create-report' [EXECUTE]             │
│     ├─ TENANT_ADMIN → 'btn-export-pdf' [EXECUTE]                │
│     ├─ TENANT_ADMIN → 'btn-export-excel' [HIDDEN]               │
│     ├─ TENANT_ADMIN → 'searchInput' [EXECUTE]                   │
│     ├─ TENANT_ADMIN → 'dateRangeFilter' [EXECUTE]               │
│     └─ TENANT_ADMIN → 'section-charts' [VIEW]                   │
└──────────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────────┐
│                         BACKEND API                               │
├──────────────────────────────────────────────────────────────────┤
│  GET /api/profile                                                │
│  └─ Consulta vistas:                                             │
│      ├─ v_user_menu_access (menús)                               │
│      └─ v_user_permissions (permisos)                            │
│                                                                  │
│  Respuesta JSON:                                                 │
│  {                                                               │
│    "user": { ... },                                              │
│    "menus": [                                                    │
│      {                                                           │
│        "name": "Reports",                                        │
│        "route": "/reports",                                      │
│        "location": "navbar",                                     │
│        "access": "execute"                                       │
│      }                                                           │
│    ],                                                            │
│    "permissions": [                                              │
│      {                                                           │
│        "component": "reports",                                   │
│        "access": "execute",                                      │
│        "elements": [                                             │
│          { "element_key": "btn-create-report", "access": "execute" },│
│          { "element_key": "btn-export-excel", "access": "hidden" }  │
│        ]                                                         │
│      }                                                           │
│    ]                                                             │
│  }                                                               │
└──────────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────────┐
│                      FRONTEND (ANGULAR)                           │
├──────────────────────────────────────────────────────────────────┤
│  1. AuthService.login()                                          │
│     └─ Recibe perfil completo del backend                        │
│                                                                  │
│  2. ProfileService.setProfile(data)                              │
│     ├─ Guarda menus$ BehaviorSubject                             │
│     └─ Guarda permissions$ BehaviorSubject                       │
│                                                                  │
│  3. NavbarComponent                                              │
│     └─ Filtra menus con location: 'navbar'                       │
│        → Muestra "Reportes" en navbar                            │
│                                                                  │
│  4. Usuario hace clic en "Reportes"                              │
│     └─ Router navega a /reports                                  │
│                                                                  │
│  5. permissionGuard                                              │
│     └─ Valida si user tiene permiso del component 'reports'     │
│        ✅ access: 'execute' → Permite acceso                     │
│                                                                  │
│  6. ReportsComponent carga                                       │
│     └─ Constructor inicializa Observables:                       │
│        ├─ canCreate$ = canExecute$('reports', 'btn-create')     │
│        ├─ canExportPDF$ = canExecute$('reports', 'btn-export-pdf')│
│        └─ canExportExcel$ = canExecute$('reports', 'btn-export-excel')│
│                                                                  │
│  7. Template renderiza                                           │
│     ├─ *ngIf="canCreate$ | async" → ✅ Muestra botón            │
│     ├─ *ngIf="canExportPDF$ | async" → ✅ Muestra botón         │
│     └─ *ngIf="canExportExcel$ | async" → ❌ Oculta botón        │
│                                                                  │
│  8. Usuario hace clic en "Crear Reporte"                         │
│     └─ Método createReport() valida permiso nuevamente           │
│        ✅ Permiso OK → Ejecuta lógica                            │
└──────────────────────────────────────────────────────────────────┘
```

---

### 💡 Puntos Clave

1. **Base de Datos es la fuente de verdad**
   - Todo se define primero en PostgreSQL
   - Componentes, elementos, menús, roles, permisos

2. **Backend unifica los datos**
   - Endpoint `/api/profile` retorna todo junto
   - Usa vistas SQL para optimizar consultas

3. **Frontend es reactivo**
   - Usa Observables para permisos
   - Componentes se suscriben y reaccionan automáticamente
   - Template usa `*ngIf` con `async pipe`

4. **Validación en múltiples capas**
   - Guard: Valida acceso a la ruta
   - Componente: Valida acceso a elementos
   - Métodos: Valida antes de ejecutar acciones críticas

5. **Sin hard-coding**
   - Ningún permiso está hardcodeado en el frontend
   - Todo viene del backend dinámicamente
   - Cambios en BD se reflejan automáticamente

---

### 🎯 Casos de Uso Prácticos

#### Caso 1: Dar acceso a un nuevo rol

**Situación:** El rol "EDITOR" necesita acceso al módulo de reportes pero sin poder crear ni exportar.

```sql
-- 1. Asignar el menú (para que aparezca en navbar)
INSERT INTO nxc_menu.role_menu_items (id, tenant_id, role_id, menu_item_id, access_level)
VALUES (
    gen_random_uuid(),
    '00000000-0000-0000-0000-000000000001',
    (SELECT id FROM nxc_tenant.roles WHERE role_name = 'EDITOR'),
    (SELECT id FROM nxc_menu.menu_items WHERE name = 'Reports'),
    'EXECUTE'  -- Menú visible
);

-- 2. Dar acceso VIEW al componente (puede ver pero no modificar)
INSERT INTO nxc_menu.role_component_permissions (id, tenant_id, role_id, component_id, access_level)
VALUES (
    gen_random_uuid(),
    '00000000-0000-0000-0000-000000000001',
    (SELECT id FROM nxc_tenant.roles WHERE role_name = 'EDITOR'),
    (SELECT id FROM nxc_config.components WHERE component_key = 'reports'),
    'VIEW'  -- Solo lectura
);

-- 3. Ocultar botones de acción
INSERT INTO nxc_menu.role_element_permissions (id, tenant_id, role_id, element_id, access_level)
VALUES 
(gen_random_uuid(), '00000000-0000-0000-0000-000000000001',
 (SELECT id FROM nxc_tenant.roles WHERE role_name = 'EDITOR'),
 (SELECT id FROM nxc_config.component_elements WHERE element_key = 'btn-create-report'),
 'HIDDEN'),  -- No puede crear
(gen_random_uuid(), '00000000-0000-0000-0000-000000000001',
 (SELECT id FROM nxc_tenant.roles WHERE role_name = 'EDITOR'),
 (SELECT id FROM nxc_config.component_elements WHERE element_key = 'btn-export-pdf'),
 'HIDDEN'),  -- No puede exportar
(gen_random_uuid(), '00000000-0000-0000-0000-000000000001',
 (SELECT id FROM nxc_tenant.roles WHERE role_name = 'EDITOR'),
 (SELECT id FROM nxc_config.component_elements WHERE element_key = 'searchInput'),
 'EXECUTE');  -- Sí puede buscar
```

**Resultado:** EDITOR ve el menú "Reportes", puede entrar y buscar, pero no ve botones de crear/exportar.

---

#### Caso 2: Quitar acceso temporal a un componente

**Situación:** Necesitas deshabilitar temporalmente el acceso a "Reportes" para todos los VIEWERS.

```sql
-- Opción 1: Cambiar a HIDDEN (más rápido)
UPDATE nxc_menu.role_component_permissions
SET access_level = 'HIDDEN'
WHERE role_id = (SELECT id FROM nxc_tenant.roles WHERE role_name = 'VIEWER')
  AND component_id = (SELECT id FROM nxc_config.components WHERE component_key = 'reports');

-- Opción 2: Desactivar el menú para ese rol
UPDATE nxc_menu.role_menu_items
SET access_level = 'HIDDEN'
WHERE role_id = (SELECT id FROM nxc_tenant.roles WHERE role_name = 'VIEWER')
  AND menu_item_id = (SELECT id FROM nxc_menu.menu_items WHERE name = 'Reports');
```

**Resultado:** VIEWER ya no ve el menú "Reportes" en navbar ni puede acceder a `/reports`.

---

#### Caso 3: Mover menú de navbar a profile dropdown

**Situación:** El menú "Reportes" debe moverse del navbar principal al dropdown de perfil.

```sql
-- Actualizar la ubicación del menú
UPDATE nxc_menu.menu_items
SET location = 'profile',
    parent_id = (SELECT id FROM nxc_menu.menu_items WHERE name = 'ProfileMenu')
WHERE name = 'Reports';
```

**Resultado:** "Reportes" desaparece del navbar y aparece en el dropdown de perfil.

---

#### Caso 4: Crear un submenú

**Situación:** Quieres crear un grupo "Gestión" en navbar con submenús "Reportes" y "Configuración".

```sql
-- 1. Crear el grupo padre
INSERT INTO nxc_menu.menu_items (id, tenant_id, parent_id, name, title, icon, icon_type, route, location, item_type, order_index, is_active)
VALUES (
    gen_random_uuid(),
    '00000000-0000-0000-0000-000000000001',
    NULL,  -- Sin padre
    'Management',
    'Gestión',
    'settings',
    'tabler',
    NULL,  -- Los grupos no tienen ruta
    'navbar',
    'GROUP',  -- Es un grupo
    60,
    true
);

-- 2. Actualizar "Reportes" para que sea hijo de "Gestión"
UPDATE nxc_menu.menu_items
SET parent_id = (SELECT id FROM nxc_menu.menu_items WHERE name = 'Management'),
    location = 'navbar'  -- Heredará del padre
WHERE name = 'Reports';

-- 3. Asignar el grupo al rol
INSERT INTO nxc_menu.role_menu_items (id, tenant_id, role_id, menu_item_id, access_level)
VALUES (
    gen_random_uuid(),
    '00000000-0000-0000-0000-000000000001',
    (SELECT id FROM nxc_tenant.roles WHERE role_name = 'TENANT_ADMIN'),
    (SELECT id FROM nxc_menu.menu_items WHERE name = 'Management'),
    'EXECUTE'
);
```

**Resultado:** En navbar aparece "Gestión ▼" con un dropdown que contiene "Reportes".

---

#### Caso 5: Condicionar elemento según tenant

**Situación:** Solo el tenant con id específico debe ver el botón "Exportar Excel".

```sql
-- Opción 1: Crear permiso específico para un tenant
INSERT INTO nxc_menu.role_element_permissions (id, tenant_id, role_id, element_id, access_level)
VALUES (
    gen_random_uuid(),
    '00000000-0000-0000-0000-000000000002',  -- ← Tenant específico
    (SELECT id FROM nxc_tenant.roles WHERE role_name = 'TENANT_ADMIN'),
    (SELECT id FROM nxc_config.component_elements WHERE element_key = 'btn-export-excel'),
    'EXECUTE'
);

-- Para otros tenants, usar HIDDEN
INSERT INTO nxc_menu.role_element_permissions (id, tenant_id, role_id, element_id, access_level)
VALUES (
    gen_random_uuid(),
    '00000000-0000-0000-0000-000000000001',  -- ← Otro tenant
    (SELECT id FROM nxc_tenant.roles WHERE role_name = 'TENANT_ADMIN'),
    (SELECT id FROM nxc_config.component_elements WHERE element_key = 'btn-export-excel'),
    'HIDDEN'
);
```

**Resultado:** Solo usuarios del tenant específico ven el botón "Exportar Excel".

---

### ⚠️ Errores Comunes y Soluciones

#### Error 1: "El menú no aparece en navbar"

**Causas:**
1. No se asignó el menú al rol en `role_menu_items`
2. `access_level` está en `HIDDEN`
3. El usuario no tiene ese rol asignado

**Solución:**
```sql
-- Verificar asignación
SELECT rmi.*, mi.name, mi.title, r.role_name
FROM nxc_menu.role_menu_items rmi
JOIN nxc_menu.menu_items mi ON mi.id = rmi.menu_item_id
JOIN nxc_tenant.roles r ON r.id = rmi.role_id
WHERE mi.name = 'Reports';

-- Si no existe, crear
INSERT INTO nxc_menu.role_menu_items (id, tenant_id, role_id, menu_item_id, access_level)
VALUES (gen_random_uuid(), '...', '...', '...', 'EXECUTE');
```

---

#### Error 2: "El componente no carga (guard bloquea)"

**Causas:**
1. No existe permiso del componente para ese rol
2. `access_level` está en `HIDDEN`
3. Nombre del componente no coincide con `data.component` en rutas

**Solución:**
```sql
-- Verificar permiso del componente
SELECT rcp.*, c.component_key, r.role_name, rcp.access_level
FROM nxc_menu.role_component_permissions rcp
JOIN nxc_config.components c ON c.id = rcp.component_id
JOIN nxc_tenant.roles r ON r.id = rcp.role_id
WHERE c.component_key = 'reports';

-- Si no existe, crear con EXECUTE o VIEW
INSERT INTO nxc_menu.role_component_permissions (id, tenant_id, role_id, component_id, access_level)
VALUES (gen_random_uuid(), '...', '...', '...', 'EXECUTE');
```

---

#### Error 3: "Todos los botones aparecen aunque deberían estar ocultos"

**Causas:**
1. No se crearon permisos de elementos
2. El componente no está usando `*ngIf` con permisos
3. Falta importar `PermissionService`

**Solución en Frontend:**
```typescript
// ❌ MAL: Sin validación
<button (click)="export()">Exportar</button>

// ✅ BIEN: Con validación
<button *ngIf="canExport$ | async" (click)="export()">Exportar</button>

// En el componente
canExport$: Observable<boolean>;

constructor(private permissionService: PermissionService) {
  this.canExport$ = this.permissionService.canExecute$('reports', 'btn-export-excel');
}
```

---

#### Error 4: "El perfil no se actualiza después de cambiar permisos en BD"

**Causa:** El perfil se carga al hacer login y se guarda en localStorage.

**Solución:**
```typescript
// Opción 1: Hacer logout y login nuevamente
this.authService.logout();

// Opción 2: Forzar recarga del perfil
this.profileService.loadProfile().subscribe();

// Opción 3: Limpiar localStorage y refrescar
localStorage.clear();
window.location.reload();
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
