
**Decision**: SearchDialogConnected is a thin connected wrapper; all presentation — layout, list rendering, input handling — is delegated to a presentational SearchDialog component.
**Rationale**: Keeps SearchDialog reusable with different data sources (testing, alternative content), while SearchDialogConnected orchestrates the integration with the application's standard data layer.
**Approved**: pending

**Decision**: `sectionLabels` is computed with `useMemo` keyed on `nav.sections`, but the selection handler passed as `onSelect` is defined inline and is not wrapped in `useCallback`.
**Rationale**: `useMemo` avoids recomputing the label map when unrelated props cause the wrapper to re-render. The selection handler needs no referential stability because SearchDialog never uses it as an effect or memoization dependency — it is only invoked directly from a keyboard or click handler.
**Approved**: pending

**Decision**: Selection handling calls `navigate(entry.slug)` before calling `onClose()`.
**Rationale**: Ensures navigation state updates before the dialog disappears, avoiding a moment where the dialog closes but the route has not yet changed.
**Approved**: pending

