
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| site-header-001 | render-header, render-brand | `{ brand: <div>Logo</div>, links: [{ href: '/', label: 'Home' }], bar: 'nav' }` | Header element renders with brand div visible |
| site-header-002 | render-bar-nav, bar-nav-visible-at-breakpoint | `{ barLinks: [{ href: '/', label: 'Home' }], links: [{ href: '/', label: 'Home' }], bar: 'nav' }`, viewport at the breakpoint or wider | Nav element with aria-label="Site" is present and visible, with links rendered as anchors |
| site-header-002b | render-bar-nav, bar-nav-visible-at-breakpoint | Same props as site-header-002, viewport narrower than the breakpoint | Nav element is present in the DOM (queryable) but not visible (`display: none`) |
| site-header-003 | render-action | `{ links: [{ href: '/', label: 'Home' }], action: <button>Sign up</button>, bar: 'nav' }`, viewport at the breakpoint or wider | Action div renders with button visible |
| site-header-004 | hide-bar-nav, drawer-visibility, support-bar-prop | `{ links: [{ href: '/', label: 'Home' }], bar: 'drawer' }` at all widths | Inline nav element does not render; the burger and drawer wrapper are visible at every width |
| site-header-005 | real-anchors | `{ links: [{ href: '/about', label: 'About' }], barLinks: [{ href: '/about', label: 'About' }] }` | Each link renders as `<a href="/about">About</a>` |
| site-header-006 | omit-brand-from-drawer | `{ brand: <div>Logo</div>, links: [{ href: '/', label: 'Home' }], bar: 'nav' }`, viewport narrower than the breakpoint (drawer visible) | NavChrome receives no brand prop; the wordmark appears once on the page |
| site-header-007 | reset-drawer-state | Viewport resizes from narrower than the breakpoint to at-or-wider than it, with the drawer open | NavChrome remounts, drawer state resets |
| site-header-008 | pass-full-links | `{ barLinks: [short links], links: [all links] }`, viewport at the breakpoint or wider | NavChrome receives full `links` array; drawer shows all links |
| site-header-009b | support-bar-prop | `{ links: [{ href: '/', label: 'Home' }], bar: 'nav' }` (default), viewport at the breakpoint or wider | Inline nav shown |
| site-header-010 | drawer-visibility | `{ links: [{ href: '/', label: 'Home' }], bar: 'nav' }`, viewport narrower than the breakpoint | Drawer wrapper is present and visible (not `display: none`) |
| site-header-011 | drawer-visibility | `{ links: [{ href: '/', label: 'Home' }], bar: 'nav' }`, viewport at the breakpoint or wider | Drawer wrapper remains in the DOM but is hidden via CSS (`display: none`) |
| site-header-012 | edge case: no brand | `{ links: [{ href: '/', label: 'Home' }] }` with no `brand` | No `.lp-site-brand` element is rendered |
| site-header-013 | edge case: no action, action-visible-at-breakpoint | `{ links: [{ href: '/', label: 'Home' }] }` with no `action`, viewport at the breakpoint or wider | No `.lp-site-action` element is rendered |
| site-header-014 | action-visible-at-breakpoint | `{ links: [{ href: '/', label: 'Home' }], action: <button>Sign up</button>, bar: 'nav' }`, viewport narrower than the breakpoint | `.lp-site-action` is present in the DOM but not visible (`display: none`) |
| site-header-015 | edge case: barLinks defaults to links | `{ links: [{ href: '/a', label: 'A' }, { href: '/b', label: 'B' }], bar: 'nav' }` with no `barLinks`, viewport at the breakpoint or wider | The bar's `<nav>` contains anchors for `/a` and `/b` |
| site-header-016 | render-bar-nav | `{ links: [{ href: '/', label: 'Home' }], navLabel: 'Primary', bar: 'nav' }` | The bar's `<nav>` has `aria-label="Primary"` |
| site-header-017 | pass-through-props | `{ links: [{ href: '/', label: 'Home' }], footer: <p>Contact</p>, navLabel: 'Primary' }` | NavChrome receives `footer` and `navLabel` unchanged; the drawer's `<nav>` is labelled "Primary" and shows the footer |
| site-header-018 | brand-centered-below-breakpoint | `{ brand: <div>Logo</div>, links: [{ href: '/', label: 'Home' }], bar: 'nav' }`, viewport narrower than the breakpoint | The wordmark is horizontally centered in the bar |
