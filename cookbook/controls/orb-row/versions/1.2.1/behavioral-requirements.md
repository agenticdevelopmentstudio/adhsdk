
- **render-orb-links**: The component MUST render each site as an `<a>` element with `href` pointing to the site's URL.
- **apply-current-state**: The component MUST apply the `is-current` class to the link whose `id` matches `currentSite`.
- **set-aria-current**: When a link is current, the component MUST set `aria-current="page"` on that link; other links MUST NOT have `aria-current` set.
- **render-emoji-hidden**: The component MUST render the emoji in a `<span>` with `aria-hidden="true"` so it is not exposed in the accessibility tree.
- **render-tooltip-role**: The component MUST render the site name in a `<span>` with `role="tooltip"`.
- **apply-gradient-background**: The component MUST apply each site's `iconGradient` value as the CSS `background` style property on the orb link.
- **render-indicator-when-current**: When a site is current, the component MUST render an indicator `<span>` with class `orb-row-here` and `aria-hidden="true"`.
- **set-navigation-role**: The component MUST render the container with `role="navigation"` and `aria-label="Agentic family"`.
- **set-docked-class**: When the `docked` prop is `true`, the component MUST apply the `is-docked` class to the root container.
- **apply-custom-class**: The component MUST append any `className` prop value to the root container's class list.
- **set-link-label**: The component MUST set `aria-label="{site.name}"` on each orb link so it has an accessible name distinct from its (hidden) visual content.
- **render-focus-indicator**: When an orb link receives keyboard focus, the component MUST present a visible focus indicator (a box-shadow ring applied via `:focus-visible`) and pause its floating animation.
- **show-tooltip-on-focus**: The component MUST reveal the tooltip span on keyboard focus (`:focus-visible`) as well as on pointer hover.

