
- **Toolbar role**: The strip inherits `ButtonBar`'s toolbar semantics via `ariaLabel`
  (required prop).
- **Search field**: Input is `type="search"` with an accessible name via `aria-label`
  (defaults to `"Filter"`, overridable via `search.label`).
- **Icon**: The Search icon is `aria-hidden="true"` (decorative, not focusable).
- **Keyboard navigation**: Users can tab to the filter field and type. `Escape`
  follows the browser's native `type="search"` behavior: in browsers that
  implement it, pressing `Escape` while the field has focus and a non-empty
  value clears the field and fires `onChange` with `""`. `Enter` has no
  component-specific handling — the component attaches no `onKeyDown`, so the
  browser default applies (form submission if the header is inside a `<form>`,
  otherwise no-op).
- **Touch target**: see **touch-target-minimum**.

