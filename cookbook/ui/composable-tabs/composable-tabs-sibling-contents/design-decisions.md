
- **Decision**: Compute the sibling list from the live hierarchy on each call instead of caching it.
  **Rationale**: The doc comment states it "answers for whatever the layout is now": a pane added or closed since the last call is counted or not, so callers never act on a stale list.
  **Approved**: pending

- **Decision**: Return an empty array, not an error, when the view controller is not inside a pane, or the chain to the root split is broken.
  **Rationale**: The doc comment states the result is "empty when it is not inside a pane"; callers such as the terminal chat controllers use the result in `first(where:)` lookups, which an empty array answers with no match.
  **Approved**: pending

- **Decision**: Answer from the tab's root split, not from the enclosing split.
  **Rationale**: Panes nested in sub-splits are part of the same tab, so the walk goes up to the root split and uses its depth-first order, the order the user reads the panes in.
  **Approved**: pending

