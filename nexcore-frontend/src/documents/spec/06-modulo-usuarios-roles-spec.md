# NexCore Frontend — Especificación Módulo Usuarios & Roles
**Versión:** 1.0  
**Fecha:** 2026-05-26  
**Estado:** Propuesto para implementación

---

## 1. Objetivo

Definir los requisitos funcionales, de experiencia de usuario y criterios de aceptación del módulo **Usuarios & Roles** para el frontend NexCore, basado en el diseño de referencia (`users-list.html`) y en los servicios API disponibles del módulo `module-tenant`.

---

## 2. Alcance

Este documento cubre el módulo de gestión de personas y permisos, organizado en tres sub-módulos accesibles desde la misma pantalla mediante tabs:

1. Usuarios — listar, crear, editar, suspender, activar, eliminar y asignar roles
2. Invitaciones — invitar, listar, revocar y aceptar invitaciones
3. Roles — listar, crear, editar y eliminar roles personalizados

---

## 3. Restricciones de diseño

1. No se debe modificar el header global (`app-navbar`).
2. No se debe modificar el sidebar global (`app-sidebar`).
3. La implementación debe adaptarse al layout existente: `.page-wrap > .layout > .content`.
4. El look and feel debe seguir fielmente el sistema de estilos establecido (tokens CSS, clases BEM del módulo tenant).
5. Los mismos componentes visuales reutilizados del módulo tenant deben mantener su comportamiento sin clases nuevas que rompan coherencia visual:
   - `.card`, `.toolbar`, `.table-wrap`, `.status-chip`, `.btn`, `.modal-backdrop`, `.modal`, `.pager-btn`

Referencias visuales:
1. [nexcore-infra/mockups/users-list.html](nexcore-infra/mockups/users-list.html)

API base de referencia:
1. [nexcore-infra/postman/nexcore-collection.json](nexcore-infra/postman/nexcore-collection.json)

---

## 4. Roles y permisos

| Operación | Rol mínimo requerido |
|---|---|
| Listar usuarios del tenant | TENANT_ADMIN |
| Crear usuario | TENANT_ADMIN |
| Editar usuario (datos propios) | EDITOR, VIEWER (campos propios) |
| Editar usuario (datos de otro) | TENANT_ADMIN (`X-Is-Tenant-Admin: true`) |
| Suspender / Activar / Eliminar usuario | TENANT_ADMIN |
| Asignar roles a usuario | TENANT_ADMIN |
| Invitar usuario | TENANT_ADMIN |
| Revocar invitación | TENANT_ADMIN |
| Listar / crear / editar / eliminar roles | TENANT_ADMIN |
| Acceso completo al módulo | SUPER_ADMIN (bypass total) |

Todos los requests deben incluir `X-Tenant-Id` y `X-Actor-Id` en los headers.

---

## 5. Requisitos funcionales generales del módulo

1. La pantalla principal del módulo debe mostrar tres tabs: **Usuarios**, **Invitaciones**, **Roles**, con badge numérico indicando el total de registros de cada uno.
2. El tab activo por defecto al entrar al módulo es **Usuarios**.
3. Cada tab tiene su propia barra de herramientas (search, filtros, paginación, acción primaria).
4. Los cambios en un tab no deben afectar ni recargar el contenido de los otros tabs.
5. Las acciones críticas (suspender, activar, eliminar, revocar) deben mostrar un modal de confirmación antes de ejecutarse.
6. Toda operación debe mostrar feedback inmediato al usuario: loading, éxito y error.
7. El módulo debe ser accesible desde la ruta `/admin/users` (o la ruta que corresponda según la configuración de menú).

---

## 6. Sub-módulo: Usuarios

### 6.1 GET Listar usuarios

Endpoint:
- `GET /api/v1/users?page={page}&size={size}&status={status}&search={search}`

Headers requeridos:
- `X-Tenant-Id`

Parámetros:
1. `page`: entero >= 0 (default 0)
2. `size`: entero > 0 (default 10)
3. `status`: opcional — `PENDING_ACTIVATION | ACTIVE | SUSPENDED | BLOCKED | DELETED`
4. `search`: opcional — texto libre para filtrar por nombre, username o email

Comportamiento en UI:
1. Mostrar tabla con columnas: **Usuario** (avatar + nombre + email), **Username**, **Estado**, **Roles**, **Creado**, **Acciones**.
2. El avatar del usuario es un cuadrado con borde redondeado (8px), fondo de gradiente azul, iniciales en mayúsculas.
3. El campo **Estado** se muestra como `status-chip` con color semántico:
   - `ACTIVE` → verde (`status-active`)
   - `PENDING_ACTIVATION` → naranja (`status-pending`)
   - `SUSPENDED` → rojo (`status-suspended`)
   - `BLOCKED` → gris (`status-blocked`)
4. El campo **Roles** muestra chips diferenciando rol de sistema (púrpura) de rol custom (azul).
5. Toolbar izquierdo: campo de búsqueda con label.
6. Toolbar derecho: filtro de estado + paginación + botón primario **Invitar Usuario**.
7. Si `SUPER_ADMIN`, el botón de acción primaria puede ser **Crear Usuario** (creación directa sin invitación).

Criterios de aceptación:
1. Dado que se selecciona el tab Usuarios, cuando carga, entonces se consume `GET /api/v1/users` con `page=0` y `size` por defecto.
2. Dado que la API responde correctamente, entonces la tabla muestra filas con avatar, nombre, estado y roles.
3. Dado que la API retorna lista vacía o sin resultados de búsqueda, entonces se muestra empty state con mensaje sin usuarios.
4. Dado que el usuario escribe en el buscador, entonces se aplica el filtro con debounce de 300ms y se recarga la tabla.
5. Dado que el usuario cambia el filtro de estado, entonces se recarga la tabla con el estado seleccionado.
6. Dado que se navega entre páginas, entonces se solicita la nueva página y la tabla se actualiza sin modificar tabs activos.
7. Dado que la API falla, entonces se muestra alerta de error con opción de reintentar.

### 6.2 POST Crear usuario

Endpoint:
- `POST /api/v1/users`

Headers requeridos:
- `Content-Type: application/json`
- `X-Tenant-Id`
- `X-Actor-Id`

Payload:
1. `email` — requerido
2. `username` — requerido
3. `fullName` — requerido
4. `phone` — opcional
5. `roleIds` — array de UUID, puede ser vacío
6. `sendInvite` — boolean, default `true`

Comportamiento en UI:
1. El formulario de creación se abre en un **drawer lateral** (slide-over) o modal `modal-xl`.
2. El formulario está organizado en una sección de datos personales y una sección de asignación de roles.
3. El toggle `sendInvite` indica si se envía correo de activación al crear.
4. La selección de roles es una lista con checkboxes mostrando nombre y descripción de cada rol.
5. Mientras se envía, el botón principal muestra estado loading y queda deshabilitado.

Criterios de aceptación:
1. Dado que faltan campos obligatorios (email, username, fullName), cuando se intenta guardar, entonces no se envía request y se muestran validaciones en línea por campo.
2. Dado que el email no tiene formato válido, entonces se muestra error de validación antes de enviar.
3. Dado un payload válido, cuando se confirma, entonces se ejecuta `POST /api/v1/users` y se muestra notificación de éxito.
4. Dado éxito de creación, entonces el usuario nuevo aparece en la tabla sin recargar toda la pantalla.
5. Dado error `409` (email o username duplicado), entonces se muestra mensaje de negocio específico por campo.
6. Dado error técnico, entonces se muestra mensaje genérico con código de error si el backend lo provee.

### 6.3 GET Obtener usuario por ID

Endpoint:
- `GET /api/v1/users/{userId}`

Comportamiento en UI:
1. Al hacer clic en una fila de la tabla se puede navegar a una vista de detalle o abrir un panel lateral.
2. El detalle muestra: avatar grande, nombre completo, username, email, teléfono, estado, fecha de creación, fecha de actualización y roles asignados.

Criterios de aceptación:
1. Dado que se abre el detalle de un usuario, entonces se consume `GET /api/v1/users/{userId}` con el `X-Tenant-Id` correcto.
2. Dado que la API retorna 404, entonces se muestra mensaje de usuario no encontrado y opción de volver al listado.

### 6.4 PATCH Actualizar usuario

Endpoint:
- `PATCH /api/v1/users/{userId}`

Headers requeridos:
- `Content-Type: application/json`
- `X-Tenant-Id`
- `X-Actor-Id`
- `X-Is-Tenant-Admin` (true/false)

Payload editable:
1. `fullName`
2. `phone`
3. `photoUrl`
4. Campos adicionales si `X-Is-Tenant-Admin: true`

Comportamiento en UI:
1. El botón **Editar** de la fila o detalle abre el mismo formulario de creación en modo edición.
2. Los campos `email` y `username` deben mostrarse como solo lectura (no editables).
3. El formulario prerrellena los datos actuales del usuario.

Criterios de aceptación:
1. Dado que el formulario de edición se abre, entonces los campos están prerrellenos con los datos actuales.
2. Dado que se guarda sin cambios, entonces no se ejecuta `PATCH` (detección de cambios pendientes).
3. Dado un payload válido, cuando se confirma la edición, entonces se ejecuta `PATCH` y el registro se actualiza en tabla/detalle.
4. Dado error de validación backend, entonces se muestran mensajes específicos por campo.

### 6.5 POST Suspender usuario

Endpoint:
- `POST /api/v1/users/{userId}/suspend`

Comportamiento en UI:
1. Botón **Suspender** visible solo cuando el usuario tiene estado `ACTIVE` o `PENDING_ACTIVATION`.
2. Abre modal de confirmación con nombre del usuario y advertencia de impacto.
3. Tras confirmación y éxito (204), el chip de estado cambia a `SUSPENDED` y el botón cambia a **Activar**.

Criterios de aceptación:
1. Dado usuario activo, cuando se hace clic en Suspender, entonces se abre modal de confirmación.
2. Dado que se cancela el modal, entonces no se ejecuta ningún request.
3. Dado que se confirma, entonces se ejecuta `POST /suspend` y backend retorna 204.
4. Dado 204 exitoso, entonces el chip de estado pasa a `SUSPENDED` y las acciones de fila se actualizan.
5. Dado error de API, entonces el estado no cambia y se muestra notificación de error.

### 6.6 POST Activar usuario

Endpoint:
- `POST /api/v1/users/{userId}/activate`

Comportamiento en UI:
1. Botón **Activar** visible solo cuando el usuario tiene estado `SUSPENDED`.
2. Modal de confirmación simple sin campo de texto adicional.
3. Tras éxito (204), el chip de estado cambia a `ACTIVE`.

Criterios de aceptación:
1. Dado usuario suspendido, cuando se confirma activar, entonces se ejecuta `POST /activate` y retorna 204.
2. Dado 204 exitoso, entonces el estado visual pasa a `ACTIVE` de forma inmediata.
3. Dado error de API, entonces el estado no cambia y se notifica el fallo.

### 6.7 DELETE Eliminar usuario (soft-delete)

Endpoint:
- `DELETE /api/v1/users/{userId}`

Comportamiento en UI:
1. Acción disponible en el menú de acciones de la fila (no visible como botón directo para evitar clics accidentales).
2. Modal de confirmación con advertencia de que la acción es irreversible.
3. Tras éxito (204), el usuario desaparece de la tabla si el filtro activo no incluye `DELETED`.

Criterios de aceptación:
1. Dado que se intenta eliminar, entonces se muestra modal de confirmación con nombre del usuario y advertencia de impacto.
2. Dado confirmación, entonces se ejecuta `DELETE` y retorna 204.
3. Dado 204 exitoso, entonces la fila se elimina de la tabla si el filtro activo es `ACTIVE` o cualquiera que no incluya `DELETED`.
4. Dado error (ej. usuario con sesión activa), entonces se muestra mensaje descriptivo del error.

### 6.8 PUT Asignar roles a usuario

Endpoint:
- `PUT /api/v1/users/{userId}/roles`

Payload:
```json
{
  "assignments": [
    { "roleId": "uuid", "expiresAt": null }
  ]
}
```

Comportamiento en UI:
1. Botón **Editar Roles** disponible en el detalle del usuario o en el formulario de edición.
2. Abre un modal con lista de todos los roles del tenant (sistema y custom).
3. Los roles asignados actualmente aparecen preseleccionados.
4. Cada rol muestra: nombre, descripción, badge Sistema/Custom.
5. Campo opcional de fecha de expiración por rol (si el rol se marca como temporal).
6. Al guardar, se reemplaza la asignación completa.

Criterios de aceptación:
1. Dado que se abre el modal de roles, entonces se consume `GET /api/v1/roles` para poblar la lista.
2. Dado que los roles actuales del usuario están preseleccionados, entonces el usuario ve su estado real.
3. Dado que se confirma la asignación, entonces se ejecuta `PUT /users/{id}/roles` con el array completo.
4. Dado éxito, entonces los chips de roles en la tabla/detalle se actualizan.
5. Dado que se desmarca todos los roles y se confirma, entonces el usuario queda sin roles asignados.

---

## 7. Sub-módulo: Invitaciones

### 7.1 POST Invitar usuario

Endpoint:
- `POST /api/v1/users/invite`

Payload:
1. `email` — requerido
2. `roleIds` — array de UUID, puede ser vacío

Comportamiento en UI:
1. El botón **Invitar Usuario** en el tab Usuarios abre un modal de invitación.
2. El modal tiene: campo email, lista de roles con checkboxes.
3. Al enviar, el botón muestra estado loading y se cierra al recibir éxito.

Criterios de aceptación:
1. Dado que el email ya tiene una invitación pendiente, entonces se muestra error de negocio descriptivo.
2. Dado que el email ya pertenece a un usuario activo del tenant, entonces se muestra mensaje de conflicto.
3. Dado payload válido, entonces se ejecuta `POST /invite`, se notifica éxito y la invitación aparece en el tab Invitaciones.

### 7.2 GET Listar invitaciones

Endpoint:
- `GET /api/v1/users/invitations`

Headers requeridos:
- `X-Tenant-Id`

Comportamiento en UI:
1. Tabla con columnas: **Email**, **Roles pre-asignados**, **Estado**, **Enviada**, **Expira**, **Acciones**.
2. Chips de estado: `PENDING` (amarillo), `ACCEPTED` (verde), `REVOKED` (gris).
3. Solo las invitaciones `PENDING` muestran la acción **Revocar**.
4. No hay paginación si el volumen es bajo; si el backend soporta paginación, se aplica igual que en usuarios.

Criterios de aceptación:
1. Dado que se selecciona el tab Invitaciones, entonces se consume `GET /api/v1/users/invitations`.
2. Dado lista vacía, entonces se muestra empty state con mensaje y botón de invitar.
3. Dado invitación `ACCEPTED`, entonces no se muestra acción de revocar.

### 7.3 POST Revocar invitación

Endpoint:
- `POST /api/v1/users/invitations/{invitationId}/revoke`

Comportamiento en UI:
1. Botón **Revocar** visible solo en invitaciones con estado `PENDING`.
2. Modal de confirmación simple antes de ejecutar.
3. Tras éxito (204), el chip cambia a `REVOKED` y la acción desaparece.

Criterios de aceptación:
1. Dado invitación pendiente, cuando se confirma revocar, entonces se ejecuta `POST /revoke` y retorna 204.
2. Dado 204 exitoso, entonces el chip pasa a `REVOKED`.
3. Dado error, entonces el estado no cambia y se notifica el fallo.

### 7.4 POST Aceptar invitación (flujo público)

Endpoint:
- `POST /api/v1/users/invitations/accept`

Payload:
1. `token` — requerido (recibido por email)
2. `username` — requerido
3. `fullName` — requerido

Comportamiento en UI:
1. Pantalla pública (sin autenticación) accesible por link del email.
2. Pre-completa el email si el token lo contiene.
3. Solicita username y nombre completo.
4. Tras éxito, redirige al login.

Criterios de aceptación:
1. Dado token válido, cuando el usuario completa el formulario y confirma, entonces se ejecuta `POST /accept` y se crea el usuario.
2. Dado token expirado, entonces se muestra mensaje de expiración y enlace para solicitar nueva invitación.
3. Dado token ya usado, entonces se muestra mensaje de invitación ya aceptada y opción de login.

---

## 8. Sub-módulo: Roles

### 8.1 GET Listar roles

Endpoint:
- `GET /api/v1/roles`

Headers requeridos:
- `X-Tenant-Id`

Comportamiento en UI:
1. Tabla con columnas: **Nombre**, **Descripción**, **Tipo** (badge Sistema/Custom), **Usuarios activos**, **Acciones**.
2. Los roles de sistema (`TENANT_ADMIN`, `EDITOR`, `VIEWER`) muestran badge **Sistema** y sus acciones Editar/Eliminar están deshabilitadas con tooltip explicativo.
3. Los roles custom muestran badge **Custom** con acciones Editar y Eliminar activas.

Criterios de aceptación:
1. Dado que se selecciona el tab Roles, entonces se consume `GET /api/v1/roles`.
2. Dado que no hay roles custom, entonces se muestra empty state solo para la sección custom; los roles de sistema siempre se listan.
3. Dado rol de sistema, entonces los botones de Editar y Eliminar están deshabilitados visualmente y muestran tooltip `Rol de sistema — no editable`.

### 8.2 POST Crear rol

Endpoint:
- `POST /api/v1/roles`

Payload:
1. `name` — requerido, texto en mayúsculas
2. `description` — opcional
3. `isDefault` — boolean

Comportamiento en UI:
1. Botón **Crear Rol** en la barra de herramientas del tab Roles.
2. Abre modal con formulario simple: nombre (input forzado a mayúsculas), descripción (textarea), toggle de rol predeterminado.
3. El hint del toggle explica que solo puede existir un rol predeterminado por tenant.

Criterios de aceptación:
1. Dado nombre vacío, entonces no se ejecuta request y se muestra validación.
2. Dado nombre duplicado dentro del tenant, entonces se muestra error `409` con mensaje descriptivo.
3. Dado payload válido, entonces se crea el rol y aparece en la tabla como tipo **Custom**.
4. Dado `isDefault: true` cuando ya existe un rol predeterminado, entonces el anterior deja de ser default y se notifica el cambio.

### 8.3 PATCH Actualizar rol

Endpoint:
- `PATCH /api/v1/roles/{roleId}`

Payload:
1. `name`
2. `description`
3. `isDefault`

Comportamiento en UI:
1. El modal de edición es el mismo que el de creación en modo edición.
2. Para roles de sistema el botón Editar está deshabilitado y no abre el modal.

Criterios de aceptación:
1. Dado rol custom, cuando se edita y guarda, entonces se ejecuta `PATCH` y la tabla se actualiza.
2. Dado rol de sistema, entonces el botón Editar está deshabilitado; no se puede llegar al modal por ningún flujo de UI.
3. Dado error de negocio, entonces se muestran mensajes descriptivos en el modal.

### 8.4 DELETE Eliminar rol

Endpoint:
- `DELETE /api/v1/roles/{roleId}`

Comportamiento en UI:
1. Modal de confirmación con nombre del rol y advertencia de que los usuarios perderán el rol.
2. Si el backend retorna error porque el rol tiene usuarios asignados, el modal muestra estado de error bloqueante con el conteo de usuarios afectados.
3. Para roles de sistema, el botón Eliminar está deshabilitado y no se puede acceder al modal.

Criterios de aceptación:
1. Dado rol custom sin usuarios asignados, cuando se confirma eliminar, entonces se ejecuta `DELETE` y retorna 204.
2. Dado 204 exitoso, entonces el rol desaparece de la tabla.
3. Dado rol con usuarios asignados activos, entonces el backend retorna error y el modal muestra el mensaje bloqueante sin cerrar.
4. Dado rol de sistema, entonces el botón Eliminar está deshabilitado en la UI y no es posible ejecutar el flujo.

---

## 9. Requisitos de UX/UI del módulo

1. El header del módulo muestra título **Usuarios & Roles** con subtítulo descriptivo.
2. Los tres tabs tienen badge numérico con el total de registros de cada sub-módulo.
3. Tabla con ordenamiento por columna (sort buttons con indicadores ▲▼) en: nombre completo, username, estado y fecha de creación.
4. Los avatares de usuario usan gradiente de color variable por usuario (asignado por índice o hash del username) para diferenciarlos visualmente.
5. Las chips de rol diferencian visualmente los roles de sistema (color púrpura) de los roles custom (color azul) con bordes y fondos semánticos.
6. Los modales de confirmación de acciones destructivas deben tener el header con clase `danger-header` (fondo rojizo) para comunicar el riesgo.
7. El estado de loading de la tabla muestra el mismo texto genérico que el módulo tenant (`tenant.list.loading` pattern).
8. El estado empty muestra ilustración o icono SVG + mensaje + acción primaria contextual.
9. Todos los botones respetan los estados: Default, Hover (`translateY(-1px)`), Loading (texto cambiado + disabled), Disabled (opacity 0.6).
10. Los tooltips sobre botones deshabilitados explican por qué están deshabilitados (ej. `Rol de sistema — no editable`).
11. En ninguna pantalla del módulo se alteran estilos, estructura o comportamiento del header y sidebar globales.

---

## 10. Requisitos de validación de datos

### Usuario
1. `email`: requerido, formato RFC-5322 válido, único en el tenant.
2. `username`: requerido, sin espacios, solo letras minúsculas, números, punto y guion; mínimo 3 caracteres.
3. `fullName`: requerido, mínimo 3 caracteres, máximo 200.
4. `phone`: opcional, solo dígitos, puede incluir `+` al inicio.
5. `roleIds`: array, puede ser vacío; cada UUID debe existir en el catálogo de roles del tenant.

### Invitación
1. `email`: requerido, formato válido.
2. `roleIds`: array, puede ser vacío.

### Rol
1. `name`: requerido, mínimo 3 caracteres, máximo 100, transformado a mayúsculas automáticamente.
2. `description`: opcional, máximo 500 caracteres.
3. `isDefault`: booleano, default `false`.

---

## 11. Estados y manejo de errores

| Estado | Comportamiento |
|---|---|
| Loading tabla | Spinner o texto de carga en lugar de la tabla |
| Empty state | Ilustración + mensaje + botón contextual (ej. "Invitar usuario") |
| Error de API | Alerta `alert error` en zona feedback + mensaje descriptivo + reintentar |
| Éxito de operación | Alerta `alert success` en zona feedback o notificación toast no intrusiva |
| Error de validación inline | Mensaje rojo debajo del campo, sin bloquear el formulario completo |
| Error de negocio (409, 422) | Mensaje descriptivo mapeado desde código de error del backend |
| Error técnico (500+) | Mensaje genérico con código de error si el backend lo incluye |
| Modal con error bloqueante | El modal permanece abierto mostrando el error sin cerrarse automáticamente |

---

## 12. Trazabilidad API → Pantallas

| Pantalla / Acción | Endpoint |
|---|---|
| Tab Usuarios — Listado | `GET /api/v1/users` |
| Crear usuario | `POST /api/v1/users` |
| Ver detalle usuario | `GET /api/v1/users/{id}` |
| Editar usuario | `PATCH /api/v1/users/{id}` |
| Suspender usuario | `POST /api/v1/users/{id}/suspend` |
| Activar usuario | `POST /api/v1/users/{id}/activate` |
| Eliminar usuario | `DELETE /api/v1/users/{id}` |
| Asignar roles | `PUT /api/v1/users/{id}/roles` |
| Tab Invitaciones — Listado | `GET /api/v1/users/invitations` |
| Invitar usuario | `POST /api/v1/users/invite` |
| Revocar invitación | `POST /api/v1/users/invitations/{id}/revoke` |
| Aceptar invitación (público) | `POST /api/v1/users/invitations/accept` |
| Tab Roles — Listado | `GET /api/v1/roles` |
| Crear rol | `POST /api/v1/roles` |
| Editar rol | `PATCH /api/v1/roles/{id}` |
| Eliminar rol | `DELETE /api/v1/roles/{id}` |
| Selector de roles (modales) | `GET /api/v1/roles` (compartido) |

---

## 13. Criterios de aceptación globales del módulo

1. El módulo permite el ciclo completo de vida de un usuario: invitar → activar → editar → asignar roles → suspender → activar → eliminar.
2. El módulo permite el ciclo completo de vida de un rol custom: crear → editar → asignar a usuarios → eliminar.
3. Todas las acciones destructivas o de cambio de estado requieren confirmación explícita mediante modal.
4. Los cambios de estado se reflejan en la UI de forma inmediata y consistente sin recarga total de la página.
5. Las restricciones de backend sobre roles de sistema se respetan visualmente: botones deshabilitados antes de intentar llamadas.
6. El módulo respeta el sistema de permisos: los headers `X-Tenant-Id`, `X-Actor-Id` y `X-Is-Tenant-Admin` se envían correctamente según el contexto del usuario autenticado.
7. Header y sidebar globales no se modifican ni en estructura ni en estilos.
8. El módulo cumple el diseño base de referencia entregado en `users-list.html`.
9. Los tres tabs (Usuarios, Invitaciones, Roles) son accesibles y funcionales sin errores de navegación.
10. La aplicación no rompe si el backend responde lentamente: se muestran estados de carga adecuados.

---

## 14. Fuera de alcance

1. Implementación o modificación de endpoints backend.
2. Rediseño de header, sidebar o sistema de navegación global.
3. Gestión de permisos granulares sobre componentes UI (esa lógica pertenece al módulo Menu — Perfil de UI).
4. Auditoría de cambios o historial de acciones por usuario.
5. Importación masiva de usuarios (bulk import).
6. Gestión de contraseñas desde este módulo (pertenece al módulo Autenticación).
7. Gestión de sesiones activas de un usuario (pertenece al módulo Auth Service).
8. Configuración de políticas de seguridad del tenant (pertenece al módulo Tenant).
