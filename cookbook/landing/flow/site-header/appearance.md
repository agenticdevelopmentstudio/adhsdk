
- **Breakpoint**: 62rem — referred to below as *the breakpoint*.
- **Header layout**: Horizontal flexbox row containing brand, navigation, and action.
- **Bar height**: Determined by child component heights (brand, nav links, action).
- **Navigation alignment**: At or above the breakpoint with `bar='nav'`, the brand sits at the left end while the navigation links and the action bunch together at the right end — `flow.css` pushes the nav flush against the action with `margin-left: auto`, not to the bar's center. Below the breakpoint (where the inline nav and action are hidden) and at every width when `bar='drawer'`, the brand is centered in the bar instead.
- **Link styling**: The inline navigation links are `SiteHeader`'s own `<a>` elements (a sibling of the `NavChrome` wrapper, not rendered through it), so they cannot inherit `NavChrome`'s styling. `flow.css` gives them their own styling directly: `color: var(--lp-ink-dim, #a0a0a0)` at `0.88rem`, no underline, brightening to `var(--lp-ink, #ededed)` on hover with a `0.18s` color transition.
- **Drawer styling**: Inherits from NavChrome.
- **Scrolling**: Header scrolls away with page content (not fixed).
- **Responsive layout**: At the breakpoint, the inline navigation becomes visible via a CSS media query; below it, the `<nav>` stays in the DOM but is hidden by that same query (not removed) under `bar='nav'`.

