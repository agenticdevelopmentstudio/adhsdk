
**Decision**: The entire 24px grab row/column is the drag target, not just the thin 3px visual line.
**Rationale**: WCAG 2.2 SC 2.5.8 (Target Size, Minimum) requires a minimum 24×24px touch target; using the full 24px area keeps pointer and touch users within an accessible target while the visual line itself stays thin for minimal visual intrusion.
**Approved**: pending

**Decision**: Two step buttons provide a non-drag alternative for resizing.
**Rationale**: WCAG 2.2 SC 2.5.7 (Dragging Movements) requires a non-drag alternative for pointer users who cannot perform sustained drags; the step buttons allow incremental resize via single clicks/taps.
**Approved**: pending

**Decision**: Keyboard support covers arrow keys (± `step`) plus Home/End (jump to `minRatio`/`maxRatio`).
**Rationale**: Arrow keys allow incremental adjustment aligned with the separator's axis; Home and End give quick access to the bounds.
**Approved**: pending

**Decision**: Out-of-range ratios are silently clamped to `[minRatio, maxRatio]` rather than rejected with an error.
**Rationale**: Clamping prevents invalid states and simplifies the caller's logic; no validation error is emitted.
**Approved**: pending

**Decision**: Pointer capture (`setPointerCapture`) is used during a drag.
**Rationale**: This is standard practice for resizable elements — it keeps the drag tracked even if the pointer moves outside the separator, and ensures smooth dragging behavior.
**Approved**: pending

**Decision**: The component manages no "collapsed" state for either pane.
**Rationale**: Leaving collapse behavior to the caller gives maximum flexibility in how the split is used.
**Approved**: pending

**Decision**: The ratio is computed from the pointer offset divided by the container's full extent, not from an absolute pixel delta.
**Rationale**: This makes the ratio represent a fraction of space independent of the container's absolute size.
**Approved**: pending

**Decision**: The default `step` is `0.03` (3% per key press).
**Rationale**: This gives responsive keyboard navigation without requiring excessive key presses to traverse the full range; callers can override it for different responsiveness.
**Approved**: pending

**Decision**: The default bounds are `minRatio = 0.2` and `maxRatio = 0.8`.
**Rationale**: Each pane keeps at least 20% of the space by default, preventing either pane from becoming unusably small; callers can override the bounds.
**Approved**: pending

