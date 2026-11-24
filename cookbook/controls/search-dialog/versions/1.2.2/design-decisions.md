
- **Top 20 results limit**
  **Decision**: Results are sliced to the first 20 entries (`state.results.slice(0, 20)`) before grouping.
  **Rationale**: Bounds DOM size for display performance while assuming the backing search state returns results in descending relevance order, keeping interaction smooth on large result sets (see **limit-results-to-twenty**). Implementors MUST ensure `state.results` is pre-sorted by relevance.
  **Approved**: pending

- **Reset on open, not on close**
  **Decision**: The search state is reset (`state.reset()`) when `open` transitions from `false` to `true`, not when it transitions from `true` to `false`.
  **Rationale**: `state` is a caller-owned object that persists for as long as the caller keeps it, independent of the dialog's own mount lifecycle. The reset effect depends only on `open` so that typing does not retrigger a reset on every keystroke — resetting on every state change would clobber the user's in-progress query, per the source comment. Resetting on open guarantees a clean slate each time the dialog reappears.
  **Approved**: pending

- **requestAnimationFrame for focus**
  **Decision**: Input focus is deferred to `requestAnimationFrame()` rather than called synchronously on open.
  **Rationale**: Deferring to the next animation frame ensures the input element has been painted to the DOM before focus is requested, since focusing an element before it has rendered can silently fail.
  **Approved**: pending

- **Form wrapper for autofill suppression**
  **Decision**: The input is wrapped in a `<form role="search">` element, not a `<div>`, with an `onSubmit` handler that calls `preventDefault()`.
  **Rationale**: Per the source comment, a field with no form ancestor is scoped for autofill against the whole document, so Safari classifies it from whatever else the page happens to say; giving the field a form of its own is what stopped iOS Safari's "AutoFill Contact" suggestion from appearing above the keyboard, measured on iOS 26 against a production chat input. `role="search"` preserves semantic intent, and `onSubmit` only blocks the navigation an implicit submit would trigger, since Enter is already handled by the input's `onKeyDown` (see **enter-selects-highlighted-result**, **prevent-form-submission**).
  **Approved**: pending

- **Slug as React key**
  **Decision**: Each result uses `entry.slug` as its list-reconciliation key (React's `key` prop) rather than the array index.
  **Rationale**: `entry.slug` is assumed to be a stable identifier per entry, so reconciliation stays correct if results reorder or the same entries reappear across renders (see **stable-result-identity**). This is a rendering-library detail, not a claim any other platform's list view is required to replicate.
  **Approved**: pending

- **Selected index highlighting via CSS class, not inline style**
  **Decision**: The selected result applies the `awt-search-dialog__result--selected` class modifier via a ternary; no inline styles are used for selection appearance.
  **Rationale**: Decouples visual design from component code and lets CSS drive appearance and theme variation (see **highlight-selected-result**).
  **Approved**: pending

