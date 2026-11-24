
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| site-header-001 | render-header | `{ brand: <div>Logo</div>, links: [{ href: '/', label: 'Home' }], bar: 'nav' }` | Header element renders with brand div visible |
| site-header-002 | render-bar-nav, bar-nav-visible-at-breakpoint | `{ barLinks: [{ href: '/', label: 'Home' }], links: [{ href: '/', label: 'Home' }], bar: 'nav' }`, viewport at the breakpoint or wider | Nav element with aria-label="Site" is present and visible, with links rendered as anchors |
| site-header-002b | render-bar-nav, bar-nav-visible-at-breakpoint | Same props as site-header-002, viewport narrower than the breakpoint | Nav element is present in the DOM (queryable) but not visible (`display: none`) |
| site-header-003 | render-action | `{ links: [{ href: '/', label: 'Home' }], action: <button>Sign up</button>, bar: 'nav' }`, viewport at the breakpoint or wider | Action div renders with button visible |
| site-header-004 | hide-bar-nav, drawer-visibility | `{ links: [{ href: '/', label: 'Home' }], bar: 'drawer' }` at all widths | Inline nav element does not render; drawer renders at all widths |
| site-header-005 | real-anchors | `{ links: [{ href: '/about', label: 'About' }], barLinks: [{ href: '/about', label: 'About' }] }` | Each link renders as `<a href="/about">About</a>` |
| site-header-006 | omit-brand-from-drawer | `{ brand: <div>Logo</div>, links: [{ href: '/', label: 'Home' }] }` | NavChrome receives no brand prop |
| site-header-007 | reset-drawer-state | Viewport resizes from narrower than the breakpoint to at-or-wider than it, with the drawer open | NavChrome remounts, drawer state resets |
| site-header-008 | pass-full-links | `{ barLinks: [short links], links: [all links] }`, viewport at the breakpoint or wider | NavChrome receives full `links` array; drawer shows all links |
| site-header-009a | support-bar-prop | `{ links: [{ href: '/', label: 'Home' }], bar: 'drawer' }` | Burger shown at every width; inline nav hidden |
| site-header-009b | support-bar-prop | `{ links: [{ href: '/', label: 'Home' }], bar: 'nav' }` (default), viewport at the breakpoint or wider | Inline nav shown |
| site-header-010 | drawer-visibility | `{ links: [{ href: '/', label: 'Home' }], bar: 'nav' }`, viewport narrower than the breakpoint | Drawer wrapper is present and visible (not `display: none`) |
| site-header-011 | drawer-visibility | `{ links: [{ href: '/', label: 'Home' }], bar: 'nav' }`, viewport at the breakpoint or wider | Drawer wrapper remains in the DOM but is hidden via CSS (`display: none`) |

