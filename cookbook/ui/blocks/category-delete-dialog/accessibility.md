
- **role**: The component MUST render as a dialog with `role="dialog"` and `aria-modal="true"` (inherited unchanged from the `Dialog` primitive via `AlertModal`).
- **description**: The component MUST provide an accessible description containing the main explanation text and, when present, the orphaned warning and the error text. The description MUST be associated via `DialogDescription`.
- **button-labels**: Action buttons MUST have explicit labels: "Delete" for the destructive action and "Cancel" for the dismissal action.
- **focus-management**: Focus MUST be managed by the `AlertModal`/`Dialog` primitives — trapped within the dialog and returned to the trigger element on dismissal.
- **semantic-structure**: The description MUST be composed of block-level `<span>` elements rather than `<p>` elements, so the full text remains part of the accessible description exposed via `DialogDescription` instead of being re-parented outside it by the browser's `<p>`-in-`<p>` handling (see Design Decisions).

