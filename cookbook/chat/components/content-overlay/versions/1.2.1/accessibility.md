
- **Role**: The close button is a native HTML `<button>` element, providing automatic semantic button role.
- **Label**: The close button is labeled by its text content: `closeLabel` prop or default `'← back'`. When `closeLabel` is an empty string, the button has no accessible name (see **Edge Cases**).
- **Keyboard support**: Native button element supports keyboard activation (Enter, Space keys) from the platform. The `pointer-events: none` used when closed blocks pointer/click hit-testing but not keyboard focus or keyboard-triggered activation, so the close button (and any focusable content in the body) remains tab-reachable and screen-reader-visible while the overlay is closed — see the non-modal Design Decision.

