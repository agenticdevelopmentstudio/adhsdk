
This is the model, persistence-contract, and orchestration layer behind
the Notes feature:
a local, on-device notes store with no UI of its own. A note is an
immutable-id value whose title and excerpt are always derived from its
markdown content, never stored. A note folder is the tree shape a folders
pane displays, built from a flat category/edge read. The storage contract
is the abstract, five-operation asynchronous persistence seam the manager
depends on, required to be safe to call from multiple threads, with a
versioned stale-write error and an optional change stream for storages
that see other writers. The note and its document mapping live in the
markdown tier, so a daemon can share them; the mapping owns the entire
frontmatter-ownership contract for the one key a note writes, `pinned`,
and the markdown-backed conformer is the concrete implementation that
applies it to a markdown-store document. The manager is the object,
confined to the primary UI thread, that owns the in-memory list of notes,
issues every storage call off that thread in strict issue order, runs a
per-note debounced autosave, shows notes changed by another writer live,
turns a stale save into a "(conflicted copy)" note rather than losing
text, and surfaces a failed read or write as a single failure record.

This is a different, unrelated contract from the web-side notes client —
its notes are a backend content
resource reached over a REST API, these are a local, on-device store
reached through the storage contract described here, and the shared name
is a coincidence, not a shared contract.

