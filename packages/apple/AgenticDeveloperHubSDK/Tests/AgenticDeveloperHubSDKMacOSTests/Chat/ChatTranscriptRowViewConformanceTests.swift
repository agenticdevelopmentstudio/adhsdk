// Tests/AgenticDeveloperHubSDKMacOSTests/Chat/ChatTranscriptRowViewConformanceTests.swift
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKCoreMacOS
import AgenticDeveloperHubSDKUI
import AppKit
import XCTest
@testable import AgenticDeveloperHubSDKMacOS

/// Conformance vectors for `ChatTranscriptRowView`: header and icon wiring,
/// alignment, the press gestures, hit-testing, hover and selection styling,
/// the delivery marks and the live theme repaint.
@MainActor
final class ChatTranscriptRowViewConformanceTests: XCTestCase {

    /// A `ThemeStorage` with nothing behind it, so a test can run a real
    /// `ThemeManager` without touching `UserSettings` or `UserDefaults`.
    private final class StubThemeStorage: ThemeStorage {
        var customThemes: [ColorTheme] = []
        var activeThemeID: String?
        var onExternalChange: (() -> Void)?
    }

    /// The row's parent. Records the presses the row passes up the responder
    /// chain, which is what "the default press handling still runs" means.
    private final class PressRecorderView: NSView {
        var mouseDowns = 0
        var mouseUps = 0
        override func mouseDown(with event: NSEvent) { mouseDowns += 1 }
        override func mouseUp(with event: NSEvent) { mouseUps += 1 }
    }

    private final class EventLog {
        var events: [String] = []
        var messages: [ChatMessage] = []
    }

    private struct Fixture {
        let row: ChatTranscriptRowView
        let host: PressRecorderView
    }

    private var windows: [NSWindow] = []

    override func tearDown() async throws {
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
        try await super.tearDown()
    }

    // MARK: - Fixtures

    private func makeMessage(
        role: ChatMessage.Role = .assistant,
        text: String = "hello there",
        attributed: Bool = true,
        appIdentity: String = "iTerm2",
        delivery: ChatMessage.Delivery = .settled
    ) -> ChatMessage {
        var message = ChatMessage(
            id: "msg-\(UUID().uuidString)",
            role: role,
            text: text,
            attribution: attributed
                ? .init(
                    sourceID: "s1", context: ["proj", "main"], name: "a session",
                    iconSymbol: "sparkles", appIdentity: appIdentity)
                : nil)
        message.delivery = delivery
        return message
    }

    private func logging(_ log: EventLog, open: Bool = true, jump: Bool = true, select: Bool = true,
                         toggle: Bool = true) -> ChatTranscriptRowView.Actions {
        ChatTranscriptRowView.Actions(
            onOpen: open ? { log.events.append("open"); log.messages.append($0) } : nil,
            onJump: jump ? { log.events.append("jump"); log.messages.append($0) } : nil,
            onToggleExpanded: toggle ? { log.events.append("toggle"); log.messages.append($0) } : nil,
            onSelect: select ? { log.events.append("select"); log.messages.append($0) } : nil)
    }

    private func laidOut(
        _ message: ChatMessage,
        actions: ChatTranscriptRowView.Actions = .init(),
        width: CGFloat = 420,
        maxBubbleWidth: CGFloat = 300,
        lineLimit: Int? = nil,
        withCover: Bool = false
    ) -> Fixture {
        let row = ChatTranscriptRowView(
            message: message, maxBubbleWidth: maxBubbleWidth, actions: actions, lineLimit: lineLimit)
        let host = PressRecorderView(frame: NSRect(x: 0, y: 0, width: width, height: 400))
        let window = NSWindow(contentRect: host.frame, styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView = host
        windows.append(window)
        host.addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            row.topAnchor.constraint(equalTo: host.topAnchor)
        ])
        host.layoutSubtreeIfNeeded()
        if withCover {
            let cover = NSView(frame: host.bounds)
            cover.autoresizingMask = [.width, .height]
            host.addSubview(cover)
        }
        host.layoutSubtreeIfNeeded()
        return Fixture(row: row, host: host)
    }

    private func descendants(of view: NSView) -> [NSView] {
        view.subviews + view.subviews.flatMap { descendants(of: $0) }
    }

    private func icon(in row: ChatTranscriptRowView) -> NSButton? {
        descendants(of: row).compactMap { $0 as? NSButton }
            .first { $0.accessibilityIdentifier() == "chat-row.jump" }
    }

    private func header(in row: ChatTranscriptRowView) throws -> SessionHeaderView {
        try XCTUnwrap(row.subviews.compactMap { $0 as? SessionHeaderView }.first, "the row has no header")
    }

    private func bubble(in row: ChatTranscriptRowView) throws -> AIChatBubbleView {
        try XCTUnwrap(row.subviews.compactMap { $0 as? AIChatBubbleView }.first, "the row has no bubble")
    }

    private func timeLabel(in row: ChatTranscriptRowView) throws -> NSTextField {
        try XCTUnwrap(
            row.subviews.compactMap { $0 as? NSTextField }
                .first { $0.stringValue.range(of: #"^\d{1,2}:\d{2}"#, options: .regularExpression) != nil },
            "the row has no timestamp")
    }

    private func failureLabel(in row: ChatTranscriptRowView, reason: String) throws -> NSTextField {
        try XCTUnwrap(
            row.subviews.compactMap { $0 as? NSTextField }.first { $0.stringValue == reason },
            "the row has no failure label")
    }

    private func bubbleText(_ bubble: AIChatBubbleView) -> String {
        bubble.subviews.compactMap { ($0 as? NSTextView)?.string }.first ?? ""
    }

    /// A descendant's alignment rect in the row's own coordinates.
    private func aligned(_ view: NSView, in row: NSView) -> NSRect {
        row.convert(view.alignmentRect(forFrame: view.frame), from: view.superview)
    }

    private func palette(of row: NSView) -> SemanticPalette { row.resolvedThemeScope.palette }

    private func mouseEvent(
        _ type: NSEvent.EventType, in view: NSView, clickCount: Int = 1, at point: NSPoint? = nil
    ) -> NSEvent {
        let spot = point ?? NSPoint(x: view.bounds.midX, y: view.bounds.midY)
        if type == .mouseEntered || type == .mouseExited {
            return NSEvent.enterExitEvent(
                with: type, location: view.convert(spot, to: nil), modifierFlags: [],
                timestamp: ProcessInfo.processInfo.systemUptime,
                windowNumber: view.window?.windowNumber ?? 0, context: nil,
                eventNumber: 0, trackingNumber: 0, userData: nil)!
        }
        return NSEvent.mouseEvent(
            with: type, location: view.convert(spot, to: nil), modifierFlags: [],
            timestamp: ProcessInfo.processInfo.systemUptime,
            windowNumber: view.window?.windowNumber ?? 0, context: nil,
            eventNumber: 0, clickCount: clickCount, pressure: 1)!
    }

    /// A point in the row's coordinates, expressed in its superview's, which is
    /// what `hitTest(_:)` takes.
    private func hit(_ row: ChatTranscriptRowView, at point: NSPoint) -> NSView? {
        row.hitTest(row.convert(point, to: row.superview))
    }

    private func centre(of view: NSView, in row: NSView) -> NSPoint {
        let box = row.convert(view.bounds, from: view)
        return NSPoint(x: box.midX, y: box.midY)
    }

    private func lightAndDarkThemeIDs() -> (dark: String, light: String) {
        (BuiltInThemes.solarizedDark.id, BuiltInThemes.solarizedLight.id)
    }

    private func colored(_ color: NSColor, alpha: CGFloat) -> CGColor {
        color.withAlphaComponent(alpha).cgColor
    }

    // MARK: - Header and icon

    func testV1_headerLineIsPresentWithTheAttributionText() throws {
        let message = makeMessage()
        let fixture = laidOut(message)
        let header = try header(in: fixture.row)
        XCTAssertEqual(header.accessibilityLabel(), message.attribution?.headerLine)
        XCTAssertEqual(header.accessibilityLabel(), "proj » main » a session")
    }

    func testV2_noAttributionMeansNoIcon() {
        let fixture = laidOut(makeMessage(attributed: false))
        XCTAssertNil(icon(in: fixture.row))
    }

    func testV3_attributionShowsA28PointIcon() throws {
        let fixture = laidOut(makeMessage())
        let button = try XCTUnwrap(icon(in: fixture.row))
        // The size is set on the button's anchors, its alignment rect; the
        // frame is larger by the bezel's insets.
        let drawn = button.alignmentRect(forFrame: button.frame)
        XCTAssertEqual(drawn.width, 28, accuracy: 0.5)
        XCTAssertEqual(drawn.height, 28, accuracy: 0.5)
    }

    func testV4_iconIsInertWithoutAJumpAction() throws {
        let fixture = laidOut(makeMessage(), actions: .init(onOpen: { _ in }))
        let button = try XCTUnwrap(icon(in: fixture.row))
        XCTAssertNil(button.target)
        XCTAssertNil(button.action)
        XCTAssertNil(button.toolTip)
        XCTAssertEqual(button.accessibilityLabel(), "iTerm2", "the icon's label is not the default one")
    }

    func testV5_wiredIconHasTooltipAndAccessibilityLabel() throws {
        let message = makeMessage(appIdentity: "iTerm2")
        let fixture = laidOut(message, actions: .init(onJump: { _ in }))
        let button = try XCTUnwrap(icon(in: fixture.row))
        XCTAssertEqual(button.toolTip, "Go to this conversation in iTerm2")
        let headerLine = try XCTUnwrap(message.attribution?.headerLine)
        XCTAssertEqual(button.accessibilityLabel(), "Go to \(headerLine)")
    }

    func testV6_clickingTheIconJumpsOnceWithTheMessage() throws {
        let log = EventLog()
        let message = makeMessage()
        let fixture = laidOut(message, actions: logging(log))
        let button = try XCTUnwrap(icon(in: fixture.row))

        button.performClick(nil)

        XCTAssertEqual(log.events, ["jump"])
        XCTAssertEqual(log.messages.map(\.id), [message.id])
    }

    // MARK: - Bubble and timestamp

    func testV7_bubbleCarriesNoInlineTimestamp() throws {
        let fixture = laidOut(makeMessage(text: "just the words"))
        XCTAssertEqual(bubbleText(try bubble(in: fixture.row)), "just the words")
    }

    func testV8_settledRowShowsItsTimestampDirectlyBelowTheBubble() throws {
        let message = makeMessage()
        let fixture = laidOut(message)
        let bubble = try bubble(in: fixture.row)
        let label = try timeLabel(in: fixture.row)
        let box = aligned(label, in: fixture.row)

        XCTAssertEqual(label.stringValue, AIChatBubbleView.timeFormatter.string(from: message.timestamp))
        let gap = bubble.frame.minY - box.maxY
        XCTAssertTrue((-0.5...6).contains(gap), "the timestamp is not directly under the bubble: gap \(gap)")
    }

    func testV9_userRowAnchorsToTheTrailingEdge() throws {
        let fixture = laidOut(makeMessage(role: .user))
        let row = fixture.row
        let header = try header(in: row)
        let trail = aligned(header.breadcrumb, in: row).maxX

        XCTAssertEqual(aligned(header, in: row).maxX, row.bounds.maxX - 8, accuracy: 0.5)
        XCTAssertEqual(try bubble(in: row).frame.maxX, trail, accuracy: 0.5)
        XCTAssertEqual(aligned(try timeLabel(in: row), in: row).maxX, trail, accuracy: 0.5)
    }

    func testV10_nonUserRowAnchorsToTheLeadingEdge() throws {
        let fixture = laidOut(makeMessage(role: .assistant))
        let row = fixture.row
        let header = try header(in: row)
        let lead = aligned(header.breadcrumb, in: row).minX

        XCTAssertEqual(aligned(header, in: row).minX, row.bounds.minX + 8, accuracy: 0.5)
        XCTAssertEqual(try bubble(in: row).frame.minX, lead, accuracy: 0.5)
        XCTAssertEqual(aligned(try timeLabel(in: row), in: row).minX, lead, accuracy: 0.5)
    }

    func testV11_bubbleWidthCapFor400PointRow() {
        XCTAssertEqual(ChatTranscriptRowView.maxBubbleWidth(forRowWidth: 400), 312)
    }

    func testV12_bubbleWidthCapHasAnEightyPointFloor() {
        XCTAssertEqual(ChatTranscriptRowView.maxBubbleWidth(forRowWidth: 50), 80)
    }

    // MARK: - Presses

    func testV13_pressSelectsAndStillReachesTheDefaultHandling() {
        let log = EventLog()
        let message = makeMessage()
        let fixture = laidOut(message, actions: logging(log))

        fixture.row.mouseDown(with: mouseEvent(.leftMouseDown, in: fixture.row))

        XCTAssertEqual(log.events, ["select"])
        XCTAssertEqual(log.messages.map(\.id), [message.id])
        XCTAssertEqual(fixture.host.mouseDowns, 1)
    }

    func testV14_pressWithoutSelectActionStillReachesTheDefaultHandling() {
        let log = EventLog()
        let fixture = laidOut(makeMessage(), actions: logging(log, select: false))

        fixture.row.mouseDown(with: mouseEvent(.leftMouseDown, in: fixture.row))

        XCTAssertEqual(log.events, [])
        XCTAssertEqual(fixture.host.mouseDowns, 1)
    }

    func testV15_doubleClickOpensOnceWithTheMessage() {
        let log = EventLog()
        let message = makeMessage()
        let fixture = laidOut(message, actions: logging(log, select: false))

        fixture.row.mouseUp(with: mouseEvent(.leftMouseUp, in: fixture.row, clickCount: 2))

        XCTAssertEqual(log.events, ["open"])
        XCTAssertEqual(log.messages.map(\.id), [message.id])
    }

    func testV16_singleClickDoesNotOpenAndForwardsTheRelease() {
        let log = EventLog()
        let fixture = laidOut(makeMessage(), actions: logging(log, select: false))

        fixture.row.mouseUp(with: mouseEvent(.leftMouseUp, in: fixture.row, clickCount: 1))

        XCTAssertEqual(log.events, [])
        XCTAssertEqual(fixture.host.mouseUps, 1)
    }

    func testV17_doubleClickReleasedOutsideTheRowDoesNotOpen() {
        let log = EventLog()
        let fixture = laidOut(makeMessage(), actions: logging(log, select: false))
        let row = fixture.row
        let outside = NSPoint(x: row.bounds.maxX + 50, y: row.bounds.midY)

        row.mouseUp(with: mouseEvent(.leftMouseUp, in: row, clickCount: 2, at: outside))

        XCTAssertEqual(log.events, [])
        XCTAssertEqual(fixture.host.mouseUps, 1)
    }

    func testV18_togglingTheBubbleReportsOnceWithTheMessage() throws {
        let log = EventLog()
        let message = makeMessage()
        let fixture = laidOut(message, actions: logging(log))

        try bubble(in: fixture.row).onToggleExpanded?()

        XCTAssertEqual(log.events, ["toggle"])
        XCTAssertEqual(log.messages.map(\.id), [message.id])
    }

    func testV19_bubbleTextIsSelectable() throws {
        let fixture = laidOut(makeMessage())
        let textView = try XCTUnwrap(try bubble(in: fixture.row).subviews.compactMap { $0 as? NSTextView }.first)
        XCTAssertTrue(textView.isSelectable)
    }

    // MARK: - Hit-testing

    func testV20_plainBackgroundHitsTheRow() {
        let fixture = laidOut(makeMessage(text: "short"))
        let row = fixture.row
        let point = NSPoint(x: row.bounds.maxX - 4, y: row.bounds.midY)
        XCTAssertTrue(hit(row, at: point) === row)
    }

    func testV21_bubbleTextHitsTheBubble() throws {
        let fixture = laidOut(makeMessage(text: "some words to hit"))
        let bubble = try bubble(in: fixture.row)
        let target = hit(fixture.row, at: centre(of: bubble, in: fixture.row))
        XCTAssertTrue(target?.isDescendant(of: bubble) ?? false, "hit \(String(describing: target))")
    }

    func testV22_wiredIconHitsTheIconButton() throws {
        let fixture = laidOut(makeMessage(), actions: .init(onJump: { _ in }))
        let button = try XCTUnwrap(icon(in: fixture.row))
        let target = hit(fixture.row, at: centre(of: button, in: fixture.row))
        XCTAssertTrue(target?.isDescendant(of: button) ?? false, "hit \(String(describing: target))")
    }

    func testV23_unwiredIconHitsTheRow() throws {
        let fixture = laidOut(makeMessage(), actions: .init(onOpen: { _ in }))
        let button = try XCTUnwrap(icon(in: fixture.row))
        let target = hit(fixture.row, at: centre(of: button, in: fixture.row))
        XCTAssertTrue(target === fixture.row, "hit \(String(describing: target))")
    }

    func testV24_pointOutsideTheRowHitsNothing() {
        let fixture = laidOut(makeMessage())
        XCTAssertNil(hit(fixture.row, at: NSPoint(x: -10, y: 10)))
    }

    // MARK: - Hover

    func testV25_hoverFillsWithSelectionColourWhenPressable() {
        let fixture = laidOut(makeMessage(), actions: .init(onOpen: { _ in }))
        let row = fixture.row

        row.mouseEntered(with: mouseEvent(.mouseEntered, in: row))

        let expected = colored(palette(of: row).nsColor(.selection), alpha: 0.18)
        XCTAssertEqual(row.layer?.backgroundColor, expected)
    }

    func testV26_noHoverFillWithoutAnOpenAction() {
        let fixture = laidOut(makeMessage(), actions: .init())
        fixture.row.mouseEntered(with: mouseEvent(.mouseEntered, in: fixture.row))
        XCTAssertEqual(fixture.row.layer?.backgroundColor?.alpha ?? 0, 0)
    }

    func testV27_noHoverFillWhileAnotherViewIsFrontmost() {
        let fixture = laidOut(makeMessage(), actions: .init(onOpen: { _ in }), withCover: true)
        fixture.row.mouseEntered(with: mouseEvent(.mouseEntered, in: fixture.row))
        XCTAssertEqual(fixture.row.layer?.backgroundColor?.alpha ?? 0, 0)
    }

    func testV28_exitingRemovesTheHoverFill() {
        let fixture = laidOut(makeMessage(), actions: .init(onOpen: { _ in }))
        let row = fixture.row
        row.mouseEntered(with: mouseEvent(.mouseEntered, in: row))
        XCTAssertGreaterThan(row.layer?.backgroundColor?.alpha ?? 0, 0, "the fixture is wrong: hover did not fill")

        row.mouseExited(with: mouseEvent(.mouseExited, in: row))

        XCTAssertEqual(row.layer?.backgroundColor?.alpha ?? 0, 0)
    }

    func testV29_pointingCursorCoversTheRowWhenPressable() throws {
        throw XCTSkip("Cursor rects are write-only in AppKit: there is no API to read back what a view added")
    }

    func testV30_noCursorWhenNotPressable() throws {
        throw XCTSkip("Cursor rects are write-only in AppKit: there is no API to read back what a view added")
    }

    // MARK: - Selection

    func testV31_selectingDrawsATwoPointSelectionBorder() {
        let fixture = laidOut(makeMessage())
        fixture.row.isSelected = true
        XCTAssertEqual(fixture.row.layer?.borderWidth, 2)
        XCTAssertEqual(fixture.row.layer?.borderColor, palette(of: fixture.row).nsColor(.selection).cgColor)
    }

    func testV32_deselectingRemovesTheBorder() {
        let fixture = laidOut(makeMessage())
        fixture.row.isSelected = true
        fixture.row.isSelected = false
        XCTAssertEqual(fixture.row.layer?.borderWidth, 0)
    }

    func testV33_settingTheSameValueDoesNotRedraw() {
        let fixture = laidOut(makeMessage())
        fixture.row.layer?.borderWidth = 7

        fixture.row.isSelected = false

        XCTAssertEqual(fixture.row.layer?.borderWidth, 7, "an unchanged value re-applied the frame")
    }

    // MARK: - Delivery

    func testV34_sendingShowsTheTypingIndicatorBetweenBubbleAndTimestamp() throws {
        let fixture = laidOut(makeMessage(role: .user, delivery: .sending))
        let row = fixture.row
        let indicator = try XCTUnwrap(row.subviews.compactMap { $0 as? TypingIndicatorView }.first)
        let bubble = try bubble(in: row)
        let label = try timeLabel(in: row)

        XCTAssertLessThanOrEqual(indicator.frame.maxY, bubble.frame.minY + 0.5)
        XCTAssertLessThanOrEqual(label.frame.maxY, indicator.frame.minY + 2.5)
    }

    func testV35_failedShowsTheReasonInCaptionDangerTextWithoutAnIndicator() throws {
        let fixture = laidOut(makeMessage(role: .user, delivery: .failed("Network error")))
        let row = fixture.row
        let label = try failureLabel(in: row, reason: "Network error")
        let palette = palette(of: row)
        let bubble = try bubble(in: row)

        XCTAssertEqual(label.font, palette.font(.caption))
        XCTAssertEqual(label.textColor, palette.nsColor(.danger))
        XCTAssertEqual(label.lineBreakMode, .byWordWrapping)
        XCTAssertEqual(label.maximumNumberOfLines, 0)
        XCTAssertLessThanOrEqual(label.frame.maxY, bubble.frame.minY + 0.5)
        XCTAssertTrue(row.subviews.compactMap { $0 as? TypingIndicatorView }.isEmpty)
    }

    func testV36_settledAddsNothingBetweenBubbleAndTimestamp() throws {
        let fixture = laidOut(makeMessage())
        let row = fixture.row
        XCTAssertEqual(row.subviews.count, 3, "expected only the header, bubble and timestamp")
        let bubble = try bubble(in: row)
        let label = try timeLabel(in: row)
        let gap = bubble.frame.minY - aligned(label, in: row).maxY
        XCTAssertTrue((-0.5...6).contains(gap), "the timestamp is not attached to the bubble: gap \(gap)")
    }

    func testV37_failureLabelIsRemeasuredToItsActualWidth() throws {
        let reason = "Typing into a session needs iTerm2 or Terminal.app; this one runs in Ghostty, which cannot"
            + " be typed into from here"
        let message = makeMessage(role: .assistant, delivery: .failed(reason))
        let fixture = laidOut(message, width: 220, maxBubbleWidth: 300)
        fixture.host.layoutSubtreeIfNeeded()
        let label = try failureLabel(in: fixture.row, reason: reason)

        XCTAssertGreaterThan(label.frame.width, 0)
        XCTAssertLessThan(label.frame.width, 300, "the fixture is wrong: the row is not narrower than the cap")
        XCTAssertEqual(label.preferredMaxLayoutWidth, label.frame.width, accuracy: 0.5)
        let oneLine = NSTextField(labelWithString: "x")
        oneLine.font = label.font
        XCTAssertGreaterThan(label.frame.height, oneLine.fittingSize.height * 1.5, "the reason did not wrap")
    }

    // MARK: - Theme

    func testV38_themeChangeRepaintsTheRowImmediately() throws {
        let ids = lightAndDarkThemeIDs()
        let storage = StubThemeStorage()
        storage.activeThemeID = ids.dark
        let manager = ThemeManager(storage: storage, appearanceDriver: nil)
        try withExtendedLifetime(manager) {
            let reason = "it failed"
            let message = makeMessage(role: .user, delivery: .failed(reason))
            let fixture = laidOut(message, actions: .init(onOpen: { _ in }))
            let row = fixture.row
            row.isSelected = true
            row.mouseEntered(with: mouseEvent(.mouseEntered, in: row))
            let darkSelection = palette(of: row).nsColor(.selection).cgColor

            manager.selectTheme(id: ids.light)

            let fresh = palette(of: row)
            XCTAssertNotEqual(fresh.nsColor(.selection).cgColor, darkSelection, "the fixture's themes do not differ")
            let time = try timeLabel(in: row)
            XCTAssertEqual(time.textColor, fresh.nsColor(.timestampText))
            XCTAssertEqual(time.font, fresh.font(.caption))
            let failure = try failureLabel(in: row, reason: reason)
            XCTAssertEqual(failure.textColor, fresh.nsColor(.danger))
            XCTAssertEqual(failure.font, fresh.font(.caption))
            XCTAssertEqual(row.layer?.borderColor, fresh.nsColor(.selection).cgColor)
            XCTAssertEqual(row.layer?.backgroundColor, colored(fresh.nsColor(.selection), alpha: 0.18))
        }
    }

    // MARK: - Expansion

    private var longText: String { (0..<40).map { "line \($0) of a long reply" }.joined(separator: "\n") }

    func testV39_rowReportsTruncationAndExpandabilityOfItsBubble() throws {
        let fixture = laidOut(makeMessage(text: longText), lineLimit: 3)
        let bubble = try bubble(in: fixture.row)

        XCTAssertTrue(bubble.isTruncated, "the fixture is wrong: the message was not cut")
        XCTAssertEqual(fixture.row.isTruncated, bubble.isTruncated)
        XCTAssertEqual(fixture.row.isExpandable, bubble.isExpandable)
        XCTAssertTrue(fixture.row.isTruncated)
        XCTAssertTrue(fixture.row.isExpandable)
    }

    func testV40_settingIsExpandedOpensTheBubbleOut() throws {
        let fixture = laidOut(makeMessage(text: longText), lineLimit: 3)
        let bubble = try bubble(in: fixture.row)
        XCTAssertFalse(bubbleText(bubble).contains("line 39"), "the fixture is wrong: the message was not cut")

        fixture.row.isExpanded = true
        fixture.host.layoutSubtreeIfNeeded()

        XCTAssertTrue(bubble.isExpanded)
        XCTAssertTrue(bubbleText(bubble).contains("line 39"), "the expanded bubble still hides the message")
    }

    // MARK: - Construction

    func testV41_cornerRadiusIsEightPoints() {
        XCTAssertEqual(laidOut(makeMessage()).row.layer?.cornerRadius, 8)
    }

    func testV42_archivalConstructionIsUnavailable() throws {
        throw XCTSkip("Compile-time unavailability; the runtime fatalError cannot be caught in a test")
    }

    func testV43_doubleClickSelectsBeforeItOpens() {
        let log = EventLog()
        let fixture = laidOut(makeMessage(), actions: logging(log))
        let row = fixture.row

        row.mouseDown(with: mouseEvent(.leftMouseDown, in: row, clickCount: 1))
        row.mouseUp(with: mouseEvent(.leftMouseUp, in: row, clickCount: 1))
        row.mouseDown(with: mouseEvent(.leftMouseDown, in: row, clickCount: 2))
        row.mouseUp(with: mouseEvent(.leftMouseUp, in: row, clickCount: 2))

        XCTAssertEqual(log.events, ["select", "select", "open"])
    }

    func testV44_floorFirstAppliesAt168Points() {
        XCTAssertEqual(ChatTranscriptRowView.maxBubbleWidth(forRowWidth: 168), 80)
    }

    func testV45_floorNoLongerAppliesAt169Points() {
        XCTAssertEqual(ChatTranscriptRowView.maxBubbleWidth(forRowWidth: 169), 81)
    }
}
