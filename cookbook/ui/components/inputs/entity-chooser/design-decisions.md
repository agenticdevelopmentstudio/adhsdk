
- **Decision**: Compose `ListChooser`, don't fork it.
  **Rationale**: All list, filter, roving-keyboard, and add-new behavior is `ListChooser`'s; `EntityChooser` only layers selection semantics (single value vs. set + chips). One authoritative home for the list/keyboard logic; the chooser stays disposable.
  **Approved**: pending
- **Decision**: Multi mode is repeated single-accept, kept open across commits, not a bespoke multi-select.
  **Rationale**: Rather than re-writing `ListChooser` to toggle rows in a persistent selection list (a different keyboard model), multi mode reuses the single-accept engine and passes `keepOpenOnCommit` so the browser stays open after each accept — one open can add as many entries as needed (see **trigger-label-only-multi**, **add-to-set-multi**). The set lives in the parent, and selected options are hidden so the browser never re-offers them. Simpler, fully accessible, zero duplication of keyboard logic.
  **Approved**: pending
- **Decision**: Chips reuse the `RemovableChip` component.
  **Rationale**: So tag editing looks and reads the same everywhere the component is used.
  **Approved**: pending
- **Decision**: Pass `value=null` to the inner `ListChooser` in multi mode.
  **Rationale**: Keeps the trigger reading "Choose…" (an add affordance) rather than echoing a single committed value.
  **Approved**: pending
- **Decision**: Offer a `selectionPlacement="host"` option for layout flexibility.
  **Rationale**: When the chip set is rendered inline with the trigger, a wrapping multi-line group cannot keep a fixed column width. Handing the chips to the host lets the host draw them in a separate area (e.g., a different row or column) and keep the trigger's width stable and aligned with fields above/below.
  **Approved**: pending
- **Decision**: Provide no built-in async state.
  **Rationale**: `options` is a controlled in-memory prop; the caller owns fetching/loading/error — consistent with the sibling form controls.
  **Approved**: pending

