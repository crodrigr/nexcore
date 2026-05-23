---
name: NexCore
colors:
  surface: '#f8f9ff'
  surface-dim: '#d7dae2'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f1f3fc'
  surface-container: '#ebeef6'
  surface-container-high: '#e5e8f0'
  surface-container-highest: '#dfe2ea'
  on-surface: '#181c22'
  on-surface-variant: '#404752'
  inverse-surface: '#2d3137'
  inverse-on-surface: '#eef1f9'
  outline: '#707883'
  outline-variant: '#bfc7d4'
  surface-tint: '#0061a4'
  primary: '#0061a4'
  on-primary: '#ffffff'
  primary-container: '#2196f3'
  on-primary-container: '#002c4f'
  inverse-primary: '#9ecaff'
  secondary: '#b80049'
  on-secondary: '#ffffff'
  secondary-container: '#e2165f'
  on-secondary-container: '#fffbff'
  tertiary: '#904d00'
  on-tertiary: '#ffffff'
  tertiary-container: '#db7900'
  on-tertiary-container: '#452200'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d1e4ff'
  primary-fixed-dim: '#9ecaff'
  on-primary-fixed: '#001d36'
  on-primary-fixed-variant: '#00497d'
  secondary-fixed: '#ffd9de'
  secondary-fixed-dim: '#ffb2be'
  on-secondary-fixed: '#400014'
  on-secondary-fixed-variant: '#900038'
  tertiary-fixed: '#ffdcc2'
  tertiary-fixed-dim: '#ffb77b'
  on-tertiary-fixed: '#2e1500'
  on-tertiary-fixed-variant: '#6d3900'
  background: '#f8f9ff'
  on-background: '#181c22'
  surface-variant: '#dfe2ea'
typography:
  headline-xl:
    fontFamily: Inter
    fontSize: 40px
    fontWeight: '700'
    lineHeight: 48px
    letterSpacing: -0.02em
  headline-xl-mobile:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  navbar-height: 64px
  sidebar-width: 280px
  gutter: 24px
  margin-mobile: 16px
  margin-desktop: 32px
  unit-base: 8px
---

## Brand & Style
This design system is built upon a **Corporate Modern** aesthetic, prioritizing clarity, precision, and efficiency. It is designed for professional environments where information density must be balanced with extreme legibility.

The visual language utilizes a structured approach to white space and a disciplined color application to evoke a sense of reliability and technological sophistication. The goal is to provide a neutral yet powerful framework that supports complex workflows without cognitive overload. It blends the systematic rigor of enterprise software with the approachability of modern SaaS interfaces.

## Colors
The palette is centered around a high-energy **Blue 500** as the primary driver for action and brand recognition, balanced by a vibrant **Pink 500** for secondary accents and distinctive highlights. 

The system utilizes a comprehensive grayscale to manage content hierarchy. In the light mode, backgrounds use soft off-whites to reduce eye strain, while the dark mode shifts to deep charcoals to maintain contrast. Feedback colors are strictly reserved for functional communication (success, warning, error, info) to ensure they remain semantically meaningful and highly visible against the neutral backdrop.

## Typography
The typography relies exclusively on **Inter**, a typeface engineered for screen legibility. This design system employs a mobile-first scaling strategy: large display headings compress significantly on smaller screens to preserve vertical space and prevent awkward line breaks.

Hierarchy is established through weight and scale rather than decorative shifts. Use `700` for primary page titles to anchor the layout, `600` for sectional headers, and `400` for all body and instructional text. Labels utilize a slight tracking (letter-spacing) increase and uppercase styling to differentiate them from standard body copy.

## Layout & Spacing
The layout follows a **12-column fluid grid** for desktop and a **4-column grid** for mobile. A strict 8px base unit (unit-base) governs all spatial relationships, ensuring vertical rhythm across components.

The **Navbar** is fixed at 64px, serving as the global anchor. The **Sidebar** defaults to 280px on desktop for primary navigation. For content-heavy dashboards, use a 24px gutter to provide sufficient breathing room between cards and data modules. In mobile views, margins scale down to 16px to maximize the available screen real estate for content.

## Elevation & Depth
This design system uses **Ambient Shadows** and **Tonal Layers** to define the Z-axis. Depth is used functionally: higher elevation implies interactivity or temporary status (e.g., modals).

1.  **Level 0 (Base):** Default background.
2.  **Level 1 (Cards):** Surface color with a subtle 4px blur, 2% opacity black shadow.
3.  **Level 2 (Dropdowns/Hover states):** 8px blur, 5% opacity shadow.
4.  **Level 3 (Modals):** 16px blur, 12% opacity shadow with a backdrop dimming effect.

In Dark Mode, elevation is communicated through slightly lighter surface-container tones rather than increased shadow density, maintaining the professional aesthetic without "glow" effects.

## Shapes
The shape language is defined by a **Rounded** philosophy. Standard UI elements (buttons, inputs) utilize a 0.5rem (8px) radius. Larger containers, specifically **Cards**, utilize `rounded-lg` (16px) to create a softer, more modern framing for content. 

Circular shapes are reserved exclusively for avatars and specific status indicators. This consistent use of rounded corners softens the systematic nature of the corporate layout, making the platform feel contemporary and accessible.

## Components

### Buttons
- **Primary:** Solid #2196f3 background, white text. No shadow on rest, slight elevation on hover.
- **Secondary:** Solid #e91e63 background, white text.
- **Ghost:** Transparent background, primary color border and text. On hover, a 10% opacity primary color fill appears.

### Cards
Cards are the primary container. They feature the `rounded-lg` (16px) radius, a 1px neutral-light border, and a subtle Level 1 shadow. Padding within cards should default to 24px (3 units).

### Inputs
- **Default:** White background, 1px neutral border, 8px radius.
- **Hover:** Border color darkens by 10%.
- **Focus:** 2px solid primary color border with a soft glow (30% opacity primary shadow).
- **Error:** 1px solid #f44336 border with error message text in `body-sm`.

### Sidebar & Navbar
The Navbar is a Level 2 surface with a bottom border. The Sidebar uses a slightly darker neutral background than the main canvas to create clear architectural separation.

### Chips & Tags
Used for status and filtering. Use a 10% opacity background of the corresponding category color (e.g., Success green) with full-color text to ensure legibility while remaining visually "light."