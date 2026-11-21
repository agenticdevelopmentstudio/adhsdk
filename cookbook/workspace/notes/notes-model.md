---
id: d46b3e1c-9cd9-41b6-bdd2-524ece5e294b
title: "Notes Model"
type: ingredient
version: 2.0.0
status: review
language: en
created: 2026-09-24
modified: 2026-11-21
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The on-device model, storage contract, and orchestrator behind the Notes feature — a versioned note and its shared markdown mapping, a note folder, an async storage seam with stale errors and a change stream, a markdown-backed conformer, and the manager coordinating them, live changes and conflicted copies included."
platforms:
  - swift
  - macos
tags:
  - notes
  - markdown
  - persistence
  - frontmatter
  - debounce
  - concurrency
  - taxonomy
depends-on:
  - 9f938c20-ea6e-42d7-9ddf-9531a96e3ad0
related: []
references:
  - packages/apple/AgenticDeveloperHubSDK/Markdown/Note.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Markdown/MarkdownNoteMapping.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/NotesWindow/NoteFolder.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/NotesWindow/NoteStorage.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/NotesWindow/NoteTaxonomyProviding.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/NotesWindow/MarkdownNoteStorage.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/NotesWindow/NotesManager.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/NotesWindow/NotesMarkdownReExports.swift (adhsdk)
approved-by: ""
approved-date: ""
---

# Notes Model

## Overview

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

## Behavioral Requirements

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
  no document has that id.
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
  notification; a deletion of a held note removes it; an upsert fetches that note and replaces the held
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
- **notesmanager-live-changes-skip-dirty**: An upsert for a note with an
  edit not yet saved MUST NOT be applied over the editor — checked both
  before the fetch and again after it returns — so that note's next save
  takes the stale-resolution path instead.
- **notesmanager-stale-resolution**: When a save fails with the stale
  error, the manager MUST obtain the stored note (from the error, or by
  fetching it), then: if the stored content still equals the content the
  note last had when it matched storage, it MUST re-save the editor's
  current note on top of the stored version; otherwise it MUST keep the
  other writer's note in the list and, when the editor's text differs
  from that base, put the editor's latest text — including anything typed
  after the failed save was scheduled — into a new note whose content is
  `"# <title> (conflicted copy)\n\n"` followed by that text. When only
  the pin differs from the base, no copy is made: the pin state MUST be
  re-applied on top of the other writer's note. If the note no longer
  exists in storage, the edit MUST likewise become a conflicted-copy note
  rather than vanish.
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

## Appearance

Not applicable — this is a model, storage contract, and orchestrator with
no visual surface, not a visual component.

## States

Not applicable — this is a model, storage contract, and orchestrator with
no visual surface, not a visual component.

## Accessibility

Not applicable — this is a model, storage contract, and orchestrator with
no visual surface, not a visual component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| notes-model-001 | markdownnotestorage-note-mapping | Insert a note with content `"# Groceries\n\nMilk"`, then fetch all notes. | The returned note's id matches the inserted id, its title is `"Groceries"`, and its content is `"# Groceries\n\nMilk"`. |
| notes-model-002 | markdownnotestorage-title-never-written | Insert a note with content `"# Groceries\n\nMilk"`. | The stored document's frontmatter is empty; no title key is ever written. |
| notes-model-003 | markdownnotestorage-frontmatter-ownership, markdownnotestorage-pin-claim-rule | Insert an unpinned note, update it with pinned set to true, then again with pinned set to false. | Frontmatter is empty before the pin, holds a pinned fence while pinned, and is empty again after the unpin. |
| notes-model-004 | markdownnotestorage-update-atomicity | 30 concurrent tasks each update the same note (a no-op content revert), racing 30 concurrent tasks each appending an index marker to the same document's owner-id field through a separate in-transaction write. | Every one of the 30 owner-id marks survives in the final document. |
| notes-model-005 | markdownnotestorage-update-missing-throws | Update a note that was never inserted. | The call fails. |
| notes-model-006 | markdownnotestorage-note-mapping | Create a document directly with a non-unique-identifier id (a server-style id), then fetch all notes. | The returned list is empty — the non-unique-identifier document is skipped, not crashed on. |
| notes-model-007 | markdownnotestorage-pin-claim-rule | Create a document directly with a foreign, never-owned pinned key set to true alongside an unrelated layout key, then fetch all notes. | The note's pinned flag is false; its content still contains the foreign pinned line untouched. |
| notes-model-008 | markdownnotestorage-pin-release-rule | Pin a note, then in one update call set its content to a hand-typed pinned fence plus new body text, and set pinned to false in the same call. | The hand-typed pinned line survives byte-for-byte; the frontmatter-ownership record for that document is empty afterward. |
| notes-model-009 | note-title-derivation | Create a document directly with a numeric frontmatter title, then fetch all notes. | The note's title is the body heading — a numeric frontmatter title falls through to the body line. |
| notes-model-010 | notefolder-tree-cycle-safety | Build the folder tree from edges forming a 3-node cycle with no true root. | The returned roots list is not empty — the cycle degrades to treating all three categories as roots. |
| notes-model-011 | notesmanager-storage-issue-order | 24 create-note calls, then 24 concurrently-issued pin-toggle tasks against a storage double that dwells 50ms per call and records arrival order. | The storage double never observes more than one call in flight at a time, and the arrival order of the updates equals the exact order the 24 tasks were issued in. |
| notes-model-012 | notesmanager-failure-surface, notesmanager-create-rollback | Create a note from content against a storage double whose insert operation always fails. | Returns nothing; the manager's recorded failure names the create operation; the notes list stays empty. |
| notes-model-013 | notesmanager-taxonomy-accessor, notetaxonomyproviding-contract | Construct the manager with a markdown-backed storage implementation, versus a storage implementation that does not support the taxonomy-provider extension. | The taxonomy accessor returns the same document store instance (as the taxonomy interface) in the first case, nothing in the second. |
| notes-model-014 | notesmanager-live-changes | A manager over an observable storage double; another writer updates a held note to a higher version and the double emits an upsert for it. | The held note is replaced by the fetched one and a change notification is posted. |
| notes-model-015 | notesmanager-live-changes | The double emits an upsert for a note whose fetched version equals the held version. | The held note is left unchanged (its own echo). |
| notes-model-016 | notesmanager-live-changes-skip-dirty | Edit a note's content, then before the debounced save runs the double emits an upsert for that note with a newer version. | The edited content stays in the list; the change is not applied. |
| notes-model-017 | notesmanager-stale-resolution | Another writer changes a note's text; this manager then saves an edit to the same note and storage answers stale. | The other writer's note stays in the list and a new note titled `"<title> (conflicted copy)"` holds the edited text. |
| notes-model-018 | notesmanager-stale-resolution | Storage answers stale but its stored content equals what the editor started from (only the version moved). | The edit is re-saved on top of the stored version and no conflicted copy is created. |
| notes-model-019 | notemapping-shared, note-version | Map a markdown document with local version 7 and an owned `pinned: true` to a note. | The note's version is 7, it is pinned, and its content has the owned `pinned` line stripped. |
| notes-model-020 | notesmanager-version-ledger, notestorage-writes-return-version | Over a versioned storage double, save an edit to a note, then save a second edit to it. | Both saves land on the same note with no stale error and no conflicted copy, and the held note's version equals the stored version. |
| notes-model-021 | notesmanager-version-ledger | Create a note through the manager, then save an edit to it. | The edit lands on the created note with no conflicted copy. |
| notes-model-022 | notesmanager-live-changes, notesmanager-version-ledger | Save an edit, then the double emits an upsert for that note at the version the save returned. | The held note keeps the saved text and is not replaced. |
| notes-model-023 | notesmanager-stale-resolution | Another writer changes a note's text; this manager edits it twice before the debounced save runs and storage answers stale. | The conflicted copy holds the second edit's text. |
| notes-model-024 | notesmanager-stale-resolution, notesmanager-pin-toggle-immediate | Another writer changes a note's text; this manager then toggles the note's pin and storage answers stale. | No conflicted copy is created; the stored note keeps the other writer's text and is pinned, and so does the held note. |
| notes-model-025 | notesmanager-taxonomy-notification, notestorage-change-stream | A loaded manager over an observable storage double applies a taxonomy change. | The taxonomy-change notification is posted with the manager as subject; no notes change notification is posted and the notes list is unchanged. |
| notes-model-026 | notesmanager-taxonomy-notification, notesmanager-live-changes | A loaded manager over an observable storage double applies a resync. | The notes are reloaded and the taxonomy-change notification is posted. |

## Edge Cases

- An empty-content note (created from an empty string) derives the
  untitled-title sentinel, never an empty string title.
- Writing `pinned` when the document's frontmatter already reads
  byte-identical to the value about to be written claims the key without
  mutating a single byte of content.
- A quoted foreign value the app would otherwise rewrite as an unquoted
  boolean — `pinned: "true"` — is left completely alone and never
  claimed, because rewriting it would change bytes that belong to the
  user.
- A frontmatter `title` written as a flow sequence (`title: [a, b]`), an
  empty string (`title: ""`), or a whitespace-only string
  (`title: "   "`) all fall through to the derived body-line title,
  exactly as the shared markdown title-derivation utility does for every
  other document authored the same way.
- A foreign frontmatter key unrelated to `pinned` (e.g. `author: mike`)
  survives a read and an unrelated no-op re-save byte-for-byte.
- Building the folder tree with no edges at all treats every category as
  an unparented root.
- Deleting a note by an id with no corresponding document does not fail:
  the store's delete operation treats a missing id as success by design
  (the document store's delete operation is idempotent), so calling delete twice for the same
  note is safe.
- Toggling a pin while a debounced content save for the same note is
  still pending does not wait for it: toggling the pin writes through
  immediately against whatever content is already in memory, ahead of
  the debounced write.
- Updating a note's single-transaction read-merge-write buys atomicity
  against a concurrent writer, not ordering between two update calls on
  the same note — the markdown-backed conformer has no concurrency token,
  so the second one to commit always wins over the whole note. A storage
  with a token (a daemon-backed one) refuses the later write as stale
  instead, and the manager resolves it.
- A note deleted by another writer while this editor still has an unsaved
  edit is not lost: the stale save turns the edit into a
  "(conflicted copy)" note.
- A pin toggle that meets another writer's text change has no text of its
  own to keep, so it pins the other writer's note instead of making a
  conflicted copy.
- A resync from the change stream discards the manager's record of
  unsaved edits along with the list, because it reloads every note.
- A resync also posts the taxonomy-change notification, even when no
  category changed: the feed lost track of what changed, so the folders
  pane rebuilds its tree as well as the notes list.
- A taxonomy change posts only the taxonomy-change notification; it
  never reloads or refetches a note, so a note's folder membership
  changing elsewhere updates the folders pane without touching an
  unsaved edit.
- A storage that is not observable never posts the taxonomy-change
  notification, so the folders pane shows another writer's category edit
  only when one of this window's own folder edits or membership changes
  next rebuilds the tree.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `storage` | the storage contract (safe for concurrent use) | none — required init parameter | The manager takes no default; the concrete backend (e.g. the markdown-backed conformer) is supplied by the caller. |
| `store` | the markdown document store | none — required init parameter | The markdown-backed conformer takes no default; the caller constructs and owns the document store. |
| `saveDebounce` | duration | 1 second | A fixed internal constant, not externally configurable in the given sources. |
| `pinnedKey` | text | `"pinned"` | The sole frontmatter key the markdown-backed conformer ever writes, likewise a fixed internal constant. |

## Deep Linking

Not applicable: none of these sources exposes a URL scheme, route, or
path — the note model, note folder, storage contract, markdown-backed
conformer, and manager are an in-process persistence and orchestration
layer with no addressable location of their own.

## Localization

- **notes-storage-failure-titles**: A storage failure's operation titles
  are four hardcoded English literals — "Couldn't Load Notes", "Couldn't
  Create Note", "Couldn't Save Note", "Couldn't Delete Note" — with no
  localization mechanism wrapping any of them; a caller presenting the
  storage failure sees exactly this English text.
- **notes-storage-failure-consequences**: A storage failure's operation
  consequences likewise are four hardcoded English sentences describing
  what the failure means for what is on screen; the delete case
  interpolates a separately-localized product/location name into an
  otherwise unlocalized English sentence.
- **notes-storage-failure-message-passthrough**: A storage failure's
  message is the underlying error's own localized description, shown
  verbatim; whatever localization that error itself carries, or lacks,
  passes through this layer unchanged — the markdown-backed conformer and
  the manager neither translate nor re-wrap it.

## Accessibility Options

Not applicable: this layer renders nothing and animates nothing to adapt —
Reduce Motion, Increase Contrast, and Differentiate Without Color are
presentation concerns for a host view (out of scope here), not for the
note model, note folder, storage contract, markdown-backed conformer, or
manager.

## Feature Flags

Not applicable: none of these sources reads a feature-flag key, a
settings-store toggle, or a remote-config value to gate any behavior
described above.

## Analytics

Not applicable: none of these sources emits an analytics event; the
only instrumentation present is the diagnostic logging documented under
Logging below.

## Privacy

- **Data collected**: A note's markdown content (arbitrary user-authored
  text, including any frontmatter the user hand-types into it) plus
  per-note metadata: a unique id, `createdDate`, `modifiedDate`, and
  `isPinned`.
- **Storage**: Persisted locally by whatever storage implementation the
  host injects. The markdown-backed conformer persists a note as a row in
  a local document store (a local database), keyed by
  the note's id lowercased to a string; none of the sources given
  here adds encryption, secure-credential storage, or any protection
  beyond what that document store itself already applies.
- **Transmission**: None of these sources calls out to a network
  directly. The markdown-backed conformer's insert operation does enqueue
  a create operation onto the document store's own remote outbox, so a
  note's content and metadata eventually leave the device through that
  separate, already-documented sync path, on a schedule this layer does
  not control.
- **Retention**: A note's content and metadata persist indefinitely until
  deleting it by id removes the row. Flushing pending saves shortens the
  window in which an edit exists only in memory and not yet on disk, but
  it is the caller's responsibility to invoke it (e.g. before
  termination); nothing in these sources calls it automatically.

## Logging

Subsystem: the app's own bundle identifier (via the shared logger
factory) | Category: the manager's name

| Event | Level | Message |
|-------|-------|---------|
| A storage read or write fails | error | `"<operation> failed: <error.localizedDescription>"`, where `<operation>` is `load`, `create`, `save`, or `delete` |
| Loading notes succeeds | info | `"Loaded <count> notes"` |

## Platform Notes

- **SwiftUI**: These types are plain Swift/Foundation with no AppKit
  dependency, so a SwiftUI host can wrap `NotesManager` in an
  `@Observable` or `ObservableObject` adapter (it is neither itself — see
  Design Decisions) and drive a `List`/`ForEach` from `notes`, observing
  `notesDidChangeNotification` and `storageDidFailNotification` the same
  way an AppKit host does.
- **Compose**: Port `Note` as a `data class`, `NoteFolder` as a recursive
  `data class`, and `NoteStorage` as a Kotlin `interface` of five
  `suspend` functions, with the change stream as a `Flow<NoteChange>`
  (a sealed class whose cases include `TaxonomyChanged`). The note
  taxonomy stays a plain, non-`suspend` Kotlin `interface`, because the
  folders pane and the Move-to menu call it on the main thread while they
  build rows and menus; a remote storage implements it over a local copy
  it keeps current. The taxonomy-provider extension is a second interface
  exposing `val taxonomy: NoteTaxonomy`, checked with `as?`.
  `NotesManager` becomes a `ViewModel` holding a
  `StateFlow<List<Note>>` in place of the notification pair (and a
  `SharedFlow<Unit>` in place of the taxonomy-change notification), with the
  debounced save mapped onto a coroutine job keyed by note id (the role
  `KeyedDebouncer` plays here) and the storage-issue-ordering guarantee
  reproduced with a single-threaded dispatcher or a `Mutex`.
- **React/Web**: `Note`/`NoteFolder` become plain TypeScript interfaces;
  `NoteStorage` an interface of five `Promise`-returning methods, with the change stream as an async iterable
  (a discriminated union with a `taxonomyChanged` member). The note
  taxonomy stays synchronous (plain methods, no `Promise`), answered from
  a local copy by a remote storage, and the taxonomy-provider extension
  is an optional `taxonomy` property checked before use.
  `NotesManager` becomes a store (a hook backed by
  `useSyncExternalStore`, or a small class with subscribers in place of
  `NotificationCenter`), with the per-note debounce implemented via
  `setTimeout` keyed by note id and the write-ordering guarantee
  implemented as a per-instance promise chain, exactly mirroring
  `performStorage(_:)`'s `storageChain`.
- **AppKit / UIKit**: The sources given here — `Note.swift` and
  `MarkdownNoteMapping.swift` under
  `packages/apple/AgenticDeveloperHubSDK/Markdown/`, and `NoteFolder.swift`,
  `NoteStorage.swift`, `NoteTaxonomyProviding.swift`,
  `MarkdownNoteStorage.swift`, `NotesManager.swift` and
  `NotesMarkdownReExports.swift` under
  `packages/apple/AgenticDeveloperHubSDK/macOS/Features/NotesWindow/` — are the
  source platform, with the `NoteTaxonomy` protocol they consume in
  `Markdown/NoteTaxonomy.swift`: a macOS-only target consumed by
  `NotesCoordinator`/`NotesSplitViewController` (out of scope for this
  ingredient) via `NotificationCenter` observation and `@MainActor` calls.
  `Note`, `NoteFolder`, and `MarkdownNoteStorage` are `Sendable`;
  `NotesManager` is itself `@MainActor`, and every storage call it issues
  runs off the main actor through `Task.detached`, serialized into its
  own `storageChain`; the change stream is an `AsyncStream<NoteChange>` consumed by a `Task` the manager cancels in `deinit` (see `notesmanager-confined-to-primary-thread` and
  `notesmanager-storage-off-primary-thread`). `NoteTaxonomyProviding`
  declares `var taxonomy: any NoteTaxonomy`, which `MarkdownNoteStorage`
  answers with its `store`; `NotesManager.taxonomy` is
  `(any NoteTaxonomy)?`, and `NotesSplitViewController(taxonomy:)` and
  `NotesFolderListViewController(taxonomy:)` take the same optional
  existential. `NoteChange.taxonomyChanged` and a `.resync` each make
  `apply(_:)` post `NotesManager.taxonomyDidChangeNotification`, which
  `NotesSplitViewController` observes to call `folderVC.reload()`. The version ledger is a
  `nonisolated let versions = VersionLedger()`, a `[UUID: Int64]` behind an
  `OSAllocatedUnfairLock`, read and advanced by the `write(_:version:)` and
  `insert(_:)` helpers from inside the `storageChain`, so a queued save
  never quotes a version read on the main actor before the save ahead of
  it landed (see `notesmanager-version-ledger`). `NoteFolder`'s explicit,
  non-accidental `Hashable` conformance exists because an `NSOutlineView`
  bridges a Swift value lacking that conformance to a boxed object whose
  hash falls back to that box's own identity, so two
  differently-boxed-but-equal folders from two separate `reload()`s would
  hash unequally and `isItemExpanded(_:)`/`row(forItem:)` could never
  match one across a reload (see `notefolder-value-semantics`).
  `MarkdownNoteStorage` persists through SQLite via GRDB, and neither it
  nor `NotesManager` add Keychain storage or any protection beyond what
  that store applies (see Privacy). Nothing in these files is itself
  AppKit-specific — they import only `Foundation`, `os`,
  `AgenticDeveloperHubSDKCore`, `AgenticDeveloperHubSDKMarkdown`, and
  `AgenticDeveloperHubSDKDatabase` — so the same files would compile unchanged
  into a UIKit iOS target. The notes list beside these types shows each
  note's `modifiedDate` through the shared
  [adhsdk.ingredient.foundation.formatting.relative-date](cookbook:873f79b1-444d-4c2c-8a5f-4fc01cd9022e)
  formatter (abbreviated, no cutoff), never a formatter of its own.
- **WinUI 3**: `Note`/`NoteFolder` become a `record`/`class` pair (or a
  lightweight `INotifyPropertyChanged` model if the folder tree needs to
  bind directly to a `TreeView`). `NoteStorage` becomes an interface
  returning `Task<T>` per method. `NotesManager` becomes a class backed
  by an `ObservableCollection<Note>` in place of `notes`, replacing
  `notesDidChangeNotification`/`storageDidFailNotification` with
  `INotifyCollectionChanged` and a plain C# event; a
  `SemaphoreSlim(1, 1)` awaited before each storage call reproduces the
  one-at-a-time, issue-ordered `storageChain`, and a
  `System.Threading.Timer` per note id, restarted on each edit,
  reproduces `KeyedDebouncer`'s per-key debounce-with-retry. The change
  stream becomes an `IAsyncEnumerable<NoteChange>` over a record hierarchy
  that includes a taxonomy-changed case, the note taxonomy a synchronous
  C# interface answered from a local copy, the taxonomy-provider extension
  a second interface checked with `is`, and the taxonomy-change
  notification a plain C# event.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/NotesWindow/` | confirmed (2.0.0) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Markdown/Note.swift` | confirmed (2.0.0) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Markdown/MarkdownNoteMapping.swift` | confirmed (2.0.0) |

## Design Decisions

**Decision**: Track frontmatter key ownership explicitly (`ownedFrontmatterKeys`, recorded in the same transaction as the document) rather than inferring ownership from a key's value.
**Rationale**: Two prior ad-hoc value-based guards disagreed with each other and produced two distinct defects — an unpin that could not clear its own `pinned:` key, and a foreign `pinned: true` pasted from a Hugo or Jekyll document that silently pinned the note. Recording the fact instead of guessing removes both special cases in one stroke.
**Approved**: pending

**Decision**: A note has no stored `title` field at all — `title` is always `MarkdownText.deriveTitle(content)`, and `MarkdownNoteStorage` never claims a `title` frontmatter key.
**Rationale**: A stored title can go stale against edited content between an edit and the next save. A third historical defect, on the `title` key this class used to also own, came from exactly that: a save overwrote a hand-typed `title:` fence because the app assumed any title it did not recognize was stale.
**Approved**: pending

**Decision**: `updateNote`'s read, merge, and write happen inside one `MarkdownStore.mutateDocument` transaction rather than as three separate calls.
**Rationale**: Nothing today needs it — `NotesCoordinator` builds one `NotesManager` shared by every host, and that manager already serializes its own storage calls — but the transaction is cheap enough to pay for up front, before the writer that would need it (a background sync pull, a second coordinator) exists, because the read-and-write layer is the only layer that can make the pair indivisible later.
**Approved**: pending

**Decision**: (AppKit/macOS) `NotesManager` runs every storage call off the main actor, but re-serializes them into one `storageChain` so they still execute strictly in the order they were issued.
**Rationale**: Each write hands storage a whole `Note` snapshot taken on the main actor. Before storage moved off the main actor, issue order and execution order were the same thing for free — no suspension point existed inside a call. Detaching each call independently would silently give that up, letting a stale content-save land after a newer pin-toggle write and resurrect superseded content.
**Approved**: pending

**Decision**: (AppKit/macOS) A debounced save whose write throws stays pending and is retried with backoff (via `KeyedDebouncer`), rather than being dropped after a log line.
**Rationale**: Three prior, independent copies of this cancel-and-reschedule-then-flush-once pattern (in this manager, `TextDocumentSaveScheduler`, and `SemanticTokenHighlightProvider`) each dropped a note whose write threw. A dropped note left the user's edit unsaved with no further attempt and no visible failure until the next launch, at which point it was already gone.
**Approved**: pending

**Decision**: `storageFailure` is one optional value, overwritten by the next failure, rather than a queue of past failures.
**Rationale**: A failing storage backend fails every subsequent operation identically, so a second queued alert would only repeat what the first one already said. A single slot is the smallest shape that still makes a failure visible to the user.
**Approved**: pending

**Decision**: Pinning a note is implemented by editing the note's own markdown `content` (a `pinned:` frontmatter line) rather than as a separate, local-only column.
**Rationale**: The cost is named directly in `MarkdownNoteStorage`'s own comments: once a remote writer exists, pinning appends a version on the server. That cost is accepted because the alternative — a local-only column — would silently vanish on the note's first sync.
**Approved**: pending

**Decision**: (AppKit/macOS) A stale save re-saves on top of the stored version when the stored text is still what the editor started from, and otherwise keeps the other writer's note and puts the editor's text in a new "(conflicted copy)" note (Decision 10 of the apps-suite design).
**Rationale**: A version bump alone (a pin elsewhere, a no-op round trip) is not a conflict and should not produce a copy; a real text change elsewhere must never be overwritten, and the user's edit must never vanish. A copy keeps both texts visible with no merge UI.
**Approved**: pending

**Decision**: The folders pane, the Move-to menu and the split view reach categories through `NoteTaxonomy`, a synchronous protocol in the Markdown tier, rather than through `MarkdownStore`; `NoteTaxonomyProviding.taxonomy` and `NotesManager.taxonomy` expose it, and another writer's category edit arrives as `NoteChange.taxonomyChanged`.
**Rationale**: Exposing `MarkdownStore` meant only a storage with a local GRDB file could show folders, and a daemon-backed storage could not. The interface stays synchronous, unlike `NoteStorage`, because its callers run on the main actor while they build menus and rows, where a network round trip would stall the UI; a remote storage answers from a local copy it keeps current and announces outside changes on its change stream. `MarkdownStore` conforms with the methods it already had, so the existing storage changed nothing.
**Approved**: pending

**Decision**: `Note` and `MarkdownNoteMapping` live in the Markdown framework, not the macOS feature tier, and `NoteStorage` is `async`.
**Rationale**: A daemon or CLI serving notes must apply exactly the same pinning rules as the app without linking AppKit, and a daemon-backed storage answers over the network. Synchronous conformers still satisfy the async requirements, so the move cost existing storages nothing.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | best-practices |
| [adc.check.reliability.error-recovery](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/694a971d-282d-501b-8861-c4ece3b01edd) | passed | reliability |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | passed | reliability |
| [adc.check.reliability.state-recovery](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/6e64e2f2-28ad-55d5-a8ed-cee075366674) | partial | reliability |

Separation of concerns holds structurally: `NoteStorage` is a narrow, five-method asynchronous persistence seam that knows nothing about markdown, frontmatter, or ownership; `MarkdownNoteStorage` is the only conformer that reaches into `MarkdownStore`, the folders seam (`NoteTaxonomyProviding`) hands out the `NoteTaxonomy` protocol rather than the store, and `MarkdownNoteStorage` alone applies the entire frontmatter-ownership contract, whose rules live in the shared `MarkdownNoteMapping`; `NotesManager` owns in-memory state, notification, debouncing, and failure surfacing without ever touching a document's bytes directly. Unit test coverage holds: `MarkdownNoteStorageTests`, `NoteFolderTests`, `NotesStorageFailureTests`, `NotesManagerStorageOrderingTests`, `NotesManagerMarkdownStoreTests`, and `NotesManagerLiveChangeTests` between them exercise nearly every requirement above by name, including the concurrency-ordering and ownership-race cases. Explicit error handling holds: every one of the five `NoteStorage` methods is `async throws`, and every `NotesManager` call site either propagates the failure to its caller (`createNote` returning `nil`) or records it as a typed `NotesStorageFailure` with a log line — nothing here discards an error silently. Error recovery holds for the debounced save path specifically: `KeyedDebouncer`'s contract keeps a note whose write threw pending and retries it with backoff, rather than dropping it once and logging. Data integrity holds: `MarkdownNoteMapping.note(from:ownedKeys:)` skips a document whose id fails `UUID(uuidString:)` rather than crashing or corrupting the list, and `updateNote`'s single-transaction read-merge-write is what lets another writer's concurrent, in-transaction mark survive rather than being silently overwritten. State recovery is marked partial: `flushPendingSaves()` exists precisely to drain every pending debounced save before termination and to report which ones still failed, but nothing in the sources given here calls it automatically — invoking it is a caller precondition (the host app's own termination handling, out of scope for this ingredient), so a host that never calls it can still lose an in-flight edit to a crash or a forced quit.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 2.0.0 | 2026-11-21 | Mike Fullerton | Note and MarkdownNoteMapping move to the Markdown tier; Note carries a version; NoteStorage is async with fetchNote(id:), a stale(current:) error and an ObservableNoteStorage change stream; NotesManager applies other writers' changes live and turns a stale save into a (conflicted copy) note. Folders go through the synchronous NoteTaxonomy: NoteTaxonomyProviding.taxonomy and NotesManager.taxonomy replace the MarkdownStore accessors (notesmanager-markdown-store-accessor becomes notesmanager-taxonomy-accessor), and NoteChange.taxonomyChanged and a resync post taxonomyDidChangeNotification (notesmanager-taxonomy-notification). |
| 1.1.4 | 2026-11-13 | Mike Fullerton | The notes list shows modified dates through the shared relative-date formatter. |
| 1.1.3 | 2026-10-04 | Mike Fullerton | Dropped the stray reference to the hub's notes client from the overview. |
| 1.1.2 | 2026-10-04 | Mike Fullerton | Legacy recipe citations restored to the legacy recipes' own adhsdk://recipes/ domains; the adhsdk://recipes/ form named nothing. |
| 1.1.1 | 2026-10-04 | Mike Fullerton | Removed the upward dependency on adh/hub/content/markdown-store (frontmatter depends-on and in-text links); the document store is described in plain terms. |
| 1.1.0 | 2026-09-27 | Mike Fullerton | Platform-neutral description; platform specifics in Platform Notes; moved to workspace/notes/. |
| 1.0.1 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.0.0 | 2026-09-24 | Mike Fullerton | Initial creation |
