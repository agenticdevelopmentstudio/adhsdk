
**Decision**: Compose `OptionMenu`'s primitives (`Popover`, `Input`, `Button`), don't fork it.
**Rationale**: The roving selection, `aria-activedescendant`, and Popover-with-trigger shape are shared with `OptionMenu`, but the single field that both filters and creates is a distinct interaction. Subclassing `OptionMenu` (fixed list + bottom "Other" row) would have entangled two models; composing the same primitives keeps each control single-responsibility.
**Approved**: pending

**Decision**: Filter on typed text; preview the highlight separately.
**Rationale**: Keeping the filter query separate from the previewed highlight label means arrow-navigation never re-filters the list out from under the user. Users can arrow through matches without the list collapsing, and typing again replaces the preview and re-filters.
**Approved**: pending

**Decision**: Selection and commit are distinct actions.
**Rationale**: Moving the highlight never fires `onChange`; only an accept (Enter, OK, or row click) commits. This allows users to explore the list without side effects, matching standard form control behavior.
**Approved**: pending

**Decision**: No built-in async state.
**Rationale**: `items` is a controlled in-memory prop, so loading/error belong to the caller — consistent with sibling form controls like `OptionMenu` and `RecipientInput`. This keeps the component presentational and predictable.
**Approved**: pending

**Decision**: Esc, Cancel, and — in keep-open mode — Shift+Enter are the three ways to dismiss; plain Enter never dismisses in keep-open mode.
**Rationale**: In multi-select ("collect a set") mode, plain Enter adds another entry without closing, so a separate keyboard signal for "I'm done" is needed alongside Esc and Cancel. Shift+Enter fills that role, completing the keyboard accessibility matrix without adding a new modal state. Outside keep-open mode, every accept already closes the popover, so Shift+Enter there is indistinguishable from plain Enter — it still accepts and closes.
**Approved**: pending

**Decision**: Exact-match text resolution.
**Rationale**: If the trimmed, lowercased user input exactly matches an item's label, it resolves to that item with `isNew:false`, not a new free-text entry. This prevents accidental duplication when a user types an existing item's full name.
**Approved**: pending

