
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

