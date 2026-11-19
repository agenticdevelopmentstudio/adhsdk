
- **Decision**: Identify each row by the panel's original index in the
  full, unfiltered array, rather than by its position in the currently
  filtered list.
  **Rationale**: Per the source's own doc comment, "the position is the
  row's identity, so a filtered row still selects the panel it names" — a
  stable id under filtering is what lets index-based selection, visibility
  querying, and the hosting split view's arrow-key stepping keep working
  correctly while a search query is active.
  **Approved**: pending
- **Decision**: Group panels into sections by contiguous run of matching
  section value, rather than by collecting every panel that shares a
  section title regardless of position.
  **Rationale**: Per the source's own comment, "Sections come out in the
  order the panels arrive, and a run of panels sharing one section title
  is one section. Grouping by title across the whole list instead hoisted
  every unsectioned panel to the top of the sidebar, silently reordering a
  list whose author had already put it in the order they meant."
  **Approved**: pending
- **Decision**: Filter the sidebar in place (hiding non-matching rows)
  instead of replacing it with a separate search-results list.
  **Rationale**: Per the source's own doc comment, "Filtering the sidebar
  (rather than replacing it with a results list) is what keeps a search
  reversible: the row the user is reading stays where it was in the list,
  and deleting the query puts its neighbours back around it."
  **Approved**: pending
- **Decision**: Expose a visibility query as a separate operation rather
  than having index-based selection silently clear the search query
  whenever the target row is currently filtered out.
  **Rationale**: Per the source's own doc comment, "clearing the search on
  the caller's behalf when it was not needed throws away a filter the user
  is still reading by" — the caller (the settings split view) is expected
  to check visibility first and decide for itself whether to clear the
  query.
  **Approved**: pending
- **Decision**: Selecting a panel by index never invokes the selection
  callback.
  **Rationale**: Programmatic selection flows through the hosting split
  view's own selection method, which is the caller in source that drives
  index-based selection, so the callback exists only to report a
  user-driven row pick, not to echo back a selection the caller itself
  just made.
  **Approved**: pending
- **Decision**: Declare the component `open`, letting a host app subclass
  it to customize row presentation or add secondary actions, rather than
  sealing it or exposing customization through composition only. (AppKit.)
  **Rationale**: Per the source's own doc comment, "Open so client apps can
  customize row presentation or add secondary actions."
  **Approved**: pending
- **Decision**: Observe only the title and the subtitle of each listed
  panel's descriptor; leave its icon, disabled flag, section, and heading
  unobserved, so a change to one of those waits for the next rebuild.
  **Rationale**: The source documents no reason for observing only these
  two fields — its comment says only that the rows rebuild when a listed
  panel's title or subtitle changes. Recorded so the choice is explicit
  and can be confirmed or widened.
  **Approved**: pending
- **Decision**: An out-of-range index (index-based selection, visibility
  querying) and a row id that is not an integer or is out of range
  (row-id resolution) fail silently: no log line and no debug assertion.
  **Rationale**: Each operation guards and returns without logging, and
  the ancestor's select-by-id documents a no-op for an id it does not
  hold; the hosting split view also relies on a filtered-out row being a
  quiet no-op (it asks for visibility first). Whether a debug assertion or
  log line is wanted is not settled in source.
  **Approved**: pending
- **Decision**: The selection-callback bridge is wired only on the normal
  construction path; an instance decoded from an archive gets no bridge,
  so its selection callback never fires.
  **Rationale**: Open issue, not intended behavior: the archive-decoding
  initializer calls only its superclass and performs no further setup.
  Either wire the bridge on that path too or document that the component
  must not be decoded from an archive.
  **Approved**: pending
