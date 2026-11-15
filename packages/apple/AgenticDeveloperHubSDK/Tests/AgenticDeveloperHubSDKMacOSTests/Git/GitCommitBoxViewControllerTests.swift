import AppKit
import Foundation
import Testing
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKMacOS

@Suite("GitCommitBoxViewController")
@MainActor
struct GitCommitBoxViewControllerTests {

    /// A loaded box whose commits and amend toggles are recorded in order.
    private final class Recorder {
        var commits: [(message: String, amend: Bool)] = []
        var amends: [Bool] = []
    }

    private static func box(_ recorder: Recorder) -> GitCommitBoxViewController {
        let box = GitCommitBoxViewController()
        box.onCommit = { message, amend in recorder.commits.append((message, amend)) }
        box.onAmendChanged = { recorder.amends.append($0) }
        box.loadViewIfNeeded()
        return box
    }

    /// Types `text` the way the user would: the text view's string changes and it says so.
    private func type(_ text: String, into box: GitCommitBoxViewController) {
        box.messageView.string = text
        box.messageView.didChangeText()
    }

    @Test("the controls carry their identifiers, titles and ⌘↩, and the message is plain text")
    func controls() {
        let box = Self.box(Recorder())
        #expect(box.view.accessibilityIdentifier() == "git.commitBox")
        #expect(box.headerLabel.stringValue == "Commit Message")
        #expect(box.headerLabel.accessibilityIdentifier() == "git.commitBox.header")
        #expect(box.messageView.accessibilityIdentifier() == "git.commitBox.message")
        #expect(box.messageView.isRichText == false)
        #expect(box.messageView.enclosingScrollView != nil)
        #expect(box.amendBox.title == "Amend")
        #expect(box.amendBox.accessibilityIdentifier() == "git.commitBox.amend")
        #expect(box.commitButton.title == "Commit")
        #expect(box.commitButton.accessibilityIdentifier() == "git.commitBox.commit")
        #expect(box.commitButton.keyEquivalent == "\r")
        #expect(box.commitButton.keyEquivalentModifierMask == .command)
    }

    @Test("Commit is disabled for an empty or blank message and with nothing staged, enabled with amend")
    func enabling() {
        let box = Self.box(Recorder())
        box.canAmend = true
        #expect(box.commitButton.isEnabled == false)

        box.hasStagedChanges = true
        #expect(box.commitButton.isEnabled == false)
        type("  \n\t ", into: box)
        #expect(box.commitButton.isEnabled == false)
        type("Fix", into: box)
        #expect(box.commitButton.isEnabled == true)

        box.hasStagedChanges = false
        #expect(box.commitButton.isEnabled == false)
        box.isAmend = true
        #expect(box.commitButton.isEnabled == true)
        box.message = " "
        #expect(box.commitButton.isEnabled == false)
    }

    @Test("pressing Commit sends the message as typed and the amend state")
    func commit() {
        let recorder = Recorder()
        let box = Self.box(recorder)
        box.hasStagedChanges = true
        type("Subject\n\nBody line\n", into: box)
        box.commitButton.performClick(nil)
        #expect(recorder.commits.count == 1)
        #expect(recorder.commits.first?.message == "Subject\n\nBody line\n")
        #expect(recorder.commits.first?.amend == false)

        box.canAmend = true
        box.amendBox.performClick(nil)
        box.commitButton.performClick(nil)
        #expect(recorder.commits.count == 2)
        #expect(recorder.commits.last?.amend == true)
    }

    @Test("toggling Amend reports each new state; setting isAmend reports nothing")
    func amendToggle() {
        let recorder = Recorder()
        let box = Self.box(recorder)
        box.canAmend = true
        box.amendBox.performClick(nil)
        #expect(recorder.amends == [true])
        #expect(box.isAmend == true)
        box.amendBox.performClick(nil)
        #expect(recorder.amends == [true, false])
        box.isAmend = true
        #expect(recorder.amends == [true, false])
        #expect(box.amendBox.state == .on)
    }

    @Test("canAmend false disables and unticks the checkbox without a report")
    func cannotAmend() {
        let recorder = Recorder()
        let box = Self.box(recorder)
        #expect(box.amendBox.isEnabled == false)
        box.canAmend = true
        #expect(box.amendBox.isEnabled == true)
        box.amendBox.performClick(nil)
        type("Fix", into: box)
        #expect(box.commitButton.isEnabled == true)

        box.canAmend = false
        #expect(box.amendBox.isEnabled == false)
        #expect(box.amendBox.state == .off)
        #expect(box.isAmend == false)
        #expect(box.commitButton.isEnabled == false)
        #expect(recorder.amends == [true])
        box.isAmend = true
        #expect(box.isAmend == false)
    }

    @Test("a disabled Commit sends nothing")
    func disabledCommit() {
        let recorder = Recorder()
        let box = Self.box(recorder)
        box.commitButton.performClick(nil)
        #expect(recorder.commits.isEmpty)
    }

    @Test("the message can be set and read before the view loads")
    func beforeLoad() {
        let box = GitCommitBoxViewController()
        box.message = "Early"
        #expect(box.message == "Early")
        box.loadViewIfNeeded()
        #expect(box.messageView.string == "Early")
    }

    @Test("the message view fills the box's height, so a click anywhere in it lands in the text")
    func messageFillsTheBox() {
        let box = Self.box(Recorder())
        box.view.frame = NSRect(x: 0, y: 0, width: 300, height: 200)
        box.view.layoutSubtreeIfNeeded()
        box.viewDidLayout()
        let height = box.messageView.enclosingScrollView?.contentSize.height ?? 0
        #expect(height > 40)
        #expect(box.messageView.autoresizingMask.contains(.height))
        #expect(box.messageView.minSize.height == height)
        #expect(box.messageView.frame.height >= height)
    }

    @Test("the message keeps its own undo stack, which clearUndoHistory empties")
    func undoHistory() {
        let box = Self.box(Recorder())
        #expect(box.messageView.undoManager === box.messageUndoManager)
        box.messageUndoManager.registerUndo(withTarget: box) { _ in }
        #expect(box.messageUndoManager.canUndo)
        box.clearUndoHistory()
        #expect(!box.messageUndoManager.canUndo)
    }
}
