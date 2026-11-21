import Foundation
import AgenticDeveloperHubSDKMarkdown

/// `NoteStorage` over `MarkdownStore`: a note is a markdown document with a
/// live `content.notes` marker row.
///
/// Nothing above it changes. `NotesManager` already takes a `NoteStorage` and
/// `NotesCoordinator` already takes one from its caller, so replacing
/// `NotesDatabaseManager` is one conformance here and one line in Whippet —
/// which is the whole reason that seam exists.
///
/// `Sendable` as written: `store` is a `let MarkdownStore`, itself
/// `@unchecked Sendable`, and `pinnedKey` is a `static let` constant — there
/// is no other stored state, so the compiler-derived conformance below costs
/// nothing (M1(b) in the review this fixes).
public final class MarkdownNoteStorage: NoteStorage, Sendable {

    /// Exposed so a host can reach the taxonomy and the REST queue; the four
    /// `NoteStorage` methods deliberately do not.
    public let store: MarkdownStore

    /// The one frontmatter key this class writes; the rules for it live in
    /// `MarkdownNoteMapping`, shared with every other notes storage.
    private static let pinnedKey = MarkdownNoteMapping.pinnedKey

    public init(store: MarkdownStore) {
        self.store = store
    }

    // MARK: - Ownership
    //
    // Whether `pinned` was written by this app or typed by the user is
    // recorded in `MarkdownStore.ownedFrontmatterKeys`, never inferred; the
    // rules that follow from it are `MarkdownNoteMapping`'s.
    //
    // `Note.version` is never checked here: this storage writes last-writer-
    // wins and never throws `NoteStorageError.stale`. It still reports the
    // document's `local_version` (read into `Note.version` and returned from
    // each write), so a caller's held version stays true. The methods stay
    // synchronous, which satisfies the async protocol and keeps existing
    // synchronous callers compiling.

    // MARK: - NoteStorage

    public func fetchAllNotes() throws -> [Note] {
        // One query for every document's owned keys rather than one per
        // document: the list is the hot path, and the ownership record is
        // small enough to read whole.
        let owned = try store.ownedFrontmatterKeysByDocument()
        return try store.documents(marker: .note)
            .compactMap { MarkdownNoteMapping.note(from: $0, ownedKeys: owned[$0.id] ?? []) }
            .sorted(by: Note.defaultSort)
    }

    @discardableResult
    public func insertNote(_ note: Note) throws -> Int64 {
        // A create claims a key only when the note's own text does not already
        // have one, so a hand-typed `pinned:` fence is kept, unclaimed.
        let (content, owned) = MarkdownNoteMapping.content(
            for: note, existing: nil, ownedKeys: [])
        // Both stamps, separately. `now:` dates the write; `createdAt:` is the
        // note's own birthday, which `Note` already carries and which nothing
        // else in the row records — passing only `now:` stamped `created_at`
        // with the modification date, so every note appeared to have been
        // created when it was last edited, irrecoverably.
        return try store.createDocument(
            content: content,
            markers: [.note],
            id: note.id.uuidString.lowercased(),
            now: note.modifiedDate,
            createdAt: note.createdDate,
            ownedFrontmatterKeys: owned).version
    }

    /// Rewrites the keys this class owns in place, preserving whatever position
    /// and whatever foreign keys the stored frontmatter already has, so an
    /// unmodified fetch-then-save round-trips byte for byte.
    ///
    /// When the caller's `content` differs from what the last read handed back,
    /// the user edited the text — and the text is then wholly theirs. Ownership
    /// is dropped in that same step: a key that survives into the new content
    /// survives because the user kept it there, and re-claiming it would be the
    /// same guess this class stopped making.
    ///
    /// The read, the merge and the write are **one** transaction
    /// (`MarkdownStore.mutateDocument`), not three calls.
    ///
    /// The merge below writes the whole row back, so a writer landing between
    /// a separate read and write would have its change overwritten with no
    /// error. Today nothing can: `NotesCoordinator` builds one `NotesManager`
    /// and hands the same instance to both the notes window and Quick Note,
    /// and that manager issues its storage calls one at a time. This is
    /// defence for the writer that is not here yet — a background sync pull,
    /// a second coordinator — and it is cheap enough to be worth having
    /// before that writer arrives, because the layer that reads and writes
    /// together is the only layer that can make the pair indivisible.
    ///
    /// It buys atomicity, not ordering. Two concurrent writers still resolve
    /// last-writer-wins over the whole note, matching adh (whose head has no
    /// concurrency token either): the merge assigns `document.content =
    /// note.content` outright, so a stale snapshot still clobbers a newer one
    /// — atomically. A compare-and-swap would be a different feature, and
    /// would need a token adh does not send.
    @discardableResult
    public func updateNote(_ note: Note) throws -> Int64 {
        let id = note.id.uuidString.lowercased()
        return try store.mutateDocument(id: id, now: note.modifiedDate) { document, owned in
            let merged = MarkdownNoteMapping.content(
                for: note, existing: document.content, ownedKeys: owned)
            document.content = merged.content
            owned = merged.ownedKeys
        }
    }

    public func fetchNote(id: UUID) throws -> Note? {
        let key = id.uuidString.lowercased()
        guard let document = try store.document(id: key, marker: .note) else { return nil }
        let owned = try store.ownedFrontmatterKeys(forDocument: key)
        return MarkdownNoteMapping.note(from: document, ownedKeys: owned)
    }

    public func deleteNote(id: UUID) throws {
        try store.deleteDocument(id: id.uuidString.lowercased())
    }
}
