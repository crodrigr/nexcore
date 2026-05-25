# NexCore Frontend — Especificación Módulo Tenant
**Versión:** 1.0  
**Fecha:** 2026-05-25  
**Estado:** Propuesto para implementación

---

## 1. Objetivo
Definir los requisitos funcionales, de experiencia de usuario y criterios de aceptación del módulo Tenant para frontend, basado en la propuesta visual de referencia y en los servicios API disponibles.

## 2. Alcance
Este documento cubre únicamente el módulo Tenant para las capacidades:
1. Listar tenants
2. Crear tenant
3. Actualizar tenant
4. Suspender tenant
5. Activar tenant

## 3. Restricciones de diseño
1. No se debe modificar header global.
2. No se debe modificar sidebar global.
3. La implementación del módulo Tenant debe adaptarse al layout existente.
4. El look and feel del contenido interno del módulo Tenant debe seguir el estilo de las referencias.

Referencias visuales:
1. [nexcore-frontend/src/documents/nexcore_frontend/tenant/listenan.png](nexcore-frontend/src/documents/nexcore_frontend/tenant/listenan.png)
2. [nexcore-frontend/src/documents/nexcore_frontend/tenant/create-tenant.png](nexcore-frontend/src/documents/nexcore_frontend/tenant/create-tenant.png)
3. [nexcore-frontend/src/documents/nexcore_frontend/tenant/modal-update.png](nexcore-frontend/src/documents/nexcore_frontend/tenant/modal-update.png)
4. [nexcore-frontend/src/documents/nexcore_frontend/tenant/confirmar-cambios.png](nexcore-frontend/src/documents/nexcore_frontend/tenant/confirmar-cambios.png)
5. [nexcore-frontend/src/documents/nexcore_frontend/tenant/alert.png](nexcore-frontend/src/documents/nexcore_frontend/tenant/alert.png)

API base de referencia:
1. [nexcore-infra/postman/nexcore-collection.json](nexcore-infra/postman/nexcore-collection.json)

---

## 4. Roles y permisos
1. El módulo está orientado a operación de SUPER_ADMIN.
2. Listar y crear tenant deben estar protegidos para SUPER_ADMIN.
3. Suspender y activar tenant deben estar protegidos para SUPER_ADMIN.
4. Actualización de tenant debe respetar reglas de backend, incluyendo escenarios con header X-Actor-Super-Admin.

---

## 5. Requisitos funcionales generales del módulo
1. Debe existir una pantalla de listado con búsqueda y paginación.
2. Debe existir formulario de creación por secciones:
- Company Information
- Regional and Localization
- Plan and Deployment
3. Debe existir edición de tenant con confirmación de cambios antes de guardar.
4. Deben existir acciones de cambio de estado del tenant (suspender/activar).
5. Las acciones sensibles deben mostrar confirmaciones con mensajes de impacto.
6. La interfaz debe mostrar estados visuales claros de tenant: Active, Provisioning, Suspended.
7. Debe haber feedback al usuario en éxito y error para todas las operaciones.

---

## 6. Endpoints y contrato funcional esperado

### 6.1 GET Listar tenants
Endpoint:
- GET /api/v1/tenants?page={page}&size={size}

Parámetros:
1. page: obligatorio, entero >= 0
2. size: obligatorio, entero > 0

Comportamiento en UI:
1. Mostrar tabla con columnas mínimas:
- Name
- Slug
- Plan
- Mode
- Status
- Timezone
- Created At
2. Mostrar buscador superior para filtrar por name, slug o id (si backend no soporta filtro server-side, aplicar filtro client-side sobre página cargada hasta que exista endpoint filtrable).
3. Mostrar paginación y total de registros.

Criterios de aceptación:
1. Dado que se abre el módulo Tenant, cuando carga la pantalla, entonces se consume GET de listado con page y size por defecto.
2. Dado que la API responde correctamente, entonces la tabla muestra filas y estado visual por cada tenant.
3. Dado que la API retorna vacío, entonces se muestra estado Empty con mensaje sin resultados.
4. Dado que la API falla, entonces se muestra alerta de error y opción de reintentar.
5. Dado que el usuario cambia página, entonces se solicita la nueva página y la tabla se refresca sin modificar header/sidebar.

### 6.2 POST Crear tenant
Endpoint:
- POST /api/v1/tenants

Payload mínimo esperado (según colección):
1. slug
2. name
3. legalName
4. taxId
5. plan
6. mode
7. timezone
8. locale
9. dateFormat
10. currency

Comportamiento en UI:
1. Formulario seccionado con validaciones en línea.
2. Slug editable con prefijo visual de dominio.
3. Botón principal Create Tenant.
4. Botón secundario Cancel.
5. Si hay cambios sin guardar y el usuario intenta salir, mostrar advertencia de pérdida de cambios.

Criterios de aceptación:
1. Dado que faltan campos obligatorios, cuando se intenta crear, entonces no se envía request y se muestran validaciones.
2. Dado un payload válido, cuando se confirma Create Tenant, entonces se ejecuta POST y se muestra feedback de éxito.
3. Dado éxito de creación, entonces el usuario vuelve al listado y visualiza el nuevo tenant o su detalle.
4. Dado error de negocio (slug duplicado, taxId inválido, etc.), entonces se muestra mensaje de error específico.
5. Dado error técnico, entonces se muestra mensaje genérico y acción de reintento.

### 6.3 PATCH Actualizar tenant
Endpoint:
- PATCH /api/v1/tenants/{tenant_id}

Payload esperado (según colección, editable por reglas backend):
1. name
2. legalName
3. timezone
4. locale
5. mfaRequired
6. sessionTimeoutMinutes
7. maxLoginAttempts
8. passwordMinLength
9. passwordRequiresUpper
10. passwordRequiresSpecial

Comportamiento en UI:
1. Permitir edición desde vista detalle o modal de actualización.
2. Mostrar modal de confirmación antes de guardar cambios.
3. Mostrar bloque de Impact Summary cuando aplique (según tipo de cambio sensible).
4. No cerrar automáticamente la vista de edición cuando hay errores.

Criterios de aceptación:
1. Dado cambios en formulario, cuando el usuario pulsa guardar, entonces se abre confirmación de cambios.
2. Dado que el usuario confirma, entonces se ejecuta PATCH con los campos modificados.
3. Dado éxito en PATCH, entonces se notifica éxito y se refresca la información mostrada.
4. Dado error de validación, entonces se muestran mensajes por campo o mensaje de negocio.
5. Dado cancelación en modal de confirmación, entonces no se llama PATCH.

### 6.4 POST Suspender tenant
Endpoint:
- POST /api/v1/tenants/{tenant_id}/suspend

Comportamiento en UI:
1. Acción visible solo cuando tenant está activo/provisioning y el usuario tiene permiso.
2. Abrir modal de riesgo con advertencia clara del impacto.
3. Requerir confirmación reforzada tipeando SUSPEND antes de habilitar acción final.
4. Tras éxito, actualizar estado visual a Suspended.

Criterios de aceptación:
1. Dado tenant en estado elegible, cuando se selecciona suspender, entonces se abre modal de confirmación de riesgo.
2. Dado que no se escribe SUSPEND, entonces el botón final permanece deshabilitado.
3. Dado que se confirma correctamente, entonces se ejecuta POST suspend y backend retorna 204.
4. Dado 204 exitoso, entonces se muestra notificación y la fila/detalle pasa a estado Suspended.
5. Dado error, entonces se mantiene estado previo y se muestra mensaje de fallo.

### 6.5 POST Activar tenant
Endpoint:
- POST /api/v1/tenants/{tenant_id}/activate

Comportamiento en UI:
1. Acción visible solo cuando tenant está Suspended.
2. Confirmación simple o modal de activación.
3. Tras éxito, actualizar estado visual a Active.

Criterios de aceptación:
1. Dado tenant suspendido, cuando se pulsa activar y se confirma, entonces se ejecuta POST activate.
2. Dado 204 exitoso, entonces se refleja estado Active sin recargar toda la aplicación.
3. Dado error de API, entonces el estado no cambia y se notifica el error.

---

## 7. Requisitos de UX/UI del módulo Tenant
1. Jerarquía visual clara con título, subtítulo y acción primaria Create Tenant.
2. Tabla con legibilidad alta y badges de estado por color semántico.
3. Formularios agrupados en cards con iconografía y etiquetas claras.
4. Modales de confirmación para acciones sensibles.
5. Mensajes de impacto en cambios de seguridad/estado.
6. Estados de botones:
- Default
- Hover
- Disabled
- Loading
7. En ninguna pantalla del módulo se alteran estilos/estructura de header y sidebar.

---

## 8. Requisitos de validación de datos
1. slug:
- requerido
- minúsculas, números y guion
- sin espacios
2. name y legalName:
- requeridos
- longitud mínima y máxima configurable
3. taxId:
- requerido
- formato según país del tenant
4. timezone, locale, dateFormat, currency:
- requeridos
5. plan y mode:
- requeridos
- valores válidos según catálogo backend

---

## 9. Estados y manejo de errores
1. Loading de tabla y formularios.
2. Empty state de listado.
3. Error state con opción reintentar.
4. Éxito con notificación no intrusiva.
5. Errores de negocio con mensaje entendible.
6. Errores técnicos con trazabilidad mínima (id de error si backend lo provee).

---

## 10. Trazabilidad API -> Pantallas
1. Listado Tenant
- GET /api/v1/tenants
2. Crear Tenant
- POST /api/v1/tenants
3. Editar Tenant
- PATCH /api/v1/tenants/{tenant_id}
4. Suspender Tenant
- POST /api/v1/tenants/{tenant_id}/suspend
5. Activar Tenant
- POST /api/v1/tenants/{tenant_id}/activate

---

## 11. Criterios de aceptación globales del módulo
1. El módulo permite el ciclo completo de vida operativo: listar, crear, actualizar, suspender y activar.
2. Todas las acciones críticas requieren confirmación explícita.
3. Los cambios de estado se reflejan en UI de forma inmediata y consistente.
4. El módulo funciona respetando permisos de rol esperados.
5. Header y sidebar no se modifican.
6. El módulo cumple el diseño base de referencia entregado.

---

## 12. Fuera de alcance
1. Implementación de nuevos endpoints backend.
2. Rediseño de header/sidebar.
3. Gestión de usuarios y roles fuera del contexto tenant.
4. Analítica avanzada y reportes históricos del tenant.
