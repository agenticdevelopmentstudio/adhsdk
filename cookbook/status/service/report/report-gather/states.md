
Not applicable — this is a data-gathering module, not a visual component. Its runtime states are per-source results: each source ends as `{ ok: true, data }` or `{ ok: false, error }`, and a dashboard may still be refreshing at its deadline, which the rules module records as a coverage note.

