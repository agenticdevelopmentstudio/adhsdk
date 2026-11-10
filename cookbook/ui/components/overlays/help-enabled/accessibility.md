
- **Role**: The interactive variant (with help entry) acts as a button that opens a popover. The component does not explicitly set role; it relies on Popover and PopoverTrigger to establish the correct semantics.
- **Label**: The trigger element contains the children text as its accessible label.
- **Screen reader announcement of the trigger**: HelpEnabled does not itself set `aria-haspopup`/`aria-expanded` or an accessible description beyond the children text; it delegates that to `PopoverTrigger` (Base UI's `Popover.Trigger`), which applies `aria-haspopup` and `aria-expanded` automatically to the element it renders. The accessible name remains only the children text — no additional description such as "Show help" is added.
- **Badge accessibility**: The Info icon badge is marked `aria-hidden="true"` as it is a visual affordance that duplicates the interactive nature of the parent element.
- **Focus**: The trigger element is focusable via keyboard (Tab key) and displays a visible focus indicator (gold ring).
- **Popover context**: The help content is announced by the popover's own accessibility attributes (out of scope for this component).
- **Plain text variant**: When rendered as plain text (no help entry, no fallback), the element is not interactive and does not receive focus.

