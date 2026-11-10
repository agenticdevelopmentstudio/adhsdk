
**Decision**: PopoverAnchor wraps both the trigger and the panel inside the same container, rather than wrapping only the trigger.
**Rationale**: Keeping both inside one DOM subtree means the pointer never leaves the anchor's boundary while moving from the trigger to the panel, so `onMouseLeave` does not fire along the way. Wrapping only the trigger would put the panel outside that boundary and reintroduce the close-delay gap the anchor exists to remove.
**Approved**: pending

**Decision**: The component defines no padding, background, or border of its own.
**Rationale**: It is purely a positioning and hover-boundary context; visual styling is left entirely to the `className` prop and external CSS, so it composes with whatever panel appearance is applied on top of it.
**Approved**: pending

**Decision**: The anchor's optional callback prop wires the native `mouseleave` event (`onMouseLeave`) rather than `pointerleave` (`onPointerLeave`).
**Rationale**: `useHoverPopoverGroup`'s `anchorProps` contract is typed and implemented as `{ onMouseLeave: () => void }` (`packages/web/packages/popover/src/useHoverPopoverGroup.ts`) and is spread directly onto `<PopoverAnchor>`. Matching that event keeps `PopoverAnchor` a drop-in target for the hook's props without an adapter layer.
**Approved**: pending

