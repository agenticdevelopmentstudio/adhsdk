
- **render-on-hover**: The tooltip MUST display when the user hovers over the trigger element.
- **render-on-focus**: The tooltip MUST display when the trigger element receives keyboard focus.
- **respect-provider-delay**: The tooltip MUST respect the `delay` property set on the `TooltipProvider`, which controls the number of milliseconds before the tooltip opens (this wrapper defaults it to 200ms).
- **not-clipped-by-ancestors**: The tooltip content MUST NOT be clipped by an ancestor's `overflow` or stacking-context constraints.
- **position-relative-to-trigger**: The tooltip MUST position relative to the trigger element using a Positioner component that supports `side` (top, bottom, left, right), `sideOffset`, and `align` (start, center, end) properties.
- **support-style-override**: The tooltip content MUST support consumer-supplied overrides or extensions to its default styling.
- **show-arrow**: The tooltip SHOULD display an optional pointer (arrow) by default; it MAY be disabled by setting the `arrow` prop to `false`.
- **render-children-in-content**: The tooltip content MUST render the provided `children` prop as the label text.
- **dismiss-on-escape**: The tooltip MUST dismiss when the user presses Escape while it is open (inherited from Base UI).
- **remain-open-on-content-hover**: The tooltip MUST remain open while the pointer is over the tooltip content itself, not only while it is over the trigger (inherited from Base UI).
- **dismiss-on-pointer-leave-or-blur**: The tooltip MUST dismiss when the pointer leaves both the trigger and the content, or when the trigger loses focus (inherited from Base UI).

