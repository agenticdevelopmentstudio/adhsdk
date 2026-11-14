import AppKit
import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKLanguage
@testable import AgenticDeveloperHubSDKMacOS

@MainActor
private final class RecordingBlameDelegate: GitBlameDelegate {
    private(set) var selected: [String] = []
    func blame(_ blame: GitBlameViewController, didSelectCommit id: String) {
        selected.append(id)
    }
}

@Suite("GitBlameViewController")
@MainActor
struct GitBlameViewControllerTests {

    private static func sha(_ prefix: String) -> String {
        prefix + String(repeating: "0", count: 40 - prefix.count)
    }

    private static let uncommitted = String(repeating: "0", count: 40)
    private static let date = Date(timeIntervalSince1970: 1_790_000_000)

    private static func day(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private static func commit(_ id: String, _ name: String, _ email: String) -> GitBlame.Commit {
        GitBlame.Commit(id: id, author: GitPerson(name: name, email: email, date: date), summary: "s", previous: nil)
    }

    /// Recipe vector 051: lines 1–2 from c1, line 3 from c2, line 4 from c1, line 5 uncommitted.
    private static func blame() -> GitBlame {
        let first = sha("c1"), second = sha("c2")
        return GitBlame(lines: [
            GitBlame.Line(commitID: first, originalLine: 1, finalLine: 1, text: "let a = 1"),
            GitBlame.Line(commitID: first, originalLine: 2, finalLine: 2, text: "let b = 2"),
            GitBlame.Line(commitID: second, originalLine: 3, finalLine: 3, text: "let c = 3"),
            GitBlame.Line(commitID: first, originalLine: 3, finalLine: 4, text: "let d = 4"),
            GitBlame.Line(commitID: uncommitted, originalLine: 5, finalLine: 5, text: "let e = 5")
        ], commits: [
            first: commit(first, "Ann Lee", "ann@example.com"),
            second: commit(second, "Bob Roe", "bob@example.com"),
            uncommitted: commit(uncommitted, "Not Committed Yet", "not.committed.yet")
        ])
    }

    private static func controller(_ source: GitViewsFakeContentSource,
                                   coloring: GitSyntaxColoring? = nil) -> GitBlameViewController {
        let controller = GitBlameViewController(source: source, coloring: coloring)
        controller.loadViewIfNeeded()
        return controller
    }

    private static func rows(_ controller: GitBlameViewController) -> [LineViewerRow] {
        guard let source = controller.viewer.dataSource else { return [] }
        return (0..<source.rowCount).map(source.row(at:))
    }

    @Test("the view and viewer carry their identifiers")
    func identifiers() {
        let controller = Self.controller(GitViewsFakeContentSource())
        #expect(controller.view.accessibilityIdentifier() == "git.blame")
        #expect(controller.viewer.scrollView.accessibilityIdentifier() == "git.blame.lines")
        #expect(controller.errorLabel.accessibilityIdentifier() == "git.blame.error")
        #expect(controller.errorLabel.isHidden)
    }

    @Test("the gutter shows sha, initials and date on the first line of each run")
    func gutters() async throws {
        let source = GitViewsFakeContentSource()
        source.blames["a.swift@c9"] = Self.blame()
        let controller = Self.controller(source)
        controller.show(path: "a.swift", at: "c9")
        await controller.loadTask?.value

        #expect(source.blameRequests == ["a.swift@c9"])
        let rows = Self.rows(controller)
        let day = Self.day(Self.date)
        #expect(rows.map(\.text) == ["let a = 1", "let b = 2", "let c = 3", "let d = 4", "let e = 5"])
        #expect(rows.map(\.gutter) == [["c1000000", "AL", day], [], ["c2000000", "BR", day],
                                       ["c1000000", "AL", day], ["00000000", "NC", day]])
        let model = try #require(controller.viewer.dataSource)
        #expect(model.gutterColumnCount == 3)
        #expect(model.gutterColumnWidth(0) == 8)
        #expect(model.gutterColumnWidth(1) == 2)
        #expect(model.gutterColumnWidth(2) == 10)
    }

    @Test("a sha click selects that row's commit; an uncommitted row selects nothing")
    func selectCommit() async {
        let source = GitViewsFakeContentSource()
        source.blames["a.swift@"] = Self.blame()
        let controller = Self.controller(source)
        let delegate = RecordingBlameDelegate()
        controller.delegate = delegate
        controller.show(path: "a.swift", at: nil)
        await controller.loadTask?.value

        controller.viewer.notifyGutterClick(column: 0, row: 0)
        controller.viewer.notifyGutterClick(column: 0, row: 1)
        controller.viewer.notifyGutterClick(column: 1, row: 2)
        controller.viewer.notifyGutterClick(column: 0, row: 4)
        controller.viewer.notifyGutterClick(column: 0, row: 99)
        #expect(delegate.selected == [Self.sha("c1"), Self.sha("c1")])
    }

    @Test("the lines are syntax coloured from the blame's own text")
    func coloured() async throws {
        let source = GitViewsFakeContentSource()
        source.blames["a.swift@"] = Self.blame()
        let controller = Self.controller(source, coloring: try GitTextMateFixture.coloring())
        controller.show(path: "a.swift", at: nil)
        await controller.loadTask?.value
        let rows = Self.rows(controller)
        #expect(rows.count == 5)
        #expect(rows.allSatisfy { !$0.runs.isEmpty })
        #expect(rows[0].runs.first?.range == NSRange(location: 0, length: 3))
        #expect(source.contentsRequests.isEmpty)
    }

    @Test("a failed blame is shown, and the next show clears it")
    func failure() async {
        let source = GitViewsFakeContentSource()
        source.failing = ["blame:a.swift@"]
        source.blames["b.swift@"] = Self.blame()
        let controller = Self.controller(source)
        controller.show(path: "a.swift", at: nil)
        await controller.loadTask?.value
        #expect(!controller.errorLabel.isHidden)
        #expect(controller.errorLabel.isSelectable)
        #expect(controller.errorLabel.stringValue == gitViewsFailure.localizedDescription)
        #expect(Self.rows(controller).isEmpty)

        controller.show(path: "b.swift", at: nil)
        await controller.loadTask?.value
        #expect(controller.errorLabel.isHidden)
        #expect(Self.rows(controller).count == 5)

        controller.clear()
        #expect(Self.rows(controller).isEmpty)
    }

    @Test("the latest show wins in either order of return", arguments: [true, false])
    func latestWins(laterReturnsFirst: Bool) async {
        let source = GitViewsFakeContentSource()
        let one = GitBlame(lines: [GitBlame.Line(commitID: Self.sha("c1"), originalLine: 1, finalLine: 1,
                                                 text: "first")],
                           commits: [Self.sha("c1"): Self.commit(Self.sha("c1"), "Ann Lee", "a")])
        source.blames = ["a@": one, "b@": Self.blame()]
        source.holding = ["blame:a@", "blame:b@"]
        let controller = Self.controller(source)

        controller.show(path: "a", at: nil)
        let first = controller.loadTask
        await source.waitUntilHeld("blame:a@")
        controller.show(path: "b", at: nil)
        let second = controller.loadTask
        await source.waitUntilHeld("blame:b@")

        if laterReturnsFirst {
            source.release("blame:b@")
            await second?.value
            source.release("blame:a@")
            await first?.value
        } else {
            source.release("blame:a@")
            await first?.value
            source.release("blame:b@")
            await second?.value
        }
        #expect(Self.rows(controller).count == 5)
    }
}
