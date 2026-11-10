
- **Null/empty input**: The view model is a non-optional, typed constructor
  parameter; the type system rules out a missing value. The wrapped field's
  own revert-on-empty-text behavior — an empty text-field value fails the
  parse the same as any other unparseable text — is documented at
  edge-cases ([adhsdk.ingredient.ui.settings.rows.number-field-view](cookbook:acd561ca-90a4-4303-a411-cfe23410b42a)).
- **Boundary values**: Clamping at the minimum/maximum, and skipping the
  clamp when the minimum exceeds the maximum, is entirely the wrapped
  view's behavior; see
  edge-cases ([adhsdk.ingredient.ui.settings.rows.number-field-view](cookbook:acd561ca-90a4-4303-a411-cfe23410b42a)).
  This component only supplies those bounds, via the view model's own
  minimum/maximum values (**wraps-number-field-view**).
- **Out-of-range magnitude and fractional/locale-formatted text**: Parsing
  — POSIX-first with a locale-aware fallback, magnitude-exactness rejection,
  and fractional rejection — is entirely the wrapped view's behavior; see
  edge-cases ([adhsdk.ingredient.ui.settings.rows.number-field-view](cookbook:acd561ca-90a4-4303-a411-cfe23410b42a)).
- **Concurrent access**: Not applicable — this component MUST be usable
  only on the UI thread (**confines-to-ui-thread**), so all construction
  and mutation is serialized to that thread. The wrapped view carries the
  same confinement independently; see
  edge-cases ([adhsdk.ingredient.ui.settings.rows.number-field-view](cookbook:acd561ca-90a4-4303-a411-cfe23410b42a)).
- **Error states**: Not applicable — every operation in source
  (construction, forwarding, and end-of-editing handling) is synchronous
  and non-throwing; no error-producing path appears in this file.
- **Offline/disconnected state**: Not applicable — the component performs
  no networking; it only forwards to the wrapped view, which itself only
  reads from and writes to an in-process view model.
- **Overwritten external observer**: This is entirely the wrapped view's
  behavior — its initializer, not this component's, unconditionally
  assigns the view model's external-change handler; see
  edge-cases ([adhsdk.ingredient.ui.settings.rows.number-field-view](cookbook:acd561ca-90a4-4303-a411-cfe23410b42a)).
- **Delegate reassignment**: Because the text field's editing delegate is
  set to the wrapped view, not this component, a caller that reassigns the
  editing delegate to something else silently disables commit-on-editing-
  end; this component's own end-of-editing handler only fires if a caller
  explicitly re-points the editing delegate back at the outer component
  (see Design Decisions).

