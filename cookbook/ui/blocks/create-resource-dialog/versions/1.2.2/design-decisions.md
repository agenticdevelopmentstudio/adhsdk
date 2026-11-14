
**Decision**: Render the dialog through `createPortal` into `document.body`, not inline in the tree that opened it.
**Rationale**: Ancestors of the open button may set `overflow: hidden`/`overflow: auto` or own a stacking context that clips a `fixed`-positioned descendant; in this app's hierarchical pane stack, ancestors above the focused pane are also marked `inert` and `aria-hidden` in narrow mode, which would block keyboard and screen-reader interaction with the dialog if it stayed a descendant. Portaling to `document.body` escapes both constraints.
**Approved**: pending

**Decision**: Leave focus unmanaged — no focus moved into the dialog on open, no focus trap while it is open, and no focus restored to the invoking control on close.
**Rationale**: The source implements none of this and records no rationale for the omission; it is documented here as an absent feature, not a decision. See the Focus management entry in Accessibility for what the source does and does not handle. Escape, Cancel, and × still give keyboard users an unambiguous way to close the dialog, so the omission does not leave it unreachable by keyboard.
**Approved**: pending

**Decision**: Compare draft to pristine state with `JSON.stringify` rather than a structural-equality library or a manual dirty flag.
**Rationale**: This is simple and handles nested objects and arrays out of the box. The trade-off is serialization cost on every state change, plus the false-dirty/false-clean cases recorded under Edge Cases (key order, `undefined`/function-valued fields, `Map`/`Set` contents). A future optimization could switch to a structural comparison library or a custom dirty-flag pattern.
**Approved**: pending

**Decision**: Run the unsaved-changes guard only on close (Cancel, ×, Escape), never on Save.
**Rationale**: A validation failure on Save should let the user correct the field and retry without an extra confirmation step; routing only the close paths through `UnsavedChangesAlert` avoids that churn while still protecting against losing a dirty draft.
**Approved**: pending

**Decision**: Run `validate` synchronously and completely before starting the async `create` call; leave any server-side check (uniqueness, availability) to `create` itself.
**Rationale**: Synchronous validation gives immediate feedback for client-side problems (empty fields, format violations) without a network round trip. `saveEnabled` is itself synchronous — `(draft) => boolean`, called on every render — but a host can still surface the result of an async pre-check (e.g. a debounced identifier-availability probe) through it: the host runs the check, stores the boolean result in its own state, and `saveEnabled` reads that state; the host's re-render is what feeds the async result in, not `saveEnabled` awaiting anything itself.
**Approved**: pending

**Decision**: Make `onSaveError` optional, and keep inline error display independent of it.
**Rationale**: The callback exists for telemetry/logging; the error is shown inline regardless of whether a host supplies it, so implementations that don't need telemetry can omit it with no loss of user-facing behavior.
**Approved**: pending

**Decision**: Keep `renderForm` a pure composition seam — it receives only `draft`, `onChange`, and `error`, and owns everything about how fields (and, per the Appearance and Accessibility entries above, the error message itself) are rendered.
**Rationale**: This keeps the dialog free of any specific form library or field structure, so it works for any domain form the host wants to compose into it.
**Approved**: pending

