
- **Role**: `role="separator"` per ARIA authoring practices for resizable panes.
- **Orientation**: `aria-orientation` matches the `orientation` prop (`horizontal` or `vertical`).
- **Value**: `aria-valuenow` (current ratio as percentage, 0–100), `aria-valuemin` (minimum ratio as percentage), `aria-valuemax` (maximum ratio as percentage), all rounded to the nearest integer.
- **Label**: `aria-label` provided for the separator (default "Resize split", overridable). Step buttons each have an `aria-label` (defaults: "Grow top pane" and "Grow bottom pane" for horizontal, "Grow left pane" and "Grow right pane" for vertical).
- **Keyboard navigation**: Component is focusable (`tabIndex={0}`) and supports keyboard resize: arrow keys (up/down for horizontal, left/right for vertical) adjust by `step`, Home sets to `minRatio`, End sets to `maxRatio`.
- **Dragging alternative**: WCAG 2.2 SC 2.5.7 (Dragging Movements) — step buttons provide a single-pointer, non-drag resize alternative for users who cannot perform sustained drags.
- **Target size**: The 24px grab area (including both the visual line and step buttons) meets WCAG 2.2 SC 2.5.8 (Target Size, Minimum) of at least 24×24px. No target bleeds into adjacent panes.
- **Hidden elements**: `aria-hidden="true"` is applied to the visual line and step button icons, as they are decorative and their roles are expressed via ARIA properties and labels.
- **Focus visible**: Focus ring is only shown on keyboard focus (`:focus-visible`), not on pointer focus, to avoid visual clutter during drag.

