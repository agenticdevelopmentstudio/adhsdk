import Foundation

/// How a `Note` is carried in a markdown document: the `pinned` frontmatter
/// key and the record of which frontmatter keys this client wrote.
///
/// Lifted out of `MarkdownNoteStorage` so every place that turns a document
/// into a note — the app's storage, the daemon's notes service, a CLI — applies
/// exactly the same pinning rules. Two copies of these rules would be two
/// answers to "is this note pinned?", and the rules exist because guessing
/// that answer from the bytes went wrong twice.
///
/// The rules turn on one fact the document itself cannot carry: for `pinned`,
/// did *this app* write it, or did the user type it? That fact is recorded in
/// `ownedKeys` (`MarkdownStore.ownedFrontmatterKeys`) instead of inferred:
///
///   * a key we own is ours to rewrite, to clear, and to hide from the editor;
///   * a key we do not own is the user's, and is never touched or acted on;
///   * ownership is *claimed* only when we write a key that was absent (or that
///     already reads exactly as what we were about to write), and *released*
///     the moment we clear it or the user edits the text it lived in.
public enum MarkdownNoteMapping {

    /// The one frontmatter key a note writes. There is no `title` key: a note's
    /// title is `MarkdownText.deriveTitle(content)`.
    public static let pinnedKey = "pinned"

    // MARK: - Document → note

    /// The note a document shows, or `nil` when its id is not a UUID — a
    /// server-authored document the UUID-keyed notes UI cannot represent.
    public static func note(from document: MarkdownDocument, ownedKeys: Set<String>) -> Note? {
        guard let id = UUID(uuidString: document.id) else { return nil }
        return Note(
            id: id,
            content: strippedContent(of: document.content, ownedKeys: ownedKeys),
            createdDate: document.createdAt,
            modifiedDate: document.updatedAt,
            isPinned: isPinned(document.content, ownedKeys: ownedKeys),
            version: document.version)
    }

    /// Pinned only by a `pinned: true` this client wrote. A `pinned: true` we
    /// did not write is somebody else's key that happens to share our name — a
    /// Hugo or Jekyll document pasted into a note — and must not pin it.
    public static func isPinned(_ content: String, ownedKeys: Set<String>) -> Bool {
        ownedKeys.contains(pinnedKey) && Frontmatter.value(pinnedKey, in: content) == "true"
    }

    /// `content` with the keys *we* wrote removed, and nothing else touched —
    /// a `pinned:` the user typed stays visible in the editor along with every
    /// other line in its original order. This is both what `Note.content`
    /// shows and how a save tells "nothing changed" from "the user edited it".
    public static func strippedContent(of content: String, ownedKeys: Set<String>) -> String {
        ownedKeys.sorted().reduce(content) { content, key in
            Frontmatter.setting(key, to: nil, in: content)
        }
    }

    // MARK: - Note → document

    /// The content to store for `note`, and the keys this client owns in it
    /// afterwards.
    ///
    /// - `existing == nil` is a create: a key is claimed only when the note's
    ///   own text does not already have one, so a hand-typed `pinned:` fence is
    ///   kept, unclaimed and untouched.
    /// - Otherwise `existing` is the stored content and `ownedKeys` the stored
    ///   claims. When the note's content differs from what the last read handed
    ///   back, the user edited the text and it is wholly theirs: ownership is
    ///   dropped in that same step. The owned keys are then rewritten in place,
    ///   so an unmodified fetch-then-save round-trips byte for byte.
    public static func content(
        for note: Note, existing: String?, ownedKeys: Set<String>
    ) -> (content: String, ownedKeys: Set<String>) {
        guard let existing else {
            var content = note.content
            var owned: Set<String> = []
            if note.isPinned, Frontmatter.value(pinnedKey, in: content) == nil {
                content = Frontmatter.setting(pinnedKey, to: .bool(true), in: content)
                owned.insert(pinnedKey)
            }
            return (content, owned)
        }

        var content = existing
        var owned = ownedKeys
        if note.content != strippedContent(of: existing, ownedKeys: ownedKeys) {
            content = note.content
            owned = []
        }
        // Built once and used twice — asked about by `mayWrite`, then written —
        // so the write that is permitted is provably the write that happens.
        let desiredPin: FrontmatterValue? = note.isPinned ? .bool(true) : nil
        if mayWrite(pinnedKey, as: desiredPin, in: content, owned: owned) {
            content = Frontmatter.setting(pinnedKey, to: desiredPin, in: content)
            if note.isPinned {
                owned.insert(pinnedKey)
            } else {
                owned.remove(pinnedKey)
            }
        }
        return (content, owned)
    }

    /// Whether a note may write `key` — because it already owns it, or because
    /// writing would take nothing from the user: the key is absent, or writing
    /// it would change no bytes.
    ///
    /// "Changes no bytes" is asked literally, by performing the write and
    /// comparing, rather than by comparing values: `Frontmatter.value`
    /// *unquotes*, so a user's `pinned: "true"` compared equal to `"true"` and
    /// the app then rewrote it as a boolean and claimed a key it had just taken
    /// from the user.
    static func mayWrite(
        _ key: String, as desired: FrontmatterValue?, in content: String, owned: Set<String>
    ) -> Bool {
        if owned.contains(key) { return true }
        guard Frontmatter.value(key, in: content) != nil else { return true }
        return Frontmatter.setting(key, to: desired, in: content) == content
    }
}
