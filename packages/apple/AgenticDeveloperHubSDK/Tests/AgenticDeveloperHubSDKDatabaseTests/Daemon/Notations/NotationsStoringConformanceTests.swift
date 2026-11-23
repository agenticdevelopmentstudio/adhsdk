import XCTest
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKDatabase

/// The `NotationsStoring` contract, exercised through the protocol so that any
/// other store (adhd's, over its client library) can be held to the same tests.
/// `NotationsStore` is the conformer here.
final class NotationsStoringConformanceTests: XCTestCase {

    private var tempRoot: URL!
    private var store: (any NotationsStoring)!

    private let projectID = UUID()
    private let created = Date(timeIntervalSince1970: 1_000)
    private let edited = Date(timeIntervalSince1970: 2_000)
    private let archivedAt = Date(timeIntervalSince1970: 3_000)

    override func setUpWithError() throws {
        try super.setUpWithError()
        tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("notations-store-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
        store = try NotationsStore(path: tempRoot.appendingPathComponent("Notations.db").path)
    }

    override func tearDownWithError() throws {
        store = nil
        try? FileManager.default.removeItem(at: tempRoot)
        try super.tearDownWithError()
    }

    // MARK: - Saving

    func testASavedNotationIsReadBackWhole() async throws {
        let key = makeKey(branch: "feature")
        let saved = try await store.save(id: nil, key: key, content: "# Plan", at: created)

        let found = try await store.notation(id: saved.id)
        XCTAssertEqual(found, saved)
        XCTAssertEqual(found?.projectID, projectID)
        XCTAssertEqual(found?.projectName, key.projectName)
        XCTAssertEqual(found?.projectPath, key.projectPath)
        XCTAssertEqual(found?.branch, "feature")
        XCTAssertEqual(found?.forkPoint, key.forkPoint)
        XCTAssertEqual(found?.content, "# Plan")
        XCTAssertEqual(found?.state, .active)
        XCTAssertEqual(found?.createdAt, created)
        XCTAssertEqual(found?.modifiedAt, created)
        XCTAssertNil(found?.archivedAt)
    }

    func testAMissingNotationIsNil() async throws {
        let found = try await store.notation(id: UUID())
        XCTAssertNil(found)
    }

    /// One active notation per branch: a second save for the same key, with no
    /// id, lands on the notation already there.
    func testASecondSaveForTheSameKeyReusesTheActiveNotation() async throws {
        let key = makeKey(branch: "feature")
        let first = try await store.save(id: nil, key: key, content: "one", at: created)
        let second = try await store.save(id: nil, key: key, content: "two", at: edited)

        XCTAssertEqual(second.id, first.id)
        XCTAssertEqual(second.content, "two")
        let active = try await store.activeNotations(projectID: projectID, branch: "feature")
        XCTAssertEqual(active.map(\.id), [first.id])
        XCTAssertEqual(active.first?.modifiedAt, edited)
        XCTAssertEqual(active.first?.createdAt, created)
    }

    func testUpdateContentRewritesTheContentAndTheModifiedDate() async throws {
        let saved = try await store.save(id: nil, key: makeKey(branch: "feature"), content: "old", at: created)
        let updated = try await store.updateContent(id: saved.id, content: "new", at: edited)
        XCTAssertTrue(updated)

        let found = try await store.notation(id: saved.id)
        XCTAssertEqual(found?.content, "new")
        XCTAssertEqual(found?.modifiedAt, edited)
    }

    func testUpdateContentOfAMissingNotationReportsFalse() async throws {
        let updated = try await store.updateContent(id: UUID(), content: "nothing", at: edited)
        XCTAssertFalse(updated)
    }

    func testRecordTipStoresAndClearsTheLastTip() async throws {
        let saved = try await store.save(id: nil, key: makeKey(branch: "feature"), content: "x", at: created)
        try await store.recordTip(id: saved.id, tip: "abc123")
        let withTip = try await store.notation(id: saved.id)
        XCTAssertEqual(withTip?.lastTip, "abc123")

        try await store.recordTip(id: saved.id, tip: nil)
        let cleared = try await store.notation(id: saved.id)
        XCTAssertNil(cleared?.lastTip)
    }

    // MARK: - Archiving and deleting

    func testArchiveIsOnceOnly() async throws {
        let saved = try await store.save(id: nil, key: makeKey(branch: "feature"), content: "x", at: created)
        let first = try await store.archive(id: saved.id, at: archivedAt)
        let second = try await store.archive(id: saved.id, at: edited)
        XCTAssertTrue(first)
        XCTAssertFalse(second)

        let found = try await store.notation(id: saved.id)
        XCTAssertEqual(found?.state, .archived)
        XCTAssertEqual(found?.archivedAt, archivedAt)
    }

    /// Archiving frees the branch: the next save for the same key is a new
    /// notation, and the archived one stays as it was.
    func testASaveAfterArchivingStartsANewNotation() async throws {
        let key = makeKey(branch: "feature")
        let first = try await store.save(id: nil, key: key, content: "one", at: created)
        try await store.archive(id: first.id, at: archivedAt)
        let second = try await store.save(id: nil, key: key, content: "two", at: edited)

        XCTAssertNotEqual(second.id, first.id)
        let kept = try await store.notation(id: first.id)
        XCTAssertEqual(kept?.content, "one")
    }

    func testDeletingAnActiveNotationIsRefused() async throws {
        let saved = try await store.save(id: nil, key: makeKey(branch: "feature"), content: "x", at: created)
        do {
            try await store.deleteArchived(id: saved.id)
            XCTFail("an active notation was deleted")
        } catch let error as NotationsStoreError {
            XCTAssertEqual(error, .notArchived(saved.id))
        }
        let found = try await store.notation(id: saved.id)
        XCTAssertNotNil(found)
    }

    func testDeletingAMissingNotationReportsFalse() async throws {
        let deleted = try await store.deleteArchived(id: UUID())
        XCTAssertFalse(deleted)
    }

    func testAnArchivedNotationCanBeDeleted() async throws {
        let saved = try await store.save(id: nil, key: makeKey(branch: "feature"), content: "x", at: created)
        try await store.archive(id: saved.id, at: archivedAt)
        let deleted = try await store.deleteArchived(id: saved.id)
        XCTAssertTrue(deleted)

        let found = try await store.notation(id: saved.id)
        XCTAssertNil(found)
    }

    // MARK: - Queries

    func testActiveNotationForAKeyIgnoresArchivedOnesAndOtherBranches() async throws {
        let key = makeKey(branch: "feature")
        let archived = try await store.save(id: nil, key: key, content: "old", at: created)
        try await store.archive(id: archived.id, at: archivedAt)
        try await store.save(id: nil, key: makeKey(branch: "other"), content: "other", at: created)
        let missing = try await store.activeNotation(for: key)
        XCTAssertNil(missing)

        let active = try await store.save(id: nil, key: key, content: "new", at: edited)
        let found = try await store.activeNotation(for: key)
        XCTAssertEqual(found?.id, active.id)
    }

    func testAllFiltersByState() async throws {
        let kept = try await store.save(id: nil, key: makeKey(branch: "kept"), content: "k", at: created)
        let gone = try await store.save(id: nil, key: makeKey(branch: "gone"), content: "g", at: created)
        try await store.archive(id: gone.id, at: archivedAt)

        let everything = try await store.all(state: nil)
        let active = try await store.all(state: .active)
        let archived = try await store.all(state: .archived)
        XCTAssertEqual(Set(everything.map(\.id)), [kept.id, gone.id])
        XCTAssertEqual(active.map(\.id), [kept.id])
        XCTAssertEqual(archived.map(\.id), [gone.id])
    }

    // MARK: - Changes

    func testChangesYieldAfterAWrite() async throws {
        var iterator = store.changes.makeAsyncIterator()
        try await store.save(id: nil, key: makeKey(branch: "feature"), content: "x", at: created)
        let change: Void? = await iterator.next()
        XCTAssertNotNil(change)
    }

    // MARK: - Helpers

    private func makeKey(branch: String) -> NotationKey {
        NotationKey(
            projectID: projectID, projectName: "whippet", projectPath: "/tmp/whippet",
            branch: branch, forkPoint: "0123456789abcdef0123456789abcdef01234567")
    }
}
