
- **render-header**: Component MUST render a `<header>` element containing all provided content.
- **render-brand**: Component MUST render the `brand` prop as a child of a `.lp-site-brand` div if provided.
- **render-bar-nav**: Component MUST render navigation links from `barLinks` (or `links` if `barLinks` is not provided) in a `<nav>` element with `aria-label` defaulting to "Site" whenever `bar` is `'nav'`.
- **bar-nav-visible-at-breakpoint**: The `<nav>` element rendered under **render-bar-nav** MUST be visible at the breakpoint or wider and hidden below it via a CSS media query, while remaining present in the DOM at every width.
- **render-action**: Component MUST render the `action` prop in a `.lp-site-action` div if provided.
- **hide-bar-nav**: Component MUST NOT render the inline navigation bar when `bar` is `'drawer'` at any viewport width.
- **real-anchors**: Component MUST render navigation links as real `<a>` elements with `href` attributes, so they remain discoverable to crawlers and reachable through an assistive-technology link rotor even when **bar-nav-visible-at-breakpoint**'s media query hides them below the breakpoint.
- **drawer-visibility**: Component MUST always mount a `NavChrome` component in a drawer wrapper; the wrapper is hidden via CSS at the breakpoint or wider when `bar` is `'nav'`, and stays visible at every width when `bar` is `'drawer'`.
- **omit-brand-from-drawer**: Component MUST NOT pass the `brand` prop to `NavChrome` in the drawer.
- **reset-drawer-state**: Component MUST remount `NavChrome` when the drawer wrapper transitions from visible to hidden (the viewport growing from narrower than the breakpoint to at-or-wider than it), to reset `NavChrome`'s internal state.
- **pass-full-links**: Component MUST always pass the complete `links` array to `NavChrome`, regardless of which links are shown in the bar.
- **support-bar-prop**: Component MUST accept a `bar` prop that is either `'nav'` (default) or `'drawer'`.

