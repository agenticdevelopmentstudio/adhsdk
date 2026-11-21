import Foundation
@testable import AgenticDeveloperHubSDKMacOS

/// An in-memory `ObservableNoteStorage` with a version per note, as a daemon
/// would keep: every write bumps it, and an update quoting an older version is
/// refused with `NoteStorageError.stale`. `otherWriter(_:)` changes a note the
/// way a second app would, behind the manager's back.
final class VersionedNoteStorage: ObservableNoteStorage, @unchecked Sendable {
    private let lock = NSLock()
    private var rows: [UUID: Note] = [:]
    private var continuation: AsyncStream<NoteChange>.Continuation?
    /// When true, a stale refusal carries no note and the manager must re-read.
    var staleWithoutCurrent = false

    init(_ notes: [Note] = []) {
        for var note in notes {
            note.version = max(note.version, 1)
            rows[note.id] = note
        }
    }

    func note(_ id: UUID) -> Note? {
        lock.lock(); defer { lock.unlock() }
        return rows[id]
    }

    var all: [Note] {
        lock.lock(); defer { lock.unlock() }
        return Array(rows.values)
    }

    /// Changes a note as another writer would, and returns the stored result.
    @discardableResult
    func otherWriter(_ id: UUID, content: String? = nil, pinned: Bool? = nil) -> Note {
        lock.lock(); defer { lock.unlock() }
        var note = rows[id]!
        if let content { note.content = content }
        if let pinned { note.isPinned = pinned }
        note.version += 1
        rows[id] = note
        return note
    }

    func changes() -> AsyncStream<NoteChange> {
        let (stream, continuation) = AsyncStream<NoteChange>.makeStream()
        lock.lock(); self.continuation = continuation; lock.unlock()
        return stream
    }

    func emit(_ change: NoteChange) {
        lock.lock(); let continuation = self.continuation; lock.unlock()
        continuation?.yield(change)
    }

    func fetchAllNotes() throws -> [Note] { all }

    func fetchNote(id: UUID) throws -> Note? { note(id) }

    @discardableResult func insertNote(_ note: Note) throws -> Int64 {
        lock.lock(); defer { lock.unlock() }
        var stored = note
        stored.version = 1
        rows[note.id] = stored
        return 1
    }

    @discardableResult func updateNote(_ note: Note) throws -> Int64 {
        lock.lock(); defer { lock.unlock() }
        guard let existing = rows[note.id] else {
            throw NoteStorageError.stale(current: nil)
        }
        guard existing.version == note.version else {
            throw NoteStorageError.stale(current: staleWithoutCurrent ? nil : existing)
        }
        var stored = note
        stored.version = existing.version + 1
        rows[note.id] = stored
        return stored.version
    }

    func deleteNote(id: UUID) throws {
        lock.lock(); defer { lock.unlock() }
        rows[id] = nil
    }
}
