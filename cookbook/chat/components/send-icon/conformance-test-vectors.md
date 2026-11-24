
| ID | Requirements | Input | Expected |
|-----|-------------|-------|----------|
| send-icon-001 | render-svg-arrow | Render component with no props | SVG renders with `<line>` and `<polygon>` elements visible |
| send-icon-002 | use-current-color | Render the component | The `<svg>` has `stroke="currentColor"`, so the computed stroke follows the parent's `color` (in a browser test, `color: red` on the parent yields a red computed `stroke`) |
| send-icon-003 | maintain-aspect-ratio | Render inside a container sized differently than 20×20 (e.g., 40×40) | Icon stays fixed at 20×20 pixels; it does not resize to fill the container, because `width`/`height` are hardcoded on the `<svg>` |
| send-icon-004 | remain-static | Inspect the rendered `<svg>` | No `on*` event-handler attributes are present, no `tabindex` attribute is set, and `pointer-events` is not overridden |
| send-icon-005 | render-svg-arrow, maintain-aspect-ratio | Inspect the rendered `<svg>`'s `viewBox` attribute | `viewBox="0 0 24 24"` — a 24-unit coordinate space rendered into a 20×20 box (`width="20" height="20"`), so the arrow is drawn slightly smaller than its own coordinate grid rather than at 1:1 scale. |
| send-icon-006 | decorative-hidden | Inspect the rendered `<svg>` | `aria-hidden="true"` and `focusable="false"` are present, and no `role` attribute is set |
