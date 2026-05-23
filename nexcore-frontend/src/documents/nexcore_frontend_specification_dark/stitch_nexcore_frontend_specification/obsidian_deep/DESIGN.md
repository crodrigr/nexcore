---
name: Obsidian Deep
colors:
  surface: '#0f1419'
  surface-dim: '#0f1419'
  surface-bright: '#353940'
  surface-container-lowest: '#0a0e14'
  surface-container-low: '#181c22'
  surface-container: '#1c2026'
  surface-container-high: '#262a30'
  surface-container-highest: '#31353b'
  on-surface: '#dfe2ea'
  on-surface-variant: '#bfc7d4'
  inverse-surface: '#dfe2ea'
  inverse-on-surface: '#2d3137'
  outline: '#89919d'
  outline-variant: '#404752'
  surface-tint: '#9ecaff'
  primary: '#9ecaff'
  on-primary: '#003258'
  primary-container: '#2196f3'
  on-primary-container: '#002c4f'
  inverse-primary: '#0061a4'
  secondary: '#7bd0ff'
  on-secondary: '#00354a'
  secondary-container: '#00a6e0'
  on-secondary-container: '#00374d'
  tertiary: '#ffb77b'
  on-tertiary: '#4d2700'
  tertiary-container: '#db7900'
  on-tertiary-container: '#452200'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#d1e4ff'
  primary-fixed-dim: '#9ecaff'
  on-primary-fixed: '#001d36'
  on-primary-fixed-variant: '#00497d'
  secondary-fixed: '#c4e7ff'
  secondary-fixed-dim: '#7bd0ff'
  on-secondary-fixed: '#001e2c'
  on-secondary-fixed-variant: '#004c69'
  tertiary-fixed: '#ffdcc2'
  tertiary-fixed-dim: '#ffb77b'
  on-tertiary-fixed: '#2e1500'
  on-tertiary-fixed-variant: '#6d3900'
  background: '#0f1419'
  on-background: '#dfe2ea'
  surface-variant: '#31353b'
typography:
  display-lg:
    fontFamily: Hanken Grotesk
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Hanken Grotesk
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Hanken Grotesk
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 36px
  title-md:
    fontFamily: Hanken Grotesk
    fontSize: 20px
    fontWeight: '500'
    lineHeight: 28px
  body-lg:
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
    fontFamily: Geist
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.05em
  code-sm:
    fontFamily: Geist
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  base: 4px
  xs: 0.25rem
  sm: 0.5rem
  md: 1rem
  lg: 1.5rem
  xl: 2.5rem
  gutter: 1rem
  margin-mobile: 1rem
  margin-desktop: 2rem
---

## Brand & Style
This design system is engineered for high-performance enterprise environments, focusing on deep focus and visual longevity. The brand personality is technical, precise, and authoritative. 

The design style utilizes **Modern Corporate** principles adapted for a dark-first environment. It emphasizes functional clarity through structured layering and intentional use of light. By leveraging high-contrast typography against deep slate surfaces, the system reduces eye strain while maintaining a sophisticated, developer-centric aesthetic. The emotional response is one of reliability, security, and calm control.

## Colors
The palette is anchored by a deep navy base (`#0f172a`) and slate surfaces (`#1e293b`) to establish clear hierarchical depth. 

- **Primary Blue (#2196f3):** Reserved strictly for primary actions, active states, and critical wayfinding.
- **Secondary Sky (#38bdf8):** Used for accents, illustrative icons, and secondary data visualizations.
- **Neutrals:** The "Slate" scale provides the structural foundation. Text hierarchy is enforced through contrast: White (`#f8fafc`) for headers and Slate-400 (`#94a3b8`) for secondary information.
- **Borders:** Subtle slate outlines (`#334155`) define boundaries without creating visual noise.

## Typography
The typography system uses a tri-font strategy to balance character and utility. 

- **Hanken Grotesk** is used for headlines to provide a sharp, contemporary edge.
- **Inter** serves as the workhorse for body copy, ensuring maximum readability across varying pixel densities.
- **Geist** is employed for labels, data points, and technical strings, leaning into its developer-friendly, monospaced-adjacent proportions.

On mobile devices, large display styles scale down by approximately 15% to maintain composition integrity within narrower viewports.

## Layout & Spacing
This design system utilizes a **12-column fluid grid** for desktop and a **4-column grid** for mobile. 

A strict 4px baseline grid governs all spatial relationships. Vertical rhythm is maintained by using `md` (16px) and `lg` (24px) spacing for most component groupings. Content containers should adhere to a max-width of 1440px on large screens to preserve line length readability. On mobile, margins are compressed to 16px to maximize horizontal real estate for data.

## Elevation & Depth
Depth is communicated through **Tonal Layering** rather than traditional shadows, which can appear muddy in dark modes.

- **Level 0 (Base):** Deep Navy (`#0f172a`) for the main background.
- **Level 1 (Card/Surface):** Slate (`#1e293b`) for primary content containers.
- **Level 2 (Overlay/Menu):** Lighter Slate (`#334155`) for tooltips, dropdowns, and modals.

When shadows are necessary for floating elements (modals), use a high-spread, low-opacity black shadow (`rgba(0,0,0,0.5)`) combined with a 1px inner border of a lighter slate to simulate a "rim light" effect.

## Shapes
The shape language is **Soft**, utilizing a 4px (0.25rem) standard radius for buttons and inputs. Larger components like cards use a 8px (0.5rem) radius. This subtle rounding softens the technical aesthetic without sacrificing the professional, structured feel. High-density components (like data grid cells or tags) should maintain 2px or 4px radii to remain space-efficient.

## Components
- **Buttons:** Primary buttons use the Primary Blue hex with white text. Secondary buttons use a ghost style with a Slate-700 border.
- **Input Fields:** Backgrounds should be 1-step darker than their parent surface. Active states must use a 2px Primary Blue focus ring with a 2px offset.
- **Chips/Tags:** Use low-saturation backgrounds with high-saturation text (e.g., a dark blue background with light blue text) to ensure legibility without overpowering the UI.
- **Cards:** Cards should not have shadows by default; they are defined by their `#1e293b` surface color against the `#0f172a` background.
- **Lists:** Use subtle `#334155` dividers. Hover states should utilize a subtle background highlight of `#334155` at 50% opacity.
- **Status Indicators:** Use semantic colors (Red for Error, Green for Success) but desaturate them by 10% compared to a light-mode equivalent to prevent "vibrating" against the dark background.