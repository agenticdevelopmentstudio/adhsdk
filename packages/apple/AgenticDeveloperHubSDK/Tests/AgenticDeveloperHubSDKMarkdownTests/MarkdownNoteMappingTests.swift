import Foundation
import Testing
@testable import AgenticDeveloperHubSDKMarkdown

@Suite("MarkdownNoteMapping")
struct MarkdownNoteMappingTests {

    private let id = UUID()
    private let date = Date(timeIntervalSince1970: 1_000_000)

    private func note(_ content: String, pinned: Bool) -> Note {
        Note(id: id, content: content, createdDate: date, modifiedDate: date, isPinned: pinned)
    }

    private func document(_ content: String, version: Int64 = 3) -> MarkdownDocument {
        MarkdownDocument(
            id: id.uuidString.lowercased(), content: content,
            ownerKind: .customer, ownerID: "c", createdAt: date, updatedAt: date,
            version: version)
    }

    @Test("a pinned note round-trips pinned, with the key hidden from the editor")
    func pinnedRoundTrips() throws {
        let written = MarkdownNoteMapping.content(
            for: note("# Title\n\nbody", pinned: true), existing: nil, ownedKeys: [])
        #expect(written.ownedKeys == ["pinned"])

        let read = try #require(MarkdownNoteMapping.note(
            from: document(written.content), ownedKeys: written.ownedKeys))
        #expect(read.isPinned)
        #expect(read.content == "# Title\n\nbody")
        #expect(read.version == 3)
    }

    @Test("unpinning clears our key and releases it")
    func unpinRoundTrips() throws {
        let pinned = MarkdownNoteMapping.content(
            for: note("# Title", pinned: true), existing: nil, ownedKeys: [])
        let unpinned = MarkdownNoteMapping.content(
            for: note("# Title", pinned: false), existing: pinned.content, ownedKeys: pinned.ownedKeys)
        #expect(unpinned.ownedKeys.isEmpty)

        let read = try #require(MarkdownNoteMapping.note(
            from: document(unpinned.content), ownedKeys: unpinned.ownedKeys))
        #expect(!read.isPinned)
        #expect(read.content == "# Title")
    }

    @Test("a hand-typed pinned: is kept, unclaimed, and does not pin")
    func handTypedPinnedIsKept() throws {
        let typed = "---\npinned: true\n---\n# Hugo"
        let written = MarkdownNoteMapping.content(
            for: note(typed, pinned: false), existing: nil, ownedKeys: [])
        #expect(written.content == typed)
        #expect(written.ownedKeys.isEmpty)

        let read = try #require(MarkdownNoteMapping.note(
            from: document(written.content), ownedKeys: written.ownedKeys))
        #expect(!read.isPinned)
        #expect(read.content == typed)
    }

    @Test("an unmodified fetch-then-save round-trips byte for byte")
    func unmodifiedSaveIsByteIdentical() throws {
        let pinned = MarkdownNoteMapping.content(
            for: note("# Title\n\nbody", pinned: true), existing: nil, ownedKeys: [])
        let read = try #require(MarkdownNoteMapping.note(
            from: document(pinned.content), ownedKeys: pinned.ownedKeys))
        let again = MarkdownNoteMapping.content(
            for: read, existing: pinned.content, ownedKeys: pinned.ownedKeys)
        #expect(again.content == pinned.content)
        #expect(again.ownedKeys == pinned.ownedKeys)
    }

    @Test("a document whose id is not a UUID has no note")
    func nonUUIDHasNoNote() {
        let doc = MarkdownDocument(
            id: "server-authored", content: "# X", ownerKind: .customer, ownerID: "c",
            createdAt: date, updatedAt: date)
        #expect(MarkdownNoteMapping.note(from: doc, ownedKeys: []) == nil)
    }
}
