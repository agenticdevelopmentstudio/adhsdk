
- **group-name**: The frame MUST be a group named "Collapse or expand all lists".
- **button-name**: Each button's accessible name MUST be its explicit label ("Collapse all lists", "Expand all lists"), because the glyph is hidden and no text is visible.
- **disabled-announced**: A disabled button MUST be announced as disabled and MUST be skipped by the Tab order.
- **keyboard-operation**: Both buttons are native buttons, so Tab reaches an enabled one and Enter or Space activates it.
- **focus-ring-visible**: A keyboard-focused button MUST show the focus ring.
- **touch-target-size**: NEEDS REVIEW: Not implemented in source. Each half is a 14px chevron row with 4px by 2px padding, roughly 34px by 18px, below the 44x44 CSS px platform minimum; settling it needs the rendered size at the production theme and a decision on whether this dense toolbar control is held to that minimum (WCAG 2.2 floor is 24x24 CSS px).
- **contrast-ratio**: NEEDS REVIEW: Not implemented in source. Muted text on the page background, and the disabled state at 35% opacity, depend on theme tokens; whether either meets 3:1 for a non-text control needs measured token values per theme.

