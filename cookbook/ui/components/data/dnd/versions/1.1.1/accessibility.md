
- **Role**: DragGrip renders as a span but receives `role="button"` and `tabIndex=0` from dnd-kit's attributes (when keyboard sensor is enabled), making it keyboard-focusable and operable.
- **Label**: DragGrip MUST have an accessible name via aria-label ("Reorder" or "Reorder {subject}" when subject is provided).
- **Announcements**: Live region announcements MUST announce when an item is picked up, when it is dragged over a target or over no target, when it is dropped, and when dragging is cancelled.
- **Keyboard navigation**: Space or Enter starts the drag. Arrow keys move the dragged item to adjacent items (respecting orientation and axis constraints). Enter confirms the drop. Escape cancels the drag.
- **Icon**: GripVertical icon MUST have `aria-hidden="true"` because the accessible affordance is the label and role, not the icon.
- **Minimum touch target**: DragGrip measures 24px tall × 16px wide (`h-6 w-4`), which falls short of the 44×44pt (iOS) / 48×48dp (Android) minimum touch target. Hosts that need touch compliance MUST enlarge the hit area — e.g., wrapping the grip in enough padding to reach at least 44×44 — rather than relying on the grip's own bounds.
- **No nested buttons**: DragGrip renders as span (not button) because dnd-kit may spread `role="button"` onto it, and a nested button inside a button is invalid. When the handle is inside another button (calendar chip, timeline bar), the `keyboard` prop MUST be false to prevent spreading attributes.

