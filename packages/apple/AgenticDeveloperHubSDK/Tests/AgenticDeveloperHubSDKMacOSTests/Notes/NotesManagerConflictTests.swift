import XCTest
@testable import AgenticDeveloperHubSDKMacOS

/// Decision 10: a stale save never loses text.
@MainActor
final class NotesManagerConflictTests: XCTestCase {

    private func makeNote(_ content: String) -> Note {
        Note(id: UUID(), content: content, createdDate: Date(), modifiedDate: Date(), isPinned: false)
    }

    func testStaleSaveWithUnchangedBaseReSavesOnTop() async {
        let note = makeNote("# Base")
        let storage = VersionedNoteStorage([note])
        let manager = NotesManager(storage: storage)
        await manager.loadNotes()

        // Another writer bumps the version without changing the text.
        storage.otherWriter(note.id)
        await manager.updateNote(manager.notes[0], content: "# Base, mine")
        let failed = await manager.flushPendingSaves()

        XCTAssertEqual(failed, [])
        XCTAssertEqual(storage.note(note.id)?.content, "# Base, mine")
        XCTAssertEqual(storage.all.count, 1)
        XCTAssertNil(manager.storageFailure)
    }

    func testStaleSaveWithoutCurrentReReadsAndReSaves() async {
        let note = makeNote("# Base")
        let storage = VersionedNoteStorage([note])
        storage.staleWithoutCurrent = true
        let manager = NotesManager(storage: storage)
        await manager.loadNotes()

        storage.otherWriter(note.id)
        await manager.updateNote(manager.notes[0], content: "# Base, mine")
        await manager.flushPendingSaves()

        XCTAssertEqual(storage.note(note.id)?.content, "# Base, mine")
    }

    func testStaleSaveWithChangedBaseKeepsTheirsAndCreatesAConflictedCopy() async {
        let note = makeNote("# Shared\n\nstart")
        let storage = VersionedNoteStorage([note])
        let manager = NotesManager(storage: storage)
        await manager.loadNotes()

        storage.otherWriter(note.id, content: "# Shared\n\ntheirs")
        await manager.updateNote(manager.notes[0], content: "# Shared\n\nmine")
        await manager.flushPendingSaves()

        XCTAssertEqual(storage.note(note.id)?.content, "# Shared\n\ntheirs")
        XCTAssertEqual(manager.notes.first(where: { $0.id == note.id })?.content, "# Shared\n\ntheirs")

        let copies = storage.all.filter { $0.id != note.id }
        XCTAssertEqual(copies.count, 1)
        XCTAssertEqual(copies.first?.content, "# Shared (conflicted copy)\n\n# Shared\n\nmine")
        XCTAssertTrue(manager.notes.contains(where: { $0.id == copies.first?.id }))
    }

    func testStalePinToggleWithUnchangedBaseReSaves() async {
        let note = makeNote("# Pin me")
        let storage = VersionedNoteStorage([note])
        let manager = NotesManager(storage: storage)
        await manager.loadNotes()

        storage.otherWriter(note.id)
        await manager.togglePin(note: manager.notes[0])

        XCTAssertEqual(storage.note(note.id)?.isPinned, true)
        XCTAssertNil(manager.storageFailure)
    }

    // MARK: - The manager's own writes are never stale against each other

    func testConsecutiveSavesAreNotStaleAgainstEachOther() async {
        let note = makeNote("# Draft")
        let storage = VersionedNoteStorage([note])
        let manager = NotesManager(storage: storage)
        await manager.loadNotes()

        await manager.updateNote(manager.notes[0], content: "# Draft\n\none")
        await manager.flushPendingSaves()
        await manager.updateNote(manager.notes[0], content: "# Draft\n\none two")
        await manager.flushPendingSaves()

        XCTAssertEqual(storage.note(note.id)?.content, "# Draft\n\none two")
        XCTAssertEqual(storage.all.count, 1, "a second save must not take the conflict path")
        XCTAssertEqual(manager.notes.first?.version, storage.note(note.id)?.version)
    }

    func testASaveAfterCreateIsNotStale() async throws {
        let storage = VersionedNoteStorage()
        let manager = NotesManager(storage: storage)
        await manager.loadNotes()

        let createdID = await manager.createNote(content: "# New")
        let id = try XCTUnwrap(createdID)
        let created = try XCTUnwrap(manager.notes.first(where: { $0.id == id }))
        await manager.updateNote(created, content: "# New\n\nmore")
        await manager.flushPendingSaves()

        XCTAssertEqual(storage.note(id)?.content, "# New\n\nmore")
        XCTAssertEqual(storage.all.count, 1)
    }

    func testTheManagersOwnEchoIsNotRefetchedOverTheEditor() async {
        let note = makeNote("# Echo")
        let storage = VersionedNoteStorage([note])
        let manager = NotesManager(storage: storage)
        await manager.loadNotes()

        await manager.updateNote(manager.notes[0], content: "# Echo\n\nsaved")
        await manager.flushPendingSaves()
        await manager.apply(.upserted(note.id))

        XCTAssertEqual(manager.notes.first?.content, "# Echo\n\nsaved")
        XCTAssertEqual(manager.notes.first?.version, storage.note(note.id)?.version)
    }

    // MARK: - The conflicted copy holds the editor's latest text

    func testConflictedCopyHoldsTheEditorsLatestText() async {
        let note = makeNote("# Shared\n\nstart")
        let storage = VersionedNoteStorage([note])
        let manager = NotesManager(storage: storage)
        await manager.loadNotes()

        storage.otherWriter(note.id, content: "# Shared\n\ntheirs")
        await manager.updateNote(manager.notes[0], content: "# Shared\n\nmine")
        await manager.updateNote(manager.notes[0], content: "# Shared\n\nmine, and more")
        await manager.flushPendingSaves()

        let copies = storage.all.filter { $0.id != note.id }
        XCTAssertEqual(copies.map(\.content), ["# Shared (conflicted copy)\n\n# Shared\n\nmine, and more"])
    }

    func testStalePinToggleOverChangedTextPinsTheirsWithoutACopy() async {
        let note = makeNote("# Pin me")
        let storage = VersionedNoteStorage([note])
        let manager = NotesManager(storage: storage)
        await manager.loadNotes()

        storage.otherWriter(note.id, content: "# Pin me\n\ntheirs")
        await manager.togglePin(note: manager.notes[0])

        XCTAssertEqual(storage.all.count, 1, "a pin toggle has no text to save in a copy")
        XCTAssertEqual(storage.note(note.id)?.content, "# Pin me\n\ntheirs")
        XCTAssertEqual(storage.note(note.id)?.isPinned, true)
        XCTAssertEqual(manager.notes.first?.isPinned, true)
        XCTAssertEqual(manager.notes.first?.content, "# Pin me\n\ntheirs")
    }
}
