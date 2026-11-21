
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
- A resync from the change stream reloads every note but keeps each note
  with an unsaved edit as the editor has it, with its base and its ledger
  version, so the edit's save still conflicts properly rather than
  overwriting another writer's text or vanishing.
- Another writer deletes a note this editor is typing into. The typed text
  is stored as a conflicted copy before the note leaves the list.
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

