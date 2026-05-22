# NexCore Frontend — Especificación de Diseño e Implementación
**Versión:** 1.0  
**Fecha:** 2026-05  
**Estado:** En desarrollo activo  

## 1. Visión General
El frontend de NexCore es una aplicación Angular 18 construida con **Nx workspace**, diseñada para ser:
- **Multi-tenant**: renderiza UI según permisos dinámicos del tenant
- **Themeable**: soporte nativo de modo **Light** y **Dark** con tokens de diseño
- **Modular**: feature libraries organizadas por dominio
- **Accesible**: WCAG 2.1 AA compliance
- **Responsive**: diseño mobile-first con breakpoints consistentes

## 2. Sistema de Design Tokens
### Colores Primarios
- Primary 500: #2196f3
- Secondary 500: #e91e63
- Success: #4caf50
- Warning: #ff9800
- Error: #f44336
- Info: #03a9f4

### Tipografía
- Primaria: 'Inter', sans-serif
- Secundaria: 'Roboto', sans-serif
- Mono: 'JetBrains Mono'

### Espaciado
- Base 8px (4px, 8px, 12px, 16px, 20px, 24px, 32px...)

## 3. Arquitectura de UI
- **Navbar**: Sticky, 64px, incluye búsqueda, notificaciones, toggle de tema y menú de usuario.
- **Sidebar**: Colapsable (280px / 64px), navegación principal con iconos y badges.
- **App Layout**: Grid de 2 columnas (Sidebar + Main Content).

## 4. Pantallas Requeridas
1. **Login**: Formulario limpio con branding y soporte para OTP.
2. **Dashboard**: Grid de estadísticas (Stats Cards), gráficos (Charts) y actividad reciente.
3. **User Profile**: Vista y edición de perfil.
4. **Tenant Management**: Listado y creación de tenants.
