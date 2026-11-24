// Tests/AgenticDeveloperHubSDKMacOSTests/Chat/AIChatBubbleLayoutConformanceTests.swift
import AgenticDeveloperHubSDKCoreUI
import AgenticDeveloperHubSDKUI
import AppKit
import XCTest
@testable import AgenticDeveloperHubSDKCore
@testable import AgenticDeveloperHubSDKCoreMacOS
@testable import AgenticDeveloperHubSDKMacOS

/// Conformance vectors chat-bubble-023 ... chat-bubble-047: the line limit, the
/// expand toggle, the bubble's width, selection, the mouse and the theme change.
@MainActor
final class AIChatBubbleLayoutConformanceTests: AIChatBubbleConformanceCase {

    // MARK: - Line limit

    func testV023_aLongMessageIsCutAtThreeLinesAndEndsInAnEllipsis() throws {
        let made = bubble(text: lines(6), lineLimit: 3)
        XCTAssertTrue(made.isTruncated)
        XCTAssertEqual(try shownText(of: made), "line 0\nline 1\nline 2…")
    }

    func testV024_aMessageUnderTheLimitIsWhole() throws {
        let made = bubble(text: lines(2), lineLimit: 3)
        XCTAssertFalse(made.isTruncated)
        XCTAssertEqual(try shownText(of: made), lines(2))
    }

    func testV025_anExpandedMessageIsWhole() throws {
        let made = bubble(text: lines(6), lineLimit: 3, isExpanded: true)
        XCTAssertFalse(made.isTruncated)
        XCTAssertEqual(try shownText(of: made), lines(6))
    }

    func testV026_noLimitMeansWholeAndNoToggle() throws {
        let made = bubble(text: lines(20), lineLimit: nil)
        XCTAssertFalse(made.isTruncated)
        XCTAssertFalse(made.isExpandable)
        XCTAssertEqual(try shownText(of: made), lines(20))
        XCTAssertTrue(try toggle(of: made).isHidden)
    }

    // MARK: - Expand toggle

    func testV027_theToggleIsVisibleWhenTheTextRunsPastTheLimit() throws {
        XCTAssertFalse(try toggle(of: bubble(text: lines(6), lineLimit: 3)).isHidden)
    }

    func testV028_theToggleIsHiddenWhenTheTextJustFits() throws {
        XCTAssertTrue(try toggle(of: bubble(text: lines(3), lineLimit: 3)).isHidden)
    }

    func testV029_theCollapsedToggleIsADownChevronTintedLikeTheText() throws {
        let made = bubble(role: .assistant, text: lines(6), lineLimit: 3)
        let button = try toggle(of: made)
        let image = try XCTUnwrap(button.image)
        XCTAssertEqual(try XCTUnwrap(image.tiffRepresentation), try symbolBytes("chevron.down.circle.fill"))
        XCTAssertNotEqual(try XCTUnwrap(image.tiffRepresentation), try symbolBytes("chevron.up.circle.fill"))
        XCTAssertEqual(button.accessibilityLabel(), "Show the whole message")
        XCTAssertEqual(button.toolTip, "Show the whole message")
        XCTAssertEqual(button.contentTintColor, try textColor(of: made))
    }

    func testV030_theExpandedToggleIsAnUpChevron() throws {
        let button = try toggle(of: bubble(text: lines(6), lineLimit: 3, isExpanded: true))
        let image = try XCTUnwrap(button.image)
        XCTAssertEqual(try XCTUnwrap(image.tiffRepresentation), try symbolBytes("chevron.up.circle.fill"))
        XCTAssertEqual(button.accessibilityLabel(), "Show less")
        XCTAssertEqual(button.toolTip, "Show less")
    }

    func testV031_theToggleCallsTheHandlerAndDoesNotFlipTheState() throws {
        let made = bubble(text: lines(6), lineLimit: 3)
        var calls = 0
        made.onToggleExpanded = { calls += 1 }
        try toggle(of: made).performClick(nil)
        XCTAssertEqual(calls, 1)
        XCTAssertFalse(made.isExpanded)
        XCTAssertTrue(made.isTruncated)
    }

    func testV032_theToggleIsDisabledWithoutAHandler() throws {
        XCTAssertFalse(try toggle(of: bubble(text: lines(6), lineLimit: 3)).isEnabled)
    }

    func testV033_theToggleIsEnabledWithAHandler() throws {
        let made = bubble(text: lines(6), lineLimit: 3)
        made.onToggleExpanded = {}
        XCTAssertTrue(try toggle(of: made).isEnabled)
        made.onToggleExpanded = nil
        XCTAssertFalse(try toggle(of: made).isEnabled)
    }

    // MARK: - Expanded state

    func testV034_flippingIsExpandedRemeasuresAndShowsTheWholeText() throws {
        let made = bubble(text: lines(6), lineLimit: 3)
        XCTAssertEqual(try shownText(of: made), "line 0\nline 1\nline 2…")
        let before = try XCTUnwrap(made.layer).frame.height

        made.isExpanded = true
        relayout(made)

        XCTAssertEqual(try shownText(of: made), lines(6))
        XCTAssertFalse(made.isTruncated)
        XCTAssertGreaterThan(made.frame.height, before, "the bubble did not grow to hold the whole text")
    }

    func testV035_settingIsExpandedToItsCurrentValueDoesNotRerender() throws {
        let opened = bubble(text: lines(6), lineLimit: 3, isExpanded: true)
        XCTAssertEqual(try shownText(of: opened), lines(6), "the value given at init was not honored")

        let made = bubble(text: lines(6), lineLimit: 3)
        let storage = try XCTUnwrap(textView(of: made).textStorage)
        storage.setAttributedString(NSAttributedString(string: "sentinel"))

        made.isExpanded = false
        XCTAssertEqual(try shownText(of: made), "sentinel", "an unchanged value re-rendered the bubble")

        made.isExpanded = true
        XCTAssertNotEqual(try shownText(of: made), "sentinel", "a changed value did not re-render the bubble")
    }

    // MARK: - Width

    func testV036_aShortBubbleIsItsContentPlusTwentyFour() throws {
        let made = bubble(text: "ok", maxWidth: 300, fillsWidthWhenWrapped: false)
        let view = try textView(of: made)
        XCTAssertEqual(made.frame.width, view.frame.width + 24, accuracy: 0.01)
        XCTAssertLessThanOrEqual(made.frame.width, 300)
        XCTAssertLessThan(made.frame.width, 100, "a two-letter message is not a narrow bubble")
        let measured = ceil(try XCTUnwrap(view.textStorage).boundingRect(
            with: NSSize(width: 276, height: 1000), options: [.usesLineFragmentOrigin]).width)
        XCTAssertEqual(view.frame.width, measured, accuracy: 2)
    }

    func testV037_aWrappedBubbleThatFillsIsExactlyMaxWidth() throws {
        let made = bubble(text: wrapping, maxWidth: 300, fillsWidthWhenWrapped: true)
        XCTAssertGreaterThan(try lineCount(of: made), 1, "the text did not wrap")
        XCTAssertEqual(made.frame.width, 300, accuracy: 0.01)
    }

    func testV038_aSingleLineBubbleThatFillsStaysAtItsContentWidth() throws {
        let made = bubble(text: "ok", maxWidth: 300, fillsWidthWhenWrapped: true)
        XCTAssertEqual(try lineCount(of: made), 1)
        XCTAssertEqual(made.frame.width, try textView(of: made).frame.width + 24, accuracy: 0.01)
        XCTAssertLessThan(made.frame.width, 300)
    }

    func testV039_fillingRelaxesBothWidthConstraintsByOnePoint() throws {
        let filling = bubble(text: wrapping, fillsWidthWhenWrapped: true)
        let relaxed = NSLayoutConstraint.Priority(rawValue: NSLayoutConstraint.Priority.required.rawValue - 1)
        XCTAssertEqual(try widthConstraint(of: filling, on: filling).priority, relaxed)
        let field = try textView(of: filling)
        XCTAssertEqual(try widthConstraint(of: field, on: field).priority, relaxed)

        let fixed = bubble(text: wrapping, fillsWidthWhenWrapped: false)
        XCTAssertEqual(try widthConstraint(of: fixed, on: fixed).priority, .required)
        let fixedField = try textView(of: fixed)
        XCTAssertEqual(try widthConstraint(of: fixedField, on: fixedField).priority, .required)
    }

    private func widthConstraint(of item: NSView, on holder: NSView) throws -> NSLayoutConstraint {
        let everywhere = holder.constraints + (holder.superview?.constraints ?? [])
        return try XCTUnwrap(everywhere.first {
            $0.firstItem === item && $0.firstAttribute == .width && $0.secondItem == nil
        }, "no width constraint on \(item)")
    }

    // MARK: - Selection

    func testV040_textIsSelectableWhenAskedFor() throws {
        XCTAssertTrue(try textView(of: bubble(isTextSelectable: true)).isSelectable)
    }

    func testV041_textIsNotSelectableWhenNotAskedFor() throws {
        XCTAssertFalse(try textView(of: bubble(isTextSelectable: false)).isSelectable)
    }

    func testV042_selectionAndCaretColorsComeFromThePalette() throws {
        let view = try textView(of: bubble())
        XCTAssertEqual(view.selectedTextAttributes[.backgroundColor] as? NSColor, palette.nsColor(.selection))
        XCTAssertEqual(view.selectedTextAttributes[.foregroundColor] as? NSColor, palette.nsColor(.selectionText))
        XCTAssertEqual(view.insertionPointColor, palette.nsColor(.cursor))
    }

    // MARK: - Mouse

    func testV043_aDoubleClickGoesToTheHandlerAndSelectsNoWord() throws {
        let made = bubble(text: "select these words")
        var doubles = 0
        made.onDoubleClick = { doubles += 1 }
        let view = try textView(of: made)
        view.mouseDown(with: try mouseDown(clickCount: 2, in: made))
        XCTAssertEqual(doubles, 1)
        XCTAssertEqual(view.selectedRange().length, 0, "the default double-click selected a word")

        made.mouseDown(with: try mouseDown(clickCount: 2, in: made))
        XCTAssertEqual(doubles, 2, "a double-click on the bubble itself did not reach the handler")
    }

    func testV044_aSingleClickOnTextStartsASelectionDrag() throws {
        throw XCTSkip("NSTextView.mouseDown runs a tracking loop until the window server delivers a mouse-up")
    }

    func testV045_aDoubleClickWithoutAHandlerSelectsAWord() throws {
        throw XCTSkip("NSTextView.mouseDown runs a tracking loop until the window server delivers a mouse-up")
    }

    func testV046_aClickOnTheBubblesPaddingIsReportedAndKeptWhenSelectable() throws {
        let selectable = bubble(isTextSelectable: true)
        var clicks = 0
        selectable.onSingleClick = { clicks += 1 }
        selectable.mouseDown(with: try mouseDown(clickCount: 1, in: selectable))
        XCTAssertEqual(clicks, 1)
        let selectableHost = try XCTUnwrap(selectable.superview as? BubblePressRecorder)
        XCTAssertEqual(selectableHost.presses, 0, "the press was forwarded up the responder chain")

        // The contrast that makes the line above mean something: this bubble
        // does hand the press on, and the recorder sees it.
        let passive = bubble(isTextSelectable: false)
        passive.mouseDown(with: try mouseDown(clickCount: 1, in: passive))
        XCTAssertEqual(try XCTUnwrap(passive.superview as? BubblePressRecorder).presses, 1)
    }

    // MARK: - Theme change

    func testV047_aThemeChangeRestylesTheSameBubbleInPlace() throws {
        let first = customTheme(from: BuiltInThemes.dracula)
        let second = customTheme(
            from: BuiltInThemes.nord, terminal: ThemeTerminalOptions(fontName: "Courier", fontSize: 17))
        let made = useTheme(first, alongside: [second])
        let bubbleView = bubble(role: .user, text: "hello there")
        let identity = ObjectIdentifier(bubbleView)
        let before = palette
        let widthBefore = bubbleView.frame.width

        made.selectTheme(id: second.id)
        relayout(bubbleView)
        let after = palette

        XCTAssertNotEqual(before.nsColor(.userBubble), after.nsColor(.userBubble), "the themes agree on the fill")
        XCTAssertEqual(try XCTUnwrap(bubbleView.layer).backgroundColor, after.nsColor(.userBubble).cgColor)
        XCTAssertEqual(try textColor(of: bubbleView), after.nsColor(.userText))
        let restyled = try font(at: 0, in: bubbleView)
        XCTAssertEqual(restyled.fontName, "Courier")
        XCTAssertEqual(restyled.pointSize, 17, accuracy: 0.01)
        XCTAssertNotEqual(bubbleView.frame.width, widthBefore, "the bubble was not measured again")
        XCTAssertEqual(ObjectIdentifier(bubbleView), identity)
    }
}
