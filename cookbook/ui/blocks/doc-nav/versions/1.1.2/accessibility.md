
- **Navigation landmark**: Component renders a `<nav>` element (both desktop aside and mobile drawer use semantic nav)
- **Aria-current**: Selected links MUST carry `aria-current="page"` to announce to assistive technology
- **Section collapse button**: Collapse control MUST have `aria-expanded={true|false}` and an accessible label (`aria-label="Expand/Collapse [section name]"`)
- **Scrim not announced**: Scrim overlay carries `aria-hidden="true"` and is not focusable, ensuring screen readers do not announce it as a control
- **Drawer dismiss button**: Close button MUST have `aria-label` (e.g., "Close navigation")
- **Heading links nested under leaf**: Heading links appear in a nested list and inherit semantic structure from the leaf's `<li>` parent
- **Color not sole indicator**: Selected state uses both bold weight AND accent bar, not color alone
- **Contrast**: All text must meet WCAG AA contrast requirements against their backgrounds
- **Minimum touch target**: Section collapse button MUST be at least 44×44px (achieved via padding); links have 0.125rem vertical padding, totaling roughly 24-28px height, relying on spacing rather than individual link height for target size — below the 44px minimum on its own (see Compliance)

