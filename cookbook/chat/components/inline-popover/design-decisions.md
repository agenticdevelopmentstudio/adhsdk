
**Decision**: The component accepts a `defaultOpen` prop to seed its internal `useState`, and is uncontrolled only — there is no `open` or `onOpenChange` prop, so a caller cannot drive the open state from outside once mounted.
**Rationale**: `defaultOpen` lets the caller pick the initial state; the default is `true`, so the content is visible until the user collapses it.
**Approved**: pending

**Decision**: The disclosure content is marked `aria-hidden` on the root element when closed, rather than relying on CSS `display: none` alone.
**Rationale**: This communicates the hidden state to assistive technology directly. (Applying it to the root instead of only `.pc-popover-body` also hides the toggle button when closed — see **Accessibility**.)
**Approved**: pending

**Decision**: Links always open in a new tab, with `target="_blank"` and `rel="noopener noreferrer"`.
**Rationale**: This prevents navigation away from the containing page and prevents the opened page from accessing the `window.opener` property. Callers who need different link behavior (same-tab navigation, new window) should handle link clicks at a higher level or wrap the component.
**Approved**: pending

**Decision**: Title, description, and links are only rendered if their data is truthy.
**Rationale**: This leaves no empty title, description or links element in the DOM when that content is not provided.
**Approved**: pending

**Decision**: The component uses CSS classes (`pc-popover`, `pc-popover-open`, etc.) rather than inline styles.
**Rationale**: This allows complete separation of presentation logic and gives callers full control over appearance.
**Approved**: pending

**Decision**: The toggle is built from a custom `button` + `div` pair with `pc-popover-*` classes rather than the native `<details>`/`<summary>` elements.
**Rationale**: A hand-built toggle lets the arrow indicator and title be composed freely inside the button's label while keeping the existing `pc-popover-*` CSS class contract; `<details>`/`<summary>` would need different default styling and event handling to match it. The accepted costs are the documented failures: the root `aria-hidden` hides the toggle button itself when closed, there is no `aria-expanded` on the button, and the fixed `aria-label` replaces the visible title as the accessible name.
**Approved**: pending

