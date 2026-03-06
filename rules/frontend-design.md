---
paths:
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/*.vue"
  - "**/*.css"
---

# Frontend Design Standards

## Design System Discipline

- Always use the project's design tokens from Tailwind config - never hardcode colors, spacing, or shadows
- Use 4px/8px spacing grid via Tailwind classes (`p-2`, `gap-4`, `space-y-6`)
- If the project has a `tailwind.config.js` with custom tokens, read it first and use those exact tokens
- One source of truth for design tokens - all components reference it, none override it

## Typography Hierarchy

- Establish clear scale: display > h1 > h2 > h3 > h4 > body > caption > overline
- Limit to 2-3 font weights per page (regular, medium, bold)
- Line height: 1.2 for headings, 1.5-1.6 for body text
- Never use font-size directly - use the Tailwind text scale (`text-sm`, `text-base`, `text-lg`)
- Truncate long text with `truncate` or `line-clamp-*`, never let text break layouts

## Visual Hierarchy

- **One focal point per section** - not everything can be equally prominent
- **Action hierarchy**: primary = filled/colored button, secondary = outline, tertiary = ghost/text-only
- **Progressive disclosure** over information dumps - show summary, expand on demand
- **Visual weight distribution**: use size, color, and spacing to guide the eye
- **Content grouping**: related items cluster tightly, distinct groups separated by larger gaps
- **Z-pattern / F-pattern** reading flow for content-heavy pages

## Component States (MANDATORY)

Every interactive component MUST handle these visual states:

| State | What to Show |
|-------|-------------|
| Default | Resting state with clear affordance |
| Hover | Subtle elevation, color shift, or scale (150ms ease) |
| Focus-visible | Visible ring/outline for keyboard users (never remove) |
| Active/Pressed | Slight depression or darker shade |
| Disabled | Reduced opacity (0.5), `cursor-not-allowed`, no hover effects |
| Loading | Skeleton shimmer OR spinner with disabled interaction |
| Error | Red border/text, error message below, shake animation optional |
| Empty | Illustrated empty state with call-to-action, never blank space |

## Layout Principles

- **CSS Grid** for 2D layouts (dashboards, card grids, complex forms)
- **Flexbox** for 1D layouts (navbars, button groups, inline elements)
- Max nesting: 3 levels of flex/grid containers - refactor if deeper
- **Mobile-first**: start with single column, add complexity at larger breakpoints
- Use `max-w-*` containers to prevent ultra-wide line lengths
- Consistent gutter: pick one gap value per layout type and stick to it

## Animation & Motion

- **Meaningful only** - animate state changes, page transitions, content reveals
- **No decorative animation** - no spinning logos, bouncing elements, or gratuitous parallax
- Ease curves: `ease-out` for entrances, `ease-in` for exits, `ease-in-out` for movement
- Duration scale:
  - 150ms: micro-interactions (hover, focus, toggle)
  - 300ms: state transitions (expand, collapse, tab switch)
  - 500ms: page-level (route transitions, modal open/close)
- Use `prefers-reduced-motion` media query to disable non-essential animation
- Stagger animations for lists (50-100ms delay between items)

## Color Usage

- **Semantic naming**: success (green), warning (amber), error (red), info (blue)
- **WCAG AA minimum**: 4.5:1 contrast for text, 3:1 for large text and UI elements
- **Palette limit**: max 1 primary + 1 accent + neutrals per page section
- **Dark mode**: use proper surface hierarchy (surface-1, surface-2, surface-3), not simple color inversion
- **State colors**: don't reuse brand colors for success/error - keep semantic colors distinct

## Spacing & Density

- **Consistent rhythm**: pick section gaps (e.g., `space-y-8` between sections, `space-y-4` within sections)
- **Dense**: data tables, admin panels, settings pages - tighter padding (`p-2`, `gap-2`)
- **Comfortable**: forms, cards, content pages - medium padding (`p-4`, `gap-4`)
- **Airy**: marketing, landing pages, hero sections - generous padding (`p-8`, `gap-8`)
- **Touch targets**: minimum 44x44px for mobile interactive elements

## Responsive Design

- Start mobile, enhance upward: `sm:` → `md:` → `lg:` → `xl:`
- **Breakpoint strategy**: content dictates breakpoints, not device names
- Stack horizontally-laid elements vertically on mobile
- Hide secondary information on small screens, show on larger
- Test: does it work at 320px? At 1920px? At 2560px?

## Anti-Patterns (NEVER DO)

- No inline `style={{}}` attributes - use Tailwind classes or CSS modules
- No hardcoded hex/rgb colors outside design tokens
- No `!important` - fix specificity instead
- No pixel values for spacing - use Tailwind spacing scale
- No semantic-less `<div>` soup - use `<section>`, `<article>`, `<nav>`, `<aside>`, `<header>`, `<footer>`
- No uniform card grids where every card looks identical - vary visual weight
- No generic "rounded corners + pastel gradient + centered text" AI aesthetic
- No walls of text without visual breaks, icons, or illustrations
- No form fields without labels (placeholder is NOT a label)
- No modals without close button AND escape key handling
- No infinite scroll without clear loading indicator and end state
