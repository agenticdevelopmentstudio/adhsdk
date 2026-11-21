
### Note

- **note-identity**: A note MUST be uniquely identifiable and comparable
  for equality, MUST be safe to pass across concurrent contexts, and its
  id MUST be immutable once created.
- **note-fields**: A note MUST carry exactly `content` (text),
  `createdDate` (immutable), `modifiedDate`, `isPinned`, and `version` as
  its stored state; it MUST have no stored `title` field.
- **note-version**: A note's `version` MUST be the storage's concurrency
  token for that note — a 64-bit integer defaulting to 0 — which a write
  quotes to be accepted. A storage with no concurrency token MUST leave it
  at 0 and ignore it; a storage backed by the markdown store's local row
  version MUST return that value.
- **note-markdown-tier**: The note value and its document mapping MUST
  live in the markdown tier with no UI-framework dependency, so a daemon
  or a command-line tool can build and map notes without linking the
  desktop UI framework; the desktop feature tier MUST re-export the
  markdown tier so its existing callers keep compiling unchanged.
- **note-title-derivation**: A note's title MUST be computed on every
  access from its content via the shared markdown title-derivation
  utility, never stored, so it can never go stale against content
  between an edit and the next save.
- **note-excerpt-derivation**: A note's excerpt MUST be computed via the
  shared markdown excerpt-derivation utility, applied to the note's
  content together with its frontmatter, which MUST skip the line the
  title was derived from so a heading used as the title is never repeated
  as the first line of the excerpt underneath it.
- **note-untitled-sentinel**: A note's untitled-title sentinel MUST be the
  same sentinel value the markdown utilities themselves define for
  "untitled," not a second string with the same text, so a comparison
  against it can never disagree with the markdown layer's own sentinel.
- **note-default-sort**: A note's default sort order MUST place pinned
  notes before unpinned notes, and within each group order by
  `modifiedDate` descending.
- **note-factory**: Creating a new note from content MUST produce a note
  with a fresh unique id, `createdDate` and `modifiedDate` both set to the
  current time, and `isPinned` false.

### NoteFolder

- **notefolder-value-semantics**: A note folder MUST be uniquely
  identifiable, comparable for equality, and hashable by value — not by
  object identity — and MUST be safe to pass across concurrent contexts.
  Value-based hashing here is deliberate, not an accidental default: a UI
  element that tracks expansion or selection state by matching folder
  values across reloads needs two equal folders produced by two separate
  reads to hash equally, which a reference/object-identity-based hash
  would not guarantee (see Platform Notes).
- **notefolder-all-notes-sentinel**: An id of the empty string MUST be
  reserved for the synthetic "All Notes" root; the folder-tree-building
  operation MUST never itself produce a node with an empty id, since
  every real category id is a lowercased unique identifier minted at
  category-creation time.
- **notefolder-tree-multi-parent**: The folder-tree-building operation
  MUST build a category reachable from more than one parent once per
  parent, so it appears as an independent value under each parent rather
  than a shared reference.
- **notefolder-tree-direct-counts**: Each built folder's note count MUST
  be the category's own direct count from the supplied counts, never a
  sum over its children; a parent's count MAY therefore be smaller than
  the sum of its children's counts.
- **notefolder-tree-total-independent**: The caller MUST supply the "All
  Notes" total count separately (e.g. from the store's own note-count
  query) rather than deriving it by summing the per-category counts,
  because a note filed under two categories would double-count that sum
  and an uncategorized note would be missed by it entirely.
- **notefolder-tree-cycle-safety**: The folder-tree-building operation
  MUST bound every downward walk with a set of the ids already on the
  current path, so a cycle in the edge data truncates that branch instead
  of recursing forever; when every category lies on a cycle with no true
  root, it MUST fall back to treating every category as a root rather
  than losing the graph entirely.
- **notefolder-tree-orphan-edges**: The folder-tree-building operation
  MUST ignore any edge whose parent or child id is not present in the
  supplied category list.

### NoteStorage & NoteTaxonomyProviding

- **notestorage-contract**: The storage contract MUST declare exactly
  five asynchronous operations that can fail — fetch all notes, fetch one
  note by id (answering nothing when it no longer exists), insert a note,
  update a note, and delete a note by id — and MUST itself be safe to call
  from multiple threads, since the manager calls these operations off the
  primary thread; the thread safety of the concrete storage is the
  conformer's own responsibility, stated as a precondition, not enforced
  by the contract itself. A synchronous throwing implementation MUST
  still satisfy each operation.
- **notestorage-fetch-one-fallback**: The contract MUST supply a default
  single-note fetch built on fetching all notes and picking the one with
  the matching id, so a storage with no cheaper single-note read conforms
  without writing one.
- **notestorage-stale-error**: Updating a note MUST fail with a stale
  error when the storage holds a newer version than the note's `version`;
  the error MUST carry the stored note when the storage can say what it
  is, and nothing when the caller must re-read it. A storage with no
  concurrency token MUST never raise it.
- **notestorage-writes-return-version**: Inserting and updating a note
  MUST return the version the storage now holds for it, so the caller can
  quote that version on its next write; a storage with no concurrency
  token MUST still return the version it reports on read.
- **notestorage-change-stream**: A storage MAY additionally be observable:
  it then MUST expose a stream of changes made by any writer, each one
  naming an upserted note id, a deleted note id, a resync (the storage
  lost track of what changed and the reader must re-read everything), or
  a taxonomy change (another writer changed the categories or which notes
  are in them, and no note changed).
- **notetaxonomyproviding-contract**: A storage implementation MAY
  additionally support a taxonomy-provider extension, which exposes a
  note taxonomy — the markdown tier's synchronous category interface —
  for folder queries and edits, never the concrete document store
  behind it, so a storage that keeps its categories elsewhere (a daemon
  over HTTP, answering from a local copy) can supply folders too. The
  markdown-backed conformer MUST supply its markdown document store as
  that taxonomy. The base storage contract itself MUST NOT reference
  categories, so a storage backend with no taxonomy concept can implement
  the base contract alone and simply not support folders.

### MarkdownNoteStorage

- **markdownnotestorage-safe-for-concurrent-use**: The markdown-backed
  conformer MUST be safe to use concurrently; its only stored state is a
  reference to the markdown document store (itself declared safe to
  share across threads, by a manually-verified guarantee) and a fixed
  constant, so this safety property holds as written with no additional
  synchronization.
- **markdownnotestorage-note-mapping**: The markdown-backed conformer
  MUST represent a note as a markdown document carrying the `.note`
  marker, and fetching all notes MUST skip any document whose id does not
  parse as a valid unique identifier rather than crashing on it — a
  document with a non-unique-identifier id is server-authored and outside
  this model's addressing scheme.
- **markdownnotestorage-fetch-sort**: Fetching all notes MUST return its
  notes sorted by the note's default sort order (pinned-first, then
  `modifiedDate` descending).
- **markdownnotestorage-timestamps**: Inserting a note MUST stamp the
  underlying document's current-time and created-time parameters
  separately, from the note's `modifiedDate` and `createdDate`
  respectively, so a note's original creation date is preserved
  distinctly from its last-modified date rather than both collapsing
  onto one write timestamp.
- **notemapping-shared**: The rules turning a markdown document into a
  note and a note back into document content (pin ownership, stripping
  owned keys, claim and release) MUST live in one shared mapping in the
  markdown tier, used by the markdown-backed conformer and by every other
  notes storage, so there is only one answer to "is this note pinned?".
  Mapping a document to a note MUST carry the document's local version
  into the note's `version`.
- **markdownnotestorage-version-ignored**: The markdown-backed conformer
  MUST ignore a note's `version` on every write and MUST never fail with
  the stale error, yet MUST return the document's new local version from
  every insert and update.
- **markdownnotestorage-fetch-one**: Fetching one note by id MUST read
  that one document and its ownership record, and MUST answer nothing when
  no live document with the note marker has that id, so a doc or paper
  sharing the id space is never handed back as a note (fetching all notes
  lists by the same marker).
- **markdownnotestorage-frontmatter-ownership**: The markdown-backed
  conformer MUST record, per document, which frontmatter keys it itself
  wrote, and MUST use that recorded fact — never the key's value — to
  decide whether a `pinned` key found in a document's frontmatter
  reflects this app's own pin state or a foreign key a user or another
  tool wrote.
- **markdownnotestorage-pin-claim-rule**: The markdown-backed conformer
  MAY claim (write and own) the `pinned` key only when it is currently
  absent from the document's frontmatter, or when writing the desired
  value would change no bytes of the document's content; it MUST NOT
  claim or rewrite a `pinned` key that already holds a different, foreign
  value or a differently-quoted/differently-styled equivalent value.
- **markdownnotestorage-pin-release-rule**: Whenever updating a note
  finds the note's content differs from what this layer last derived for
  it (the stored content with owned keys stripped), it MUST treat the
  entire frontmatter as released — the user edited the text — clearing
  the ownership record for that document before deciding whether to
  write `pinned` again in the same call.
- **markdownnotestorage-title-never-written**: The markdown-backed
  conformer MUST NOT write a `title` frontmatter key under any
  circumstance; a note's title is always derived from its content, and a
  hand-typed `title:` fence MUST be left untouched, exactly like any
  other foreign frontmatter key.
- **markdownnotestorage-strip-on-read**: The markdown-backed conformer
  MUST strip only the frontmatter keys it owns from the text it exposes
  as a note's content; every other line — including a foreign `pinned:`
  key — MUST remain visible, in its original order, in that content.
- **markdownnotestorage-update-atomicity**: Updating a note MUST perform
  its read, merge, and write as a single transaction, not as separate
  read-then-write calls, so a concurrent writer's in-transaction append to
  the same document (e.g. to an unrelated field) survives an update call
  on that document; this buys atomicity, not ordering — two concurrent
  updates on the same note still resolve last-writer-wins over the whole
  note.
- **markdownnotestorage-update-missing-throws**: Updating a note MUST
  fail when the note's id does not correspond to an existing document.
- **markdownnotestorage-delete**: Deleting a note by id MUST remove the
  corresponding document from the store by delegating to the store's own
  document-delete operation.

### NotesManager

- **notesmanager-confined-to-primary-thread**: The manager MUST be
  confined to the primary UI thread; its published state (the notes list,
  the load-completion flag, the storage failure) MUST be read and
  mutated only there.
- **notesmanager-change-notification**: The manager MUST post a change
  notification (with the manager itself as the subject and no payload)
  after every operation that changes the notes list — a load, a create, a
  content update, a pin toggle, a delete, an applied change from another
  writer, or a conflicted copy — so an observer re-reads the
  notes list from the posting manager rather than from a stale payload
  snapshot that could already be out of date by the time it is read.
- **notesmanager-note-replaced-notification**: The manager MUST post a
  note-replaced notification, with the manager as subject and the note's id
  under the note-id key, whenever it replaces a held note's text with
  another writer's — an applied upsert over a held note, a stale save that
  keeps the other writer's note, or a reload that brings a held note's
  changed text — so an editor showing that note re-shows it instead of
  keeping text that is no longer the note's. The notes window MUST re-show
  the open note on it when the editor's text differs from the note's, and
  leave the editor alone for any other note.
- **notesmanager-taxonomy-notification**: The manager MUST post a
  taxonomy-change notification (same shape: the manager as subject, no
  payload) when its storage's change stream reports a taxonomy change,
  and again after the notes reload a resync triggers, since a resync may
  have carried a category edit. A taxonomy change MUST NOT touch the
  notes list or post the notes change notification. This window's own
  category edits do not come through it; an observer that shows folders
  rebuilds them on it, which is how another writer's folders appear.
- **notesmanager-failure-surface**: The manager MUST record a failed
  storage operation as a single failure record carrying the operation and
  the error's description, log it as an error, and post a storage-failure
  notification; a new failure MUST overwrite rather than queue behind a
  previous one, since a failing store fails every subsequent operation
  identically. The manager's failure-reporting entry point MUST apply
  this same recording for a failure the manager did not itself trigger —
  a caller that wrote to the manager's wrapped document store directly.
- **notesmanager-clear-failure**: Clearing the storage failure MUST set it
  to unset; it is the only way the storage failure is cleared, so
  whichever host shows the failure is responsible for calling it.
- **notesmanager-load-failure-keeps-loaded-true**: When fetching all notes
  fails, loading notes MUST still mark the manager as loaded and MUST
  leave the notes list as it was (empty, on first launch) rather than
  leaving the manager perpetually unloaded.
- **notesmanager-create-rollback**: When inserting a note fails, creating
  a note from content MUST record the failure, return nothing, and MUST
  NOT append the note to the notes list — a note that was never durably
  persisted MUST NOT remain visible in the list.
- **notesmanager-content-update-debounced**: Updating a note's content
  MUST update the in-memory note, re-sort the notes list, and post the
  change notification synchronously, then MUST schedule the actual
  storage write through a per-note debounced save (a 1-second debounce,
  keyed by note id) rather than writing to storage immediately.
- **notesmanager-debounce-reread**: A scheduled debounced save MUST
  re-look-up the note by id inside the scheduled work rather than
  capturing a snapshot at schedule time, so a save that runs late, or is
  retried after a failure, persists the note as it stands when the save
  actually executes, not as it stood when the keystroke landed.
- **notesmanager-debounce-retry**: A debounced save whose write fails
  MUST remain pending and be retried with backoff, rather than being
  dropped after a single log line.
- **notesmanager-pin-toggle-immediate**: Toggling a note's pin state MUST
  update the in-memory note, then write it through storage immediately on
  a snapshot of the just-toggled note, bypassing the content-update
  debounce entirely; the note MUST count as having an unsaved edit until
  that write lands, so another writer's change is not applied over it.
- **notesmanager-delete-optimistic**: Deleting a note by id MUST remove
  the note from the notes list before attempting the storage delete, and
  MUST record — but MUST NOT use to reinstate the note — a failure of
  that storage delete.
- **notesmanager-storage-off-primary-thread**: Every storage operation
  the manager issues MUST run off the primary UI thread, through a
  detached unit of work, because the concrete storage's I/O (e.g. the
  markdown-backed conformer's local-database calls) would otherwise block
  every other host confined to that thread and sharing this manager (a
  second notes window, Quick Note) for the duration of the call.
- **notesmanager-storage-issue-order**: The manager MUST serialize its own
  storage calls into one ordered chain, so each next call awaits the
  previous one and they execute in the exact order they were issued,
  never overlapping and never reordered — because updating a note carries
  a whole note snapshot taken on the primary thread, and an out-of-order
  write (a stale content save landing after a newer pin toggle) would
  resurrect superseded content. This ordering covers only calls issued by
  this one manager instance; a second, independent writer against the
  same storage contract is outside its scope.
- **notesmanager-live-changes**: When its storage is observable, the
  manager MUST subscribe to the storage's change stream at construction
  and cancel the subscription when it is released, applying each change
  on the primary thread: a resync reloads every note and then posts the
  taxonomy-change notification; a taxonomy change only posts that
  notification; a deletion of a held note removes it — unless the note has an unsaved
  edit, in which case the editor's text is first stored as a conflicted
  copy and the note is removed only once the copy is stored (a failed copy
  records the failure and keeps the note); an upsert fetches that note and replaces the held
  copy only when the fetched version is higher than the version ledger
  holds for it (a version at or below it is the manager's own echo),
  appends it when not held, and removes the held copy when the fetch
  answers nothing.
- **notesmanager-version-ledger**: The manager MUST keep, per note, the
  last version storage confirmed — filled by a load, advanced by every
  insert and update's returned version and by every change it adopts, and
  cleared when the note is forgotten — and MUST read and advance it inside
  its ordered storage chain, so each queued write quotes the version the
  write before it produced and two consecutive saves of its own are never
  stale against each other. The in-memory note's `version` MUST follow the
  ledger once a save lands.
- **notesmanager-reload-keeps-unsaved-edits**: A load or resync MUST NOT
  overwrite or forget a note with an unsaved edit: it keeps that note's
  in-memory text, the base content and pin it last matched storage with,
  and its ledger version (also for a note that turns dirty while the read
  is in flight), and it MUST NOT clear the record of unsaved edits, so the
  pending save is judged against the version it started from — it lands
  when nobody else wrote, goes stale and keeps both texts when another
  writer did, and becomes a conflicted copy when the note was deleted.
- **notesmanager-live-changes-skip-dirty**: An upsert for a note with an
  edit not yet saved MUST NOT be applied over the editor — checked both
  before the fetch and again after it returns — so that note's next save
  takes the stale-resolution path instead.
- **notesmanager-stale-resolution**: When a save fails with the stale
  error, the manager MUST obtain the stored note (from the error, or by
  fetching it), then: if the stored content still equals the content the
  note last had when it matched storage, it MUST re-save the editor's
  current note on top of the stored version, taking the stored pin when
  this editor did not change the pin since its base (so another writer's
  pin or unpin survives) and the editor's pin when it did; otherwise it MUST keep the
  other writer's note in the list and, when the editor's text differs
  from that base, put the editor's latest text — including anything typed
  after the failed save was scheduled, and anything typed while the copy is
  being written — into a new note, stored before the held note is replaced
  with the other writer's, so a failed copy leaves the edit in the editor.
  The copy is the editor's text with " (conflicted copy)" added wherever
  the title comes from: a frontmatter `title` or `name` is marked in place,
  a leading heading is marked in place, and otherwise a
  `# <title> (conflicted copy)` heading is inserted after any frontmatter
  block, so the frontmatter survives and the heading is never doubled. When only
  the pin differs from the base, no copy is made: the pin state MUST be
  re-applied on top of the other writer's note. If the note no longer
  exists in storage, the edit MUST likewise become a conflicted-copy note
  rather than vanish, stored once before the note is forgotten, and not at
  all when the note was already forgotten.
- **notesmanager-taxonomy-accessor**: The manager's taxonomy accessor
  MUST return the storage's note taxonomy only when the storage
  implementation also supports the taxonomy-provider extension, and MUST
  return nothing otherwise, so a host whose storage supplies no taxonomy
  (e.g. a test double) can treat the folders feature as simply
  unavailable. It MUST be typed as the taxonomy interface, never as the
  markdown document store, so a consumer that shows or edits folders
  depends only on the interface and a daemon-backed storage drives it
  unchanged.
- **notesmanager-flush-before-termination**: Flushing pending saves MUST
  synchronously drain every pending debounced save and MUST return the
  ids of any note whose flushed write still failed, so a caller invoked
  before app termination can act on what did not reach disk.
- **notesmanager-logging**: The manager MUST log every storage failure as
  an error, including the operation's name and the error's description,
  and MUST log a successful load as informational, including the count of
  notes loaded.

