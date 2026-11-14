import AppKit
import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// A history data source whose lists a test sets directly, recording what the view asks of it.
@MainActor
private final class FakeHistorySource: GitHistoryDataSource {
    var commits: [GitCommit] = []
    var graphRows: [CommitGraphLayout<String>.Row] = []
    var query = GitLogQuery()
    var refsByCommit: [String: [GitRef]] = [:]

    private(set) var setQueries: [GitLogQuery] = []
    private(set) var loadMoreCount = 0
    /// Appended by the next `loadMore`, if set.
    var nextPage: [GitCommit] = []

    /// While set, `setQuery` waits until `releaseHeld()`.
    var holdsSetQuery = false
    private(set) var held: [CheckedContinuation<Void, Never>] = []

    func setQuery(_ query: GitLogQuery) async {
        self.query = query
        setQueries.append(query)
        if holdsSetQuery {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                MainActor.assumeIsolated { self.held.append(continuation) }
            }
        }
    }

    func releaseHeld() {
        let waiting = held
        held = []
        for continuation in waiting { continuation.resume() }
    }

    func loadMore() async {
        loadMoreCount += 1
        commits += nextPage
        graphRows += nextPage.map { _ in GitHistoryViewControllerTests.row(width: 1) }
        nextPage = []
    }

    func refs(at commitID: String) -> [GitRef] { refsByCommit[commitID] ?? [] }
}

/// Records every delegate call in order: the selected commit's id, or nil.
@MainActor
private final class RecordingHistoryDelegate: GitHistoryDelegate {
    private(set) var events: [String?] = []
    func history(_ history: GitHistoryViewController, didSelect commit: GitCommit?) { events.append(commit?.id) }
}

@Suite("GitHistoryViewController")
@MainActor
struct GitHistoryViewControllerTests {

    nonisolated static func row(width: Int) -> CommitGraphLayout<String>.Row {
        CommitGraphLayout<String>.Row(column: 0, lane: 0, top: [], bottom: [], width: width)
    }

    /// A 40-character sha starting with `prefix`.
    private static func sha(_ prefix: String) -> String {
        prefix + String(repeating: "0", count: 40 - prefix.count)
    }

    private static let now = Date()

    private static func commit(_ prefix: String, subject: String = "subject", author: String = "Ann Lee",
                               age: TimeInterval = 3600) -> GitCommit {
        let person = GitPerson(name: author, email: "\(author.lowercased())@example.com",
                               date: now.addingTimeInterval(-age))
        return GitCommit(id: sha(prefix), parents: [], author: person, committer: person, subject: subject, body: "")
    }

    private static func ref(_ kind: GitRef.Kind, _ name: String, at prefix: String) -> GitRef {
        let full: String
        switch kind {
        case .localBranch: full = "refs/heads/\(name)"
        case .remoteBranch: full = "refs/remotes/\(name)"
        case .tag: full = "refs/tags/\(name)"
        }
        return GitRef(kind: kind, fullName: full, name: name, target: sha(prefix),
                      upstream: nil, ahead: 0, behind: 0, isHead: false)
    }

    private static func source(count: Int) -> FakeHistorySource {
        let source = FakeHistorySource()
        source.commits = (0..<count).map { commit(String(format: "c%03d", $0), subject: "commit \($0)") }
        source.graphRows = source.commits.map { _ in row(width: 1) }
        return source
    }

    private func cell<T: NSView>(_ history: GitHistoryViewController, _ column: String, row: Int) -> T? {
        let table = history.tableView
        let tableColumn = table.tableColumns.first { $0.identifier.rawValue == column }
        return history.tableView(table, viewFor: tableColumn, row: row) as? T
    }

    @Test("rows come from the source, one per commit, with each column filled")
    func rowsFromSource() throws {
        let source = FakeHistorySource()
        source.commits = [
            Self.commit("aa11", subject: "Fix the thing", author: "Ann Lee", age: 3 * 3600),
            Self.commit("bb22", subject: "Second"),
            Self.commit("cc33", subject: "Third")
        ]
        source.graphRows = [Self.row(width: 1), Self.row(width: 2), Self.row(width: 1)]
        let history = GitHistoryViewController(source: source)
        history.loadViewIfNeeded()

        #expect(history.view.accessibilityIdentifier() == "git.history")
        #expect(history.tableView.accessibilityIdentifier() == "git.history.table")
        #expect(history.numberOfRows(in: history.tableView) == 3)
        #expect(history.tableView.tableColumns.map(\.identifier.rawValue)
                == ["graph", "subject", "author", "date", "sha"])

        let graph: CommitGraphCellView = try #require(cell(history, "graph", row: 1))
        #expect(graph.row == Self.row(width: 2))

        let subject: GitHistorySubjectCellView = try #require(cell(history, "subject", row: 0))
        #expect(subject.subjectLabel.stringValue == "Fix the thing")
        #expect(subject.accessibilityIdentifier() == "git.history.subject")

        let author: GitHistoryAuthorCellView = try #require(cell(history, "author", row: 0))
        #expect(author.nameLabel.stringValue == "Ann Lee")
        #expect(author.avatar.side == 18)
        #expect(author.avatar.content == AvatarContent(name: "Ann Lee", seed: "ann lee@example.com", imageURL: nil))
        #expect(author.accessibilityIdentifier() == "git.history.author")

        let date: NSTextField = try #require(cell(history, "date", row: 0))
        let authored = source.commits[0].author.date
        #expect(date.stringValue == RelativeDateFormatting.string(for: authored))
        #expect(date.toolTip == authored.formatted(date: .abbreviated, time: .shortened))
        #expect(date.accessibilityIdentifier() == "git.history.date")

        let sha: NSTextField = try #require(cell(history, "sha", row: 0))
        #expect(sha.stringValue == "aa110000")
        #expect(sha.accessibilityIdentifier() == "git.history.sha")
    }

    @Test("the graph column is as wide as the widest loaded row, at least one column")
    func graphWidth() {
        let source = Self.source(count: 2)
        source.graphRows = [Self.row(width: 1), Self.row(width: 3)]
        let history = GitHistoryViewController(source: source)
        history.loadViewIfNeeded()
        let column = history.tableView.tableColumns[0]
        #expect(column.width == 3 * CommitGraphCellView.columnWidth)

        source.commits = []
        source.graphRows = []
        history.reload()
        #expect(column.width == CommitGraphCellView.columnWidth)
    }

    @Test("ref badges per row: local, remote, tag in that order, each styled by kind")
    func refBadges() throws {
        let source = FakeHistorySource()
        source.commits = [Self.commit("aa11"), Self.commit("bb22")]
        source.graphRows = [Self.row(width: 1), Self.row(width: 1)]
        source.refsByCommit[Self.sha("aa11")] = [
            Self.ref(.tag, "v1", at: "aa11"),
            Self.ref(.remoteBranch, "origin/main", at: "aa11"),
            Self.ref(.localBranch, "main", at: "aa11"),
            Self.ref(.localBranch, "dev", at: "aa11")
        ]
        let history = GitHistoryViewController(source: source)
        history.loadViewIfNeeded()

        let first: GitHistorySubjectCellView = try #require(cell(history, "subject", row: 0))
        #expect(first.badges == [
            GitHistoryRefBadge(title: "main", kind: .localBranch),
            GitHistoryRefBadge(title: "dev", kind: .localBranch),
            GitHistoryRefBadge(title: "origin/main", kind: .remoteBranch),
            GitHistoryRefBadge(title: "v1", kind: .tag)
        ])
        #expect(first.badgeViews.map { $0.accessibilityIdentifier() } == [
            "git.history.badge.local", "git.history.badge.local", "git.history.badge.remote", "git.history.badge.tag"
        ])
        #expect(first.badges.map(\.style) == [.filled, .filled, .outlined, .outlined])
        #expect(first.badges.map(\.role) == [.accent, .accent, .accent, .warning])

        let second: GitHistorySubjectCellView = try #require(cell(history, "subject", row: 1))
        #expect(second.badges.isEmpty)
        #expect(second.badgeViews.isEmpty)
    }

    @Test("paging: a row in the last 50 asks for more once, not again until the count changes")
    func pagingTrigger() async {
        let source = Self.source(count: 120)
        let history = GitHistoryViewController(source: source)
        history.loadViewIfNeeded()

        history.rowWillAppear(69)
        await history.pagingTask?.value
        #expect(source.loadMoreCount == 0)

        history.rowWillAppear(70)
        await history.pagingTask?.value
        #expect(source.loadMoreCount == 1)

        // The count did not change: the end of the history does not loop.
        history.rowWillAppear(71)
        await history.pagingTask?.value
        history.rowWillAppear(119)
        await history.pagingTask?.value
        #expect(source.loadMoreCount == 1)

        source.nextPage = (120..<130).map { Self.commit(String(format: "d%03d", $0)) }
        source.commits.removeLast() // a refresh changed the count
        history.reload()
        history.rowWillAppear(100)
        await history.pagingTask?.value
        #expect(source.loadMoreCount == 2)
        #expect(history.numberOfRows(in: history.tableView) == 129)
    }

    @Test("paging: a new query pages again even when its first page is the same size")
    func pagingAfterQueryChange() async {
        let source = Self.source(count: 120)
        let history = GitHistoryViewController(source: source)
        history.loadViewIfNeeded()

        history.rowWillAppear(70)
        await history.pagingTask?.value
        #expect(source.loadMoreCount == 1)

        await history.setQuery("author:Ann")
        history.rowWillAppear(70)
        await history.pagingTask?.value
        #expect(source.loadMoreCount == 2)
    }

    @Test("a short history asks for more from its first visible row")
    func pagingShortHistory() async {
        let source = Self.source(count: 3)
        let history = GitHistoryViewController(source: source)
        history.loadViewIfNeeded()
        history.rowWillAppear(0)
        await history.pagingTask?.value
        #expect(source.loadMoreCount == 1)
    }

    @Test("selection reports the commit; reload keeps a surviving one silently and clears a removed one")
    func selectionAndReload() {
        let source = Self.source(count: 3)
        let delegate = RecordingHistoryDelegate()
        let history = GitHistoryViewController(source: source)
        history.delegate = delegate
        history.loadViewIfNeeded()

        history.tableView.selectRowIndexes(IndexSet(integer: 1), byExtendingSelection: false)
        #expect(delegate.events == [Self.sha("c001")])

        source.commits.insert(Self.commit("new0"), at: 0)
        source.graphRows.insert(Self.row(width: 1), at: 0)
        history.reload()
        #expect(delegate.events == [Self.sha("c001")])
        #expect(history.tableView.selectedRow == 2)

        source.commits.removeAll { $0.id == Self.sha("c001") }
        source.graphRows.removeLast()
        history.reload()
        #expect(delegate.events == [Self.sha("c001"), nil])
        #expect(history.tableView.selectedRow == -1)

        // Nothing selected: a reload stays silent.
        history.reload()
        #expect(delegate.events == [Self.sha("c001"), nil])
    }

    @Test("select(commitID:) selects a loaded commit and reports it; an unknown id changes nothing")
    func selectCommitID() {
        let source = Self.source(count: 3)
        let delegate = RecordingHistoryDelegate()
        let history = GitHistoryViewController(source: source)
        history.delegate = delegate
        history.loadViewIfNeeded()

        history.select(commitID: Self.sha("c002"))
        #expect(history.tableView.selectedRow == 2)
        #expect(delegate.events == [Self.sha("c002")])

        history.select(commitID: Self.sha("zzzz"))
        #expect(history.tableView.selectedRow == 2)
        #expect(delegate.events == [Self.sha("c002")])

        history.tableView.deselectAll(nil)
        #expect(delegate.events == [Self.sha("c002"), nil])
    }

    @Test("setQuery: sha: selects a loaded match without replacing the query; other forms reach the source")
    func setQuery() async {
        let source = Self.source(count: 3)
        let delegate = RecordingHistoryDelegate()
        let history = GitHistoryViewController(source: source)
        history.delegate = delegate
        history.loadViewIfNeeded()

        await history.setQuery("sha:C001")
        #expect(source.setQueries.isEmpty)
        #expect(history.tableView.selectedRow == 1)
        #expect(delegate.events == [Self.sha("c001")])

        await history.setQuery("sha:ffff")
        #expect(history.tableView.selectedRow == 1)
        #expect(delegate.events == [Self.sha("c001")])

        await history.setQuery("author:Ann")
        var expected = GitLogQuery()
        expected.author = "Ann"
        #expect(source.setQueries == [expected])

        await history.setQuery("")
        #expect(source.setQueries == [expected, GitLogQuery()])
    }

    @Test("setQuery: a search overtaken by a later one does not select")
    func setQueryOvertaken() async {
        let source = Self.source(count: 3)
        source.query.author = "Someone"
        let delegate = RecordingHistoryDelegate()
        let history = GitHistoryViewController(source: source)
        history.delegate = delegate
        history.loadViewIfNeeded()

        // The sha: search replaces the author filter, and the source holds it there.
        source.holdsSetQuery = true
        let first = Task { await history.setQuery("sha:c001") }
        while source.held.isEmpty { await Task.yield() }
        source.holdsSetQuery = false
        await history.setQuery("author:Ann")
        source.releaseHeld()
        await first.value
        #expect(delegate.events.isEmpty)
        #expect(history.tableView.selectedRow == -1)
    }
}
