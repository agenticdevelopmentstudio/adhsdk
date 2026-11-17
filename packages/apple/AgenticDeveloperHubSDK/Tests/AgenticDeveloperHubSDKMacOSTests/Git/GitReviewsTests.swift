import AppKit
import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// A history source holding fixed reviews and recording every review request.
@MainActor
private final class ReviewHistorySource: GitHistoryDataSource {
    var commits: [GitCommit] = []
    var graphRows: [CommitGraphLayout<String>.Row] = []
    var query = GitLogQuery()
    var headCommit: String?
    var operationState: GitOperationState = .none
    var reviews: [String: GitCommitReview] = [:]
    private(set) var reviewRequests: [[String]] = []

    func setQuery(_ query: GitLogQuery) async { self.query = query }
    func loadMore() async {}
    func refs(at commitID: String) -> [GitRef] { [] }
    func review(for sha: String) -> GitCommitReview? { reviews[sha] }
    func requestReviews(for shas: [String]) { reviewRequests.append(shas) }
}

/// Reviews from a table a test changes, with a change stream the test ticks. Never a
/// Partner store: the window only reads through this protocol.
private final class FakeReviews: GitReviewsProviding, @unchecked Sendable {
    private let lock = NSLock()
    private var table: [String: GitCommitReview] = [:]
    private var asked: [[String]] = []
    private let stream: AsyncStream<Void>
    private let continuation: AsyncStream<Void>.Continuation

    init() {
        (stream, continuation) = AsyncStream<Void>.makeStream()
    }

    func set(_ review: GitCommitReview) { lock.withLock { table[review.sha] = review } }
    var batches: [[String]] { lock.withLock { asked } }
    func tick() { continuation.yield() }

    func reviews(repoPath: String, shas: [String]) async -> [String: GitCommitReview] {
        lock.withLock {
            asked.append(shas)
            return table.filter { shas.contains($0.key) }
        }
    }

    func changes() -> AsyncStream<Void> { stream }
}

private final class QuietWatcher: GitRepositoryWatching {
    func start(onChange: @escaping @Sendable (Set<GitRepositoryChange>) -> Void) {}
    func stop() {}
}

/// Coding Partner reviews in the Git window (recipe `workspace/git/git-views`, "Reviews";
/// `workspace/git/git-window`, "Reviews").
@Suite("Git window reviews", .serialized)
@MainActor
struct GitReviewsTests {
    private static let date = Date(timeIntervalSince1970: 1_800_000_000)

    private static func sha(_ prefix: String) -> String {
        prefix + String(repeating: "0", count: 40 - prefix.count)
    }

    private static func commit(_ id: String) -> GitCommit {
        let person = GitPerson(name: "Ann Lee", email: "ann@example.com", date: date)
        return GitCommit(id: id, parents: [], author: person, committer: person, subject: "subject", body: "")
    }

    private static func review(_ sha: String, _ state: GitCommitReview.State, summary: String? = nil,
                               skipReason: String? = nil) -> GitCommitReview {
        GitCommitReview(sha: sha, state: state, summary: summary, skipReason: skipReason, reviewID: "repo:\(sha)")
    }

    private func subjectCell(_ history: GitHistoryViewController, row: Int) -> GitHistorySubjectCellView? {
        let table = history.tableView
        let column = table.tableColumns.first { $0.identifier.rawValue == "subject" }
        return history.tableView(table, viewFor: column, row: row) as? GitHistorySubjectCellView
    }

    // MARK: History badges

    @Test("a badge per review state, with the summary's first line as tooltip; none when skipped or absent")
    func historyBadges() throws {
        let source = ReviewHistorySource()
        let ids = ["aa", "bb", "cc", "dd", "ee", "ff"].map(Self.sha)
        source.commits = ids.map(Self.commit)
        source.graphRows = ids.map { _ in CommitGraphLayout<String>.Row(column: 0, lane: 0, top: [], bottom: [],
                                                                         width: 1) }
        source.reviews[ids[0]] = Self.review(ids[0], .done, summary: "\n  Looks fine.  \nMore.")
        source.reviews[ids[1]] = Self.review(ids[1], .running)
        source.reviews[ids[2]] = Self.review(ids[2], .queued)
        source.reviews[ids[3]] = Self.review(ids[3], .failed)
        source.reviews[ids[4]] = Self.review(ids[4], .skipped, skipReason: "Merge commit")
        let history = GitHistoryViewController(source: source)
        history.loadViewIfNeeded()

        let done = try #require(subjectCell(history, row: 0))
        #expect(!done.reviewView.isHidden)
        #expect(done.reviewView.accessibilityIdentifier() == "git.history.review")
        #expect(done.reviewView.symbolName == "text.magnifyingglass")
        #expect(done.reviewView.role == .accent)
        #expect(done.reviewView.toolTip == "Looks fine.")
        #expect(done.reviewView.accessibilityLabel() == "Looks fine.")

        let running = try #require(subjectCell(history, row: 1))
        #expect(running.reviewView.symbolName == "hourglass")
        #expect(running.reviewView.toolTip == "Running")
        let queued = try #require(subjectCell(history, row: 2))
        #expect(queued.reviewView.symbolName == "hourglass")
        #expect(queued.reviewView.role == .secondaryText)
        let failed = try #require(subjectCell(history, row: 3))
        #expect(failed.reviewView.symbolName == "xmark.octagon")
        #expect(failed.reviewView.role == .danger)
        #expect(failed.reviewView.toolTip == "Failed")

        let skipped = try #require(subjectCell(history, row: 4))
        #expect(skipped.reviewBadge == nil)
        #expect(skipped.reviewView.isHidden)
        let none = try #require(subjectCell(history, row: 5))
        #expect(none.reviewBadge == nil)
        #expect(none.reviewView.isHidden)
    }

    @Test("reload asks the source for the reviews of the rows on screen, and only those")
    func historyRequests() {
        let source = ReviewHistorySource()
        source.commits = (0..<200).map { Self.commit(Self.sha(String(format: "c%03d", $0))) }
        source.graphRows = source.commits.map { _ in
            CommitGraphLayout<String>.Row(column: 0, lane: 0, top: [], bottom: [], width: 1)
        }
        let history = GitHistoryViewController(source: source)
        history.view.frame = NSRect(x: 0, y: 0, width: 800, height: 240)
        history.view.layoutSubtreeIfNeeded()
        history.reload()

        let visible = history.visibleCommitIDs
        #expect(!visible.isEmpty)
        #expect(visible.count < 200)
        #expect(source.reviewRequests.last == visible)
    }

    // MARK: Detail section

    private static func detail() -> GitCommitDetailViewController {
        let detail = GitCommitDetailViewController(source: GitViewsFakeContentSource(),
                                                   pasteboard: NSPasteboard(name: .init("git.review.\(UUID())")))
        detail.loadViewIfNeeded()
        return detail
    }

    @Test("the Review section shows the state and summary after Agent Sessions, and opens the review")
    func detailSection() {
        let detail = Self.detail()
        detail.reviewLookup = { commit in
            commit.id == "c1" ? Self.review("c1", .done, summary: "Looks fine.\nOne nit.") : nil
        }
        detail.show(commit: Self.commit("c1"))
        let section = detail.reviewView
        #expect(!section.isHidden)
        #expect(section.accessibilityIdentifier() == "git.commit.review")
        #expect(section.caption.stringValue == "Review")
        #expect(section.stateLabel.stringValue == "Done")
        #expect(section.symbolView.symbolName == "text.magnifyingglass")
        #expect(section.summaryLabel.stringValue == "Looks fine.\nOne nit.")
        #expect(section.openButton.isHidden)

        let arranged = detail.headerStack.arrangedSubviews
        let sessions = arranged.firstIndex { $0 === detail.agentSessionsView }
        #expect(sessions.map { $0 + 1 } == arranged.firstIndex { $0 === section })

        var opened: [String] = []
        detail.onOpenReview = { opened.append($0) }
        #expect(!section.openButton.isHidden)
        section.openButton.performClick(nil)
        #expect(opened == ["repo:c1"])
    }

    @Test("a skipped review shows its reason; no lookup, or no review, hides the section")
    func detailSkippedAndAbsent() {
        let detail = Self.detail()
        detail.show(commit: Self.commit("c1"))
        #expect(detail.reviewView.isHidden)
        detail.reviewLookup = { _ in nil }
        #expect(detail.reviewView.isHidden)
        detail.reviewLookup = { _ in Self.review("c1", .skipped, skipReason: "Merge commit") }
        #expect(!detail.reviewView.isHidden)
        #expect(detail.reviewView.stateLabel.stringValue == "Skipped")
        #expect(detail.reviewView.symbolView.symbolName == "minus.circle")
        #expect(detail.reviewView.summaryLabel.stringValue == "Merge commit")
        detail.show(commit: nil)
        #expect(detail.reviewView.isHidden)
    }

    // MARK: Session wiring

    private let client = GitClient(configuration: .default)

    private func window(_ repository: GitTestRepository, reviews: (any GitReviewsProviding)?) async
        -> GitWindowSession {
        let model = GitRepositoryModel(root: repository.root, client: client, watcher: QuietWatcher(),
                                       reviews: reviews)
        let session = GitWindowSession(model: model, client: client, coloring: nil)
        await session.start()
        return session
    }

    @Test("without a provider nothing is wired and every review is nil")
    func noProvider() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-window-reviews")
        defer { repository.tearDown() }
        let session = await window(repository, reviews: nil)
        #expect(session.model.reviewLoader == nil)
        #expect(session.detail.reviewLookup == nil)
        #expect(session.reviewChangesTask == nil)
        session.onOpenReview = { _ in }
        #expect(session.detail.onOpenReview == nil)
        session.stop()
    }

    @Test("a change tick reads the shown commit's review again, so a finished review replaces a queued one")
    func changeTickRerequests() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-window-reviews")
        defer { repository.tearDown() }
        try repository.write("one\n", to: "a.txt")
        try await repository.run(["add", "a.txt"])
        try await repository.commit("first", at: 1_800_000_000)
        let head = try await repository.sha("HEAD")

        let reviews = FakeReviews()
        reviews.set(Self.review(head, .queued))
        let session = await window(repository, reviews: reviews)
        defer { session.stop() }
        let loader = try #require(session.model.reviewLoader)
        loader.delay = .milliseconds(20)
        var opened: [String] = []
        session.onOpenReview = { opened.append($0) }
        #expect(session.detail.onOpenReview != nil)

        let commit = try #require(session.model.commit(head))
        session.detail.show(commit: commit)
        await loader.queueTask?.value
        await loader.loadTask?.value
        #expect(session.model.review(for: head)?.state == .queued)
        #expect(session.detail.reviewView.stateLabel.stringValue == "Queued")

        reviews.set(Self.review(head, .done, summary: "Fine."))
        reviews.tick()
        // The tick reaches the session through its listening task; wait for the re-read.
        for _ in 0..<100 where session.model.review(for: head)?.state != .done {
            try await Task.sleep(for: .milliseconds(10))
            await loader.queueTask?.value
            await loader.loadTask?.value
        }
        #expect(session.model.review(for: head)?.state == .done)
        #expect(session.detail.reviewView.stateLabel.stringValue == "Done")
        #expect(reviews.batches.count >= 2)
        session.detail.reviewView.openButton.performClick(nil)
        #expect(opened == ["repo:\(head)"])
    }

    @Test("a review batch posts .annotations alone: the rows redraw, the reflog is not read again")
    func batchPostsAnnotationsOnly() async throws {
        let repository = try await GitTestRepository.make(prefix: "git-window-reviews")
        defer { repository.tearDown() }
        try repository.write("one\n", to: "a.txt")
        try await repository.run(["add", "a.txt"])
        try await repository.commit("first", at: 1_800_000_000)
        let head = try await repository.sha("HEAD")

        let reviews = FakeReviews()
        reviews.set(Self.review(head, .queued))
        let session = await window(repository, reviews: reviews)
        defer { session.stop() }
        let loader = try #require(session.model.reviewLoader)
        loader.delay = .milliseconds(1)
        await loader.queueTask?.value
        await loader.loadTask?.value
        session.sidebarDidSelectReflog(session.sidebar)
        await session.reflogLoadTask?.value
        let reflogRead = session.reflogLoadTask
        var posted: [Set<GitRepositoryChange>] = []
        let observation = session.model.observe { posted.append($0) }

        // A changed review, read whether or not the window's first batch already read it.
        reviews.set(Self.review(head, .done, summary: "Fine."))
        session.model.invalidateReviews()
        session.model.requestReview(for: head)
        await loader.queueTask?.value
        await loader.loadTask?.value

        #expect(session.model.review(for: head)?.state == .done)
        #expect(posted == [[.annotations]])
        #expect(session.reflogLoadTask == reflogRead)
        withExtendedLifetime(observation) {}
    }
}
