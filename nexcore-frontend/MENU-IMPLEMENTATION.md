# Implementación del Sistema de Menús y Permisos - NexCore

## 📋 Resumen

Se ha implementado el sistema de menús dinámicos y permisos según el spec **05-menu-permiso-spec.md**. Esta implementación incluye:

- ✅ **ProfileService**: Gestión del perfil de usuario, menús y permisos
- ✅ **MenuService**: Filtrado de menús por ubicación (navbar, profile, sidebar, footer)
- ✅ **PermissionService**: Validación de permisos a nivel componente y elemento
- ✅ **NavbarComponent**: Actualizado para mostrar menús dinámicos
- ✅ **Profile Dropdown**: Menús dinámicos en el dropdown de perfil

## 🗂️ Archivos Creados/Modificados

### Servicios Nuevos
```
src/app/shared/services/
├── profile.service.ts       ← Nuevo
├── permission.service.ts    ← Nuevo
├── menu.service.ts         ← Nuevo
└── index.ts                ← Actualizado
```

### Componentes Modificados
```
src/app/shared/layout/
├── navbar.component.ts     ← Actualizado
├── navbar.component.html   ← Actualizado
└── navbar.component.scss   ← Actualizado
```

## 🔌 Integración con Backend

### Endpoint Esperado

**GET /api/profile**

Debe retornar la estructura definida en el spec:

```json
{
  "user": {
    "iduser": "uuid",
    "username": "admin",
    "name": "Administrador",
    "email": "admin@example.com",
    "phone": null,
    "photo": null,
    "roles": ["ADMIN", "VIEWER"]
  },
  "menus": [
    {
      "id": "uuid",
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
      "id": "uuid",
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
          "id": "uuid",
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
          "element_key": "btn-refresh",
          "access": "execute"
        }
      ]
    }
  ],
  "token": null
}
```

### Ubicaciones de Menú

| Location | Descripción | Implementado |
|----------|-------------|--------------|
| `navbar` | Barra de navegación principal | ✅ Sí |
| `profile` | Dropdown del avatar/perfil | ✅ Sí |
| `sidebar` | Barra lateral | ⏳ Pendiente |
| `footer` | Pie de página | ⏳ Pendiente |

### Tipos de Menú

| item_type | Descripción | Comportamiento |
|-----------|-------------|----------------|
| `ITEM` | Enlace directo | Navega a `route` |
| `GROUP` | Grupo con submenús | Muestra dropdown con `children` |
| `DIVIDER` | Separador visual | Renderiza línea divisoria |
| `EXTERNAL_LINK` | Link externo | Abre en nueva pestaña |

### Niveles de Acceso

| access | Descripción | UI |
|--------|-------------|-----|
| `execute` | Acceso completo | Visible e interactivo |
| `view` | Solo visualización | Visible pero deshabilitado (gris) |
| `hidden` | Sin acceso | No se muestra |

## 🚀 Uso

### 1. ProfileService

Gestiona el perfil del usuario y carga los datos desde el backend.

```typescript
import { ProfileService } from '@shared/services';

constructor(private profileService: ProfileService) {}

ngOnInit() {
  // Cargar perfil desde el backend
  this.profileService.loadProfile().subscribe();
  
  // Acceder al usuario
  this.profileService.user$.subscribe(user => {
    console.log('Usuario actual:', user);
  });
  
  // Obtener menús por ubicación
  this.profileService.getMenusByLocation('navbar').subscribe(menus => {
    console.log('Menús navbar:', menus);
  });
}
```

### 2. MenuService

Filtra y organiza menús por ubicación.

```typescript
import { MenuService } from '@shared/services';

constructor(private menuService: MenuService) {}

ngOnInit() {
  // Obtener menús de navbar
  this.navbarMenus$ = this.menuService.getNavbarMenus();
  
  // Obtener menús de profile
  this.profileMenus$ = this.menuService.getProfileMenus();
}
```

### 3. PermissionService

Valida permisos de componentes y elementos.

```typescript
import { PermissionService } from '@shared/services';

constructor(private permissionService: PermissionService) {}

ngOnInit() {
  // Validar acceso a componente
  this.canViewDashboard$ = this.permissionService.canView$('dashboard');
  this.canExecuteDashboard$ = this.permissionService.canExecute$('dashboard');
  
  // Validar acceso a elemento específico
  this.canCreateUser$ = this.permissionService.canExecute$('user-management', 'btn-create-user');
  
  // Uso en template
  // <button *ngIf="canCreateUser$ | async">Crear Usuario</button>
}
```

### 4. NavbarComponent

El navbar ya está configurado para cargar menús dinámicos automáticamente:

```html
<app-navbar></app-navbar>
```

**Características implementadas:**
- ✅ Menús dinámicos de navbar
- ✅ Menús dinámicos en profile dropdown
- ✅ Soporte para grupos con submenús
- ✅ Estados deshabilitados (access: 'view')
- ✅ Iconos dinámicos
- ✅ Navegación interna y externa
- ✅ Logout con limpieza de perfil

## 📝 Flujo de Carga

```
1. Usuario accede a la aplicación
   ↓
2. NavbarComponent se inicializa (ngOnInit)
   ↓
3. ProfileService.loadProfile() se ejecuta
   ↓
4. GET /api/profile (backend)
   ↓
5. Respuesta guardada en localStorage y BehaviorSubjects
   ↓
6. MenuService filtra menús por location
   ↓
7. Template renderiza menús dinámicos
   ↓
8. Usuario interactúa con menús
```

## 🎨 Personalización de Estilos

Los estilos están en `navbar.component.scss` usando variables CSS:

```scss
// Menú navbar
.navbar-menu-item {
  // Personalizar aquí
}

// Dropdown de profile
.profile-dropdown {
  // Personalizar aquí
}
```

**Variables CSS disponibles:**
- `--color-text-primary`
- `--color-text-secondary`
- `--color-interactive-primary`
- `--hover-bg`
- `--color-surface`
- `--color-border-light`

## 🔒 Persistencia

El perfil se guarda automáticamente en `localStorage` con la clave `'profile'`:

```typescript
localStorage.getItem('profile') // Perfil completo
```

Al hacer logout, el perfil se limpia:

```typescript
profileService.clearProfile() // Limpia memoria y localStorage
```

## 🧪 Testing

### Datos de Prueba (Mock)

Si el backend no está disponible, puedes simular la respuesta:

```typescript
// En app.config.ts o interceptor
export const mockProfile: Profile = {
  user: {
    iduser: '00000000-0000-0000-0001-000000000001',
    username: 'test.user',
    name: 'Usuario de Prueba',
    email: 'test@nexcore.io',
    phone: null,
    photo: null,
    roles: ['USER']
  },
  menus: [
    {
      id: '1',
      name: 'Dashboard',
      title: 'Dashboard',
      icon: 'layout-dashboard',
      icon_type: 'tabler',
      route: '/dashboard',
      location: 'navbar',
      item_type: 'ITEM',
      access: 'execute',
      order_index: 10,
      children: []
    }
  ],
  permissions: [],
  token: null
};
```

## 📋 Checklist de Implementación

### ✅ Completado
- [x] ProfileService creado
- [x] MenuService creado
- [x] PermissionService creado
- [x] NavbarComponent actualizado
- [x] Template navbar actualizado con menús dinámicos
- [x] Profile dropdown con menús dinámicos
- [x] Estilos CSS agregados
- [x] Manejo de estados deshabilitados
- [x] Soporte para grupos y submenús

### ⏳ Pendiente
- [ ] Sidebar con menús dinámicos
- [ ] Footer con menús dinámicos
- [ ] Componente de íconos dinámicos (tabler, material, etc.)
- [ ] Guard de rutas con PermissionService
- [ ] Tests unitarios
- [ ] Tests e2e

## 🐛 Troubleshooting

### El navbar no muestra menús

1. Verificar que el backend responde en `/api/profile`
2. Verificar la estructura de la respuesta JSON
3. Abrir DevTools → Console para ver errores
4. Verificar que los menús tienen `location: 'navbar'`

### El usuario no se carga

1. Verificar token de autenticación en headers
2. Verificar que el perfil existe en localStorage: `localStorage.getItem('profile')`
3. Forzar recarga: `profileService.loadProfile().subscribe()`

### Menús aparecen pero no funcionan

1. Verificar que tienen `route` definido
2. Verificar que `item_type` es correcto
3. Verificar que `access !== 'hidden'`

## 📚 Referencias

- **Spec completo**: `nexcore-frontend/src/documents/spec/05-menu-permiso-spec.md`
- **Base de datos**: `nexcore-infra/database/schema-nexcore.sql`
- **Seed data**: `nexcore-infra/database/02-migrate-base.sql`

## 🎯 Próximos Pasos

1. **Conectar con backend real**: Configurar proxy en `angular.json` o environment
2. **Implementar guards**: Usar `PermissionService.canAccessRoute()` en rutas
3. **Agregar componente de íconos**: Librería de íconos dinámica
4. **Implementar sidebar**: Misma lógica pero con `location: 'sidebar'`
5. **Tests**: Unit tests para servicios y componentes

---

**Versión**: 1.0.0  
**Fecha**: Mayo 2026  
**Autor**: NexCore Team
