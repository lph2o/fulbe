---
name: Heritage Modernism
colors:
  surface: '#f8f9fa'
  surface-dim: '#d9dadb'
  surface-bright: '#f8f9fa'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f4f5'
  surface-container: '#edeeef'
  surface-container-high: '#e7e8e9'
  surface-container-highest: '#e1e3e4'
  on-surface: '#191c1d'
  on-surface-variant: '#414844'
  inverse-surface: '#2e3132'
  inverse-on-surface: '#f0f1f2'
  outline: '#717973'
  outline-variant: '#c1c8c2'
  surface-tint: '#3f6653'
  primary: '#012d1d'
  on-primary: '#ffffff'
  primary-container: '#1b4332'
  on-primary-container: '#86af99'
  inverse-primary: '#a5d0b9'
  secondary: '#735c00'
  on-secondary: '#ffffff'
  secondary-container: '#fed65b'
  on-secondary-container: '#745c00'
  tertiary: '#002842'
  on-tertiary: '#ffffff'
  tertiary-container: '#003f63'
  on-tertiary-container: '#59adee'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#c1ecd4'
  primary-fixed-dim: '#a5d0b9'
  on-primary-fixed: '#002114'
  on-primary-fixed-variant: '#274e3d'
  secondary-fixed: '#ffe088'
  secondary-fixed-dim: '#e9c349'
  on-secondary-fixed: '#241a00'
  on-secondary-fixed-variant: '#574500'
  tertiary-fixed: '#cde5ff'
  tertiary-fixed-dim: '#93ccff'
  on-tertiary-fixed: '#001d32'
  on-tertiary-fixed-variant: '#004b74'
  background: '#f8f9fa'
  on-background: '#191c1d'
  surface-variant: '#e1e3e4'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
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
  label-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-sm:
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
  unit: 4px
  container-max-width: 1280px
  gutter: 24px
  margin-mobile: 16px
  margin-desktop: 40px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 32px
---

## Brand & Style
The design system is built on the intersection of cultural heritage and global professional standards. It prioritizes a premium, "High-Trust" aesthetic that balances the warmth of community with the precision of a fintech platform.

The visual style is **Contemporary Minimalism**. It utilizes generous whitespace, purposeful structural alignment, and a refined "paper-and-ink" quality. The UI avoids unnecessary ornamentation, allowing content and cultural symbolism to lead. The emotional response is one of stability, prestige, and quiet confidence—positioning the platform as the definitive global hub for professional and cultural connection.

## Colors
The palette is grounded in a deep **Forest Green** (Primary), symbolizing growth and ancestral roots. This is accented by **Soft Gold** (Secondary) to denote prestige and high value in cultural exchange.

- **Primary (#1B4332):** Used for key brand moments, primary buttons, and heavy navigational headers.
- **Secondary (#D4AF37):** Reserved for rewards, verified statuses, and high-level cultural highlights. Use sparingly to maintain its premium impact.
- **Accent (#0077B5):** A trusted Blue utilized specifically for interactive elements, links, and technical data visualizations.
- **Surface:** The background uses a soft **Off-white (#F8F9FA)** to reduce eye strain and provide a more tactile, sophisticated feel than pure white.

## Typography
This design system employs **Inter** for its exceptional legibility and systematic feel. The hierarchy is "top-heavy," using tight letter-spacing and bold weights for headings to create a sense of editorial authority.

Body text maintains a standard tracking to ensure comfortable long-form reading. Small labels and "Overlines" should be set in Semi-Bold with slight tracking increases to maintain clarity at small scales. Always prioritize vertical rhythm by aligning text to a 4px baseline grid.

## Layout & Spacing
The layout follows a **12-column fluid grid** for desktop and a **4-column grid** for mobile. 

- **Density:** The system leans toward a "loose" density. Use `stack-lg` (32px) to separate distinct content sections and `stack-md` (16px) for internal card padding.
- **Safe Areas:** On mobile, ensure a minimum 16px horizontal margin. On desktop, content should be centered with a max-width of 1280px to prevent line lengths from becoming unreadable.
- **Vertical Rhythm:** All spacing increments must be multiples of 4px.

## Elevation & Depth
Depth is created through **Tonal Layering** and **Soft Ambient Shadows**. 

- **Surface Levels:** The base background is #F8F9FA. Primary cards and containers use pure #FFFFFF to "lift" off the page.
- **Shadows:** Use extremely diffused shadows. For a standard card: `0px 4px 20px rgba(0, 0, 0, 0.04)`. Avoid heavy blacks; shadows should feel like a subtle "glow" of depth.
- **Interactions:** Upon hover, elements should slightly increase their shadow spread and move -2px on the Y-axis to provide tactile feedback.

## Shapes
The shape language is **Refined & Friendly**. 

- **Standard Radius:** 8px (0.5rem) is the default for buttons, input fields, and small cards.
- **Large Radius:** 16px (1rem) is used for main content containers and modals to create a modern, app-like feel.
- **Full Radius:** Pills are used exclusively for "Status Tags" or "Chips" to distinguish them from actionable buttons.

## Components
### Buttons
- **Primary:** Solid #1B4332 with White text. High-contrast, rectangular with 8px radius.
- **Secondary:** Transparent background with a 1px border of #1B4332.
- **Ghost:** No border, #0077B5 text for low-priority actions.

### Cards
Cards are the primary content vehicle. They must have a white background, 16px padding, and an 8px or 16px border radius. Use a subtle 1px border (#E9ECEF) instead of a shadow if multiple cards are placed in a tight grid.

### Navigation
- **Desktop:** Top-aligned, sticky navigation with a blurred background (backdrop-filter: blur(10px)).
- **Mobile:** A dedicated **Bottom Navigation Bar**. Icons should be "Line" style (2px stroke) when inactive and "Solid" fill when active.

### Inputs
Text fields use a light grey fill (#F1F3F5) that transitions to a White background with a 2px #0077B5 border on focus. Labels always sit above the field in `label-md` style.

### Chips/Badges
Small, pill-shaped elements used for categories. For "Cultural" categories, use a light tint of the Secondary Gold with dark gold text.