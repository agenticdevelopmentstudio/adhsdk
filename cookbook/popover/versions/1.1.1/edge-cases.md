
- **Content larger than max-width** (full-featured): If popover content exceeds 288px width, text MUST wrap rather than overflow the panel's width; no max-height or overflow-scroll behavior for content that also exceeds the panel's height is defined in the source.
- **Placement adjustment** (full-featured): If the requested `side` would render the popover outside the viewport, the positioning library (base-ui) MAY auto-adjust placement or alignment to keep the popover visible.
- **Empty children** (full-featured, lightweight): If no children are provided, the popover MUST render as an empty panel; no fallback content is added.
- **Rapid visibility toggles** (lightweight): If `open` toggles rapidly, the panel MUST remain stable without layout thrashing, since it stays mounted throughout (see **hide-on-close-visibility**).
- **Arrow orientation per placement** (full-featured): When `arrow={true}`, the arrow MUST be rotated per the active `side`: 45deg for top, 225deg for bottom, 315deg for left, 135deg for right.
- **Tab-out closes without returning focus** (full-featured): Tabbing forward past the last focusable element inside the panel closes the popover via Base UI's `focus-out` dismissal; unlike Escape or an outside press on a non-focusable area, this path does not return focus to the trigger — focus instead lands on the next tabbable element after the trigger, continuing the forward Tab (see **return-focus-on-close**, popover-022).

