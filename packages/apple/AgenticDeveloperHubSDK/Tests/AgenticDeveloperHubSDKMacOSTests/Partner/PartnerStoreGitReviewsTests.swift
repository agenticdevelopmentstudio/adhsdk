import XCTest
import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// `PartnerStore.reviews(repoPath:shas:)` and `PartnerGitReviews`, what the Git window reads
/// its reviews through. A scratch store in a temporary directory; never the live one.
final class PartnerStoreGitReviewsTests: XCTestCase {

    private var directory: URL!
    private var store: PartnerStore!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PartnerStoreGitReviewsTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        store = try PartnerStore(path: directory.appendingPathComponent("Partner.db").path)
    }

    override func tearDownWithError() throws {
        store = nil
        try? FileManager.default.removeItem(at: directory)
    }

    private func makeReview(_ id: String, sha: String, repo: String = "repo-a", path: String? = nil,
                            state: PartnerReviewState = .done) -> PartnerReview {
        PartnerReview(id: id, repoID: repo, repoPath: path ?? "/r/\(repo)", repoName: repo, sha: sha,
                      parent: "parent-\(id)", branch: "main", subject: "subject \(id)", author: "Ann",
                      committedAt: Date(timeIntervalSince1970: 1_000), state: state)
    }

    func testOnlyTheRepoPathsAskedForShasAreAnswered() throws {
        try store.insertReview(makeReview("a", sha: "s1"))
        try store.insertReview(makeReview("b", sha: "s2"))
        try store.insertReview(makeReview("c", sha: "s1", repo: "repo-b"))
        let found = try store.reviews(repoPath: "/r/repo-a", shas: ["s1", "s3"])
        XCTAssertEqual(Set(found.keys), ["s1"])
        XCTAssertEqual(found["s1"]?.id, "a")
        XCTAssertEqual(try store.reviews(repoPath: "/r/repo-a", shas: []), [:])
    }

    func testASupersededReviewIsReturned() throws {
        var superseded = makeReview("a", sha: "s1")
        superseded.supersededBy = ["s9"]
        try store.insertReview(superseded)
        try store.insertReview(makeReview("b", sha: "s2"))
        let found = try store.reviews(repoPath: "/r/repo-a", shas: ["s1", "s2"])
        XCTAssertEqual(Set(found.keys), ["s1", "s2"])
        XCTAssertEqual(found["s1"]?.id, "a")
        XCTAssertEqual(found["s1"]?.supersededBy, ["s9"])
    }

    func testTwoRepoIdsAtOnePathAnswerTheRowInsertedLastOnATie() throws {
        try store.insertReview(makeReview("old", sha: "s1", repo: "id-1", path: "/r/shared"))
        try store.insertReview(makeReview("new", sha: "s1", repo: "id-2", path: "/r/shared"))
        XCTAssertEqual(try store.reviews(repoPath: "/r/shared", shas: ["s1"])["s1"]?.id, "new")
    }

    func testARowReviewedAgainLaterWinsOverANewerInsert() throws {
        var old = makeReview("old", sha: "s1", repo: "id-1", path: "/r/shared")
        var new = makeReview("new", sha: "s1", repo: "id-2", path: "/r/shared")
        new.finishedAt = Date(timeIntervalSince1970: 2_000)
        try store.insertReview(old)
        try store.insertReview(new)
        // The older row is re-reviewed after the newer one finished; an UPDATE keeps its rowid.
        old.finishedAt = Date(timeIntervalSince1970: 3_000)
        try store.updateReview(old)
        XCTAssertEqual(try store.reviews(repoPath: "/r/shared", shas: ["s1"])["s1"]?.id, "old")
    }

    func testMoreShasThanOneChunkAreAllAsked() throws {
        try store.insertReview(makeReview("a", sha: "s-last"))
        let shas = (0..<1_200).map { "s-\($0)" } + ["s-last"]
        XCTAssertEqual(Set(try store.reviews(repoPath: "/r/repo-a", shas: shas).keys), ["s-last"])
    }

    func testTheAdapterMapsStateSummaryAndSkipReason() async throws {
        var done = makeReview("a", sha: "s1")
        done.summary = "Looks fine.\nDetails follow."
        var skipped = makeReview("b", sha: "s2", state: .skipped)
        skipped.skipReason = "Merge commit"
        try store.insertReview(done)
        try store.insertReview(skipped)
        let reviews = await PartnerGitReviews(store: store).reviews(repoPath: "/r/repo-a", shas: ["s1", "s2"])
        XCTAssertEqual(reviews["s1"], GitCommitReview(sha: "s1", state: .done, summary: "Looks fine.\nDetails follow.",
                                                      reviewID: "a"))
        XCTAssertEqual(reviews["s1"]?.summaryFirstLine, "Looks fine.")
        XCTAssertEqual(reviews["s2"]?.state, .skipped)
        XCTAssertEqual(reviews["s2"]?.skipReason, "Merge commit")
    }

    func testTheAdapterTicksOnAReviewWrite() async throws {
        let reviews = PartnerGitReviews(store: store)
        let stream = reviews.changes()
        let ticked = expectation(description: "tick")
        let listener = Task {
            for await _ in stream {
                ticked.fulfill()
                return
            }
        }
        try store.insertReview(makeReview("a", sha: "s1"))
        await fulfillment(of: [ticked], timeout: 2)
        listener.cancel()
    }
}
