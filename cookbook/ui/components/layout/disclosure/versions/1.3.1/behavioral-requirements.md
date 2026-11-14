
- **toggle-on-header-click**: Clicking the header toggle MUST flip the visibility of the children.
- **support-uncontrolled**: With `defaultOpen` and no `open` prop, the component MUST manage its own open state.
- **support-controlled**: When `open` is provided, the component MUST reflect that prop and report intent via `onOpenChange`, without mutating internal state.
- **rotate-chevron**: The leading chevron MUST rotate 90° when open and return when closed.
- **actions-exempt-from-toggle**: Interacting with the header `actions` slot MUST NOT toggle the disclosure.
- **mount-children-only-when-open**: Children MUST be mounted only when open (and unmounted when closed), not merely visually hidden.
- **expose-expanded-state**: The toggle button MUST carry `aria-expanded` reflecting the current open state.

