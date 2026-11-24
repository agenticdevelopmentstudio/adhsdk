
- **renders-with-empty-content**: If `children` is an empty string or falsy, the tooltip MUST still render and position normally, with no visible text content.
- **very-long-text-wraps**: Text longer than `max-w-xs` (320px) MUST wrap to multiple lines, and the tooltip MUST grow vertically to accommodate it.
- **single-open-tooltip**: If a user quickly moves the pointer between trigger elements within the same `TooltipProvider`, only one tooltip MUST be open at a time, and the delay timer MUST reset for the newly hovered trigger (inherited from Base UI).
- **auto-flip-near-viewport-edge**: If the configured `side` would place the tooltip outside the viewport (for example `side="bottom"` near the bottom edge), Base UI's Positioner MUST adjust the side automatically so the tooltip stays within the viewport.
- **arrow-rotates-per-side**: When `side="bottom"`, the arrow MUST rotate 225deg to point upward instead of 45deg; for `side="left"` or `side="right"`, the arrow's position MUST adjust accordingly.
- **disabled-trigger-not-observed**: The component does not observe the trigger element's `disabled` state. If the trigger becomes disabled while its tooltip is open, the tooltip does not close on its own — dismissal depends entirely on whether the trigger's own pointer-leave, blur, or Escape handling still fires, which this component does not control.

