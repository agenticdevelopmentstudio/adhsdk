
- **Role**: Container is a navigation landmark via an explicit `role="navigation"` on a `<div>` (see **set-navigation-role**); the source does not use a native `<nav>` element.
- **Label**: Container includes `aria-label="Agentic family"` to identify the navigation purpose.
- **Link labels**: Each link receives `aria-label="{site.name}"` (see **set-link-label**) for screen reader announcement.
- **Current page indicator**: Links use `aria-current="page"` to mark the active page, per WCAG best practices (see **set-aria-current**).
- **Emoji handling**: Emoji spans have `aria-hidden="true"` to prevent redundant announcement (see **render-emoji-hidden**).
- **Indicator handling**: Current-page indicator span has `aria-hidden="true"` (visual only).
- **Tooltip role**: The site name span carries `role="tooltip"` (see **render-tooltip-role**), but the source does not associate it with the link via `aria-describedby`; assistive technology receives the site name only through the link's `aria-label`, not through the tooltip role itself.
- **Keyboard focus**: `:focus-visible` pauses the floating animation and applies a box-shadow ring (see **render-focus-indicator**), and reveals the tooltip on focus the same way it does on hover (see **show-tooltip-on-focus**), matching WCAG 2.1 SC 1.4.13 (Content on Hover or Focus).
- **Minimum tap target**: Orbs are 48×48px by default (`styles/orb-row.css`), which meets the 44×44px minimum; the `max-width: 640px` breakpoint shrinks orbs to 36×36px, which falls below it.

