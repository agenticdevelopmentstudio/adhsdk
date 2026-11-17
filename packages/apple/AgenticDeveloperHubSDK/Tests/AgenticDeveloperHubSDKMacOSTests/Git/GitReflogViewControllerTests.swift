import AppKit
import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

/// Records what the reflog browser reports.
@MainActor
private final class RecordingReflogDelegate: GitReflogDelegate {
    var selections: [GitReflogEntry?] = []
    var intents: [GitReflogIntent] = []

    func reflog(_ reflog: GitReflogViewController, didSelect entry: GitReflogEntry?) {
        selections.append(entry)
    }

    func reflog(_ reflog: GitReflogViewController, didRequest intent: GitReflogIntent) {
        intents.append(intent)
    }
}

/// The reflog browser (recipe `workspace/git/git-views`, "Reflog"): five columns, one row
/// per HEAD@{n}, and a row menu whose every item becomes an intent for the session.
@Suite("GitReflogViewController")
@MainActor
struct GitReflogViewControllerTests {

    private static func entry(_ index: Int, _ sha: Character, _ action: String, _ message: String) -> GitReflogEntry {
        GitReflogEntry(
            selector: "HEAD@{\(index)}", sha: String(repeating: sha, count: 40), previousSha: nil,
            action: action, message: message, date: Date(timeIntervalSince1970: 1_767_268_800 - Double(index)))
    }

    private static let entries = [
        entry(0, "c", "commit (amend)", "three again"),
        entry(1, "b", "commit", "three"),
        entry(2, "a", "commit (initial)", "one")
    ]

    private func makeReflog() -> (GitReflogViewController, RecordingReflogDelegate) {
        let reflog = GitReflogViewController()
        let delegate = RecordingReflogDelegate()
        reflog.delegate = delegate
        reflog.loadViewIfNeeded()
        reflog.show(Self.entries)
        return (reflog, delegate)
    }

    /// Fires `item` the way AppKit does when the user chooses it.
    private func fire(_ item: NSMenuItem?) throws {
        let item = try #require(item)
        let action = try #require(item.action)
        let target = try #require(item.target as? NSObject)
        target.perform(action, with: item)
    }

    @Test("the columns are Selector, Action, Message, Commit and Commit Date, with their ids")
    func columns() {
        let (reflog, _) = makeReflog()
        #expect(reflog.tableView.tableColumns.map(\.title) == [
            "Selector", "Action", "Message", "Commit", "Commit Date"
        ])
        #expect(reflog.tableView.tableColumns.map(\.identifier.rawValue) == [
            "git.reflog.selector", "git.reflog.action", "git.reflog.message", "git.reflog.commit", "git.reflog.date"
        ])
        #expect(reflog.view.accessibilityIdentifier() == "git.reflog")
        #expect(reflog.tableView.accessibilityIdentifier() == "git.reflog.table")
        #expect(reflog.tableView.numberOfRows == 3)
    }

    @Test("a cell shows its column of the entry")
    func cellText() {
        let entry = Self.entries[0]
        #expect(GitReflogViewController.text(of: entry, in: .selector) == "HEAD@{0}")
        #expect(GitReflogViewController.text(of: entry, in: .action) == "commit (amend)")
        #expect(GitReflogViewController.text(of: entry, in: .message) == "three again")
        #expect(GitReflogViewController.text(of: entry, in: .commit) == "cccccccc")
        #expect(!GitReflogViewController.text(of: entry, in: .date).isEmpty)
    }

    @Test("a row's menu: Reset HEAD to Here with Soft, Mixed and Hard…, then Check Out and Create Branch")
    func menuTitlesAndIDs() throws {
        let (reflog, _) = makeReflog()
        let menu = try #require(reflog.contextMenu(forRow: 1))
        #expect(menu.items.map(\.title) == ["Reset HEAD to Here", "Check Out (detached)", "Create Branch Here…"])
        #expect(menu.items.map { $0.accessibilityIdentifier() } == [
            "git.reflog.menu.reset", "git.reflog.menu.checkout", "git.reflog.menu.createBranch"
        ])
        let modes = try #require(menu.items.first?.submenu)
        #expect(modes.items.map(\.title) == ["Soft", "Mixed", "Hard…"])
        #expect(modes.items.map { $0.accessibilityIdentifier() } == [
            "git.reflog.menu.resetSoft", "git.reflog.menu.resetMixed", "git.reflog.menu.resetHard"
        ])
        #expect(reflog.contextMenu(forRow: -1) == nil)
        #expect(reflog.contextMenu(forRow: 3) == nil)
    }

    @Test("each menu item requests its intent for the row's entry; Hard… asks for the reset the session confirms")
    func menuIntents() throws {
        let (reflog, delegate) = makeReflog()
        let entry = Self.entries[1]
        let menu = try #require(reflog.contextMenu(forRow: 1))
        let modes = try #require(menu.items.first?.submenu)
        try fire(modes.items[2])
        #expect(delegate.intents == [.reset(entry, .hard)])
        try fire(modes.items[0])
        try fire(modes.items[1])
        try fire(menu.items[1])
        try fire(menu.items[2])
        #expect(delegate.intents == [
            .reset(entry, .hard), .reset(entry, .soft), .reset(entry, .mixed), .checkout(entry), .createBranch(entry)
        ])
    }

    @Test("selecting a row reports its entry; showing the same list again keeps it without reporting")
    func selection() {
        let (reflog, delegate) = makeReflog()
        reflog.select(row: 1)
        #expect(delegate.selections == [Self.entries[1]])
        #expect(reflog.selectedEntry == Self.entries[1])
        reflog.show(Self.entries)
        #expect(reflog.selectedEntry == Self.entries[1])
        #expect(delegate.selections.count == 1)
    }

    @Test("a new action shifts every selector, and the selected step stays selected")
    func selectionFollowsShift() throws {
        let (reflog, delegate) = makeReflog()
        reflog.select(row: 1)
        let shifted = Self.entries.enumerated().map { index, old in
            GitReflogEntry(selector: "HEAD@{\(index + 1)}", sha: old.sha, previousSha: old.previousSha,
                           action: old.action, message: old.message, date: old.date)
        }
        let newest = GitReflogEntry(
            selector: "HEAD@{0}", sha: String(repeating: "d", count: 40), previousSha: nil,
            action: "reset", message: "moving to HEAD~1", date: Date(timeIntervalSince1970: 1_767_268_900))
        reflog.show([newest] + shifted)
        let selected = try #require(reflog.selectedEntry)
        #expect(selected.selector == "HEAD@{2}")
        #expect(selected.sha == Self.entries[1].sha)
        #expect(delegate.selections.count == 1)
    }

    @Test("a selected entry that is gone from the next list is deselected and reported as nil")
    func vanishedSelectionIsReported() {
        let (reflog, delegate) = makeReflog()
        reflog.select(row: 2)
        reflog.show(Array(Self.entries.prefix(2)))
        #expect(reflog.selectedEntry == nil)
        #expect(delegate.selections == [Self.entries[2], nil])
        // Nothing was selected, so the next list reports nothing.
        reflog.show(Self.entries)
        #expect(delegate.selections.count == 2)
    }
}
