# Especificación: Implementación Multilenguaje (i18n) — NexCore Frontend

Última actualización: 2026-05-23

Propósito: proporcionar una especificación técnica y operativa para habilitar soporte multilenguaje en toda la aplicación NexCore Frontend sin aplicar cambios todavía. Incluye decisiones de diseño, estructura de archivos, flujo de trabajo de traducción, consideraciones de rendimiento y plan de migración.

---

## 1. Resumen ejecutivo

- Objetivo: soportar múltiples idiomas (ej. `es`, `en`) en UI, mensajes desde TypeScript, validaciones, títulos de rutas, charts y metadatos, con capacidad de cambiar idioma en runtime, fallback y carga perezosa (lazy-load).
- Recomendación: usar **Transloco** (runtime, lazy-load, scopes) o como alternativa **ngx-translate**. Evitar Angular built-in i18n si se necesita cambio de idioma en runtime (built‑time obliga a builds por idioma).

Decisión principal (recomendada): Transloco.
Motivación: runtime switching, lazy-loaded scopes por feature, buen soporte para pluralization/ICU y herramientas de extracción.

---

## 2. Alcance

Incluye:
- Traducción de templates HTML y strings en TypeScript
- Internacionalización de validadores y mensajes de error
- Localización de fechas, números y monedas
- Traducción de rutas y títulos (`app.routes.ts`) y meta tags
- Chart labels y datasets
- Selector de idioma, persistencia (localStorage), e integración en perfil/navbar
- Flujo de traducción (archivos JSON, CI, integración con plataformas de traducción)
- Pruebas unitarias, e2e y QA lingüístico

No incluye (por ahora):
- Cambios a backend para i18n de mensajes de servidor (se documentará cómo integrarlo)
- Implementación SSR específica (ver consideraciones más abajo)

---

## 3. Estructura propuesta de archivos

Recomendación de estructura de ficheros en el repo (assets):

```
src/
└── assets/
    └── i18n/
        ├── en/
        │   ├── shared.json
        │   ├── auth.json
        │   ├── dashboard.json
        │   └── charts.json
        └── es/
            ├── shared.json
            ├── auth.json
            ├── dashboard.json
            └── charts.json
```

- Cada `*.json` es un scope/feature. Ejemplo: `auth.json` contiene `login`, `forgot-password`, `verify-otp`.
- Alternativa: `assets/i18n/{scope}.{lang}.json` (ambas son válidas, elegir la que facilite CI/translators).

---

## 4. Convenciones de keys y contenido

- Usar claves semánticas y jerárquicas: `feature.block.element[.subelement]`.
- Ejemplos:
  - `auth.login.title` → "Sign in"
  - `navbar.profile.signOut` → "Sign out"
  - `dashboard.stats.totalUsers.label`
- Evitar usar la cadena fuente como key.
- Mantener variables usando interpolación: `welcome: "Welcome, {{name}}"`.
- Para pluralización, usar ICU o funciones de transloco: `items: "{count, plural, =0 {...} =1 {...} other {...}}"`.

---

## 5. Cómo traducir templates y TypeScript (flujos)

1. Templates HTML
   - Reemplazar texto estático por pipe/directive: `{{ 'auth.login.title' | transloco }}` o `<ng-container *transloco="'auth.login.title'">`.
   - Para atributos: `[placeholder]="'auth.login.username' | transloco"`.

2. TypeScript
   - Inyectar `TranslocoService` y usar `translocoService.translate('key')` para obtener strings en runtime.
   - Para mensajes de validación: `const msg = this.translocoService.translate('auth.errors.required')`.
   - Para observables/reactive: `translocoService.selectTranslate('key')`.

3. Charts y datos programáticos
   - Preparar labels/datasets traducidos antes de pasar al Chart.js.
   - Ejemplo: `labels = labelsKeys.map(k => translocoService.translate(k))`.

---

## 6. Formatos y pluralización

- Usar `Intl` (nativo) para formateo de números/moneda/fechas: `new Intl.NumberFormat(locale, opts).format(value)`.
- Registrar locales si se usan pipes de Angular (`registerLocaleData`) y configurar `LOCALE_ID` cuando sea necesario.
- Para plurales y casos complejos usar ICU messages en JSON o la extensión de Transloco para pluralization.

---

## 7. Rutas, títulos y SEO

- Mantener `title` en `app.routes.ts` como clave traducible: `title: () => translocoService.translate('routes.dashboard')` o mediante un `Title` resolver que traduzca al activar la ruta.
- Para SSR/SEO (Angular Universal):
  - Opción A (mejor para SEO): usar build-time i18n para páginas públicas y Transloco para runtime en SPA. Esto es híbrido y más complejo.
  - Opción B: usar Angular Universal y pre-render para cada idioma (con Transloco pre-cargado por idioma) — requiere adaptación del servidor para cargar JSON por idioma.

Recomendación: Priorizar runtime con meta titles actualizados en cliente; evaluar SSR si SEO orgánico es crítico.

---

## 8. Lazy-loading de traducciones y performance

- Configurar traducciones por scope/feature y lazy-load por módulo (Transloco loader).
- Cache de peticiones JSON (HTTP cache / service worker) para mejorar perf.
- Mantener idioma por defecto con fallback keys y registrar missing-key handler para logging (Sentry/console).

---

## 9. Integración con librerías y componentes 3rd party

- Charts: traducir labels/datasets en el código antes de inicializar Chart.js.
- Component libraries: si usan strings internas, verificar si exponen hooks i18n; si no, envolver/patchear localmente.

---

## 10. RTL y layout

- Añadir soporte `dir='rtl'` al `<html>` o `<body>` y preparar CSS con logical properties o clases que adapten paddings/margins.
- Revisar dropdowns, posicionamientos absolutos y transform/translate que pueden necesitar ajustes.

---

## 11. Flujo de traducción y CI

- Mantener archivos JSON en repo (source-of-truth).
- Integración opcional con plataforma (POEditor, Crowdin).
- CI checks:
  - Validar JSON válido
  - Verificar que todas las keys del `en` (source) estén en los demás idiomas (reportar faltantes)
  - Ejecutar tests unitarios y e2e en al menos `en` y `es` (o idioma default y uno secundario)

---

## 12. Pruebas y QA

- Unit tests: mock `TranslocoService` para traducciones y verificar mensajes de error y validaciones.
- E2E: ejecutar flujos críticos (login, forgot-password, verify-otp, dashboard) en cada idioma priorizado.
- QA lingüístico: revisión humana de traducciones y pruebas visuales para textos largos.

---

## 13. Rollout y migración (fases y estimación)

Fase 0 — Preparación (1–2 días)
- Decidir librería (Transloco)
- Crear estructura `assets/i18n/` y añadir scaffold de `en` y `es` (archivos vacíos con keys principales)

Fase 1 — Core y Auth (2–4 días)
- Traducir `auth` (login, forgot, otp) y `navbar` (profile, menu)
- Implementar selector de idioma y persistencia
- Tests básicos y QA rápida

Fase 2 — Dashboard y Shared (3–7 días)
- Traducir dashboard, recent-activity, charts y mensajes TS
- Ajustar charts y formatos
- E2E para dashboard flows

Fase 3 — Full sweep y CI (2–4 días)
- Completar traducciones restantes, configurar CI checks, integración con plataforma de traducción
- Documentación y handoff a equipo de traducción

Estimación total aproximada: 8–17 días hábiles (dependiendo del tamaño del equipo y la automatización disponible).

---

## 14. Prioridad de archivos/componentes a traducir (mínimo viable)

Orden sugerido:
1. `src/app/shared/layout/navbar.component.*` (selector, profile menu, sign out)
2. `src/app/features/auth/**` (login, forgot-password, verify-otp)
3. `src/app/app.routes.ts` (titles)
4. `src/app/features/dashboard/**` (stat cards, charts, legends)
5. `src/app/shared/components/recent-activity/**`
6. Formularios y validaciones en `src/app/features/**`
7. Mensajes en servicios/TS (AuthService, NotificationService)
8. Resto de components y modals

---

## 15. Riesgos y mitigaciones

- Texto demasiado largo en otros idiomas → reservar espacio y usar truncation/tooltip.
- Keys faltantes → habilitar logging y fallback (mostrar key en dev).
- SSR/SEO → planificar híbrido o pre-render si SEO es crítico.
- Dependencias sin i18n → crear wrappers y documentar.

---

## 16. Entregables esperados

- Documento de configuración (esta especificación)
- Scaffold de `assets/i18n/` (archivos JSON con keys principales)
- Guía de migración para desarrolladores
- CI job que valide keys y JSON
- Tests e2e por idioma

---

## 17. Siguientes pasos propuestos (si desea que los haga)

- Generar el scaffold `assets/i18n/` con keys iniciales (sin traducciones).
- Preparar una propuesta concreta de `Transloco` configuration (código de ejemplo y dónde integrarlo).
- Generar lista de todas las keys encontradas (scan) y un archivo CSV para traducción.

Si quieres que genere alguno de estos artefactos (scaffold, configuración Transloco o listado de keys), indícalo y lo preparo sin aplicar cambios en el código base (o puedo crear los archivos scaffold en `src/spec` si prefieres revisar primero). 
