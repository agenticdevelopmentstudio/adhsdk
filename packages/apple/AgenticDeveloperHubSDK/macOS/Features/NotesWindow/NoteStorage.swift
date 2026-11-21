import Foundation

/// Abstract storage interface for note persistence.
/// Clients provide a concrete implementation backed by their storage layer
/// (SQLite, a daemon over HTTP, the file system, etc.).
///
/// Every method is `async throws`: a daemon-backed storage answers over the
/// network, and a local one may do real disk I/O. A synchronous `throws`
/// implementation still satisfies each requirement, which is why
/// `MarkdownNoteStorage` and the test doubles keep their synchronous bodies.
///
/// `Sendable` because `NotesManager` calls these methods from outside the
/// main actor — a note read or write must never hold the main actor while it
/// waits. An implementor whose storage is not safe to call from a
/// non-isolated context cannot conform.
public protocol NoteStorage: Sendable {
    func fetchAllNotes() async throws -> [Note]
    /// The stored note, or `nil` when it no longer exists.
    func fetchNote(id: UUID) async throws -> Note?
    /// Returns the version the storage gave the new note.
    @discardableResult
    func insertNote(_ note: Note) async throws -> Int64
    /// Throws `NoteStorageError.stale` when the storage has a newer version
    /// than `note.version`. A storage with no concurrency token never does.
    ///
    /// Returns the version the write produced. A caller that saves the same
    /// note again sends that version, not the one it read: without it every
    /// save after the first would be refused as stale against the caller's
    /// own previous save.
    @discardableResult
    func updateNote(_ note: Note) async throws -> Int64
    func deleteNote(id: UUID) async throws
}

extension NoteStorage {
    /// A fallback built on `fetchAllNotes`, so a storage with no cheaper
    /// single-note read conforms without writing one.
    public func fetchNote(id: UUID) async throws -> Note? {
        try await fetchAllNotes().first { $0.id == id }
    }
}

/// A write the storage refused because the note changed underneath it.
public enum NoteStorageError: Error, Equatable {
    /// `current` is the stored note when the storage could say what it is,
    /// `nil` when the caller must re-read it.
    case stale(current: Note?)
}

/// One change the storage saw, from any writer.
public enum NoteChange: Equatable, Sendable {
    case upserted(UUID)
    case deleted(UUID)
    /// The storage lost track of what changed (a gap in its feed); re-read all.
    case resync
}

/// A storage that announces changes made by other writers, so `NotesManager`
/// can show them without a reload.
public protocol ObservableNoteStorage: NoteStorage {
    func changes() -> AsyncStream<NoteChange>
}
