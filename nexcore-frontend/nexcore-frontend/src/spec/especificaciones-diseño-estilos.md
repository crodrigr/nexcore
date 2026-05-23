# Especificaciones de Diseño y Estilos - NexCore Frontend

## 📋 Tabla de Contenidos

1. [Introducción](#introducción)
2. [Estructura General de Estilos](#estructura-general-de-estilos)
3. [Archivos Maestros](#archivos-maestros)
4. [Sistema de Tokens](#sistema-de-tokens)
5. [Sistema de Temas](#sistema-de-temas)
6. [Cómo Usar los Estilos en Componentes](#cómo-usar-los-estilos-en-componentes)
7. [Guía de Personalización](#guía-de-personalización)
8. [Ejemplos Prácticos](#ejemplos-prácticos)

---

## Introducción

Este documento explica cómo están organizados los estilos en NexCore Frontend. El sistema de estilos está diseñado para ser **centralizado**, **escalable** y **fácil de modificar**.

### ¿Por qué es importante entender esta estructura?

- **Cambios globales**: Modificar un solo archivo puede cambiar el diseño de toda la aplicación
- **Consistencia**: Todos los componentes usan los mismos valores de colores, espaciados y tipografía
- **Temas**: Soporte automático para modo claro y oscuro
- **Mantenibilidad**: Facilita actualizaciones y personalizaciones futuras

---

## Estructura General de Estilos

La estructura de carpetas de estilos es la siguiente:

```
src/
├── styles/                          # 📁 Carpeta principal de estilos
│   ├── tokens/                      # 📁 Tokens de diseño (valores base)
│   │   ├── _colors.scss            # 🎨 Paleta de colores
│   │   ├── _typography.scss        # 🔤 Fuentes y tamaños
│   │   ├── _spacing.scss           # 📏 Espaciados y márgenes
│   │   └── _borders.scss           # 🔲 Bordes y radios
│   │
│   └── themes/                      # 📁 Temas (claro/oscuro)
│       ├── _light.scss             # ☀️ Tema claro
│       └── _dark.scss              # 🌙 Tema oscuro
│
├── styles.scss                      # 📄 Archivo principal (importa todo)
│
└── app/                             # 📁 Componentes de la aplicación
    └── [componente]/
        └── [componente].component.scss  # Estilos específicos del componente
```

### Flujo de Estilos

```
styles.scss (archivo principal)
    ↓
    ├─→ tokens/ (valores base)
    │   ├─→ _colors.scss
    │   ├─→ _typography.scss
    │   ├─→ _spacing.scss
    │   └─→ _borders.scss
    │
    └─→ themes/ (aplicación de temas)
        ├─→ _light.scss
        └─→ _dark.scss
            ↓
    Todos los componentes usan estos valores mediante variables CSS
```

---

## Archivos Maestros

### 1. `src/styles.scss` - Archivo Principal

Este es el **punto de entrada** de todos los estilos. Importa todos los tokens y temas.

**Ubicación**: `src/styles.scss`

**Contenido**:
```scss
// Importar tokens de diseño
@use 'styles/tokens/colors' as *;
@use 'styles/tokens/typography' as *;
@use 'styles/tokens/spacing' as *;
@use 'styles/tokens/borders' as *;

// Importar temas
@use 'styles/themes/_light' as *;
@use 'styles/themes/_dark' as *;

// Estilos globales base
html, body {
  height: 100%;
  font-family: var(--font-family-primary);
  font-size: var(--font-size-base);
  color: var(--color-text-primary);
  background: var(--color-bg-primary);
}
```

**Para qué sirve**:
- Importa todos los archivos de tokens
- Importa los temas claro y oscuro
- Define estilos base para toda la aplicación
- Configura transiciones suaves entre temas

---

## Sistema de Tokens

Los **tokens** son valores reutilizables que definen el diseño visual. Son como una "biblioteca de valores" que todos los componentes pueden usar.

### 1. Tokens de Colores (`_colors.scss`)

**Ubicación**: `src/styles/tokens/_colors.scss`

#### Estructura del archivo

El archivo se divide en dos secciones:

##### **Sección 1: Paleta Base (Colores Primitivos)**

Estos son los colores "crudos". **NO se usan directamente en componentes**.

```scss
// Primarios (azules)
$color-primary-50:  #e3f2fd;   // Azul muy claro
$color-primary-100: #bbdefb;
$color-primary-200: #90caf9;
$color-primary-300: #64b5f6;
$color-primary-400: #42a5f5;
$color-primary-500: #2196f3;   // ⭐ Azul base principal
$color-primary-600: #1e88e5;
$color-primary-700: #1976d2;
$color-primary-800: #1565c0;
$color-primary-900: #0d47a1;   // Azul muy oscuro

// Neutrales (grises y blanco/negro)
$color-neutral-0:   #ffffff;   // Blanco puro
$color-neutral-50:  #fafafa;
$color-neutral-100: #f5f5f5;
$color-neutral-200: #eeeeee;
...
$color-neutral-900: #212121;   // Negro casi puro

// Estados (feedback)
$color-success-500: #4caf50;   // Verde (éxito)
$color-warning-500: #ff9800;   // Naranja (advertencia)
$color-error-500:   #f44336;   // Rojo (error)
$color-info-500:    #03a9f4;   // Azul claro (información)
```

##### **Sección 2: Tokens Semánticos (Variables CSS)**

Estos **SÍ se usan en los componentes**. Son nombres descriptivos que indican **para qué se usa el color**.

```scss
:root {
  // 🎨 Fondos
  --color-bg-primary: #{$color-neutral-0};      // Fondo principal (blanco)
  --color-bg-secondary: #{$color-neutral-50};   // Fondo secundario (gris claro)
  --color-bg-tertiary: #{$color-neutral-100};   // Fondo terciario
  
  // 📄 Superficies (tarjetas, paneles)
  --color-surface: #{$color-neutral-0};         // Superficie principal
  --color-surface-hover: #{$color-neutral-50};  // Al pasar el mouse
  
  // ✍️ Textos
  --color-text-primary: #{$color-neutral-900};    // Texto principal (negro)
  --color-text-secondary: #{$color-neutral-700};  // Texto secundario (gris oscuro)
  --color-text-tertiary: #{$color-neutral-600};   // Texto terciario
  --color-text-inverse: #{$color-neutral-0};      // Texto inverso (blanco sobre oscuro)
  
  // 🔲 Bordes
  --color-border-light: #{$color-neutral-200};    // Borde sutil
  --color-border-medium: #{$color-neutral-300};   // Borde medio
  --color-border-heavy: #{$color-neutral-400};    // Borde fuerte
  
  // 🖱️ Elementos interactivos (botones, links)
  --color-interactive-primary: #{$color-primary-500};        // Color principal
  --color-interactive-primary-hover: #{$color-primary-600}; // Al pasar el mouse
  --color-interactive-primary-active: #{$color-primary-700};// Al hacer clic
  
  // ✅ Estados y feedback
  --color-success: #{$color-success-500};   // Verde (éxito)
  --color-warning: #{$color-warning-500};   // Naranja (advertencia)
  --color-error: #{$color-error-500};       // Rojo (error)
  --color-info: #{$color-info-500};         // Azul (información)
  
  --color-success-bg: #{$color-success-50}; // Fondo verde claro
  --color-error-bg: #{$color-error-50};     // Fondo rojo claro
}
```

**Ventaja de este sistema**:
- Los componentes usan nombres descriptivos (`--color-text-primary`)
- Los temas pueden cambiar el valor sin modificar los componentes
- Es fácil entender qué hace cada color

---

### 2. Tokens de Tipografía (`_typography.scss`)

**Ubicación**: `src/styles/tokens/_typography.scss`

Define fuentes, tamaños y pesos de texto.

```scss
:root {
  // 🔤 Familias de fuentes
  --font-family-primary: 'Inter', sans-serif;     // Fuente principal
  --font-family-secondary: 'Roboto', sans-serif;  // Fuente secundaria
  --font-family-mono: 'JetBrains Mono', monospace; // Fuente monoespaciada (código)
  
  // 📏 Tamaños de fuente
  --font-size-xs:   0.75rem;   // 12px - Muy pequeño
  --font-size-sm:   0.875rem;  // 14px - Pequeño
  --font-size-base: 1rem;      // 16px - ⭐ Base (normal)
  --font-size-lg:   1.125rem;  // 18px - Grande
  --font-size-xl:   1.25rem;   // 20px - Muy grande
  --font-size-2xl:  1.5rem;    // 24px - Título
  --font-size-3xl:  2rem;      // 32px - Título grande
  --font-size-4xl:  2.5rem;    // 40px - Título hero
  
  // ⚖️ Pesos de fuente
  --font-weight-light:    300;  // Ligera
  --font-weight-normal:   400;  // Normal
  --font-weight-medium:   500;  // Media
  --font-weight-semibold: 600;  // Semi-negrita
  --font-weight-bold:     800;  // Negrita
  
  // 📐 Alturas de línea (interlineado)
  --line-height-tight:   1.25;  // Compacto
  --line-height-normal:  1.5;   // ⭐ Normal
  --line-height-relaxed: 1.75;  // Espaciado
}
```

**Uso en componentes**:
```scss
.titulo {
  font-size: var(--font-size-2xl);
  font-weight: var(--font-weight-bold);
  line-height: var(--line-height-tight);
}
```

---

### 3. Tokens de Espaciado (`_spacing.scss`)

**Ubicación**: `src/styles/tokens/_spacing.scss`

Define espacios consistentes entre elementos (márgenes, padding, gaps).

**Sistema base de 8px**: Todos los espacios son múltiplos de 4px u 8px para mantener armonía visual.

```scss
:root {
  --spacing-0:  0;          // Sin espacio
  --spacing-1:  0.25rem;    // 4px   - Muy pequeño
  --spacing-2:  0.5rem;     // 8px   - Pequeño
  --spacing-3:  0.75rem;    // 12px  - Pequeño-medio
  --spacing-4:  1rem;       // 16px  - ⭐ Base
  --spacing-5:  1.25rem;    // 20px  - Medio
  --spacing-6:  1.5rem;     // 24px  - Medio-grande
  --spacing-8:  2rem;       // 32px  - Grande
  --spacing-10: 2.5rem;     // 40px  - Muy grande
  --spacing-12: 3rem;       // 48px  - Extra grande
  --spacing-16: 4rem;       // 64px  - Sección
  --spacing-20: 5rem;       // 80px  - Sección grande
  --spacing-24: 6rem;       // 96px  - Hero section
  --spacing-32: 8rem;       // 128px - Extra espacioso
}
```

**Uso en componentes**:
```scss
.card {
  padding: var(--spacing-6);      // 24px de padding
  margin-bottom: var(--spacing-4); // 16px de margen inferior
  gap: var(--spacing-3);          // 12px entre elementos hijos
}
```

---

### 4. Tokens de Bordes (`_borders.scss`)

**Ubicación**: `src/styles/tokens/_borders.scss`

Define anchos y radios de bordes.

```scss
:root {
  // 📏 Anchos de borde
  --border-width-thin:   1px;   // Fino
  --border-width-medium: 2px;   // Medio
  --border-width-thick:  4px;   // Grueso
  
  // 🔘 Radios de borde (esquinas redondeadas)
  --border-radius-sm:   4px;    // Pequeño
  --border-radius-base: 8px;    // ⭐ Base
  --border-radius-md:   12px;   // Medio
  --border-radius-lg:   16px;   // Grande
  --border-radius-xl:   24px;   // Extra grande
  --border-radius-full: 9999px; // Completamente redondo (píldora/círculo)
}
```

**Uso en componentes**:
```scss
.button {
  border: var(--border-width-thin) solid var(--color-border-medium);
  border-radius: var(--border-radius-base);
}
```

---

## Sistema de Temas

NexCore soporta **dos temas**: claro y oscuro. Los temas **sobrescriben** los valores de los tokens según el modo seleccionado.

### Cómo funciona

1. Por defecto, se cargan los valores del `:root` (tema claro)
2. Cuando el usuario activa el tema oscuro, se aplica el atributo `[data-theme='dark']` al `<body>`
3. Los valores de las variables CSS se sobrescriben automáticamente
4. Todos los componentes que usan las variables **cambian automáticamente**

### Tema Claro (`_light.scss`)

**Ubicación**: `src/styles/themes/_light.scss`

```scss
[data-theme='light'] {
  // Fondos claros
  --color-bg-primary: #ffffff;     // Blanco
  --color-bg-secondary: #fafafa;   // Gris muy claro
  
  // Textos oscuros
  --color-text-primary: #212121;   // Negro
  --color-text-secondary: #616161; // Gris oscuro
  
  // Bordes sutiles
  --color-border-light: #eeeeee;   // Gris claro
  
  // Sombras
  --shadow-sm: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
  --shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
}
```

### Tema Oscuro (`_dark.scss`)

**Ubicación**: `src/styles/themes/_dark.scss`

```scss
[data-theme='dark'] {
  // Fondos oscuros
  --color-bg-primary: #212121;     // Negro casi puro
  --color-bg-secondary: #424242;   // Gris oscuro
  
  // Textos claros
  --color-text-primary: #fafafa;   // Blanco
  --color-text-secondary: #e0e0e0; // Gris claro
  
  // Bordes más sutiles
  --color-border-light: #616161;   // Gris medio
  
  // Sombras más fuertes
  --shadow-sm: 0 1px 2px 0 rgba(0, 0, 0, 0.3);
  --shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.4);
  
  // Colores primarios ajustados para mejor contraste
  --color-interactive-primary: #42a5f5;        // Azul más claro
  --color-interactive-primary-hover: #64b5f6;  // Azul aún más claro
}
```

**Ventaja**: Los componentes **no necesitan saber** qué tema está activo. Simplemente usan `var(--color-text-primary)` y el valor cambia automáticamente.

---

## Cómo Usar los Estilos en Componentes

Los componentes **NO** deben:
- ❌ Usar colores directos: `color: #2196f3;`
- ❌ Usar tamaños fijos: `font-size: 16px;`
- ❌ Repetir valores: `padding: 24px;` en múltiples lugares

Los componentes **SÍ** deben:
- ✅ Usar variables CSS: `color: var(--color-text-primary);`
- ✅ Usar tokens semánticos: `font-size: var(--font-size-lg);`
- ✅ Reutilizar valores: `padding: var(--spacing-6);`

### Ejemplo de Componente: Sidebar

**Archivo**: `src/app/shared/layout/sidebar.component.scss`

```scss
.sidebar {
  // Usando tokens de espaciado y colores
  width: 260px;
  background: var(--color-bg-secondary);       // ✅ Fondo secundario
  border-right: 1px solid var(--color-border-light); // ✅ Borde claro
  padding: var(--spacing-4) var(--spacing-3);  // ✅ Espaciado consistente
  height: calc(100vh - 64px);
}

.sidebar-link {
  display: flex;
  align-items: center;
  gap: var(--spacing-3);                       // ✅ Espaciado entre ícono y texto
  padding: var(--spacing-3) var(--spacing-4);
  color: var(--color-text-secondary);          // ✅ Texto secundario
  border-radius: var(--border-radius-base);    // ✅ Radio base
  font-weight: var(--font-weight-semibold);    // ✅ Peso semi-negrita
  
  &:hover {
    background: var(--color-surface-hover);    // ✅ Hover state
  }
  
  &.active {
    background: var(--color-interactive-primary); // ✅ Color primario
    color: var(--color-text-inverse);             // ✅ Texto inverso (blanco)
  }
}
```

**Resultado**:
- En tema claro: fondo blanco, texto negro, borde gris claro
- En tema oscuro: fondo gris oscuro, texto blanco, borde gris medio
- **Sin cambiar una sola línea de código del componente** ✨

---

## Guía de Personalización

### 🎨 Cambiar el Color Principal de Toda la Aplicación

**Archivo a modificar**: `src/styles/tokens/_colors.scss`

**Paso 1**: Encuentra la paleta de colores primarios

```scss
// Busca esta sección en _colors.scss:
$color-primary-50:  #e3f2fd;
$color-primary-100: #bbdefb;
$color-primary-200: #90caf9;
$color-primary-300: #64b5f6;
$color-primary-400: #42a5f5;
$color-primary-500: #2196f3;  // ⭐ Este es el color principal
$color-primary-600: #1e88e5;
$color-primary-700: #1976d2;
$color-primary-800: #1565c0;
$color-primary-900: #0d47a1;
```

**Paso 2**: Reemplaza con tu nueva paleta

Por ejemplo, para cambiar a verde:

```scss
$color-primary-50:  #e8f5e9;  // Verde muy claro
$color-primary-100: #c8e6c9;
$color-primary-200: #a5d6a7;
$color-primary-300: #81c784;
$color-primary-400: #66bb6a;
$color-primary-500: #4caf50;  // ⭐ Verde principal
$color-primary-600: #43a047;
$color-primary-700: #388e3c;
$color-primary-800: #2e7d32;
$color-primary-900: #1b5e20;
```

**Resultado**: 
- Todos los botones primarios cambiarán a verde
- El sidebar activo cambiará a verde
- Los links cambiarán a verde
- El logo/branding cambiará a verde

**Dónde se aplica**:
- Botones principales
- Links activos
- Navbar brand
- Elementos interactivos destacados
- Gráficos y charts (color primario)

---

### 🔤 Cambiar la Fuente de Toda la Aplicación

**Archivo a modificar**: `src/styles/tokens/_typography.scss`

**Paso 1**: Cambia la fuente primaria

```scss
// Antes:
$font-family-primary: 'Inter', sans-serif;

// Después (ejemplo con Poppins):
$font-family-primary: 'Poppins', sans-serif;
```

**Paso 2**: Importa la fuente en `src/index.html`

```html
<head>
  <!-- Agrega esto en el <head> -->
  <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;800&display=swap" rel="stylesheet">
</head>
```

**Resultado**: Toda la aplicación usará la nueva fuente.

---

### 📏 Cambiar los Espaciados Globales

**Archivo a modificar**: `src/styles/tokens/_spacing.scss`

Si quieres hacer la interfaz más compacta o más espaciosa:

```scss
// Más compacta (reducir valores):
:root {
  --spacing-4: 0.75rem;  // Antes: 1rem (16px)
  --spacing-6: 1.25rem;  // Antes: 1.5rem (24px)
  --spacing-8: 1.75rem;  // Antes: 2rem (32px)
}

// Más espaciosa (aumentar valores):
:root {
  --spacing-4: 1.25rem;  // Antes: 1rem (16px)
  --spacing-6: 2rem;     // Antes: 1.5rem (24px)
  --spacing-8: 2.5rem;   // Antes: 2rem (32px)
}
```

---

### 🌙 Personalizar el Tema Oscuro

**Archivo a modificar**: `src/styles/themes/_dark.scss`

Por ejemplo, hacer el fondo aún más oscuro:

```scss
[data-theme='dark'] {
  // Cambiar de gris oscuro a negro puro
  --color-bg-primary: #000000;     // Antes: #212121
  --color-bg-secondary: #1a1a1a;   // Antes: #424242
  
  // Aumentar el contraste del texto
  --color-text-primary: #ffffff;   // Antes: #fafafa
}
```

---

### 🔲 Cambiar el Radio de Bordes (Más o Menos Redondeado)

**Archivo a modificar**: `src/styles/tokens/_borders.scss`

```scss
// Más cuadrado (menos redondeado):
:root {
  --border-radius-base: 4px;   // Antes: 8px
  --border-radius-md: 6px;     // Antes: 12px
  --border-radius-lg: 8px;     // Antes: 16px
}

// Más redondeado:
:root {
  --border-radius-base: 12px;  // Antes: 8px
  --border-radius-md: 16px;    // Antes: 12px
  --border-radius-lg: 24px;    // Antes: 16px
}
```

**Resultado**: Todos los botones, cards, inputs y paneles cambiarán su redondeo.

---

## Ejemplos Prácticos

### Ejemplo 1: Cambiar el Color de Todos los Textos

**Problema**: Quiero que los textos principales sean más oscuros.

**Solución**:

1. Abre: `src/styles/tokens/_colors.scss`
2. Busca: `--color-text-primary`
3. Cambia:
```scss
// Antes:
--color-text-primary: #{$color-neutral-900};  // #212121

// Después (más oscuro):
--color-text-primary: #{$color-neutral-1000}; // #000000 (negro puro)
```

---

### Ejemplo 2: Hacer los Botones Más Grandes

**Problema**: Los botones se ven muy pequeños.

**Solución**:

1. Abre el componente del botón (si existe) o los estilos donde se definen botones
2. Cambia el padding usando tokens:

```scss
.btn-primary {
  // Antes:
  padding: var(--spacing-3) var(--spacing-5);  // 12px 20px
  
  // Después (más grande):
  padding: var(--spacing-4) var(--spacing-8);  // 16px 32px
  
  // También puedes aumentar el tamaño de fuente:
  font-size: var(--font-size-lg);  // Antes: var(--font-size-base)
}
```

---

### Ejemplo 3: Cambiar el Color del Navbar

**Problema**: Quiero que el navbar tenga un fondo azul oscuro.

**Solución 1 (Rápida)**: Modificar directamente el componente

1. Abre: `src/app/shared/layout/navbar.component.scss`
2. Encuentra la clase `.navbar`
3. Cambia:
```scss
.navbar {
  // Antes:
  background: var(--color-bg-secondary);
  
  // Después:
  background: #1976d2;  // Azul oscuro fijo
  color: var(--color-text-inverse);  // Texto blanco
}
```

**Solución 2 (Mejor práctica)**: Crear un nuevo token

1. Abre: `src/styles/tokens/_colors.scss`
2. Agrega un nuevo token:
```scss
:root {
  // ... otros tokens
  --color-navbar-bg: #1976d2;
  --color-navbar-text: #{$color-neutral-0};
}
```

3. Actualiza `navbar.component.scss`:
```scss
.navbar {
  background: var(--color-navbar-bg);
  color: var(--color-navbar-text);
}
```

4. También puedes agregar variantes para tema oscuro en `_dark.scss`:
```scss
[data-theme='dark'] {
  --color-navbar-bg: #0d47a1;  // Azul aún más oscuro en modo oscuro
}
```

---

### Ejemplo 4: Crear un Nuevo Color de Estado (Por ejemplo, "Pendiente")

**Problema**: Necesito un color amarillo para estado "Pendiente".

**Solución**:

1. Abre: `src/styles/tokens/_colors.scss`
2. Agrega la paleta amarilla en la sección de colores primitivos:
```scss
// Estados
$color-pending-50:  #fffbea;
$color-pending-500: #fbbf24;
$color-pending-700: #f59e0b;
```

3. Agrega los tokens semánticos:
```scss
:root {
  // Estados
  --color-success: #{$color-success-500};
  --color-warning: #{$color-warning-500};
  --color-error: #{$color-error-500};
  --color-pending: #{$color-pending-500};  // ⭐ Nuevo
  
  --color-pending-bg: #{$color-pending-50}; // ⭐ Fondo amarillo claro
}
```

4. Úsalo en tu componente:
```scss
.badge-pending {
  background: var(--color-pending-bg);
  color: var(--color-pending);
  border: 1px solid var(--color-pending);
}
```

---

## 📚 Resumen: Checklist de Personalización

### Para cambiar el color principal de la app:
- [ ] Editar `src/styles/tokens/_colors.scss` → Paleta `$color-primary-*`
- [ ] Verificar que `--color-interactive-primary` apunta al nuevo color

### Para cambiar la fuente:
- [ ] Editar `src/styles/tokens/_typography.scss` → `$font-family-primary`
- [ ] Importar la fuente en `src/index.html`

### Para ajustar espaciados:
- [ ] Editar `src/styles/tokens/_spacing.scss` → Variables `--spacing-*`

### Para personalizar el tema oscuro:
- [ ] Editar `src/styles/themes/_dark.scss` → Sobrescribir variables

### Para cambiar bordes y redondeo:
- [ ] Editar `src/styles/tokens/_borders.scss` → Variables `--border-radius-*`

---

## 🎯 Consejos Finales

1. **Siempre usa variables CSS** en los componentes (no valores fijos)
2. **Documenta tus cambios** si modificas los tokens base
3. **Prueba en ambos temas** (claro y oscuro) después de hacer cambios
4. **Usa nombres semánticos** cuando crees nuevos tokens
5. **Mantén la consistencia** usando los tokens existentes antes de crear nuevos

---

## 🔗 Archivos Clave de Referencia

| Archivo | Ubicación | Propósito |
|---------|-----------|-----------|
| Punto de entrada | `src/styles.scss` | Importa todo |
| Colores | `src/styles/tokens/_colors.scss` | Paleta completa |
| Tipografía | `src/styles/tokens/_typography.scss` | Fuentes y tamaños |
| Espaciado | `src/styles/tokens/_spacing.scss` | Márgenes y padding |
| Bordes | `src/styles/tokens/_borders.scss` | Radios y anchos |
| Tema claro | `src/styles/themes/_light.scss` | Valores modo claro |
| Tema oscuro | `src/styles/themes/_dark.scss` | Valores modo oscuro |

---

**Última actualización**: Mayo 2026  
**Versión**: 1.0  
**Mantenedor**: Equipo NexCore Frontend
