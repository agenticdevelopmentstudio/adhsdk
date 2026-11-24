
**Decision**: SortableDrop reports `afterId` and `beforeId` rather than an index.
**Rationale**: This solves the concurrent reorder problem where two users simultaneously reorder the same collection — each reports a position relative to two neighbors, which remains valid even if items are inserted elsewhere. An index-based report would be ambiguous when the list changes mid-operation.
**Approved**: pending

**Decision**: Pointer drags require 5 pixels of movement before activating.
**Rationale**: This allows clicks and taps on draggable items to reach their own event handlers (e.g., a card's select or edit button) without immediately starting a drag.
**Approved**: pending

**Decision**: Droppables are re-measured on every drag move (MeasuringStrategy.Always), not just at drag start.
**Rationale**: This accommodates zones that grow, shrink, or scroll during the operation.
**Approved**: pending

**Decision**: If a drag ends with the item landing in its original position (same zone and neighbors), onDrop is not invoked.
**Rationale**: This avoids spurious writes to the backend for a user who simply jiggles an item.
**Approved**: pending

**Decision**: SortableItem and DragItem conditionally spread dnd-kit's `role="button"` and `tabIndex` onto the handle; when keyboard={false}, only listeners are spread.
**Rationale**: This prevents nested `role="button"` violations when the handle is inside another button (e.g., calendar chip, timeline bar).
**Approved**: pending

**Decision**: If renderOverlay is omitted, no DragOverlay is rendered.
**Rationale**: This allows lightweight drag feedback (e.g., just an opacity change on the original item) for simple scenarios.
**Approved**: pending

**Decision**: DragSurface MAY be constrained to the x or y axis; SortableSurface does not support axis constraint.
**Rationale**: An axis constraint reflects the semantic meaning of a free drag (e.g., a timeline bar moves horizontally to change date; vertical movement is noise). Reordering already moves along the layout axis, so SortableSurface has no separate axis to constrain.
**Approved**: pending

**Decision**: The Tailwind class `touch-none` is applied to DragGrip.
**Rationale**: Without it, a touch drag on the grip would be consumed by the browser's scroll handler, and the pointer sensor would never see a move event.
**Approved**: pending

