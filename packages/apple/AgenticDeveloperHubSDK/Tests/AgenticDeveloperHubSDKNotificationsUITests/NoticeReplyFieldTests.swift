import AppKit
import XCTest
import AgenticDeveloperHubSDKNotifications
@testable import AgenticDeveloperHubSDKNotificationsUI

/// The reply field: the one place a floating card takes typing. Panels are
/// built but never ordered front, so no test leaves a window on screen.
@MainActor
final class NoticeReplyFieldTests: XCTestCase {

    private final class Recorder {
        var responses: [(String, String?)] = []
        var acts = 0
    }

    private func replyNotice() -> Notice {
        Notice(
            id: "q", source: "agent", title: "Which branch?", urgency: .soon,
            actions: [.init(id: "answer", label: "Reply", kind: .reply(placeholder: "Branch name"))])
    }

    private func makeCard(_ notice: Notice, recorder: Recorder) -> (NoticePanel, NoticeCardView) {
        _ = NSApplication.shared
        let actions = NoticeCardActions(
            act: { recorder.acts += 1 },
            respond: { recorder.responses.append(($0, $1)) },
            snooze: { _ in }, archive: {}, close: {})
        let panel = NoticePanel(layer: .floating, hideFromSharing: false)
        let card = NoticeCardView(notice: notice, actions: actions, style: .toast)
        panel.contentView = card
        card.layoutSubtreeIfNeeded()
        panel.setContentSize(card.fittingSize)
        card.layoutSubtreeIfNeeded()
        return (panel, card)
    }

    func testCardWithoutAReplyActionHasNoField() {
        let recorder = Recorder()
        let (panel, card) = makeCard(Notice(source: "ci", title: "Done"), recorder: recorder)
        defer { panel.close() }
        XCTAssertNil(card.replyField)
    }

    func testReplyFieldShowsThePlaceholder() throws {
        let recorder = Recorder()
        let (panel, card) = makeCard(replyNotice(), recorder: recorder)
        defer { panel.close() }
        let field = try XCTUnwrap(card.replyField)
        XCTAssertEqual(field.placeholderString ?? field.placeholderAttributedString?.string, "Branch name")
        XCTAssertTrue(field.isEditable)
        XCTAssertTrue(card.actionButtons.isEmpty, "a reply action is a field, not a button")
    }

    /// The carried Task 8 finding: the card claimed every click on a text
    /// field, so the reply field could never be clicked into.
    func testClickOnReplyFieldReachesTheFieldAndAllowsKey() throws {
        let recorder = Recorder()
        let (panel, card) = makeCard(replyNotice(), recorder: recorder)
        defer { panel.close() }
        let field = try XCTUnwrap(card.replyField)
        XCTAssertGreaterThan(field.bounds.width, 0)

        let center = NSPoint(x: field.bounds.midX, y: field.bounds.midY)
        let inSuperview = field.convert(center, to: card.superview)
        let hit = card.hitTest(inSuperview)
        XCTAssertTrue(hit === field, "the click lands in the field, got \(String(describing: hit))")

        // A label still belongs to the card.
        let title = card.titleLabel.convert(
            NSPoint(x: card.titleLabel.bounds.midX, y: card.titleLabel.bounds.midY), to: card.superview)
        XCTAssertTrue(card.hitTest(title) === card)

        XCTAssertFalse(panel.allowKeyForReply)
        let inWindow = field.convert(center, to: nil)
        let down = try XCTUnwrap(NSEvent.mouseEvent(
            with: .leftMouseDown, location: inWindow, modifierFlags: [], timestamp: 0,
            windowNumber: panel.windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: 1))
        let release = try XCTUnwrap(NSEvent.mouseEvent(
            with: .leftMouseUp, location: inWindow, modifierFlags: [], timestamp: 0,
            windowNumber: panel.windowNumber, context: nil, eventNumber: 1, clickCount: 1, pressure: 0))
        // The field editor tracks the click until the button comes up.
        NSApp.postEvent(release, atStart: false)
        hit?.mouseDown(with: down)

        XCTAssertTrue(panel.allowKeyForReply, "clicking into the field lets the panel take typing")
        XCTAssertTrue(panel.canBecomeKey)
        XCTAssertEqual(recorder.acts, 0, "a click in the field does not act on the notice")

        // Once editing, the click lands in the field editor, which must also
        // stay the field's.
        if let editor = field.currentEditor() as? NSTextView {
            let editorPoint = editor.convert(NSPoint(x: editor.bounds.midX, y: editor.bounds.midY), to: card.superview)
            XCTAssertFalse(card.hitTest(editorPoint) === card)
        }
    }

    func testReturnSendsTheReply() throws {
        let recorder = Recorder()
        let (panel, card) = makeCard(replyNotice(), recorder: recorder)
        defer { panel.close() }
        let field = try XCTUnwrap(card.replyField)
        let newline = #selector(NSResponder.insertNewline(_:))

        field.stringValue = "   "
        XCTAssertTrue(card.control(field, textView: NSTextView(), doCommandBy: newline))
        XCTAssertTrue(recorder.responses.isEmpty, "an empty reply is not sent")

        field.stringValue = "main"
        XCTAssertTrue(card.control(field, textView: NSTextView(), doCommandBy: newline))
        XCTAssertEqual(recorder.responses.map(\.0), ["answer"])
        XCTAssertEqual(recorder.responses.map(\.1), ["main"])
    }

    func testEscapeClearsAndGivesUpKey() throws {
        let recorder = Recorder()
        let (panel, card) = makeCard(replyNotice(), recorder: recorder)
        defer { panel.close() }
        let field = try XCTUnwrap(card.replyField)
        card.beginReply()
        XCTAssertTrue(panel.allowKeyForReply)
        field.stringValue = "half a thought"

        XCTAssertTrue(card.control(
            field, textView: NSTextView(), doCommandBy: #selector(NSResponder.cancelOperation(_:))))
        XCTAssertEqual(field.stringValue, "")
        XCTAssertFalse(panel.allowKeyForReply)
        XCTAssertFalse(panel.canBecomeKey)
        XCTAssertTrue(recorder.responses.isEmpty)
    }

    func testFocusReplyPutsTheCursorInTheField() throws {
        let recorder = Recorder()
        let (panel, card) = makeCard(replyNotice(), recorder: recorder)
        defer { panel.close() }
        let field = try XCTUnwrap(card.replyField)
        card.focusReply()
        XCTAssertTrue(panel.allowKeyForReply)
        let responder = panel.firstResponder
        XCTAssertTrue(
            responder === field || responder === field.currentEditor(), "got \(String(describing: responder))")
    }

    func testReplyingPausesTheCountdown() throws {
        let recorder = Recorder()
        let (panel, card) = makeCard(replyNotice(), recorder: recorder)
        defer { panel.close() }
        card.startAutoDismiss(after: 8)
        card.setInOverflow(false)
        XCTAssertTrue(card.isCountdownRunning)
        card.beginReply()
        XCTAssertFalse(card.isCountdownRunning, "a card being answered does not time out")
        card.endReply()
        XCTAssertTrue(card.isCountdownRunning)
        card.stop()
    }
}
