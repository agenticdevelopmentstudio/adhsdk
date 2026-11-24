
- **content-overflow** (full-featured): If popover content exceeds 288px width, text MUST wrap rather than overflow the panel's width; no max-height or overflow-scroll behavior for content that also exceeds the panel's height is defined in the source.
- **placement-adjustment** (full-featured): If the requested `side` would render the popover outside the viewport, the positioning library (base-ui) MAY auto-adjust placement or alignment to keep the popover visible.
- **empty-children** (full-featured, lightweight): If no children are provided, the popover renders as an empty panel; no fallback content is added.
- **rapid-visibility-toggles** (lightweight): If `open` toggles rapidly, the panel stays mounted throughout and only the `hover-popover--open` class toggles; nothing mounts or unmounts (see **hide-on-close-visibility**, popover-036).
- **arrow-orientation-per-placement** (full-featured): See **arrow-orientation**.
- **tab-out-no-return-focus** (full-featured): Tabbing forward past the last focusable element inside the panel closes the popover via Base UI's `focus-out` dismissal; unlike Escape or an outside press on a non-focusable area, this path does not return focus to the trigger — focus instead lands on the next tabbable element after the trigger, continuing the forward Tab (see **return-focus-on-close**, popover-022).

