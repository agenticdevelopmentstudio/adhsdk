
- **list-semantics**: The rows MUST sit in a list whose accessible name is `ariaLabel`, which the source documents as saying what is being ranked.
- **value-in-text**: The value MUST be available as text in the row because the bar is hidden from assistive technology.
- **row-button-name**: A selectable row's accessible name comes from its visible content: the name followed by the value text.
- **pressed-announced**: A selectable row MUST announce its toggle (pressed) state; the expand button MUST announce its expanded state.
- **keyboard-operation**: Row buttons and the expand button are native buttons, so Tab reaches each and Enter or Space activates it; rows are not focusable at all without `onSelect`.
- **focus-ring-visible**: A keyboard-focused button MUST show the focus ring described under **focus-ring**.
- **touch-target-size**: NEEDS REVIEW: Not implemented in source. No minimum target is set: a row button's height is its 11px text plus a 4px gap and a 6px bar, and the expand button has 10px text with no padding. Settling it needs the rendered pixel height at the production theme's line height and a decision on whether the platform minimum (44x44 CSS px per the Apple HIG, 24x24 CSS px per WCAG 2.2) applies to a dense data list.
- **contrast-ratio**: NEEDS REVIEW: Not implemented in source. Text and bar colors are theme tokens (`text-apt-text-muted`, `text-apt-text`, `text-apt-text-dim`, `--color-apt-cat-blue`) and the dimmed state lowers a row to 55% opacity; whether any theme meets 4.5:1 for 10px and 11px text, and 3:1 for the bar, needs measured token values per theme.

