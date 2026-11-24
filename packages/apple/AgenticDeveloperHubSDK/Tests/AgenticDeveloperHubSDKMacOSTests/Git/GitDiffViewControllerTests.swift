import AppKit
import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKLanguage
@testable import AgenticDeveloperHubSDKMacOS

@MainActor
private final class RecordingDiffDelegate: GitDiffDelegate {
    enum Event: Equatable {
        case blame(String, String?)
        case history(String)
        case intent(GitDiffIntent)
    }
    private(set) var events: [Event] = []
    func diff(_ diff: GitDiffViewController, didRequestBlameFor path: String, at revision: String?) {
        events.append(.blame(path, revision))
    }
    func diff(_ diff: GitDiffViewController, didRequestHistoryFor path: String) {
        events.append(.history(path))
    }
    func diff(_ diff: GitDiffViewController, didRequest intent: GitDiffIntent) {
        events.append(.intent(intent))
    }
}

@Suite("GitDiffViewController")
@MainActor
struct GitDiffViewControllerTests {

    private typealias Fixture = GitDiffFixtures

    private static func settings() -> UserSettings {
        UserSettings(with: InMemorySettingsStorageProvider())
    }

    private static func controller(_ source: GitViewsFakeContentSource, settings: SettingsStore = settings(),
                                   coloring: GitSyntaxColoring? = nil) -> GitDiffViewController {
        let controller = GitDiffViewController(source: source, coloring: coloring, settings: settings)
        controller.loadViewIfNeeded()
        return controller
    }

    private static func texts(_ source: LineViewerDataSource?) -> [String] {
        guard let source else { return [] }
        return (0..<source.rowCount).map { source.row(at: $0).text }
    }

    /// One modified file whose single context line reads `text`.
    private static func oneLine(_ path: String, _ text: String) -> GitDiff {
        let hunk = GitDiffHunk(oldStart: 1, oldCount: 1, newStart: 1, newCount: 1, section: "",
                               lines: [Fixture.context(text, 1, 1)])
        return GitDiff(files: [GitFileDiff(oldPath: path, newPath: path, change: .modified, isBinary: false,
                                           hunks: [hunk])])
    }

    @Test("the view, controls and viewers carry their identifiers")
    func identifiers() {
        let controller = Self.controller(GitViewsFakeContentSource())
        #expect(controller.view.accessibilityIdentifier() == "git.diff")
        #expect(controller.controlsRow.accessibilityIdentifier() == "git.diff.controls")
        #expect(controller.layoutControl.accessibilityIdentifier() == "git.diff.layout")
        #expect(controller.ignoreWhitespaceButton.accessibilityIdentifier() == "git.diff.ignoreWhitespace")
        #expect(controller.wordHighlightButton.accessibilityIdentifier() == "git.diff.wordHighlight")
        #expect(controller.blameButton.accessibilityIdentifier() == "git.diff.blame")
        #expect(controller.historyButton.accessibilityIdentifier() == "git.diff.history")
        #expect(controller.inlineViewer.scrollView.accessibilityIdentifier() == "git.diff.inline")
        #expect(controller.leftViewer.scrollView.accessibilityIdentifier() == "git.diff.left")
        #expect(controller.rightViewer.scrollView.accessibilityIdentifier() == "git.diff.right")
        #expect(controller.splitView.accessibilityIdentifier() == "git.diff.split")
        #expect(controller.errorLabel.accessibilityIdentifier() == "git.diff.error")
        #expect(controller.layoutControl.segmentCount == 2)
        #expect(controller.layoutControl.label(forSegment: 0) == "Inline")
        #expect(controller.layoutControl.label(forSegment: 1) == "Side by Side")
        #expect(controller.ignoreWhitespaceButton.title == "Ignore Whitespace")
        #expect(controller.wordHighlightButton.title == "Word Highlighting")
        #expect(controller.blameButton.title == "Blame")
        #expect(controller.historyButton.title == "History")
        #expect(controller.errorLabel.isHidden)
        #expect(!controller.blameButton.isEnabled)
        #expect(!controller.historyButton.isEnabled)
    }

    @Test("the defaults are inline, whitespace counted and word highlighting on")
    func defaults() {
        let controller = Self.controller(GitViewsFakeContentSource())
        #expect(controller.layoutControl.selectedSegment == 0)
        #expect(controller.ignoreWhitespaceButton.state == .off)
        #expect(controller.wordHighlightButton.state == .on)
        #expect(!controller.inlineViewer.view.isHidden)
        #expect(controller.splitView.isHidden)
    }

    @Test("show asks for the target with the stored options and shows the stored layout")
    func showWithStoredSettings() async throws {
        let source = GitViewsFakeContentSource()
        source.diffs["c1"] = GitDiff(files: [Fixture.twoHunks()])
        let settings = Self.settings()
        settings.set(true, for: UserSettings.gitDiffIgnoreWhitespace)
        settings.set("sideBySide", for: UserSettings.gitDiffLayout)
        let controller = Self.controller(source, settings: settings)
        #expect(controller.layoutControl.selectedSegment == 1)
        #expect(controller.ignoreWhitespaceButton.state == .on)

        controller.show(target: .commit("c1", paths: ["a.swift"]), file: "a.swift")
        await controller.loadTask?.value

        let request = try #require(source.diffRequests.first)
        #expect(source.diffRequests.count == 1)
        #expect(request.target == .commit("c1", paths: ["a.swift"]))
        #expect(request.options.ignoreWhitespace)
        #expect(controller.inlineViewer.view.isHidden)
        #expect(!controller.splitView.isHidden)
        #expect(Self.texts(controller.leftViewer.dataSource).count == 8)
        #expect(Self.texts(controller.rightViewer.dataSource)[6] == "y")
        #expect(controller.blameButton.isEnabled)
        #expect(controller.historyButton.isEnabled)
    }

    @Test("switching the layout stores it and rebuilds from the shown diff without asking again")
    func layoutSwitch() async {
        let source = GitViewsFakeContentSource()
        source.diffs["c1"] = GitDiff(files: [Fixture.twoHunks()])
        let settings = Self.settings()
        let controller = Self.controller(source, settings: settings)
        controller.show(target: .commit("c1", paths: ["a.swift"]), file: "a.swift")
        await controller.loadTask?.value
        #expect(Self.texts(controller.inlineViewer.dataSource).count == 9)

        controller.layoutControl.selectedSegment = 1
        controller.layoutChanged(controller.layoutControl)
        await controller.loadTask?.value
        #expect(settings.get(UserSettings.gitDiffLayout) == "sideBySide")
        #expect(!controller.splitView.isHidden)
        #expect(controller.inlineViewer.view.isHidden)
        #expect(Self.texts(controller.rightViewer.dataSource).count == 8)

        controller.layoutControl.selectedSegment = 0
        controller.layoutChanged(controller.layoutControl)
        await controller.loadTask?.value
        #expect(settings.get(UserSettings.gitDiffLayout) == "inline")
        #expect(Self.texts(controller.inlineViewer.dataSource).count == 9)
        #expect(source.diffRequests.count == 1)
    }

    @Test("word highlighting is stored and rebuilds without asking again")
    func wordHighlightToggle() async {
        let source = GitViewsFakeContentSource()
        source.diffs["c1"] = GitDiff(files: [Fixture.twoHunks()])
        let settings = Self.settings()
        let controller = Self.controller(source, settings: settings)
        controller.show(target: .commit("c1", paths: []), file: "a.swift")
        await controller.loadTask?.value
        let emphasised = {
            (controller.inlineViewer.dataSource?.row(at: 2).runs ?? []).contains { $0.highlight == .emphasis }
        }
        #expect(emphasised())

        controller.wordHighlightButton.performClick(nil)
        await controller.loadTask?.value
        #expect(settings.get(UserSettings.gitDiffWordHighlight) == false)
        #expect(!emphasised())
        #expect(source.diffRequests.count == 1)
    }

    @Test("ignore whitespace is stored and asks for the diff again")
    func ignoreWhitespaceToggle() async {
        let source = GitViewsFakeContentSource()
        source.diffs["c1"] = GitDiff(files: [Fixture.twoHunks()])
        let settings = Self.settings()
        let controller = Self.controller(source, settings: settings)
        controller.show(target: .commit("c1", paths: []), file: "a.swift")
        await controller.loadTask?.value

        controller.ignoreWhitespaceButton.performClick(nil)
        await controller.loadTask?.value
        #expect(settings.get(UserSettings.gitDiffIgnoreWhitespace))
        #expect(source.diffRequests.map(\.options.ignoreWhitespace) == [false, true])
    }

    @Test("the file shown is the one matching its new path, else its old path")
    func picksFile() async {
        let source = GitViewsFakeContentSource()
        source.diffs["c1"] = GitDiff(files: [Self.oneLine("other", "o").files[0],
                                             GitFileDiff(oldPath: "gone", newPath: nil, change: .deleted,
                                                         isBinary: false, hunks: Self.oneLine("gone", "g")
                                                            .files[0].hunks),
                                             Self.oneLine("mine", "m").files[0]])
        let controller = Self.controller(source)
        controller.show(target: .commit("c1", paths: []), file: "mine")
        await controller.loadTask?.value
        #expect(Self.texts(controller.inlineViewer.dataSource).last == "m")

        controller.show(target: .commit("c1", paths: []), file: "gone")
        await controller.loadTask?.value
        #expect(Self.texts(controller.inlineViewer.dataSource).last == "g")
    }

    @Test("the latest show wins when the earlier diff returns last")
    func latestWinsEarlierLast() async throws {
        let source = GitViewsFakeContentSource()
        source.diffs = ["a1": Self.oneLine("a.swift", "from a"), "b1": Self.oneLine("b.swift", "from b")]
        source.files = ["b.swift@b1^1": Data("let b = 1".utf8), "b.swift@b1": Data("let b = 1".utf8),
                        "a.swift@a1^1": Data("let a = 1".utf8), "a.swift@a1": Data("let a = 1".utf8)]
        source.holding = ["diff:a1", "diff:b1"]
        let controller = Self.controller(source, coloring: try GitTextMateFixture.coloring())

        controller.show(target: .commit("a1", paths: []), file: "a.swift")
        let first = controller.loadTask
        await source.waitUntilHeld("diff:a1")
        controller.show(target: .commit("b1", paths: []), file: "b.swift")
        let second = controller.loadTask
        await source.waitUntilHeld("diff:b1")

        source.release("diff:b1")
        await second?.value
        source.release("diff:a1")
        await first?.value

        #expect(Self.texts(controller.inlineViewer.dataSource).last == "from b")
        #expect(source.contentsRequests == ["b.swift@b1^1", "b.swift@b1"])
        #expect(!(controller.inlineViewer.dataSource?.row(at: 1).runs.isEmpty ?? true))
    }

    @Test("the latest show wins when the earlier diff returns first")
    func latestWinsEarlierFirst() async throws {
        let source = GitViewsFakeContentSource()
        source.diffs = ["a1": Self.oneLine("a.swift", "from a"), "b1": Self.oneLine("b.swift", "from b")]
        source.holding = ["diff:a1", "diff:b1"]
        let controller = Self.controller(source, coloring: try GitTextMateFixture.coloring())

        controller.show(target: .commit("a1", paths: []), file: "a.swift")
        let first = controller.loadTask
        await source.waitUntilHeld("diff:a1")
        controller.show(target: .commit("b1", paths: []), file: "b.swift")
        let second = controller.loadTask
        await source.waitUntilHeld("diff:b1")

        source.release("diff:a1")
        await first?.value
        source.release("diff:b1")
        await second?.value

        #expect(Self.texts(controller.inlineViewer.dataSource).last == "from b")
        #expect(source.contentsRequests == ["b.swift@b1^1", "b.swift@b1"])
    }

    @Test("colours read for an earlier show are dropped once a later show is made")
    func latestWinsDuringColouring() async throws {
        let source = GitViewsFakeContentSource()
        source.diffs = ["a1": Self.oneLine("a.swift", "from a"), "b1": Self.oneLine("b.swift", "from b")]
        source.files = ["a.swift@a1^1": Data("let a = 1".utf8), "a.swift@a1": Data("let a = 1".utf8)]
        source.holding = ["contents:a.swift@a1^1", "diff:b1"]
        let controller = Self.controller(source, coloring: try GitTextMateFixture.coloring())

        controller.show(target: .commit("a1", paths: []), file: "a.swift")
        let first = controller.loadTask
        await source.waitUntilHeld("contents:a.swift@a1^1")
        #expect(Self.texts(controller.inlineViewer.dataSource).last == "from a")
        controller.show(target: .commit("b1", paths: []), file: "b.swift")
        let second = controller.loadTask
        await source.waitUntilHeld("diff:b1")

        source.release("contents:a.swift@a1^1")
        await first?.value
        #expect(Self.texts(controller.inlineViewer.dataSource).last == "from a")
        source.release("diff:b1")
        await second?.value
        #expect(Self.texts(controller.inlineViewer.dataSource).last == "from b")
        #expect(!source.contentsRequests.contains("a.swift@a1"))
    }

    @Test("a failed diff is shown and logged, and the next show clears it")
    func failure() async {
        let source = GitViewsFakeContentSource()
        source.failing = ["diff:a1"]
        source.diffs["b1"] = Self.oneLine("b.swift", "from b")
        let controller = Self.controller(source)

        controller.show(target: .commit("a1", paths: []), file: "a.swift")
        await controller.loadTask?.value
        #expect(!controller.errorLabel.isHidden)
        #expect(controller.errorLabel.stringValue == gitViewsFailure.localizedDescription)
        #expect(controller.errorLabel.isSelectable)
        #expect(Self.texts(controller.inlineViewer.dataSource).isEmpty)

        controller.show(target: .commit("b1", paths: []), file: "b.swift")
        await controller.loadTask?.value
        #expect(controller.errorLabel.isHidden)
        #expect(Self.texts(controller.inlineViewer.dataSource).last == "from b")
    }

    @Test("clear empties the viewer, hides the error and disables the file buttons")
    func clear() async {
        let source = GitViewsFakeContentSource()
        source.diffs["c1"] = GitDiff(files: [Fixture.twoHunks()])
        let controller = Self.controller(source)
        controller.show(target: .commit("c1", paths: []), file: "a.swift")
        await controller.loadTask?.value
        controller.clear()
        #expect(Self.texts(controller.inlineViewer.dataSource).isEmpty)
        #expect(!controller.blameButton.isEnabled)
        #expect(!controller.historyButton.isEnabled)
        #expect(controller.errorLabel.isHidden)
    }

    @Test("Blame and History name the shown file and its revision")
    func blameAndHistory() async {
        let source = GitViewsFakeContentSource()
        let deleted = GitFileDiff(oldPath: "d", newPath: nil, change: .deleted, isBinary: false, hunks: [])
        source.diffs["c1"] = GitDiff(files: [Fixture.twoHunks(path: "a"), deleted])
        source.diffs["unstaged"] = GitDiff(files: [Fixture.twoHunks(path: "a")])
        let controller = Self.controller(source)
        let delegate = RecordingDiffDelegate()
        controller.delegate = delegate

        controller.show(target: .commit("c1", paths: ["a"]), file: "a")
        await controller.loadTask?.value
        controller.blameButton.performClick(nil)
        controller.historyButton.performClick(nil)

        controller.show(target: .commit("c1", paths: ["d"]), file: "d")
        await controller.loadTask?.value
        controller.blameButton.performClick(nil)

        controller.show(target: .unstaged(paths: ["a"]), file: "a")
        await controller.loadTask?.value
        controller.blameButton.performClick(nil)

        #expect(delegate.events == [.blame("a", "c1"), .history("a"), .blame("d", "c1^1"), .blame("a", nil)])
    }

    @Test("while a later file loads, Blame and History act on it, never on the diff still shown")
    func blameAndHistoryDuringLoad() async {
        let source = GitViewsFakeContentSource()
        let deleted = GitFileDiff(oldPath: "a", newPath: nil, change: .deleted, isBinary: false, hunks: [])
        source.diffs["c1"] = GitDiff(files: [deleted])
        source.diffs["c2"] = Self.oneLine("b", "from b")
        source.holding = ["diff:c2"]
        let controller = Self.controller(source)
        let delegate = RecordingDiffDelegate()
        controller.delegate = delegate

        controller.show(target: .commit("c1", paths: ["a"]), file: "a")
        await controller.loadTask?.value
        controller.show(target: .commit("c2", paths: ["b"]), file: "b")
        await source.waitUntilHeld("diff:c2")
        controller.blameButton.performClick(nil)
        controller.historyButton.performClick(nil)
        source.release("diff:c2")
        await controller.loadTask?.value

        #expect(delegate.events == [.blame("b", "c2"), .history("b")])
    }

    @Test("a file missing from the diff shows no rows rather than another file's")
    func missingFile() async {
        let source = GitViewsFakeContentSource()
        source.diffs["c1"] = Self.oneLine("other", "o")
        let controller = Self.controller(source)
        controller.show(target: .commit("c1", paths: []), file: "mine")
        await controller.loadTask?.value
        #expect(Self.texts(controller.inlineViewer.dataSource).isEmpty)
    }

    @Test("the blame revision follows the diff target")
    func blameRevision() {
        #expect(GitDiffViewController.blameRevision(for: .commit("c1", paths: []), deleted: false) == "c1")
        #expect(GitDiffViewController.blameRevision(for: .commit("c1", paths: []), deleted: true) == "c1^1")
        #expect(GitDiffViewController.blameRevision(for: .range(from: "a", to: "b", paths: []), deleted: false)
                == "b")
        #expect(GitDiffViewController.blameRevision(for: .range(from: "a", to: "b", paths: []), deleted: true)
                == "a")
        #expect(GitDiffViewController.blameRevision(for: .staged(paths: []), deleted: false) == nil)
        #expect(GitDiffViewController.blameRevision(for: .staged(paths: []), deleted: true) == "HEAD")
        #expect(GitDiffViewController.blameRevision(for: .untracked(path: "a"), deleted: false) == nil)
    }

    // MARK: - Staging menu

    /// A point in the text area of display row `row` of `viewer`.
    private static func point(_ viewer: LineViewerViewController, row: Int) -> NSPoint {
        NSPoint(x: viewer.documentView.textOriginX + 4, y: (CGFloat(row) + 0.5) * viewer.rowHeight)
    }

    /// Selects `rows` (a contiguous range) in `viewer`, then right-clicks `clicked`.
    private static func menu(_ viewer: LineViewerViewController, select rows: ClosedRange<Int>? = nil,
                             click clicked: Int) -> NSMenu? {
        if let rows {
            viewer.documentView.handleClick(at: point(viewer, row: rows.lowerBound), modifiers: [])
            viewer.documentView.handleClick(at: point(viewer, row: rows.upperBound), modifiers: [.shift])
        }
        return viewer.documentView.contextMenu(at: point(viewer, row: clicked))
    }

    private static func titles(_ menu: NSMenu?) -> [String] {
        menu?.items.map { $0.isSeparatorItem ? "-" : $0.title } ?? []
    }

    private static func item(_ menu: NSMenu?, _ name: String) -> NSMenuItem? {
        menu?.items.first { $0.accessibilityIdentifier() == "git.diff.menu.\(name)" }
    }

    private static func fire(_ item: NSMenuItem?) {
        guard let item, let action = item.action, let target = item.target as? NSObject else {
            Issue.record("menu item has no target and action")
            return
        }
        _ = target.perform(action, with: item)
    }

    private static func loaded(_ target: GitDiffTarget, settings: SettingsStore = settings(),
                               layout: String = "inline") async -> (GitDiffViewController, RecordingDiffDelegate) {
        let source = GitViewsFakeContentSource()
        let diff = GitDiff(files: [Fixture.twoHunks()])
        for key in ["unstaged", "staged", "c1", "untracked:a.swift"] { source.diffs[key] = diff }
        settings.set(layout, for: UserSettings.gitDiffLayout)
        let controller = Self.controller(source, settings: settings)
        let delegate = RecordingDiffDelegate()
        controller.delegate = delegate
        controller.show(target: target, file: "a.swift")
        await controller.loadTask?.value
        return (controller, delegate)
    }

    @Test("a reload reading the same diff keeps the selection; one that changes the selected lines clears it")
    func reloadKeepsSelection() async {
        let source = GitViewsFakeContentSource()
        source.diffs["unstaged"] = GitDiff(files: [Fixture.twoHunks()])
        let controller = Self.controller(source)
        controller.show(target: .unstaged(paths: ["a.swift"]), file: "a.swift")
        await controller.loadTask?.value
        let viewer = controller.inlineViewer
        _ = Self.menu(viewer, select: 2...3, click: 2)
        #expect(viewer.selectedRows == IndexSet(2...3))
        let rows = Self.texts(viewer.dataSource)

        controller.reload()
        await controller.loadTask?.value
        #expect(Self.texts(viewer.dataSource) == rows)
        #expect(viewer.selectedRows == IndexSet(2...3), "the same diff read again keeps the selection")

        source.diffs["unstaged"] = Self.oneLine("a.swift", "other")
        controller.reload()
        await controller.loadTask?.value
        #expect(Self.texts(viewer.dataSource) != rows)
        #expect(viewer.selectedRows.isEmpty, "no stale row stays selected")
    }

    @Test("an unstaged diff offers stage and discard of the hunk and the selected lines")
    func unstagedMenu() async {
        let (controller, _) = await Self.loaded(.unstaged(paths: ["a.swift"]))
        let menu = Self.menu(controller.inlineViewer, select: 2...3, click: 2)
        #expect(Self.titles(menu) == ["Stage Hunk", "Stage Lines", "-", "Discard Hunk…", "Discard Lines…"])
        for name in ["stageHunk", "stageLines", "discardHunk", "discardLines"] {
            #expect(Self.item(menu, name) != nil)
        }
    }

    @Test("a selection of context lines offers only the hunk items")
    func contextOnlyMenu() async {
        let (controller, _) = await Self.loaded(.unstaged(paths: ["a.swift"]))
        let menu = Self.menu(controller.inlineViewer, click: 1)
        #expect(Self.titles(menu) == ["Stage Hunk", "-", "Discard Hunk…"])
    }

    @Test("a staged diff offers unstage of the hunk and the selected lines")
    func stagedMenu() async {
        let (controller, _) = await Self.loaded(.staged(paths: ["a.swift"]))
        let menu = Self.menu(controller.inlineViewer, click: 7)
        #expect(Self.titles(menu) == ["Unstage Hunk", "Unstage Lines"])
        #expect(Self.item(menu, "unstageHunk") != nil)
        #expect(Self.item(menu, "unstageLines") != nil)
    }

    @Test("commit, range and untracked diffs, and a diff read ignoring whitespace, have no menu")
    func noMenu() async {
        for target in [GitDiffTarget.commit("c1", paths: []), .untracked(path: "a.swift")] {
            let (controller, _) = await Self.loaded(target)
            #expect(Self.menu(controller.inlineViewer, click: 2) == nil)
        }
        let settings = Self.settings()
        settings.set(true, for: UserSettings.gitDiffIgnoreWhitespace)
        let (controller, _) = await Self.loaded(.unstaged(paths: ["a.swift"]), settings: settings)
        #expect(Self.menu(controller.inlineViewer, click: 2) == nil)
    }

    @Test("Stage Lines over two hunks sends one stage of every changed line selected, then clears the selection")
    func stageLinesAcrossHunks() async {
        let (controller, delegate) = await Self.loaded(.unstaged(paths: ["a.swift"]))
        let menu = Self.menu(controller.inlineViewer, select: 2...7, click: 4)
        Self.fire(Self.item(menu, "stageLines"))
        let file = Fixture.twoHunks()
        #expect(delegate.events == [.intent(.stage(GitPatchSelection(file: file, lines: [0: IndexSet([1, 2]),
                                                                                          1: IndexSet([1])])))])
        #expect(controller.inlineViewer.selectedRows.isEmpty)
    }

    @Test("Stage Hunk and Discard Hunk send the clicked row's hunk, a header's own")
    func hunkIntents() async {
        let (controller, delegate) = await Self.loaded(.unstaged(paths: ["a.swift"]))
        let file = Fixture.twoHunks()
        Self.fire(Self.item(Self.menu(controller.inlineViewer, click: 5), "stageHunk"))
        Self.fire(Self.item(Self.menu(controller.inlineViewer, click: 2), "discardHunk"))
        #expect(delegate.events == [.intent(.stage(.hunk(1, of: file))), .intent(.discard(.hunk(0, of: file)))])
    }

    @Test("side by side, a viewer's lines are its own side's alone, and a filler row's hunk is the one above")
    func sideBySideIntents() async {
        let (controller, delegate) = await Self.loaded(.staged(paths: ["a.swift"]), layout: "sideBySide")
        let file = Fixture.twoHunks()
        Self.fire(Self.item(Self.menu(controller.leftViewer, select: 2...6, click: 2), "unstageLines"))
        Self.fire(Self.item(Self.menu(controller.rightViewer, select: 2...6, click: 6), "unstageLines"))
        Self.fire(Self.item(Self.menu(controller.leftViewer, click: 6), "unstageHunk"))
        #expect(delegate.events == [
            .intent(.unstage(GitPatchSelection(file: file, lines: [0: IndexSet([1])]))),
            .intent(.unstage(GitPatchSelection(file: file, lines: [0: IndexSet([2]), 1: IndexSet([1])]))),
            .intent(.unstage(.hunk(1, of: file)))
        ])
        #expect(controller.leftViewer.selectedRows.isEmpty)
        #expect(controller.rightViewer.selectedRows.isEmpty)
    }

    @Test("side by side, the removal alone or the addition alone of a changed pair can be staged and discarded")
    func sideBySideHalfOfAPair() async {
        let (controller, delegate) = await Self.loaded(.unstaged(paths: ["a.swift"]), layout: "sideBySide")
        let file = Fixture.twoHunks()
        Self.fire(Self.item(Self.menu(controller.leftViewer, select: 2...2, click: 2), "stageLines"))
        Self.fire(Self.item(Self.menu(controller.rightViewer, select: 2...2, click: 2), "stageLines"))
        Self.fire(Self.item(Self.menu(controller.leftViewer, select: 2...2, click: 2), "discardLines"))
        #expect(delegate.events == [
            .intent(.stage(GitPatchSelection(file: file, lines: [0: IndexSet([1])]))),
            .intent(.stage(GitPatchSelection(file: file, lines: [0: IndexSet([2])]))),
            .intent(.discard(GitPatchSelection(file: file, lines: [0: IndexSet([1])])))
        ])
    }
}
