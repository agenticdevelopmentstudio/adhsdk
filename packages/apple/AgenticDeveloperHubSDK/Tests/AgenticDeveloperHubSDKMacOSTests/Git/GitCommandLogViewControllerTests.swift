import AppKit
import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// The roots a test hands the view, counting how often the view asks for them.
@MainActor
private final class RootSource {
    var roots: [URL]
    var asked = 0
    init(roots: [URL]) { self.roots = roots }
}

/// The command log view (recipe `workspace/git/git-views`, "Command log"), over its own
/// `GitCommandLogBook` so no other suite's git calls reach it. Nothing here spawns git.
@Suite("GitCommandLogViewController", .serialized)
@MainActor
struct GitCommandLogViewControllerTests {
    private static let root = URL(fileURLWithPath: "/tmp/command-log/repo")
    private static let worktree = URL(fileURLWithPath: "/tmp/command-log/wt-feature")

    private func record(
        _ book: GitCommandLogBook, _ arguments: [String] = ["status"], in directory: String = root.path,
        exitStatus: Int32? = 0, standardError: String? = nil
    ) {
        book.append(tool: "git", arguments: arguments, directory: directory, caller: "Tests.swift:test()",
                    duration: .milliseconds(12), exitStatus: exitStatus, standardError: standardError)
    }

    private func makeController(_ book: GitCommandLogBook) -> GitCommandLogViewController {
        let controller = GitCommandLogViewController(book: book) { [Self.root, Self.worktree] }
        controller.view.frame = NSRect(x: 0, y: 0, width: 600, height: 120)
        controller.view.layoutSubtreeIfNeeded()
        return controller
    }

    private func waitUntil(_ controller: GitCommandLogViewController, _ condition: () -> Bool) async {
        for _ in 0..<200 where !condition() {
            try? await Task.sleep(for: .milliseconds(10))
            controller.view.layoutSubtreeIfNeeded()
        }
    }

    private func lastRowIsVisible(_ controller: GitCommandLogViewController) -> Bool {
        let table = controller.tableView
        let visible = table.rows(in: table.visibleRect)
        return visible.contains(controller.shown.count - 1)
    }

    @Test("it shows the root's and its worktrees' entries, subdirectories included, and nothing else")
    func filtersByRoot() {
        let book = GitCommandLogBook(capacity: 50)
        record(book, ["status", "a"], in: Self.root.path)
        record(book, ["status", "b"], in: Self.root.appendingPathComponent("sub").path)
        record(book, ["status", "c"], in: "/tmp/command-log/repo-other")
        record(book, ["status", "d"], in: Self.worktree.path)
        record(book, ["status", "e"], in: "/elsewhere")
        record(book, ["status", "f"], in: "")
        let controller = makeController(book)
        #expect(controller.shown.map(\.arguments) == [["status", "a"], ["status", "b"], ["status", "d"]])
        #expect(controller.tableView.numberOfRows == 3)
        #expect(controller.tableView.numberOfColumns == 5)
        #expect(controller.tableView.tableColumns.map(\.title)
                == ["Time", "Command", "Directory", "Duration", "Status"])
    }

    @Test("the roots are asked for once per reload, not once per entry, and a change is picked up")
    func rootsAskedOncePerReload() {
        let book = GitCommandLogBook(capacity: 50)
        for index in 0..<20 { record(book, ["status", "\(index)"]) }
        record(book, ["status", "elsewhere"], in: "/tmp/command-log/other")
        let source = RootSource(roots: [Self.root])
        let controller = GitCommandLogViewController(book: book) {
            source.asked += 1
            return source.roots
        }
        controller.view.frame = NSRect(x: 0, y: 0, width: 600, height: 120)
        controller.view.layoutSubtreeIfNeeded()
        controller.reload()
        #expect(controller.shown.count == 20)
        #expect(source.asked <= 2)
        source.roots = [URL(fileURLWithPath: "/tmp/command-log/other")]
        controller.reload()
        #expect(controller.shown.map(\.arguments) == [["status", "elsewhere"]])
        controller.stop()
    }

    @Test("a new entry in the root is appended; one elsewhere is not")
    func appendsNewEntries() async {
        let book = GitCommandLogBook(capacity: 50)
        let controller = makeController(book)
        record(book, ["fetch"])
        record(book, ["fetch"], in: "/elsewhere")
        record(book, ["pull"])
        await waitUntil(controller) { controller.shown.count == 2 }
        #expect(controller.shown.map(\.arguments) == [["fetch"], ["pull"]])
        controller.stop()
    }

    @Test("it follows new entries while at the bottom, and stays put when scrolled up")
    func followsTheBottom() async {
        let book = GitCommandLogBook(capacity: 500)
        for index in 0..<40 { record(book, ["status", "\(index)"]) }
        let controller = makeController(book)
        #expect(lastRowIsVisible(controller))

        record(book, ["status", "40"])
        await waitUntil(controller) { controller.shown.count == 41 }
        controller.view.layoutSubtreeIfNeeded()
        #expect(lastRowIsVisible(controller))

        controller.tableView.scrollRowToVisible(0)
        controller.view.layoutSubtreeIfNeeded()
        #expect(!controller.isAtBottom)
        record(book, ["status", "41"])
        await waitUntil(controller) { controller.shown.count == 42 }
        controller.view.layoutSubtreeIfNeeded()
        #expect(!lastRowIsVisible(controller))
        #expect(controller.tableView.rows(in: controller.tableView.visibleRect).contains(0))
        controller.stop()
    }

    @Test("at the cap a reader scrolled up keeps the same rows in view as the oldest go")
    func capKeepsTheScrollAnchor() async {
        let book = GitCommandLogBook(capacity: 30)
        for index in 0..<30 { record(book, ["status", "\(index)"]) }
        let controller = makeController(book)
        let table = controller.tableView
        table.scrollRowToVisible(0)
        table.scrollRowToVisible(12)
        controller.view.layoutSubtreeIfNeeded()
        #expect(!controller.isAtBottom)
        let anchor = table.rows(in: table.visibleRect)
        let before = controller.shown[anchor.location + anchor.length / 2].id

        record(book, ["status", "30"])
        await waitUntil(controller) { controller.shown.last?.arguments == ["status", "30"] }
        controller.view.layoutSubtreeIfNeeded()

        #expect(controller.shown.count == 30)
        #expect(table.numberOfRows == 30)
        #expect(controller.shown.first?.arguments == ["status", "1"])
        let after = table.rows(in: table.visibleRect)
        #expect(controller.shown[after.location + after.length / 2].id == before)
        controller.stop()
    }

    @Test("Copy Command puts the row's command line on the pasteboard")
    func copiesTheCommand() throws {
        let book = GitCommandLogBook(capacity: 10)
        record(book, ["push", "https://***@github.com/o/r.git", "main"])
        let controller = makeController(book)
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("git.commandLog.test.\(UUID().uuidString)"))
        defer { pasteboard.releaseGlobally() }
        controller.pasteboard = pasteboard
        controller.copyCommand(row: 0)
        #expect(pasteboard.string(forType: .string) == "git push https://***@github.com/o/r.git main")

        let item = try #require(controller.tableView.menu?.items.first)
        #expect(item.title == "Copy Command")
        #expect(item.accessibilityIdentifier() == "git.commandLog.menu.copy")
        controller.stop()
    }

    @Test("the Time column is a 24-hour HH:mm:ss whatever the locale's clock")
    func timeIsTwentyFourHour() throws {
        let utc = try #require(TimeZone(identifier: "UTC"))
        let afternoon = Date(timeIntervalSince1970: 14 * 3600 + 5 * 60 + 9)
        #expect(GitCommandLogViewController.timeText(of: afternoon, in: utc) == "14:05:09")
        #expect(GitCommandLogViewController.timeText(of: Date(timeIntervalSince1970: 7), in: utc) == "00:00:07")
    }

    @Test("a failed row's tooltip is its standard error; a passed row has none")
    func failedRowTooltip() {
        let book = GitCommandLogBook(capacity: 10)
        record(book, ["status"])
        record(book, ["push"], exitStatus: 1, standardError: "rejected")
        let controller = makeController(book)
        #expect(controller.toolTip(forRow: 0) == nil)
        #expect(controller.toolTip(forRow: 1) == "rejected")
        #expect(GitCommandLogViewController.statusSymbol(of: controller.shown[1]).name == "xmark.octagon")
        #expect(GitCommandLogViewController.text(of: controller.shown[1], in: .status) == "1")
        #expect(GitCommandLogViewController.text(of: controller.shown[1], in: .duration) == "12 ms")
        #expect(GitCommandLogViewController.text(of: controller.shown[1], in: .directory) == "repo")
        controller.stop()
    }
}
