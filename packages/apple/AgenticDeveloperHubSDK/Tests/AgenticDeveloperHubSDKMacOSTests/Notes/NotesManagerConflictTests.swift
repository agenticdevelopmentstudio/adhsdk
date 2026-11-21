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
}
