
This module is the storage floor the sync stack and the app's other stores
sit on. It has two parts:

- The bounded database wraps an underlying multi-reader, single-writer
  database connection pool (or a single shared connection for a private
  in-memory database) with two guarantees so a runaway query can never
  wedge the process: a **bulkhead** (one writer plus N readers, using
  write-ahead logging, so reads never queue behind the writer) and
  **ejection** (every read/write carries a monotonic deadline; a low-level
  statement-abort mechanism aborts any statement that passes it, surfaced
  as a deadline-exceeded error). It keeps per-lane latency and eviction
  counters exposed as a metrics snapshot, and it is reentrant, so a code
  base can keep one read/write chokepoint instead of threading a raw
  connection handle everywhere.
- The storage-location helper derives where an app keeps its files — a
  dotfolder in the home directory — from the app's declared display name,
  reduced to characters a path can hold.

Consumers include the sync store (see
Offline Sync Client ([adhsdk.ingredient.data.sync.offline-sync-client](cookbook:d3a0b65f-92c0-43c1-b04c-77638eb72044))),
the markdown store (see Markdown Core ([adhsdk.ingredient.adh.hub.content.markdown-store](cookbook:11f7a665-60e9-42df-853c-fe4de3af0fd8))),
and the project database (see
Project Database ([adhsdk.ingredient.workspace.projects.project-database](cookbook:c212ea39-10e7-4146-89dd-36edb3b3455a))),
which names its file inside the storage-location helper's directory.

