import AppKit
import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

private struct DiffFailed: Error {}

/// A content source whose `diff` answers from `diffs` by commit id, like the model: it
/// records the request first and then awaits. A commit id in `holding` waits until a
/// test releases it, in any order; one in `failing` throws.
@MainActor
private final class FakeContentSource: GitContentSource {
    var diffs: [String: GitDiff] = [:]
    var holding: Set<String> = []
    var failing: Set<String> = []
    private(set) var requests: [(target: GitDiffTarget, options: GitDiffOptions)] = []
    private(set) var held: [String: CheckedContinuation<Void, Never>] = [:]

    func diff(_ target: GitDiffTarget, options: GitDiffOptions) async throws -> GitDiff {
        requests.append((target, options))
        guard case .commit(let id, _) = target else { return GitDiff(files: []) }
        if holding.contains(id) {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                MainActor.assumeIsolated { self.held[id] = continuation }
            }
        }
        if failing.contains(id) { throw DiffFailed() }
        return diffs[id] ?? GitDiff(files: [])
    }

    func release(_ id: String) {
        held.removeValue(forKey: id)?.resume()
    }

    func waitUntilHeld(_ id: String) async {
        while held[id] == nil { await Task.yield() }
    }

    func contents(path: String, at revision: String?) async throws -> Data? { nil }
    func blame(path: String, at revision: String?) async throws -> GitBlame { GitBlame(lines: [], commits: [:]) }
    func fileHistory(path: String) async throws -> [GitCommit] { [] }
    func commit(_ id: String) -> GitCommit? { nil }
}

@MainActor
private final class RecordingDetailDelegate: GitCommitDetailDelegate {
    enum Event: Equatable {
        case commit(String)
        case file(String?, commit: String)
    }
    private(set) var events: [Event] = []
    func commitDetail(_ detail: GitCommitDetailViewController, didSelectCommit id: String) {
        events.append(.commit(id))
    }
    func commitDetail(_ detail: GitCommitDetailViewController, didSelectFile file: GitFileListItem?,
                      in commit: GitCommit) {
        events.append(.file(file?.path, commit: commit.id))
    }
}

@Suite("GitCommitDetailViewController")
@MainActor
struct GitCommitDetailViewControllerTests {

    private static func sha(_ prefix: String) -> String {
        prefix + String(repeating: "0", count: 40 - prefix.count)
    }

    private static let authored = Date(timeIntervalSince1970: 1_790_000_000)
    private static let committed = Date(timeIntervalSince1970: 1_790_003_600)

    private static func commit(_ prefix: String, parents: [String] = [], subject: String = "subject",
                               body: String = "") -> GitCommit {
        GitCommit(id: sha(prefix), parents: parents.map(sha),
                  author: GitPerson(name: "Ann Lee", email: "ann@example.com", date: authored),
                  committer: GitPerson(name: "Bob Roe", email: "bob@example.com", date: committed),
                  subject: subject, body: body)
    }

    private static func file(_ path: String, _ change: GitFileDiff.Change = .modified,
                             from old: String? = nil) -> GitFileDiff {
        GitFileDiff(oldPath: old ?? (change == .added ? nil : path), newPath: path, change: change,
                    isBinary: false, hunks: [])
    }

    private static func paths(_ detail: GitCommitDetailViewController) -> [String] {
        detail.fileList.files.map(\.path)
    }

    private static func pasteboard() -> NSPasteboard {
        NSPasteboard(name: NSPasteboard.Name("git.detail.tests.\(UUID().uuidString)"))
    }

    private static func detail(_ source: FakeContentSource) -> GitCommitDetailViewController {
        let detail = GitCommitDetailViewController(source: source, pasteboard: pasteboard())
        detail.loadViewIfNeeded()
        return detail
    }

    @Test("the header shows the subject, body, people, dates, sha and parent links at once")
    func header() throws {
        let source = FakeContentSource()
        let detail = Self.detail(source)
        let commit = Self.commit("c1", parents: ["p1", "p2"], subject: "Fix it", body: "Line one\n\nLine two")
        detail.show(commit: commit)

        #expect(detail.view.accessibilityIdentifier() == "git.detail")
        #expect(detail.headerScrollView.accessibilityIdentifier() == "git.detail.header")
        #expect(detail.subjectLabel.stringValue == "Fix it")
        #expect(detail.subjectLabel.accessibilityIdentifier() == "git.detail.subject")
        #expect(detail.bodyLabel.stringValue == "Line one\n\nLine two")
        #expect(!detail.bodyLabel.isHidden)
        #expect(detail.bodyLabel.accessibilityIdentifier() == "git.detail.body")

        #expect(detail.authorRow.accessibilityIdentifier() == "git.detail.author")
        #expect(detail.authorRow.nameLabel.stringValue == "Ann Lee")
        #expect(detail.authorRow.emailLabel.stringValue == "<ann@example.com>")
        #expect(detail.authorRow.avatar.side == 28)
        #expect(detail.authorRow.avatar.content
                == AvatarContent(name: "Ann Lee", seed: "ann@example.com", imageURL: nil))
        #expect(detail.authorRow.dateLabel.stringValue
                == Self.authored.formatted(date: .abbreviated, time: .shortened))
        #expect(detail.authorRow.dateLabel.toolTip == RelativeDateFormatting.string(for: Self.authored))

        #expect(detail.committerRow.accessibilityIdentifier() == "git.detail.committer")
        #expect(detail.committerRow.nameLabel.stringValue == "Bob Roe")
        #expect(detail.committerRow.emailLabel.stringValue == "<bob@example.com>")
        #expect(detail.committerRow.avatar.content
                == AvatarContent(name: "Bob Roe", seed: "bob@example.com", imageURL: nil))
        #expect(detail.committerRow.dateLabel.stringValue
                == Self.committed.formatted(date: .abbreviated, time: .shortened))

        #expect(detail.shaLabel.stringValue == Self.sha("c1"))
        #expect(detail.shaLabel.accessibilityIdentifier() == "git.detail.sha")
        #expect(detail.copyButton.accessibilityIdentifier() == "git.detail.copySha")
        #expect(detail.copyButton.accessibilityLabel() == "Copy SHA")

        #expect(!detail.parentsRow.isHidden)
        #expect(detail.parentButtons.map(\.title) == ["p1000000", "p2000000"])
        #expect(detail.parentButtons.map { $0.accessibilityIdentifier() } == ["git.detail.parent", "git.detail.parent"])
        #expect(detail.parentButtons.map(\.toolTip) == [Self.sha("p1"), Self.sha("p2")])

        #expect(detail.fileList.view.accessibilityIdentifier() == "git.fileList.commit")
    }

    @Test("a root commit with an empty body hides the body and the parents row")
    func rootCommit() {
        let detail = Self.detail(FakeContentSource())
        detail.show(commit: Self.commit("c1", parents: ["p1"], body: "has body"))
        detail.show(commit: Self.commit("r0"))
        #expect(detail.bodyLabel.isHidden)
        #expect(detail.parentsRow.isHidden)
        #expect(detail.parentButtons.isEmpty)
    }

    @Test("copy puts the full sha on the pasteboard and a parent link reports its full sha")
    func copyAndParentLink() {
        let source = FakeContentSource()
        let board = Self.pasteboard()
        let detail = GitCommitDetailViewController(source: source, pasteboard: board)
        detail.loadViewIfNeeded()
        let delegate = RecordingDetailDelegate()
        detail.delegate = delegate
        board.clearContents()
        board.setString("stale", forType: .string)

        detail.show(commit: Self.commit("c1", parents: ["p1", "p2"]))
        detail.copyButton.performClick(nil)
        #expect(board.string(forType: .string) == Self.sha("c1"))

        detail.parentButtons[1].performClick(nil)
        #expect(delegate.events == [.commit(Self.sha("p2"))])
    }

    @Test("the files come from the commit's diff with default options, and selecting one reports it")
    func filesAndSelection() async throws {
        let source = FakeContentSource()
        let commit = Self.commit("c1")
        source.diffs[commit.id] = GitDiff(files: [
            Self.file("a.swift"),
            Self.file("b", .renamed(similarity: 90), from: "a")
        ])
        let detail = Self.detail(source)
        let delegate = RecordingDetailDelegate()
        detail.delegate = delegate

        detail.show(commit: commit)
        await detail.loadTask?.value

        let request = try #require(source.requests.first)
        #expect(source.requests.count == 1)
        #expect(request.target == .commit(commit.id, paths: []))
        #expect(request.options == GitDiffOptions())
        #expect(detail.fileList.files == [
            GitFileListItem(path: "a.swift", oldPath: nil, status: .modified),
            GitFileListItem(path: "b", oldPath: "a", status: .renamed)
        ])

        detail.fileList.tableView.selectRowIndexes(IndexSet(integer: 1), byExtendingSelection: false)
        #expect(delegate.events == [.file("b", commit: commit.id)])
        detail.fileList.tableView.deselectAll(nil)
        #expect(delegate.events == [.file("b", commit: commit.id), .file(nil, commit: commit.id)])
    }

    @Test("a newer show wins when the older diff finishes after it")
    func latestWinsOlderFinishesLast() async {
        let source = FakeContentSource()
        let first = Self.commit("aa"), second = Self.commit("bb")
        source.diffs = [first.id: GitDiff(files: [Self.file("from-a")]),
                        second.id: GitDiff(files: [Self.file("from-b")])]
        source.holding = [first.id]
        let detail = Self.detail(source)

        detail.show(commit: first)
        let taskA = detail.loadTask
        await source.waitUntilHeld(first.id)
        detail.show(commit: second)
        await detail.loadTask?.value
        #expect(Self.paths(detail) == ["from-b"])

        source.release(first.id)
        await taskA?.value
        #expect(Self.paths(detail) == ["from-b"])
        #expect(detail.subjectLabel.stringValue == second.subject)
    }

    @Test("a newer show wins when both are held and the newer is released first")
    func latestWinsBothHeld() async {
        let source = FakeContentSource()
        let first = Self.commit("aa"), second = Self.commit("bb")
        source.diffs = [first.id: GitDiff(files: [Self.file("from-a")]),
                        second.id: GitDiff(files: [Self.file("from-b")])]
        source.holding = [first.id, second.id]
        let detail = Self.detail(source)

        detail.show(commit: first)
        let taskA = detail.loadTask
        await source.waitUntilHeld(first.id)
        detail.show(commit: second)
        let taskB = detail.loadTask
        await source.waitUntilHeld(second.id)

        source.release(second.id)
        await taskB?.value
        #expect(Self.paths(detail) == ["from-b"])
        source.release(first.id)
        await taskA?.value
        #expect(Self.paths(detail) == ["from-b"])
    }

    @Test("a different commit empties the list at once, the same commit keeps it until its diff arrives")
    func emptiesOnChange() async {
        let source = FakeContentSource()
        let first = Self.commit("aa"), second = Self.commit("bb")
        source.diffs = [first.id: GitDiff(files: [Self.file("from-a")]),
                        second.id: GitDiff(files: [Self.file("from-b")])]
        let detail = Self.detail(source)

        detail.show(commit: first)
        await detail.loadTask?.value
        #expect(Self.paths(detail) == ["from-a"])

        source.holding = [first.id, second.id]
        detail.show(commit: first)
        await source.waitUntilHeld(first.id)
        #expect(Self.paths(detail) == ["from-a"])

        detail.show(commit: second)
        await source.waitUntilHeld(second.id)
        #expect(Self.paths(detail).isEmpty)
        #expect(detail.subjectLabel.stringValue == second.subject)
        source.release(first.id)
        source.release(second.id)
        await detail.loadTask?.value
        #expect(Self.paths(detail) == ["from-b"])
    }

    @Test("show(nil) empties the header and list, and a diff released afterwards changes nothing")
    func clear() async {
        let source = FakeContentSource()
        let first = Self.commit("aa", parents: ["p1"], body: "body"), second = Self.commit("bb")
        source.diffs = [first.id: GitDiff(files: [Self.file("from-a")]),
                        second.id: GitDiff(files: [Self.file("from-b")])]
        let detail = Self.detail(source)

        detail.show(commit: first)
        await detail.loadTask?.value
        source.holding = [second.id]
        detail.show(commit: second)
        let taskB = detail.loadTask
        await source.waitUntilHeld(second.id)
        #expect(Self.paths(detail).isEmpty)

        detail.show(commit: nil)
        #expect(detail.subjectLabel.stringValue.isEmpty)
        #expect(detail.bodyLabel.isHidden)
        #expect(detail.shaLabel.stringValue.isEmpty)
        #expect(detail.authorRow.nameLabel.stringValue.isEmpty)
        #expect(detail.authorRow.avatar.content == nil)
        #expect(detail.parentsRow.isHidden)
        #expect(detail.copyButton.isHidden)
        #expect(detail.headerStack.isHidden)
        #expect(detail.loadTask == nil)

        source.release(second.id)
        await taskB?.value
        #expect(Self.paths(detail).isEmpty)
    }

    @Test("a diff that throws leaves the header and an empty list")
    func diffThrows() async {
        let source = FakeContentSource()
        let first = Self.commit("aa")
        source.failing = [first.id]
        let detail = Self.detail(source)
        detail.show(commit: first)
        await detail.loadTask?.value
        #expect(detail.subjectLabel.stringValue == first.subject)
        #expect(Self.paths(detail).isEmpty)
    }

    @Test("a file selection that a new commit removes reports nil for the old commit")
    func selectionClearedByNewCommit() async {
        let source = FakeContentSource()
        let first = Self.commit("aa"), second = Self.commit("bb")
        source.diffs = [first.id: GitDiff(files: [Self.file("x")]), second.id: GitDiff(files: [Self.file("y")])]
        let detail = Self.detail(source)
        let delegate = RecordingDetailDelegate()
        detail.delegate = delegate

        detail.show(commit: first)
        await detail.loadTask?.value
        detail.fileList.tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        detail.show(commit: second)
        await detail.loadTask?.value
        #expect(delegate.events == [.file("x", commit: first.id), .file(nil, commit: first.id)])
    }
}
