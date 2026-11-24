import AppKit
import Testing
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKLanguage
@testable import AgenticDeveloperHubSDKMacOS

@MainActor
private final class RecordingMergeDelegate: GitMergeViewDelegate {
    var intents: [GitMergeIntent] = []
    func mergeView(_ view: GitMergeViewController, didRequest intent: GitMergeIntent) { intents.append(intent) }
}

/// The merge view's controls (recipe `workspace/git/git-merge-view`, "Controls").
@Suite("GitMergeViewController")
@MainActor
struct GitMergeViewControllerTests {

    /// Forty common lines, a conflict, forty more, a conflict with a base, then forty more:
    /// long enough that scrolling to either conflict is never clamped.
    private static let longText: String = {
        let filler = { (tag: String) in (1...40).map { "\(tag) \($0)" }.joined(separator: "\n") }
        return [filler("head"), "<<<<<<< HEAD", "ours", "=======", "theirs", ">>>>>>> side", filler("mid"),
                "<<<<<<< HEAD", "x", "||||||| base", "y", "=======", "z", ">>>>>>> side", filler("tail"), ""]
            .joined(separator: "\n")
    }()

    private func loaded(_ text: String = gitMergeFixtureText, coloring: GitSyntaxColoring? = nil)
        throws -> (GitMergeViewController, RecordingMergeDelegate) {
        let controller = GitMergeViewController(coloring: coloring)
        let delegate = RecordingMergeDelegate()
        controller.delegate = delegate
        controller.view.frame = NSRect(x: 0, y: 0, width: 900, height: 600)
        controller.view.layoutSubtreeIfNeeded()
        controller.show(path: "f.txt", document: try #require(GitConflictDocument.parse(text)))
        controller.view.layoutSubtreeIfNeeded()
        return (controller, delegate)
    }

    private func press(_ button: NSButton) {
        _ = (button.target as AnyObject?)?.perform(button.action, with: button)
    }

    private func offset(_ viewer: LineViewerViewController) -> CGFloat {
        viewer.scrollView.contentView.bounds.origin.y
    }

    @Test("every control, pane and viewer carries its identifier")
    func identifiers() throws {
        let (controller, _) = try loaded()
        let views: [NSView] = [controller.view, controller.controlsRow, controller.previousButton,
                   controller.nextButton,
                   controller.oursButton, controller.theirsButton, controller.bothButton, controller.baseButton,
                   controller.positionLabel, controller.cancelButton, controller.saveButton, controller.splitView,
                   controller.sidesSplit, controller.oursLabel, controller.theirsLabel, controller.resultLabel]
        let ids = views.map { $0.accessibilityIdentifier() }
        #expect(ids == ["git.merge", "git.merge.controls", "git.merge.previous", "git.merge.next",
                        "git.merge.useOurs", "git.merge.useTheirs", "git.merge.useBoth", "git.merge.useBase",
                        "git.merge.position", "git.merge.cancel", "git.merge.save", "git.merge.split",
                        "git.merge.sides", "git.merge.oursLabel", "git.merge.theirsLabel", "git.merge.resultLabel"])
        #expect(controller.oursViewer.view.accessibilityIdentifier() == "git.merge.ours")
        #expect(controller.theirsViewer.view.accessibilityIdentifier() == "git.merge.theirs")
        #expect(controller.resultViewer.view.accessibilityIdentifier() == "git.merge.result")
        #expect(controller.oursLabel.stringValue == "HEAD")
        #expect(controller.theirsLabel.stringValue == "side")
        #expect(controller.resultLabel.stringValue == "Result")
    }

    @Test("showing a file shows its rows with the first conflict current")
    func showsRows() throws {
        let (controller, _) = try loaded()
        #expect(controller.oursViewer.dataSource?.rowCount == 6)
        #expect(controller.theirsViewer.dataSource?.rowCount == 6)
        #expect(controller.resultViewer.dataSource?.rowCount == 5)
        #expect(controller.currentConflict == 0)
        #expect(controller.positionLabel.stringValue == "1 of 2")
        #expect(!controller.previousButton.isEnabled)
        #expect(controller.nextButton.isEnabled)
    }

    @Test("Next and Previous move the current conflict and scroll ours, theirs and the result to it")
    func nextAndPrevious() throws {
        let (controller, _) = try loaded(Self.longText)
        let layout = try #require(controller.layout)
        let height = controller.oursViewer.rowHeight

        press(controller.nextButton)
        #expect(controller.currentConflict == 1)
        #expect(controller.positionLabel.stringValue == "2 of 2")
        #expect(controller.previousButton.isEnabled)
        #expect(!controller.nextButton.isEnabled)
        #expect(offset(controller.oursViewer) == CGFloat(layout.sideStarts[1]) * height)
        #expect(offset(controller.theirsViewer) == offset(controller.oursViewer))
        #expect(offset(controller.resultViewer) == CGFloat(layout.resultStarts[1]) * height)

        press(controller.nextButton)
        #expect(controller.currentConflict == 1, "Next at the last conflict stays put")

        press(controller.previousButton)
        #expect(controller.currentConflict == 0)
        #expect(offset(controller.oursViewer) == CGFloat(layout.sideStarts[0]) * height)
        #expect(offset(controller.resultViewer) == CGFloat(layout.resultStarts[0]) * height)
    }

    @Test("a file shown before the view loads is scrolled to its first conflict once the panes are laid out")
    func showBeforeLoadScrollsToFirstConflict() throws {
        let controller = GitMergeViewController(coloring: nil)
        controller.show(path: "f.txt", document: try #require(GitConflictDocument.parse(Self.longText)))
        #expect(!controller.isViewLoaded, "show must not load the view itself")

        controller.view.frame = NSRect(x: 0, y: 0, width: 900, height: 600)
        controller.view.layoutSubtreeIfNeeded()

        let layout = try #require(controller.layout)
        let height = controller.oursViewer.rowHeight
        #expect(layout.sideStarts[0] == 40)
        #expect(offset(controller.oursViewer) == CGFloat(layout.sideStarts[0]) * height)
        #expect(offset(controller.theirsViewer) == offset(controller.oursViewer))
        #expect(offset(controller.resultViewer) == CGFloat(layout.resultStarts[0]) * height)
        #expect(controller.positionLabel.stringValue == "1 of 2")
        #expect(!controller.previousButton.isEnabled)
        #expect(controller.nextButton.isEnabled)
    }

    @Test("Ours, Theirs and Both set the current conflict's choice and redraw")
    func sideButtons() throws {
        let (controller, _) = try loaded()

        try #require(controller.oursViewer.dataSource?.rowCount == 6)
        press(controller.oursButton)
        #expect(controller.choices == [0: .ours])
        #expect(controller.oursViewer.dataSource?.row(at: 1).background == .added)

        press(controller.theirsButton)
        #expect(controller.choices == [0: .theirs])
        #expect(controller.theirsViewer.dataSource?.row(at: 1).background == .added)

        press(controller.nextButton)
        press(controller.bothButton)
        #expect(controller.choices == [0: .theirs, 1: .oursThenTheirs])
        #expect(controller.resultViewer.dataSource?.rowCount == 6)
    }

    @Test("Base is enabled only on a conflict that recorded a base")
    func baseNeedsABase() throws {
        let (controller, _) = try loaded()
        #expect(!controller.baseButton.isEnabled)
        press(controller.baseButton)
        #expect(controller.choices.isEmpty)

        press(controller.nextButton)
        #expect(controller.baseButton.isEnabled)
        press(controller.baseButton)
        #expect(controller.choices == [1: .base])
    }

    @Test("Save is disabled until every conflict is chosen, then sends the exact resolved text")
    func saveSendsResolved() throws {
        let (controller, delegate) = try loaded()
        #expect(!controller.saveButton.isEnabled)
        press(controller.oursButton)
        #expect(!controller.saveButton.isEnabled)
        press(controller.saveButton)
        #expect(delegate.intents.isEmpty)

        press(controller.nextButton)
        press(controller.baseButton)
        #expect(controller.saveButton.isEnabled)
        press(controller.saveButton)
        #expect(delegate.intents == [.save(path: "f.txt", text: "top\nours one\nours two\nmiddle\ny\nbottom\n")])
    }

    @Test("Cancel sends cancel")
    func cancel() throws {
        let (controller, delegate) = try loaded()
        press(controller.cancelButton)
        #expect(delegate.intents == [.cancel])
    }

    @Test("a second show starts over: no choices, the first conflict current")
    func showResets() throws {
        let (controller, _) = try loaded()
        press(controller.oursButton)
        press(controller.nextButton)
        controller.show(path: "g.txt", document: try #require(GitConflictDocument.parse(gitMergeFixtureText)))
        #expect(controller.choices.isEmpty)
        #expect(controller.currentConflict == 0)
        #expect(controller.path == "g.txt")
    }

    @Test("the panes are syntax-coloured once the colouring lands")
    func coloured() async throws {
        let text = "<<<<<<< HEAD\nlet a = 1\n=======\nlet b = 2\n>>>>>>> side\n"
        let (controller, _) = try loaded(text, coloring: try GitTextMateFixture.coloring())
        controller.show(path: "f.swift", document: try #require(GitConflictDocument.parse(text)))
        await controller.colourTask?.value
        try #require(controller.oursViewer.dataSource?.rowCount == 1)
        try #require(controller.theirsViewer.dataSource?.rowCount == 1)
        #expect(controller.oursViewer.dataSource?.row(at: 0).runs.contains { $0.foreground != nil } == true)
        #expect(controller.theirsViewer.dataSource?.row(at: 0).runs.contains { $0.foreground != nil } == true)
    }
}
