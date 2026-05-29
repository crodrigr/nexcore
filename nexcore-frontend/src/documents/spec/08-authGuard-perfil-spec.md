# NexCore Frontend — Especificación de Seguridad: AuthGuard + PermissionGuard
**Versión:** 1.0  
**Fecha:** 2026-05-29  
**Estado:** Implementado  

---

## 1. Objetivo

Definir los requisitos, criterios de aceptación y decisiones de diseño del sistema de protección de rutas del frontend NexCore, basado en el perfil dinámico de permisos que devuelve el backend tras la autenticación.

El sistema garantiza que:
- Un usuario **no autenticado** no puede acceder a ninguna ruta protegida.
- Un usuario **autenticado** solo puede navegar a las rutas para las que tiene `access: "execute"` en su perfil.
- El acceso está determinado **exclusivamente por el backend** — el frontend solo refleja lo que el servidor autoriza.

---

## 2. Contexto

### 2.1 Flujo de autenticación

```
Usuario ingresa credenciales
        ↓
POST /auth/login → challengeToken
        ↓
POST /auth/verify-otp → { accessToken, refreshToken, expiresIn, profile }
        ↓
Frontend almacena:
  localStorage.accessToken   (JWT firmado, expira en 900s)
  localStorage.refreshToken  (UUID opaco)
  localStorage.profile       (perfil con menus[] y permissions[])
        ↓
Angular Router activa las rutas protegidas
```

### 2.2 Estructura del perfil almacenado

El objeto `profile` guardado en `localStorage` contiene:

```json
{
  "user": { "iduser": "...", "username": "...", "roles": ["EDITOR"] },
  "menus": [
    { "name": "Dashboard", "route": "/dashboard", "access": "execute", "location": "sidebar" },
    { "name": "Admin",     "route": null,          "access": "hidden",  "children": [
      { "name": "User",     "route": "/users",       "access": "hidden" },
      { "name": "Permisos", "route": "/permissions", "access": "hidden" }
    ]}
  ],
  "permissions": [
    { "component": "dashboard",  "route": "/dashboard", "access": "execute", "elements": [] },
    { "component": "crm",        "route": "/crm",        "access": "execute", "elements": [] },
    { "component": "admin-panel","route": null,           "access": "hidden",  "elements": [
      { "element_key": "user",        "access": "hidden" },
      { "element_key": "permissions", "access": "hidden" }
    ]}
  ],
  "token": null
}
```

### 2.3 Fuente de verdad para protección de rutas

Se usa `permissions[]` como fuente principal porque:

| Campo | `menus[]` | `permissions[]` |
|-------|-----------|-----------------|
| Tiene `route` | Sí (en algunos) | Sí (en los que aplica) |
| Tiene `access` | Sí | Sí |
| Propósito | Navegación visible en UI | **Control de acceso a componentes** |
| Incluye elementos granulares | No | Sí (botones, tabs, campos) |

**Regla:** Una ruta solo está permitida si aparece en `permissions[]` con `access === "execute"` y `route !== null`.

---

## 3. Arquitectura de la solución

### 3.1 Archivos implementados

| Archivo | Tipo | Responsabilidad |
|---------|------|-----------------|
| `src/app/shared/guards/auth.guard.ts` | `CanActivateFn` | Valida existencia y expiración del JWT |
| `src/app/shared/guards/permission.guard.ts` | `CanActivateChildFn` | Valida permisos de ruta contra el perfil |
| `src/app/app.routes.ts` | Configuración | Aplica ambos guards al layout shell |

### 3.2 Diagrama de flujo de navegación

```
Usuario navega a una URL
            ↓
┌─────────────────────────────────┐
│         canActivate             │
│         authGuard               │
│                                 │
│  ¿Existe accessToken en         │
│  localStorage?                  │
│                                 │
│  ¿El claim "exp" del JWT        │
│  es mayor que Date.now()?       │
└─────────────────────────────────┘
         ↓ NO             ↓ SÍ
   Limpia storage    canActivateChild
   → /auth/login     permissionGuard
                           ↓
              ┌────────────────────────────┐
              │  Lee permissions[] del     │
              │  localStorage.profile      │
              │                            │
              │  Filtra: access==='execute'│
              │  y route !== null          │
              │                            │
              │  ¿targetPath coincide con  │
              │  alguna ruta permitida?    │
              └────────────────────────────┘
                    ↓ NO          ↓ SÍ
             → /dashboard    Activa la ruta ✅
             (o /login si
             no tiene dashboard)
```

### 3.3 Configuración en el router

```typescript
{
  path: '',
  component: LayoutShellComponent,
  canActivate: [authGuard],          // Corre 1 vez al activar el shell
  canActivateChild: [permissionGuard], // Corre en CADA navegación hijo
  children: [
    { path: 'dashboard',   loadComponent: () => import(...) },
    { path: 'tenants',     loadComponent: () => import(...) },
    { path: 'users',       loadComponent: () => import(...) },
    { path: 'permissions', loadComponent: () => import(...) },
    { path: 'crm',         loadChildren: () => import(...) },
  ]
}
```

**¿Por qué `canActivateChild` y no solo `canActivate`?**  
`canActivate` en el padre solo se ejecuta cuando el componente padre se activa por primera vez. Cuando el usuario ya está dentro del shell y navega entre rutas hijas (ej. de `/dashboard` a `/tenants`), el padre no se reactiva y `canActivate` no vuelve a correr. `canActivateChild` sí se ejecuta en **cada cambio de ruta hija**.

---

## 4. Implementación detallada

### 4.1 authGuard

```typescript
// src/app/shared/guards/auth.guard.ts
export const authGuard: CanActivateFn = () => {
  const router = inject(Router);
  const token = localStorage.getItem('accessToken');

  if (token && isTokenValid(token)) return true;

  // Limpiar sesión corrupta o expirada
  localStorage.removeItem('accessToken');
  localStorage.removeItem('refreshToken');
  localStorage.removeItem('profile');

  return router.createUrlTree(['/auth/login']);
};

function isTokenValid(token: string): boolean {
  // Decodifica el payload del JWT (sin verificar firma — solo para exp)
  const claims = decodeJwtPayload(token);
  const exp = claims?.['exp'];
  if (typeof exp !== 'number') return true; // sin claim exp → aceptar
  return Date.now() / 1000 < exp;
}
```

**Validaciones que realiza:**
1. ¿Existe `accessToken` en localStorage?
2. ¿El JWT tiene formato válido (3 partes separadas por `.`)?
3. ¿El claim `exp` es mayor que el timestamp actual?

### 4.2 permissionGuard

```typescript
// src/app/shared/guards/permission.guard.ts
export const permissionGuard: CanActivateChildFn = (_childRoute, state) => {
  const router = inject(Router);
  const stored = localStorage.getItem('profile');
  if (!stored) return router.createUrlTree(['/auth/login']);

  const profile = JSON.parse(stored);

  // Rutas permitidas: solo execute con route no nulo
  const allowedRoutes = profile.permissions
    .filter(p => p.route && p.access === 'execute')
    .map(p => p.route);

  const targetPath = state.url.split('?')[0].split('#')[0];

  const isAllowed = allowedRoutes.some(
    route => targetPath === route || targetPath.startsWith(route + '/')
  );

  if (isAllowed) return true;

  const hasDashboard = allowedRoutes.includes('/dashboard');
  return router.createUrlTree([hasDashboard ? '/dashboard' : '/auth/login']);
};
```

---

## 5. Ejemplo de permisos por rol

### Rol EDITOR (perfil real del sistema)

Permisos recibidos del backend:

| Componente | Route | Access |
|------------|-------|--------|
| dashboard | `/dashboard` | **execute** |
| crm | `/crm` | **execute** |
| monitoring | `/monitoring` | **execute** |
| admin-panel | `null` | hidden |
| profile-menu | `null` | execute |

**Rutas permitidas para navegación:** `/dashboard`, `/crm`, `/monitoring`

**Resultado por ruta:**

| URL solicitada | ¿En permissions execute? | Resultado |
|----------------|--------------------------|-----------|
| `/dashboard` | ✅ | Acceso permitido |
| `/crm` | ✅ | Acceso permitido |
| `/monitoring` | ✅ | Acceso permitido |
| `/tenants` | ❌ ausente | → `/dashboard` |
| `/users` | ❌ ausente (admin-panel sin route) | → `/dashboard` |
| `/permissions` | ❌ ausente | → `/dashboard` |

---

## 6. Ventajas del diseño

| Ventaja | Detalle |
|---------|---------|
| **Permisos dinámicos** | No hay roles hardcodeados en el frontend. El acceso lo define el backend para cada usuario y tenant |
| **Un guard, todos los hijos** | `canActivateChild` en el padre protege automáticamente todas las rutas hijas presentes y futuras |
| **Sin llamadas extra** | Los permisos ya vienen en el login. El guard solo hace `JSON.parse` + `Array.filter` |
| **Extensible** | Agregar una nueva ruta protegida solo requiere registrarla en `app.routes.ts` — el guard la cubre automáticamente |
| **Compatible con multi-tenant** | Cada tenant puede tener configuraciones de permisos distintas; el perfil refleja exactamente las del tenant activo |

---

## 7. Riesgos y mitigaciones

### 7.1 Manipulación del localStorage

**Riesgo:** Un usuario con conocimiento técnico puede abrir DevTools y modificar `localStorage.profile` para agregar rutas con `access: "execute"`, engañando al `permissionGuard`.

```javascript
// Ataque posible en consola del navegador:
const p = JSON.parse(localStorage.getItem('profile'));
p.permissions.push({ route: '/tenants', access: 'execute', component: 'tenants', elements: [] });
localStorage.setItem('profile', JSON.stringify(p));
// Navega a /tenants → el guard lo permite
```

**Impacto real:** El usuario llega a la pantalla pero **todas las llamadas a la API fallan con 403** porque el JWT no cambió y el backend valida permisos independientemente.

**Mitigación:** El `AuthInterceptor` adjunta el JWT firmado a cada petición HTTP. El backend verifica ese token y los permisos del usuario en cada endpoint. El frontend es solo UX — la seguridad real está en el servidor.

### 7.2 Token expirado en localStorage

**Riesgo:** El `accessToken` expira en 900 segundos (15 minutos). Si el usuario no interactúa durante ese tiempo, el token queda en localStorage pero ya no es válido.

**Mitigación actual:** `authGuard` decodifica el claim `exp` del JWT y rechaza tokens expirados antes de activar cualquier ruta.

**Mitigación pendiente (fuera de alcance):** Implementar renovación silenciosa con `refreshToken` mediante un interceptor HTTP que detecte respuestas 401 y renueve el token automáticamente.

### 7.3 Perfil desactualizado (cambio de permisos en caliente)

**Riesgo:** Un administrador modifica los permisos de un usuario mientras este tiene sesión activa. El `localStorage.profile` tiene los permisos anteriores hasta que el usuario cierre y vuelva a abrir sesión.

**Mitigación actual:** Si el backend retorna 403 en cualquier llamada, el interceptor puede detectarlo y forzar un logout.

**Mitigación recomendada:** Al recibir cualquier 403 de la API, limpiar el perfil y redirigir a login para forzar una nueva autenticación con el perfil actualizado.

### 7.4 Acceso directo por URL sin profile en storage

**Riesgo:** El usuario limpia manualmente el localStorage pero tiene un token válido en memoria, o navega a una URL protegida desde un enlace externo.

**Mitigación:** `permissionGuard` verifica que `localStorage.profile` exista y sea parseable. Si no existe, redirige a `/auth/login` aunque haya token.

---

## 8. Requisitos funcionales

| ID | Requisito |
|----|-----------|
| RF-01 | El sistema debe redirigir a `/auth/login` cualquier intento de acceder a rutas protegidas sin token válido |
| RF-02 | El sistema debe validar la expiración del JWT antes de activar cualquier ruta protegida |
| RF-03 | El sistema debe leer los permisos del perfil almacenado en `localStorage.profile` |
| RF-04 | Solo las rutas presentes en `permissions[]` con `access === "execute"` y `route !== null` deben ser accesibles |
| RF-05 | Las rutas con `access === "hidden"` o ausentes del perfil deben redirigir al dashboard |
| RF-06 | El guard de permisos debe ejecutarse en **cada** navegación entre rutas hijas, no solo en la primera |
| RF-07 | Al limpiar el storage manualmente, el sistema debe redirigir a login en el siguiente intento de navegación |
| RF-08 | Las rutas públicas (`/auth/*`, `/reset-password`) deben funcionar sin token ni perfil |

---

## 9. Criterios de aceptación

### CA-01: Usuario no autenticado

```
DADO que no existe accessToken en localStorage
CUANDO el usuario navega a /dashboard, /users, /tenants o cualquier ruta protegida
ENTONCES es redirigido a /auth/login
Y no se muestra ningún contenido de la ruta solicitada
```

### CA-02: Token expirado

```
DADO que existe accessToken en localStorage pero su claim "exp" es menor que Date.now()
CUANDO el usuario navega a cualquier ruta protegida
ENTONCES localStorage se limpia (accessToken, refreshToken, profile)
Y el usuario es redirigido a /auth/login
```

### CA-03: Ruta permitida por perfil

```
DADO que el usuario tiene sesión activa con rol EDITOR
Y su perfil incluye { "route": "/dashboard", "access": "execute" }
CUANDO navega a /dashboard
ENTONCES se activa la ruta y se muestra el componente Dashboard
```

### CA-04: Ruta no permitida — ausente del perfil

```
DADO que el usuario tiene sesión activa con rol EDITOR
Y su perfil NO incluye ninguna entrada con route "/tenants"
CUANDO navega directamente a /tenants (URL en barra del navegador)
ENTONCES es redirigido a /dashboard
Y no se muestra ningún contenido de /tenants
```

### CA-05: Ruta no permitida — access hidden

```
DADO que el usuario tiene sesión activa con rol EDITOR
Y su perfil incluye { "component": "admin-panel", "route": null, "access": "hidden" }
CUANDO navega a /users o /permissions
ENTONCES es redirigido a /dashboard
```

### CA-06: Navegación entre rutas mientras la sesión está activa

```
DADO que el usuario EDITOR está en /dashboard
CUANDO hace clic en un enlace o modifica la URL a /tenants
ENTONCES el permissionGuard se ejecuta (no el authGuard del padre)
Y el usuario es redirigido a /dashboard sin recargar la aplicación
```

### CA-07: Sub-rutas heredan el permiso

```
DADO que el usuario tiene { "route": "/crm", "access": "execute" }
CUANDO navega a /crm o a /crm/contactos o a /crm/reportes/2026
ENTONCES se permite la navegación (startsWith "/crm")
```

### CA-08: Manipulación de localStorage no otorga acceso al backend

```
DADO que el usuario modifica localStorage.profile manualmente
Y agrega { "route": "/tenants", "access": "execute" }
CUANDO navega a /tenants
ENTONCES el frontend muestra la pantalla de tenants
PERO todas las llamadas HTTP retornan 403 del backend
Y el usuario no puede ver, crear ni modificar datos
```

### CA-09: Profile ausente con token presente

```
DADO que existe accessToken válido en localStorage
PERO localStorage.profile no existe o está corrupto
CUANDO el usuario navega a cualquier ruta protegida
ENTONCES el permissionGuard redirige a /auth/login
```

### CA-10: Rutas públicas no afectadas

```
DADO cualquier estado de autenticación
CUANDO el usuario navega a /auth/login, /auth/forgot-password, /auth/reset-password
ENTONCES la ruta se activa normalmente sin intervención de los guards
```

---

## 10. Limitaciones conocidas y trabajo futuro

| Limitación | Impacto | Solución futura |
|------------|---------|-----------------|
| No hay renovación silenciosa de token | A los 15 min el usuario es expulsado aunque esté activo | Interceptor HTTP que detecte 401 y use refreshToken |
| Cambios de permisos en caliente no se reflejan | Usuario mantiene acceso hasta el próximo login | Detectar 403 del backend → logout forzado |
| localStorage es mutable por el usuario | Guard bypasseable en UI (no en API) | Aceptado: el backend es la defensa real |
| No hay `canLoad` para lazy modules | El bundle del módulo se descarga aunque no tenga permiso | Agregar `canMatch` o `canLoad` a rutas lazy |

---

## 11. Principio fundamental de seguridad

> **El frontend nunca es la última línea de defensa.**  
> Los guards protegen la experiencia de usuario — evitan que un usuario vea pantallas vacías o mensajes de error de la API. La seguridad real está garantizada por el backend, que valida el JWT firmado en **cada** llamada HTTP, independientemente de lo que diga el localStorage.

```
Manipulación de localStorage
        ↓
Guard bypaseado → Usuario llega a la ruta
        ↓
Llamada HTTP → AuthInterceptor adjunta JWT original
        ↓
Backend valida JWT firmado → rol real: EDITOR
        ↓
403 Forbidden — datos nunca expuestos
```

---

**Fecha:** 2026-05-29  
**Proyecto:** NexCore Frontend  
**Guards implementados:** `auth.guard.ts`, `permission.guard.ts`  
**Rutas protegidas:** todas las hijas de `LayoutShellComponent`
