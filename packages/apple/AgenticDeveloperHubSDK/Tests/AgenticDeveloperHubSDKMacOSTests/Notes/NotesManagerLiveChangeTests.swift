import XCTest
@testable import AgenticDeveloperHubSDKMacOS

/// Changes another writer makes reach the manager through
/// `ObservableNoteStorage.changes()`. The tests drive `apply(_:)` directly so
/// each step is awaited rather than raced against the feed task.
@MainActor
final class NotesManagerLiveChangeTests: XCTestCase {

    private func makeNote(_ content: String) -> Note {
        Note(id: UUID(), content: content, createdDate: Date(), modifiedDate: Date(), isPinned: false)
    }

    func testUpsertWithNewerVersionReplacesTheNote() async {
        let note = makeNote("# One")
        let storage = VersionedNoteStorage([note])
        let manager = NotesManager(storage: storage)
        await manager.loadNotes()

        let changed = storage.otherWriter(note.id, content: "# One, edited elsewhere")
        await manager.apply(.upserted(note.id))

        XCTAssertEqual(manager.notes.first?.content, "# One, edited elsewhere")
        XCTAssertEqual(manager.notes.first?.version, changed.version)
    }

    func testUpsertWithEqualVersionIsIgnored() async {
        let note = makeNote("# One")
        let storage = VersionedNoteStorage([note])
        let manager = NotesManager(storage: storage)
        await manager.loadNotes()
        let held = manager.notes.first

        await manager.apply(.upserted(note.id))

        XCTAssertEqual(manager.notes.first, held)
    }

    func testUpsertOfAnUnknownNoteAddsIt() async throws {
        let storage = VersionedNoteStorage()
        let manager = NotesManager(storage: storage)
        await manager.loadNotes()

        let note = makeNote("# Arrived")
        try storage.insertNote(note)
        await manager.apply(.upserted(note.id))

        XCTAssertEqual(manager.notes.map(\.id), [note.id])
    }

    func testDeletedRemovesTheNote() async {
        let note = makeNote("# Doomed")
        let storage = VersionedNoteStorage([note])
        let manager = NotesManager(storage: storage)
        await manager.loadNotes()

        await manager.apply(.deleted(note.id))

        XCTAssertTrue(manager.notes.isEmpty)
    }

    func testResyncReloads() async throws {
        let storage = VersionedNoteStorage()
        let manager = NotesManager(storage: storage)
        await manager.loadNotes()

        try storage.insertNote(makeNote("# Late"))
        await manager.apply(.resync)

        XCTAssertEqual(manager.notes.count, 1)
    }

    func testUpsertForANoteWithAnUnsavedEditIsNotApplied() async {
        let note = makeNote("# Mine")
        let storage = VersionedNoteStorage([note])
        let manager = NotesManager(storage: storage)
        await manager.loadNotes()

        await manager.updateNote(manager.notes[0], content: "# Mine, typing")
        storage.otherWriter(note.id, content: "# Theirs")
        await manager.apply(.upserted(note.id))

        XCTAssertEqual(manager.notes.first?.content, "# Mine, typing")
    }

    func testTheFeedIsSubscribed() async throws {
        let note = makeNote("# One")
        let storage = VersionedNoteStorage([note])
        let manager = NotesManager(storage: storage)
        await manager.loadNotes()

        let changed = expectation(forNotification: NotesManager.notesDidChangeNotification, object: manager)
        storage.otherWriter(note.id, content: "# Fed")
        storage.emit(.upserted(note.id))
        await fulfillment(of: [changed], timeout: 5)

        XCTAssertEqual(manager.notes.first?.content, "# Fed")
    }

    // MARK: - Taxonomy

    func testTaxonomyChangedPostsTaxonomyDidChangeAndLeavesNotesAlone() async {
        let note = makeNote("# One")
        let storage = VersionedNoteStorage([note])
        let manager = NotesManager(storage: storage)
        await manager.loadNotes()
        let posted = expectation(forNotification: NotesManager.taxonomyDidChangeNotification, object: manager)
        let notesChanged = expectation(forNotification: NotesManager.notesDidChangeNotification, object: manager)
        notesChanged.isInverted = true

        await manager.apply(.taxonomyChanged)

        await fulfillment(of: [posted, notesChanged], timeout: 0.2)
        XCTAssertEqual(manager.notes.map(\.id), [note.id])
    }

    func testResyncAlsoPostsTaxonomyDidChange() async {
        let storage = VersionedNoteStorage([makeNote("# One")])
        let manager = NotesManager(storage: storage)
        await manager.loadNotes()
        let posted = expectation(forNotification: NotesManager.taxonomyDidChangeNotification, object: manager)

        await manager.apply(.resync)

        await fulfillment(of: [posted], timeout: 1)
    }
}
