
The header toggle is a real `<button>` carrying `aria-expanded` that reflects the
open state (**expose-expanded-state**), with a visible `focus-visible` ring. As a
native `<button>`, the toggle is reachable via Tab and activatable via Enter or
Space without extra wiring (**toggle-on-header-click**). The `actions` slot sits
outside the toggle button, so its controls are independently reachable and do not
trigger the toggle.

