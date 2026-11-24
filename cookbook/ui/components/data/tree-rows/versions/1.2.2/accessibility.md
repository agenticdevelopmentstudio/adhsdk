
- **Role**: The toggle button is a native `<button>` with `type="button"`.
- **Aria-label**: Required. The button announces "Expand {label}" or "Collapse {label}" to screen readers.
- **Aria-expanded**: Required. The button sets `aria-expanded` to true or false reflecting the current state.
- **Title attribute**: Required. Provides tooltip text matching the aria-label for keyboard users and hover.
- **Label requirement**: Caller MUST pass a descriptive `label` prop (e.g., row title or data) so the toggle can announce which item is being toggled.
- **Leaf indication**: Leaves render a spacer instead of a disabled toggle, matching the toggle's footprint visually. The spacer is `aria-hidden="true"`, so screen reader users are not told about an empty, non-interactive placeholder — the visual alignment it provides is a sighted-only concern, not something assistive technology needs to perceive.
- **Focus visibility**: The button MUST have visible focus indication (ring on focus-visible).
- **Keyboard interaction**: The toggle button is a native button and MUST be keyboard accessible (Enter/Space to activate).
- **No role on label span**: The outer `<span>` is a layout container only and carries no `role` or semantic meaning. A caller embedding it in an ARIA tree/treegrid (`role="treegrid"`, `aria-level`, `aria-posinset`, `aria-setsize`) owns those attributes on its own row element — see Design Decisions → Tree-level ARIA semantics belong to the host.
- **Aria-hidden on spacer**: The spacer span MUST have `aria-hidden="true"` to prevent screen readers from announcing empty placeholder content.

