
- A problem with no suggestions renders "No suggestion." instead of apply chips
  (e.g. a flagged proper noun harper can't correct).
- A `Remove`-kind suggestion has an empty replacement; the apply chip reads
  "Remove" and applying deletes the flagged span. harper's own `applySuggestion`
  performs the edit, so `Replace` / `Remove` / `InsertAfter` kinds are all handled
  correctly (not a naive `[start,end)` splice).
- A lint superseded by a newer source change or by turning the check off is
  ignored by the control (**drop-stale-lint**). The default harper linter keeps
  the issues of whichever `lint()` call resolved last for `apply`, so an
  out-of-order resolution could still leave `apply` indexing the older results.
- Suggestions are capped at the first four per problem to keep the panel light.
- Fenced code, inline code, and markdown punctuation are not prose, so harper's
  markdown parser does not flag them.
- Dismissing the panel (Escape / outside-click) turns the check off; re-enabling
  re-lints the current source from scratch.
- The first lint after enabling runs immediately; later re-lints debounce, so a
  fast typist triggers one check, not one per keystroke.
- If harper cannot load or lint (e.g. a worker/WASM bundling failure in the host
  app), the panel degrades to the error state instead of throwing.

