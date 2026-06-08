---
name: Heritage Modern
colors:
  surface: '#fff8f4'
  surface-dim: '#e4d8ce'
  surface-bright: '#fff8f4'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#fef1e7'
  surface-container: '#f8ece1'
  surface-container-high: '#f2e6dc'
  surface-container-highest: '#ece0d6'
  on-surface: '#201b14'
  on-surface-variant: '#554339'
  inverse-surface: '#362f28'
  inverse-on-surface: '#fbefe4'
  outline: '#887368'
  outline-variant: '#dbc1b5'
  surface-tint: '#99460a'
  primary: '#964407'
  on-primary: '#ffffff'
  primary-container: '#b65c21'
  on-primary-container: '#fffbff'
  inverse-primary: '#ffb68e'
  secondary: '#645d57'
  on-secondary: '#ffffff'
  secondary-container: '#e9ded6'
  on-secondary-container: '#69615b'
  tertiary: '#944242'
  on-tertiary: '#ffffff'
  tertiary-container: '#b35a59'
  on-tertiary-container: '#fffbff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdbca'
  primary-fixed-dim: '#ffb68e'
  on-primary-fixed: '#331200'
  on-primary-fixed-variant: '#773300'
  secondary-fixed: '#ebe0d9'
  secondary-fixed-dim: '#cfc5bd'
  on-secondary-fixed: '#201b16'
  on-secondary-fixed-variant: '#4c4640'
  tertiary-fixed: '#ffdad8'
  tertiary-fixed-dim: '#ffb3b0'
  on-tertiary-fixed: '#3f0308'
  on-tertiary-fixed-variant: '#792e2f'
  background: '#fff8f4'
  on-background: '#201b14'
  surface-variant: '#ece0d6'
typography:
  headline-lg:
    fontFamily: Eb Garamond
    fontSize: 40px
    fontWeight: '500'
    lineHeight: '1.2'
  headline-md:
    fontFamily: Eb Garamond
    fontSize: 32px
    fontWeight: '500'
    lineHeight: '1.2'
  body-lg:
    fontFamily: Manrope
    fontSize: 18px
    fontWeight: '400'
    lineHeight: '1.6'
  body-md:
    fontFamily: Manrope
    fontSize: 16px
    fontWeight: '400'
    lineHeight: '1.6'
  label-md:
    fontFamily: Manrope
    fontSize: 14px
    fontWeight: '600'
    lineHeight: '1.4'
    letterSpacing: 0.02em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  xs: 4px
  sm: 12px
  md: 24px
  lg: 48px
  gutter: 24px
  margin: 32px
---

# Design System Document

## Brand & Style
The brand identity has shifted from a bright, high-energy aesthetic to a "Heritage Modern" feel. It evokes a sense of established reliability, warmth, and craftsmanship. The personality is sophisticated and grounded, targeting an audience that values quality and timeless design over fleeting trends.

The design style is a blend of **Minimalism** and **Corporate Modern**, with a touch of editorial influence. It uses generous whitespace and a refined color palette to create a focused, high-end experience that feels both professional and approachable.

## Colors
The palette is built on earthy, muted tones that suggest organic materials and stability.

- **Primary (#c2652a):** A warm, terracotta-inspired ochre used for key actions and brand presence.
- **Secondary (#78706a):** A stony warm-grey that provides a neutral, sophisticated balance.
- **Tertiary (#8c3c3c):** A deep, muted clay-red used for accents and highlighting important secondary information.
- **Neutral (#605850):** A dark umber used for text and structural elements to maintain softness compared to pure black.

The system operates in a light color mode, utilizing off-white and very light grey surfaces to maintain the warm, organic feel.

## Typography
The typography strategy pairings a classic serif with a modern geometric sans-serif to create an editorial contrast.

- **Headlines:** EB Garamond provides a sense of history and elegance. Use for large display text and section headings.
- **Body & Labels:** Manrope offers excellent readability and a clean, contemporary structure. Its geometric nature balances the classical feel of the serif headlines.

On mobile devices, headline sizes should scale down accordingly to ensure readability and prevent excessive line wrapping.

## Layout & Spacing
The system utilizes a fluid grid with a consistent 8px rhythmic base. 

- **Desktop:** 12-column grid with 24px gutters and 48px side margins.
- **Tablet:** 8-column grid with 24px gutters and 32px side margins.
- **Mobile:** 4-column grid with 16px gutters and 16px side margins.

Layouts should prioritize vertical rhythm and clear grouping of information, using ample whitespace to separate major sections.

## Elevation & Depth
Depth is expressed through **Tonal Layers** and very subtle **Ambient Shadows**. 

Instead of heavy dropshadows, the system uses slight shifts in surface color (using the neutral palette) to distinguish containers. Where elevation is necessary for interactivity (like floating buttons or cards), shadows should be soft, diffused, and slightly tinted with the neutral-warm hue to avoid a "dirty" look.

## Shapes
The shape language is "Rounded," providing a friendly but structured feel. 

- **Standard Elements:** Buttons and input fields use a 0.5rem (8px) corner radius.
- **Large Containers:** Cards and modals use a 1rem (16px) corner radius.
- **Extra Large:** Specialized sections or hero elements use a 1.5rem (24px) corner radius.

This moderate rounding softens the professional tone, making the interface feel more accessible and human.

## Components
- **Buttons:** Primary buttons use the terracotta primary color with white text. Secondary buttons use a secondary-toned outline or a soft neutral fill.
- **Input Fields:** Use the 0.5rem roundedness with a subtle 1px border in a light neutral-grey. Focus states should use the primary color for the border.
- **Cards:** Defined by a 1rem radius and either a very thin neutral border or a light tonal background shift.
- **Chips:** Use the Manrope label font style with a secondary or tertiary background at low opacity for categorization.