
- **Role**: The trigger is a native button element; the `<pre>` element holding the source has no special ARIA role (it exposes as a generic element, not a code role), so assistive technology reads its content as plain text.
- **Expanded state**: The button MUST announce expanded/collapsed state via `aria-expanded`.
- **Panel association**: The button MUST associate the panel via `aria-controls` (only when open, per source implementation).
- **Label**: The trigger text serves as the button's accessible label via its text content.
- **Keyboard navigation**: As a native button, the trigger is keyboard accessible; Enter or Space activates it. No custom keyboard handling is required.
- **Assistive technology**: Screen readers will announce "View source, button, expanded" (or "collapsed") and read the panel content when opened.

